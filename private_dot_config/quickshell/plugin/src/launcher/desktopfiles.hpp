#pragma once

#include <QString>

#include <sys/stat.h>

#include <cstdint>
#include <span>
#include <stdexcept>
#include <string>
#include <vector>

struct FileKey {
  dev_t device;
  ino_t inode;
  off_t size;
  std::int64_t modifiedNs;
  std::int64_t changedNs;

  [[nodiscard]] static FileKey of(const struct stat &status) {
    return {
        .device = status.st_dev,
        .inode = status.st_ino,
        .size = status.st_size,
        .modifiedNs = status.st_mtim.tv_sec * 1'000'000'000LL +
                      status.st_mtim.tv_nsec,
        .changedNs = status.st_ctim.tv_sec * 1'000'000'000LL +
                     status.st_ctim.tv_nsec,
    };
  }

  friend auto operator<=>(const FileKey &, const FileKey &) = default;
};

struct DesktopFile {
  QString id;
  std::string path;
  FileKey key;

  friend bool operator==(const DesktopFile &, const DesktopFile &) = default;
};

class DesktopFileReadError : public std::runtime_error {
public:
  using std::runtime_error::runtime_error;
};

[[nodiscard]] std::vector<DesktopFile>
listDesktopFiles(std::span<const std::string> applicationDirs);

[[nodiscard]] std::string readDesktopFile(const std::string &path);
