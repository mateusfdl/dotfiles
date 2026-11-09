#pragma once

#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

enum class AnchorKind : std::uint8_t { Link, Missing, Contents };

struct WatchPoint {
  AnchorKind kind;
  std::string path;
  std::string entry;

  friend auto operator<=>(const WatchPoint &, const WatchPoint &) = default;
};

[[nodiscard]] std::vector<WatchPoint>
resolveWatchPoints(std::span<const std::string> paths,
                   std::string_view immutableRoot);
