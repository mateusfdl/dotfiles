#pragma once

#include "uniquefd.hpp"
#include "watchpoints.hpp"

#include <QElapsedTimer>
#include <QObject>
#include <QSocketNotifier>
#include <QTimer>

#include <sys/inotify.h>

#include <algorithm>
#include <chrono>
#include <concepts>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <functional>
#include <span>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

class PathWatchError : public std::runtime_error {
public:
  using std::runtime_error::runtime_error;
};

class InotifyInitError : public PathWatchError {
public:
  using PathWatchError::PathWatchError;
};

class WatchLimitError : public PathWatchError {
public:
  using PathWatchError::PathWatchError;
};

struct InotifyEvent {
  int wd;
  std::uint32_t mask;
  std::string_view name;
};

template <std::invocable<const InotifyEvent &> Visit>
void forEachInotifyEvent(std::span<const std::byte> buffer, Visit &&visit) {
  std::size_t offset = 0;
  while (offset + sizeof(inotify_event) <= buffer.size()) {
    inotify_event header{};
    std::memcpy(&header, buffer.data() + offset, sizeof header);
    const std::size_t nameOffset = offset + sizeof header;
    const std::size_t nameCapacity =
        std::min<std::size_t>(header.len, buffer.size() - nameOffset);
    const auto *name =
        reinterpret_cast<const char *>(buffer.data() + nameOffset);
    visit(InotifyEvent{header.wd, header.mask,
                       std::string_view(name, ::strnlen(name, nameCapacity))});
    offset = nameOffset + header.len;
  }
}

class PathWatcher : public QObject {
  Q_OBJECT

public:
  using Resolver =
      std::function<std::vector<WatchPoint>(std::span<const std::string>)>;

  struct Timing {
    std::chrono::milliseconds quiet;
    std::chrono::milliseconds maxWait;
  };

  PathWatcher(Resolver resolver, Timing timing, QObject *parent = nullptr);

  void watch(std::span<const std::string> paths, std::string_view contentSuffix);

signals:
  void changed();

private:
  friend class PathWatcherTest;

  struct Watch {
    int wd;
    std::uint32_t mask;
    bool link;
    bool contents;
    std::vector<std::string> entries;
  };

  void ensureInotify();
  [[nodiscard]] std::vector<Watch> apply(const std::vector<WatchPoint> &points);
  void removeStaleWatches(const std::vector<Watch> &next) const;
  void readEvents(bool armOnRelevant);
  [[nodiscard]] bool handleEvent(const InotifyEvent &event);
  void warnOnce(const std::string &path, int error);
  void arm();
  void flush();

  Resolver m_resolver;
  Timing m_timing;
  std::string m_contentSuffix;
  UniqueFd m_fd;
  QSocketNotifier m_notifier;
  QTimer m_timer;
  QElapsedTimer m_burstClock;
  bool m_burstPending{false};
  std::vector<Watch> m_watches;
  std::vector<std::string> m_warnedPaths;
};
