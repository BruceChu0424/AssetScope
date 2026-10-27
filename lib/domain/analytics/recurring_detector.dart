import 'dart:math' as math;

import '../planning/recurrence.dart';

/// 周期识别输入：同一对手方/名称的一笔历史交易。
class RecurringTx {
  const RecurringTx({
    required this.date,
    required this.amountMinor,
    required this.label,
    required this.direction, // true=收入
  });

  final DateTime date;
  final BigInt amountMinor;
  final String label;
  final bool direction;
}

/// 识别出的周期建议（可直接转 ScheduledEvent 草稿）。
class RecurringSuggestion {
  const RecurringSuggestion({
    required this.label,
    required this.direction,
    required this.intervalDays,
    required this.occurrences,
    required this.medianAmountMinor,
    required this.lastDate,
    required this.amountStable,
    required this.confidence,
  });

  final String label;
  final bool direction; // true=收入

  /// 间隔中位数（天）。30≈月付，7≈周付，365≈年付。
  final int intervalDays;

  /// 观测到的次数（≥3 才建议）。
  final int occurrences;

  final BigInt medianAmountMinor;
  final DateTime lastDate;

  /// 金额是否稳定（最大偏差 ≤ 中位数的 10%）。
  final bool amountStable;

  /// 0~1：间隔规整度 × 金额稳定度 × 样本量加成。
  final double confidence;

  /// 人类可读的周期名。
  String get cadenceLabel {
    if (intervalDays >= 350 && intervalDays <= 380) return '每年';
    if (intervalDays >= 28 && intervalDays <= 32) return '每月';
    if (intervalDays >= 13 && intervalDays <= 15) return '双周';
    if (intervalDays >= 6 && intervalDays <= 8) return '每周';
    return '每 $intervalDays 天';
  }

  /// 下次预计发生日（按日历周期推进到 now 之后；月付按月历进位避免 31 天漂移）。
  DateTime nextExpected(DateTime now) {
    var d = lastDate;
    while (!d.isAfter(now)) {
      d = _advance(d);
    }
    return d;
  }

  /// 适配计划：间隔桶 → (Cadence, 自定义间隔天数)。锚点日取 [nextExpected]。
  (Cadence, int) planCadence(DateTime now) {
    if (intervalDays >= 350 && intervalDays <= 380) {
      return (Cadence.yearly, 1);
    }
    if (intervalDays >= 28 && intervalDays <= 32) {
      return (Cadence.monthly, 1);
    }
    if (intervalDays >= 13 && intervalDays <= 15) {
      return (Cadence.biweekly, 1);
    }
    if (intervalDays >= 6 && intervalDays <= 8) {
      return (Cadence.weekly, 1);
    }
    return (Cadence.customInterval, intervalDays);
  }

  DateTime _advance(DateTime d) {
    if (intervalDays >= 350 && intervalDays <= 380) {
      return DateTime(d.year + 1, d.month, d.day);
    }
    if (intervalDays >= 28 && intervalDays <= 32) {
      return DateTime(d.year, d.month + 1, d.day);
    }
    if (intervalDays >= 13 && intervalDays <= 15) {
      return d.add(const Duration(days: 14));
    }
    if (intervalDays >= 6 && intervalDays <= 8) {
      return d.add(const Duration(days: 7));
    }
    return d.add(Duration(days: intervalDays));
  }
}

/// 周期识别器：把历史交易按 (label, direction) 分桶，
/// 每桶检验"间隔中位数 ± 容差"的规整性。
///
/// 稳健统计（中位数 + MAD）而非均值/方差：对补记、跳月等
/// 个别异常点不敏感。纯 Dart，无依赖。
class RecurringDetector {
  const RecurringDetector._();

  static const _minOccurrences = 3;

  /// [toleranceDays] 间隔允许偏差（默认 ±3 天，覆盖 31/30 天月差）。
  static List<RecurringSuggestion> detect(
    List<RecurringTx> txs, {
    int toleranceDays = 3,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final byKey = <String, List<RecurringTx>>{};
    for (final t in txs) {
      final key = '${t.label} ${t.direction}';
      byKey.putIfAbsent(key, () => []).add(t);
    }
    final out = <RecurringSuggestion>[];
    for (final group in byKey.values) {
      if (group.length < _minOccurrences) continue;
      final sorted = [...group]..sort((a, b) => a.date.compareTo(b.date));
      final intervals = <int>[];
      for (var i = 1; i < sorted.length; i++) {
        intervals.add(sorted[i].date.difference(sorted[i - 1].date).inDays);
      }
      final med = _median(intervals);
      if (med < 5) continue; // 过密的多为日常消费噪声
      // 间隔规整度：落在中位数 ± 容差内的比例。
      final within = intervals
          .where((d) => (d - med).abs() <= toleranceDays)
          .length;
      final regularity = within / intervals.length;
      if (regularity < 0.7) continue;
      // 金额稳定度。
      final amounts = sorted.map((t) => t.amountMinor).toList();
      final medAmount = _medianBigInt(amounts);
      var maxDev = BigInt.zero;
      for (final a in amounts) {
        final dev = (a - medAmount).abs();
        if (dev > maxDev) maxDev = dev;
      }
      final threshold = medAmount ~/ BigInt.from(10);
      final stable = medAmount == BigInt.zero || maxDev <= threshold;
      final amountScore = stable ? 1.0 : 0.6;
      final sampleScore = math.min(1.0, sorted.length / 6);
      final s = RecurringSuggestion(
        label: sorted.first.label,
        direction: sorted.first.direction,
        intervalDays: med,
        occurrences: sorted.length,
        medianAmountMinor: medAmount,
        lastDate: sorted.last.date,
        amountStable: stable,
        confidence: regularity * amountScore * sampleScore,
      );
      // 已经远超周期未发生（>2 个周期）的不再建议。
      final overdueDays = n.difference(s.lastDate).inDays;
      if (overdueDays > med * 2) continue;
      out.add(s);
    }
    out.sort((a, b) => b.confidence.compareTo(a.confidence));
    return out;
  }

  static int _median(List<int> xs) {
    final s = [...xs]..sort();
    final mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : ((s[mid - 1] + s[mid]) / 2).round();
  }

  static BigInt _medianBigInt(List<BigInt> xs) {
    final s = [...xs]..sort();
    final mid = s.length ~/ 2;
    if (s.length.isOdd) return s[mid];
    return (s[mid - 1] + s[mid]) ~/ BigInt.two;
  }
}
