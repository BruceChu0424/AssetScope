/// 商户/对手方 → 消费分类的规则引擎。
///
/// 三级匹配策略（置信度递减）：
/// 1. 显式关键词规则（用户在 UI 中管理，持久化为 JSON）；
/// 2. 历史精确对手方（同名对手方过往最常见的分类）；
/// 3. 历史模糊对手方（最长公共子串 ≥ 2 字符）。
/// 只建议不强制：导入预览中用户可逐行改判。
library;

import 'dart:convert';

class CategoryRule {
  const CategoryRule({
    required this.keyword,
    required this.categoryId,
    this.caseSensitive = false,
  });

  final String keyword;
  final String categoryId;
  final bool caseSensitive;

  Map<String, Object?> toJson() => {
    'keyword': keyword,
    'categoryId': categoryId,
    'caseSensitive': caseSensitive,
  };

  factory CategoryRule.fromJson(Map<String, Object?> j) => CategoryRule(
    keyword: j['keyword'] as String,
    categoryId: j['categoryId'] as String,
    caseSensitive: j['caseSensitive'] as bool? ?? false,
  );
}

/// 一条历史样本：对手方被记到某分类的次数。
class CategoryHistoryEntry {
  const CategoryHistoryEntry({
    required this.counterparty,
    required this.categoryId,
    required this.count,
  });

  final String counterparty;
  final String categoryId;
  final int count;
}

class RuleMatch {
  const RuleMatch({
    required this.categoryId,
    required this.confidence,
    required this.source,
  });

  final String categoryId;

  /// 0~1。
  final double confidence;

  /// 命中来源描述（用于预览展示）。
  final RuleSource source;
}

enum RuleSource { keywordRule, exactHistory, fuzzyHistory }

class CategoryRulesEngine {
  const CategoryRulesEngine({this.rules = const [], this.history = const []});

  final List<CategoryRule> rules;
  final List<CategoryHistoryEntry> history;

  /// 规则持久化用 JSON 编解码（dart:convert 为 SDK 内置，不违反 domain 纯净性）。
  static String encodeRules(List<CategoryRule> rules) =>
      jsonEncode([for (final r in rules) r.toJson()]);

  static List<CategoryRule> decodeRules(String? json) {
    if (json == null || json.isEmpty) return const [];
    final decoded = jsonDecode(json);
    if (decoded is! List) return const [];
    return [
      for (final e in decoded)
        if (e is Map<String, Object?>)
          CategoryRule.fromJson(Map<String, Object?>.from(e)),
    ];
  }

  /// 对一个对手方给出分类建议；无建议返回 null。
  RuleMatch? match(String counterparty) {
    final cp = counterparty.trim();
    if (cp.isEmpty) return null;
    // 1) 显式规则：最长关键词优先（"美团外卖" 比 "美团" 更具体）。
    final hit = rules.where((r) => _contains(cp, r));
    if (hit.isNotEmpty) {
      final best = hit.reduce(
        (a, b) => a.keyword.length >= b.keyword.length ? a : b,
      );
      return RuleMatch(
        categoryId: best.categoryId,
        confidence: 1.0,
        source: RuleSource.keywordRule,
      );
    }
    // 2) 历史精确：取同名对手方中计数最高的分类，按占比给置信度。
    final exact = <String, int>{};
    var exactTotal = 0;
    for (final h in history) {
      if (_eq(h.counterparty, cp)) {
        exact[h.categoryId] = (exact[h.categoryId] ?? 0) + h.count;
        exactTotal += h.count;
      }
    }
    if (exactTotal > 0) {
      final best = _topByValue(exact)!;
      return RuleMatch(
        categoryId: best.key,
        confidence: (best.value / exactTotal).clamp(0.5, 1.0),
        source: RuleSource.exactHistory,
      );
    }
    // 3) 历史模糊：包含关系或 token 重叠。
    final fuzzy = <String, int>{};
    var fuzzyBestOverlap = 0;
    for (final h in history) {
      final overlap = _overlap(h.counterparty, cp);
      if (overlap > 0) {
        fuzzy[h.categoryId] = (fuzzy[h.categoryId] ?? 0) + h.count;
        if (overlap > fuzzyBestOverlap) fuzzyBestOverlap = overlap;
      }
    }
    if (fuzzy.isNotEmpty) {
      final best = _topByValue(fuzzy)!;
      return RuleMatch(
        categoryId: best.key,
        // 重叠越长越可信，且封顶 0.85：模糊建议永远低于精确。
        confidence: (0.5 + 0.35 * fuzzyBestOverlap / cp.characters.length)
            .clamp(0.5, 0.85),
        source: RuleSource.fuzzyHistory,
      );
    }
    return null;
  }

  bool _contains(String cp, CategoryRule r) => r.caseSensitive
      ? cp.contains(r.keyword)
      : cp.toLowerCase().contains(r.keyword.toLowerCase());

  bool _eq(String a, String b) => a.toLowerCase() == b.toLowerCase();

  /// 共享的最长连续子串长度（≥2 才算有效重叠；中文 1 字太泛）。
  int _overlap(String a, String b) {
    final s = a.toLowerCase();
    final t = b.toLowerCase();
    var best = 0;
    for (var i = 0; i < s.length; i++) {
      for (var len = s.length - i; len > best; len--) {
        if (t.contains(s.substring(i, i + len))) {
          if (len > best) best = len;
          break;
        }
      }
    }
    return best >= 2 ? best : 0;
  }

  MapEntry<String, int>? _topByValue(Map<String, int> m) {
    MapEntry<String, int>? best;
    m.forEach((k, v) {
      if (best == null || v > best!.value) best = MapEntry(k, v);
    });
    return best;
  }
}

extension _CharactersX on String {
  /// 码点数（中文按 1 计）。
  Iterable<String> get characters sync* {
    for (final c in runes) {
      yield String.fromCharCode(c);
    }
  }
}
