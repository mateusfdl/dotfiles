#pragma once

#include <QObject>
#include <QString>
#include <QVariant>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

#include <vector>

class FuzzySort : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

public:
  explicit FuzzySort(QObject *parent = nullptr);

  Q_INVOKABLE static QVariantMap prepare(const QString &target);

  Q_INVOKABLE static QVariantList go(const QString &search,
                                     const QVariantList &targets,
                                     const QVariantMap &options = {});

private:
  struct LowerInfo {
    std::vector<int> lowerCodes;
    int bitflags = 0;
    bool containsSpace = false;
    QString lower;
  };

  struct PreparedTarget {
    QString target;
    QString targetLower;
    std::vector<int> targetLowerCodes;
    std::vector<int> nextBeginningIndexes;
    int bitflags = 0;
    bool nextBeginningIndexesReady = false;
  };

  struct PreparedSearch {
    std::vector<int> lowerCodes;
    QString lower;
    bool containsSpace = false;
    int bitflags = 0;
    std::vector<PreparedSearch> spaceSearches;
  };

  struct MatchResult {
    double score = -1e9;
    std::vector<int> indexes;
    bool valid = false;
  };

  static QString removeAccents(const QString &str);
  static LowerInfo prepareLowerInfo(const QString &str);
  static std::vector<int> prepareBeginningIndexes(const QString &target);
  static std::vector<int> prepareNextBeginningIndexes(const QString &target);
  static PreparedTarget prepareParsed(const QString &target);
  static PreparedSearch prepareSearchParsed(const QString &search);
  static MatchResult algorithm(const PreparedSearch &search,
                               PreparedTarget &target, bool allowSpaces = false,
                               bool allowPartialMatch = false);
  static MatchResult algorithmSpaces(const PreparedSearch &search,
                                     PreparedTarget &target,
                                     bool allowPartialMatch);
  static double normalizeScore(double score);

  static PreparedTarget variantToPrepared(const QVariantMap &map);
  static QVariantList allResults(const QVariantList &targets,
                                 const QVariantMap &options);
};
