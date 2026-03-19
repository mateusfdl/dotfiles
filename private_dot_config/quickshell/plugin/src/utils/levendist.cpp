#include "levendist.hpp"

#include <algorithm>
#include <cmath>
#include <vector>

Levendist::Levendist(QObject *parent) : QObject(parent) {}

int Levendist::levenshteinDistance(QStringView s1, QStringView s2) {
  const int len1 = s1.length();
  const int len2 = s2.length();

  if (len1 == 0)
    return len2;
  if (len2 == 0)
    return len1;

  const auto longer = (len2 > len1) ? s2 : s1;
  const auto shorter = (len2 > len1) ? s1 : s2;
  const int longerLen = longer.length();
  const int shorterLen = shorter.length();

  thread_local std::vector<int> prev;
  thread_local std::vector<int> curr;
  prev.resize(shorterLen + 1);
  curr.resize(shorterLen + 1);

  for (int j = 0; j <= shorterLen; ++j) {
    prev[j] = j;
  }

  for (int i = 1; i <= longerLen; ++i) {
    curr[0] = i;
    for (int j = 1; j <= shorterLen; ++j) {
      const int cost = (longer[i - 1] == shorter[j - 1]) ? 0 : 1;
      curr[j] = std::min({prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost});
    }
    std::swap(prev, curr);
  }

  return prev[shorterLen];
}

qreal Levendist::partialRatio(QStringView shortS, QStringView longS) {
  const int lenS = shortS.length();
  const int lenL = longS.length();
  qreal best = 0.0;

  if (lenS == 0)
    return 1.0;

  for (int i = 0; i <= lenL - lenS; ++i) {
    const auto sub = longS.mid(i, lenS);
    const int dist = levenshteinDistance(shortS, sub);
    const qreal score = 1.0 - (static_cast<qreal>(dist) / lenS);
    if (score > best)
      best = score;
  }

  return best;
}

qreal Levendist::computeScore(const QString &s1, const QString &s2) {
  if (s1 == s2)
    return 1.0;

  const int dist = levenshteinDistance(s1, s2);
  const int maxLen = std::max(s1.length(), s2.length());
  if (maxLen == 0)
    return 1.0;

  const qreal full = 1.0 - (static_cast<qreal>(dist) / maxLen);
  const qreal part =
      (s1.length() < s2.length()) ? partialRatio(s1, s2) : partialRatio(s2, s1);

  qreal score = 0.85 * full + 0.15 * part;

  if (!s1.isEmpty() && !s2.isEmpty() && s1[0] != s2[0]) {
    score -= 0.05;
  }

  const int lenDiff = std::abs(s1.length() - s2.length());
  if (lenDiff >= 3) {
    score -= 0.05 * lenDiff / maxLen;
  }

  const int minLen = std::min(s1.length(), s2.length());
  int commonPrefixLen = 0;
  for (int i = 0; i < minLen; ++i) {
    if (s1[i] == s2[i]) {
      ++commonPrefixLen;
    } else {
      break;
    }
  }
  score += 0.02 * commonPrefixLen;

  if (s1.contains(s2) || s2.contains(s1)) {
    score += 0.06;
  }

  return std::clamp(score, 0.0, 1.0);
}

qreal Levendist::computeTextMatchScore(const QString &s1, const QString &s2) {
  if (s1 == s2)
    return 1.0;

  const int dist = levenshteinDistance(s1, s2);
  const int maxLen = std::max(s1.length(), s2.length());
  if (maxLen == 0)
    return 1.0;

  const qreal full = 1.0 - (static_cast<qreal>(dist) / maxLen);
  const qreal part =
      (s1.length() < s2.length()) ? partialRatio(s1, s2) : partialRatio(s2, s1);

  qreal score = 0.4 * full + 0.6 * part;

  const int lenDiff = std::abs(s1.length() - s2.length());
  if (lenDiff >= 10) {
    score -= 0.02 * lenDiff / maxLen;
  }

  const int minLen = std::min(s1.length(), s2.length());
  int commonPrefixLen = 0;
  for (int i = 0; i < minLen; ++i) {
    if (s1[i] == s2[i]) {
      ++commonPrefixLen;
    } else {
      break;
    }
  }
  score += 0.01 * commonPrefixLen;

  if (s1.contains(s2) || s2.contains(s1)) {
    score += 0.2;
  }

  return std::clamp(score, 0.0, 1.0);
}
