#include "fuzzysort.hpp"

#include <QRegularExpression>

#include <algorithm>
#include <cmath>
#include <limits>
#include <unordered_map>

static constexpr double NEG_INF = -std::numeric_limits<double>::infinity();

FuzzySort::FuzzySort(QObject *parent) : QObject(parent) {}

QString FuzzySort::removeAccents(const QString &str) {
  QString result;
  result.reserve(str.size());

  const QString nfd = str.normalized(QString::NormalizationForm_D);
  for (QChar ch : nfd) {
    const ushort code = ch.unicode();
    if (code >= 0x0300 && code <= 0x036F)
      continue;
    result.append(ch);
  }
  return result;
}

FuzzySort::LowerInfo FuzzySort::prepareLowerInfo(const QString &str) {
  const QString cleaned = removeAccents(str);
  const int strLen = cleaned.length();
  const QString lower = cleaned.toLower();

  LowerInfo info;
  info.lower = lower;
  info.lowerCodes.resize(strLen);
  info.bitflags = 0;
  info.containsSpace = false;

  for (int i = 0; i < strLen; ++i) {
    const int lowerCode = lower[i].unicode();
    info.lowerCodes[i] = lowerCode;

    if (lowerCode == 32) {
      info.containsSpace = true;
      continue;
    }

    int bit;
    if (lowerCode >= 97 && lowerCode <= 122)
      bit = lowerCode - 97;
    else if (lowerCode >= 48 && lowerCode <= 57)
      bit = 26;
    else if (lowerCode <= 127)
      bit = 30;
    else
      bit = 31;

    info.bitflags |= (1 << bit);
  }
  return info;
}

std::vector<int> FuzzySort::prepareBeginningIndexes(const QString &target) {
  const int targetLen = target.length();
  std::vector<int> beginningIndexes;
  bool wasUpper = false;
  bool wasAlphanum = false;

  for (int i = 0; i < targetLen; ++i) {
    const int code = target[i].unicode();
    const bool isUpper = (code >= 65 && code <= 90);
    const bool isAlphanum =
        isUpper || (code >= 97 && code <= 122) || (code >= 48 && code <= 57);
    const bool isBeginning =
        (isUpper && !wasUpper) || !wasAlphanum || !isAlphanum;
    wasUpper = isUpper;
    wasAlphanum = isAlphanum;
    if (isBeginning)
      beginningIndexes.push_back(i);
  }
  return beginningIndexes;
}

std::vector<int> FuzzySort::prepareNextBeginningIndexes(const QString &target) {
  const QString cleaned = removeAccents(target);
  const int targetLen = cleaned.length();
  const auto beginningIndexes = prepareBeginningIndexes(cleaned);
  std::vector<int> nextBeginningIndexes(targetLen);

  int lastIsBeginning =
      beginningIndexes.empty() ? targetLen : beginningIndexes[0];
  size_t lastIsBeginningI = 0;

  for (int i = 0; i < targetLen; ++i) {
    if (lastIsBeginning > i) {
      nextBeginningIndexes[i] = lastIsBeginning;
    } else {
      ++lastIsBeginningI;
      lastIsBeginning = (lastIsBeginningI < beginningIndexes.size())
                            ? beginningIndexes[lastIsBeginningI]
                            : targetLen;
      nextBeginningIndexes[i] = lastIsBeginning;
    }
  }
  return nextBeginningIndexes;
}

FuzzySort::PreparedTarget FuzzySort::prepareParsed(const QString &target) {
  auto info = prepareLowerInfo(target);
  PreparedTarget pt;
  pt.target = target;
  pt.targetLower = std::move(info.lower);
  pt.targetLowerCodes = std::move(info.lowerCodes);
  pt.bitflags = info.bitflags;
  pt.nextBeginningIndexesReady = false;
  return pt;
}

FuzzySort::PreparedSearch
FuzzySort::prepareSearchParsed(const QString &search) {
  const QString trimmed = search.trimmed();
  auto info = prepareLowerInfo(trimmed);

  PreparedSearch ps;
  ps.lowerCodes = std::move(info.lowerCodes);
  ps.lower = std::move(info.lower);
  ps.containsSpace = info.containsSpace;
  ps.bitflags = info.bitflags;

  if (info.containsSpace) {
    static const QRegularExpression spaceRe(QStringLiteral("\\s+"));
    const QStringList parts = trimmed.split(spaceRe);
    QSet<QString> seen;
    for (const auto &part : parts) {
      if (part.isEmpty() || seen.contains(part))
        continue;
      seen.insert(part);
      auto partInfo = prepareLowerInfo(part);
      PreparedSearch sub;
      sub.lowerCodes = std::move(partInfo.lowerCodes);
      sub.lower = std::move(partInfo.lower);
      sub.containsSpace = false;
      sub.bitflags = partInfo.bitflags;
      ps.spaceSearches.push_back(std::move(sub));
    }
  }
  return ps;
}

double FuzzySort::normalizeScore(double score) {
  if (score == NEG_INF)
    return 0.0;
  if (score > 1.0)
    return score;
  return std::exp((std::pow(-score + 1.0, 0.04307) - 1.0) * -2.0);
}

FuzzySort::MatchResult
FuzzySort::algorithm(const PreparedSearch &preparedSearch,
                     PreparedTarget &prepared, bool allowSpaces,
                     bool allowPartialMatch) {
  if (!allowSpaces && preparedSearch.containsSpace) {
    return algorithmSpaces(preparedSearch, prepared, allowPartialMatch);
  }

  const auto &searchLowerCodes = preparedSearch.lowerCodes;
  const auto &targetLowerCodes = prepared.targetLowerCodes;
  const int searchLen = static_cast<int>(searchLowerCodes.size());
  const int targetLen = static_cast<int>(targetLowerCodes.size());

  if (searchLen == 0 || targetLen == 0) {
    return {};
  }

  std::vector<int> matchesSimple;
  matchesSimple.reserve(searchLen);
  {
    int searchI = 0;
    int searchLowerCode = searchLowerCodes[0];
    for (int targetI = 0; targetI < targetLen; ++targetI) {
      if (searchLowerCode == targetLowerCodes[targetI]) {
        matchesSimple.push_back(targetI);
        ++searchI;
        if (searchI == searchLen)
          break;
        searchLowerCode = searchLowerCodes[searchI];
      }
    }
    if (searchI != searchLen)
      return {};
  }

  if (!prepared.nextBeginningIndexesReady) {
    prepared.nextBeginningIndexes =
        prepareNextBeginningIndexes(prepared.target);
    prepared.nextBeginningIndexesReady = true;
  }
  const auto &nextBeginningIndexes = prepared.nextBeginningIndexes;

  std::vector<int> matchesStrict;
  matchesStrict.reserve(searchLen);
  bool successStrict = false;
  {
    int searchI = 0;
    int targetI = (matchesSimple[0] == 0)
                      ? 0
                      : nextBeginningIndexes[matchesSimple[0] - 1];
    int backtrackCount = 0;

    if (targetI != targetLen) {
      for (;;) {
        if (targetI >= targetLen) {
          if (searchI <= 0)
            break;
          ++backtrackCount;
          if (backtrackCount > 200)
            break;
          --searchI;
          int lastMatch = matchesStrict.back();
          matchesStrict.pop_back();
          targetI = nextBeginningIndexes[lastMatch];
        } else {
          if (searchLowerCodes[searchI] == targetLowerCodes[targetI]) {
            matchesStrict.push_back(targetI);
            ++searchI;
            if (searchI == searchLen) {
              successStrict = true;
              break;
            }
            ++targetI;
          } else {
            targetI = nextBeginningIndexes[targetI];
          }
        }
      }
    }
  }

  const int substringIndex =
      (searchLen <= 1) ? -1
                       : prepared.targetLower.indexOf(preparedSearch.lower,
                                                      matchesSimple[0]);
  bool isSubstring = (substringIndex != -1);
  bool isSubstringBeginning = false;
  if (isSubstring) {
    isSubstringBeginning =
        (substringIndex == 0) ||
        (nextBeginningIndexes[substringIndex - 1] == substringIndex);
  }

  int finalSubstringIndex = substringIndex;
  if (isSubstring && !isSubstringBeginning) {
    for (int i = 0; i < static_cast<int>(nextBeginningIndexes.size());
         i = nextBeginningIndexes[i]) {
      if (i <= substringIndex)
        continue;
      bool matched = true;
      for (int s = 0; s < searchLen; ++s) {
        if (i + s >= targetLen ||
            searchLowerCodes[s] != targetLowerCodes[i + s]) {
          matched = false;
          break;
        }
      }
      if (matched) {
        finalSubstringIndex = i;
        isSubstringBeginning = true;
        break;
      }
    }
  }

  auto calculateScore = [&](const std::vector<int> &matches) -> double {
    double score = 0;
    int extraMatchGroupCount = 0;
    for (int i = 1; i < searchLen; ++i) {
      if (matches[i] - matches[i - 1] != 1) {
        score -= matches[i];
        ++extraMatchGroupCount;
      }
    }
    const int unmatchedDistance =
        matches[searchLen - 1] - matches[0] - (searchLen - 1);
    score -= (12 + unmatchedDistance) * extraMatchGroupCount;

    if (matches[0] != 0) {
      score -= matches[0] * matches[0] * 0.2;
    }

    if (!successStrict) {
      score *= 1000;
    } else {
      int uniqueBeginningIndexes = 1;
      for (int i = nextBeginningIndexes[0]; i < targetLen;
           i = nextBeginningIndexes[i]) {
        ++uniqueBeginningIndexes;
      }
      if (uniqueBeginningIndexes > 24) {
        score *= (uniqueBeginningIndexes - 24) * 10;
      }
    }

    score -= static_cast<double>(targetLen - searchLen) / 2.0;

    if (isSubstring)
      score /= (1 + searchLen * searchLen * 1);
    if (isSubstringBeginning)
      score /= (1 + searchLen * searchLen * 1);

    score -= static_cast<double>(targetLen - searchLen) / 2.0;
    return score;
  };

  std::vector<int> *matchesBest;
  double score;

  if (!successStrict) {
    if (isSubstring) {
      for (int i = 0; i < searchLen; ++i)
        matchesSimple[i] = finalSubstringIndex + i;
    }
    matchesBest = &matchesSimple;
    score = calculateScore(matchesSimple);
  } else {
    if (isSubstringBeginning) {
      for (int i = 0; i < searchLen; ++i)
        matchesSimple[i] = finalSubstringIndex + i;
      matchesBest = &matchesSimple;
      score = calculateScore(matchesSimple);
    } else {
      matchesBest = &matchesStrict;
      score = calculateScore(matchesStrict);
    }
  }

  MatchResult result;
  result.valid = true;
  result.score = score;
  result.indexes.assign(matchesBest->begin(), matchesBest->begin() + searchLen);
  return result;
}

FuzzySort::MatchResult
FuzzySort::algorithmSpaces(const PreparedSearch &preparedSearch,
                           PreparedTarget &target, bool allowPartialMatch) {
  std::vector<int> seenIndexes;
  double score = 0;

  int firstSeenIndexLastSearch = 0;
  const auto &searches = preparedSearch.spaceSearches;
  const int searchesLen = static_cast<int>(searches.size());

  std::vector<std::pair<int, int>> changes;

  bool hasAtLeast1Match = false;

  for (int i = 0; i < searchesLen; ++i) {
    auto result = algorithm(searches[i], target);

    if (allowPartialMatch) {
      if (!result.valid)
        continue;
      hasAtLeast1Match = true;
    } else {
      if (!result.valid) {
        for (int c = static_cast<int>(changes.size()) - 1; c >= 0; --c) {
          target.nextBeginningIndexes[changes[c].first] = changes[c].second;
        }
        return {};
      }
    }

    const bool isTheLastSearch = (i == searchesLen - 1);
    if (!isTheLastSearch && result.valid) {
      const auto &indexes = result.indexes;
      bool consecutive = true;
      for (size_t j = 0; j + 1 < indexes.size(); ++j) {
        if (indexes[j + 1] - indexes[j] != 1) {
          consecutive = false;
          break;
        }
      }
      if (consecutive && !indexes.empty()) {
        const int newBeginningIndex = indexes.back() + 1;
        if (newBeginningIndex > 0 &&
            newBeginningIndex - 1 <
                static_cast<int>(target.nextBeginningIndexes.size())) {
          const int toReplace =
              target.nextBeginningIndexes[newBeginningIndex - 1];
          for (int j = newBeginningIndex - 1; j >= 0; --j) {
            if (toReplace != target.nextBeginningIndexes[j])
              break;
            changes.push_back({j, target.nextBeginningIndexes[j]});
            target.nextBeginningIndexes[j] = newBeginningIndex;
          }
        }
      }
    }

    if (result.valid) {
      score += result.score / searchesLen;

      if (!result.indexes.empty() &&
          result.indexes[0] < firstSeenIndexLastSearch) {
        score -= (firstSeenIndexLastSearch - result.indexes[0]) * 2;
      }
      if (!result.indexes.empty()) {
        firstSeenIndexLastSearch = result.indexes[0];
      }
      for (int idx : result.indexes) {
        seenIndexes.push_back(idx);
      }
    }
  }

  if (allowPartialMatch && !hasAtLeast1Match) {
    for (int c = static_cast<int>(changes.size()) - 1; c >= 0; --c) {
      target.nextBeginningIndexes[changes[c].first] = changes[c].second;
    }
    return {};
  }

  for (int c = static_cast<int>(changes.size()) - 1; c >= 0; --c) {
    target.nextBeginningIndexes[changes[c].first] = changes[c].second;
  }

  auto allowSpacesResult = algorithm(preparedSearch, target, true);
  if (allowSpacesResult.valid && allowSpacesResult.score > score) {
    return allowSpacesResult;
  }

  std::sort(seenIndexes.begin(), seenIndexes.end());
  seenIndexes.erase(std::unique(seenIndexes.begin(), seenIndexes.end()),
                    seenIndexes.end());

  MatchResult finalResult;
  finalResult.valid = true;
  finalResult.score = score;
  finalResult.indexes = std::move(seenIndexes);
  return finalResult;
}

FuzzySort::PreparedTarget FuzzySort::variantToPrepared(const QVariantMap &map) {
  PreparedTarget pt;
  pt.target = map.value(QStringLiteral("target")).toString();
  pt.targetLower = map.value(QStringLiteral("_targetLower")).toString();
  pt.bitflags = map.value(QStringLiteral("_bitflags")).toInt();

  pt.targetLowerCodes.resize(pt.targetLower.length());
  for (int i = 0; i < pt.targetLower.length(); ++i) {
    pt.targetLowerCodes[i] = pt.targetLower[i].unicode();
  }

  pt.nextBeginningIndexesReady = false;
  return pt;
}

QVariantMap FuzzySort::prepare(const QString &target) {
  auto info = prepareLowerInfo(target);
  QVariantMap result;
  result[QStringLiteral("target")] = target;
  result[QStringLiteral("_targetLower")] = info.lower;
  result[QStringLiteral("_bitflags")] = info.bitflags;
  result[QStringLiteral("_prepared")] = true;
  return result;
}

QVariantList FuzzySort::allResults(const QVariantList &targets,
                                   const QVariantMap &options) {
  QVariantList results;
  int limit = options.value(QStringLiteral("limit"), 0).toInt();
  if (limit <= 0)
    limit = std::numeric_limits<int>::max();

  const QString key = options.value(QStringLiteral("key")).toString();

  if (!key.isEmpty()) {
    for (const auto &item : targets) {
      const QVariantMap obj = item.toMap();
      const QVariantMap targetMap = obj.value(key).toMap();
      if (targetMap.isEmpty())
        continue;

      QVariantMap entry;
      entry[QStringLiteral("obj")] = obj;
      entry[QStringLiteral("score")] = 0.0;
      entry[QStringLiteral("target")] =
          targetMap.value(QStringLiteral("target"));
      results.append(QVariant::fromValue(entry));
      if (results.size() >= limit)
        break;
    }
  } else {
    for (const auto &item : targets) {
      QVariantMap entry;
      entry[QStringLiteral("score")] = 0.0;
      if (item.typeId() == QMetaType::QVariantMap) {
        entry[QStringLiteral("target")] =
            item.toMap().value(QStringLiteral("target"));
      } else {
        entry[QStringLiteral("target")] = item.toString();
      }
      results.append(QVariant::fromValue(entry));
      if (results.size() >= limit)
        break;
    }
  }
  return results;
}

QVariantList FuzzySort::go(const QString &search, const QVariantList &targets,
                           const QVariantMap &options) {
  const bool all = options.value(QStringLiteral("all"), false).toBool();

  if (search.isEmpty()) {
    return all ? allResults(targets, options) : QVariantList{};
  }

  auto preparedSearch = prepareSearchParsed(search);
  const int searchBitflags = preparedSearch.bitflags;

  int limit = options.value(QStringLiteral("limit"), 0).toInt();
  if (limit <= 0)
    limit = std::numeric_limits<int>::max();

  const QString key = options.value(QStringLiteral("key")).toString();

  struct ScoredResult {
    double score;
    QVariantMap data;
  };
  std::vector<ScoredResult> results;

  if (!key.isEmpty()) {
    for (const auto &item : targets) {
      const QVariantMap obj = item.toMap();
      const QVariant targetVal = obj.value(key);
      if (!targetVal.isValid())
        continue;

      const QVariantMap targetMap = targetVal.toMap();
      if (targetMap.isEmpty())
        continue;

      const int targetBitflags =
          targetMap.value(QStringLiteral("_bitflags")).toInt();
      if ((searchBitflags & targetBitflags) != searchBitflags)
        continue;

      auto prepared = variantToPrepared(targetMap);
      auto result = algorithm(preparedSearch, prepared);
      if (!result.valid)
        continue;

      QVariantMap entry;
      entry[QStringLiteral("obj")] = obj;
      entry[QStringLiteral("score")] = normalizeScore(result.score);
      entry[QStringLiteral("_score")] = result.score;
      entry[QStringLiteral("target")] = prepared.target;

      results.push_back({result.score, std::move(entry)});
    }
  } else {
    for (const auto &item : targets) {
      PreparedTarget prepared;
      if (item.typeId() == QMetaType::QVariantMap) {
        const QVariantMap map = item.toMap();
        if (map.contains(QStringLiteral("_prepared"))) {
          prepared = variantToPrepared(map);
        } else {
          prepared =
              prepareParsed(map.value(QStringLiteral("target")).toString());
        }
      } else {
        prepared = prepareParsed(item.toString());
      }

      const int targetBitflags = prepared.bitflags;
      if ((searchBitflags & targetBitflags) != searchBitflags)
        continue;

      auto result = algorithm(preparedSearch, prepared);
      if (!result.valid)
        continue;

      QVariantMap entry;
      entry[QStringLiteral("score")] = normalizeScore(result.score);
      entry[QStringLiteral("_score")] = result.score;
      entry[QStringLiteral("target")] = prepared.target;

      results.push_back({result.score, std::move(entry)});
    }
  }

  std::sort(results.begin(), results.end(),
            [](const ScoredResult &a, const ScoredResult &b) {
              return a.score > b.score;
            });

  QVariantList output;
  const int count = std::min(static_cast<int>(results.size()), limit);
  output.reserve(count);
  for (int i = 0; i < count; ++i) {
    output.append(QVariant::fromValue(std::move(results[i].data)));
  }
  return output;
}
