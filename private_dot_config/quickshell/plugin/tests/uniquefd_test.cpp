#include "uniquefd.hpp"

#include <QtTest/QTest>

#include <fcntl.h>
#include <unistd.h>

#include <array>
#include <cerrno>
#include <utility>

namespace {

bool isOpen(int fd) { return ::fcntl(fd, F_GETFD) != -1 || errno != EBADF; }

std::array<int, 2> openPipe() {
  std::array<int, 2> fds{-1, -1};
  if (::pipe2(fds.data(), O_CLOEXEC) != 0)
    qFatal("pipe2 failed");
  return fds;
}

} // namespace

class UniqueFdTest : public QObject {
  Q_OBJECT

private slots:
  void defaultIsEmpty();
  void closesOnDestruction();
  void moveConstructionTransfersOwnership();
  void moveAssignmentClosesPreviousDescriptor();
  void resetClosesAndAdopts();
};

void UniqueFdTest::defaultIsEmpty() {
  const UniqueFd fd;
  QCOMPARE(fd.get(), -1);
  QCOMPARE(static_cast<bool>(fd), false);
}

void UniqueFdTest::closesOnDestruction() {
  const auto [readEnd, writeEnd] = openPipe();
  {
    const UniqueFd owner(readEnd);
    QCOMPARE(owner.get(), readEnd);
    QCOMPARE(static_cast<bool>(owner), true);
  }
  QCOMPARE(isOpen(readEnd), false);
  ::close(writeEnd);
}

void UniqueFdTest::moveConstructionTransfersOwnership() {
  const auto [readEnd, writeEnd] = openPipe();
  UniqueFd source(readEnd);
  const UniqueFd target(std::move(source));
  QCOMPARE(source.get(), -1);
  QCOMPARE(target.get(), readEnd);
  QCOMPARE(isOpen(readEnd), true);
  ::close(writeEnd);
}

void UniqueFdTest::moveAssignmentClosesPreviousDescriptor() {
  const auto [firstRead, firstWrite] = openPipe();
  const auto [secondRead, secondWrite] = openPipe();
  UniqueFd target(firstRead);
  UniqueFd source(secondRead);
  target = std::move(source);
  QCOMPARE(isOpen(firstRead), false);
  QCOMPARE(target.get(), secondRead);
  QCOMPARE(source.get(), -1);
  ::close(firstWrite);
  ::close(secondWrite);
}

void UniqueFdTest::resetClosesAndAdopts() {
  const auto [firstRead, firstWrite] = openPipe();
  const auto [secondRead, secondWrite] = openPipe();
  UniqueFd owner(firstRead);
  owner.reset(secondRead);
  QCOMPARE(isOpen(firstRead), false);
  QCOMPARE(owner.get(), secondRead);
  owner.reset();
  QCOMPARE(isOpen(secondRead), false);
  QCOMPARE(owner.get(), -1);
  ::close(firstWrite);
  ::close(secondWrite);
}

QTEST_GUILESS_MAIN(UniqueFdTest)
#include "uniquefd_test.moc"
