#include "desktopfiles.hpp"
#include "uniquefd.hpp"

#include <QFile>
#include <QSet>

#include <dirent.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

#include <algorithm>
#include <array>
#include <cerrno>
#include <memory>
#include <string_view>
#include <system_error>

namespace {

constexpr std::string_view DESKTOP_SUFFIX = ".desktop";
constexpr int MAX_DEPTH = 8;
constexpr std::size_t READ_CHUNK = 16384;

enum class EntryKind { Directory, File, Other };

struct DirEntry {
  std::string name;
  EntryKind kind;
};

struct DirCloser {
  void operator()(DIR *dir) const { ::closedir(dir); }
};
using DirHandle = std::unique_ptr<DIR, DirCloser>;

EntryKind kindOfMode(mode_t mode) {
  if (S_ISDIR(mode))
    return EntryKind::Directory;
  if (S_ISREG(mode))
    return EntryKind::File;
  return EntryKind::Other;
}

EntryKind classify(int dirFd, const dirent &entry) {
  switch (entry.d_type) {
  case DT_DIR:
    return EntryKind::Directory;
  case DT_REG:
    return EntryKind::File;
  case DT_LNK:
  case DT_UNKNOWN:
    break;
  default:
    return EntryKind::Other;
  }

  struct stat self{};
  if (::fstatat(dirFd, entry.d_name, &self, AT_SYMLINK_NOFOLLOW) != 0)
    return EntryKind::Other;
  if (!S_ISLNK(self.st_mode))
    return kindOfMode(self.st_mode);

  struct stat target{};
  if (::fstatat(dirFd, entry.d_name, &target, 0) != 0)
    return EntryKind::Other;
  return kindOfMode(target.st_mode);
}

std::vector<DirEntry> readEntries(DIR *dir) {
  std::vector<DirEntry> entries;
  while (const dirent *entry = ::readdir(dir)) {
    if (entry->d_name[0] == '.')
      continue;
    entries.push_back({entry->d_name, classify(::dirfd(dir), *entry)});
  }
  std::ranges::sort(entries, {}, &DirEntry::name);
  return entries;
}

struct DirIdentity {
  dev_t device;
  ino_t inode;

  friend bool operator==(const DirIdentity &, const DirIdentity &) = default;
};

struct Walk {
  QSet<QString> seenIds;
  std::vector<DirIdentity> visitedDirs;
  std::vector<DesktopFile> files;
};

bool markVisited(DIR *dir, std::vector<DirIdentity> &visitedDirs) {
  struct stat status{};
  if (::fstat(::dirfd(dir), &status) != 0)
    return false;
  const DirIdentity identity{status.st_dev, status.st_ino};
  if (std::ranges::find(visitedDirs, identity) != visitedDirs.end())
    return false;
  visitedDirs.push_back(identity);
  return true;
}

void collect(const std::string &dirPath, const std::string &idPrefix,
             int depth, Walk &walk) {
  const DirHandle dir(::opendir(dirPath.c_str()));
  if (!dir || !markVisited(dir.get(), walk.visitedDirs))
    return;

  for (const auto &entry : readEntries(dir.get())) {
    const std::string path = dirPath + '/' + entry.name;
    if (entry.kind == EntryKind::Directory) {
      if (depth < MAX_DEPTH)
        collect(path, idPrefix + entry.name + '-', depth + 1, walk);
      continue;
    }
    if (entry.kind != EntryKind::File ||
        !std::string_view(entry.name).ends_with(DESKTOP_SUFFIX))
      continue;

    QString id =
        QFile::decodeName(QByteArray::fromStdString(idPrefix + entry.name));
    struct stat status{};
    if (walk.seenIds.contains(id) ||
        ::fstatat(::dirfd(dir.get()), entry.name.c_str(), &status, 0) != 0)
      continue;
    walk.seenIds.insert(id);
    walk.files.push_back({std::move(id), path, FileKey::of(status)});
  }
}

[[noreturn]] void throwReadError(const std::string &path, int error) {
  throw DesktopFileReadError(path + ": " +
                             std::generic_category().message(error));
}

} // namespace

std::vector<DesktopFile>
listDesktopFiles(std::span<const std::string> applicationDirs) {
  Walk walk;
  for (const auto &dir : applicationDirs) {
    if (dir.starts_with('/'))
      collect(dir, {}, 0, walk);
  }
  return std::move(walk.files);
}

std::string readDesktopFile(const std::string &path) {
  const UniqueFd fd(::open(path.c_str(), O_RDONLY | O_CLOEXEC));
  if (!fd)
    throwReadError(path, errno);

  std::string contents;
  std::array<char, READ_CHUNK> chunk{};
  for (;;) {
    const auto count = ::read(fd.get(), chunk.data(), chunk.size());
    if (count == 0)
      return contents;
    if (count > 0) {
      contents.append(chunk.data(), static_cast<std::size_t>(count));
      continue;
    }
    if (errno != EINTR)
      throwReadError(path, errno);
  }
}
