#pragma once

#include <unistd.h>

#include <utility>

class UniqueFd {
public:
  UniqueFd() noexcept = default;
  explicit UniqueFd(int descriptor) noexcept : m_fd(descriptor) {}
  ~UniqueFd() { reset(); }

  UniqueFd(const UniqueFd &) = delete;
  UniqueFd &operator=(const UniqueFd &) = delete;

  UniqueFd(UniqueFd &&other) noexcept : m_fd(std::exchange(other.m_fd, -1)) {}
  UniqueFd &operator=(UniqueFd &&other) noexcept {
    if (this != &other)
      reset(std::exchange(other.m_fd, -1));
    return *this;
  }

  [[nodiscard]] int get() const noexcept { return m_fd; }
  explicit operator bool() const noexcept { return m_fd >= 0; }

  void reset(int descriptor = -1) noexcept {
    if (m_fd >= 0)
      ::close(m_fd);
    m_fd = descriptor;
  }

private:
  int m_fd = -1;
};
