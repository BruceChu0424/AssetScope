import '../money/fx_rate.dart';

/// 估值类型。
enum ValuationKind {
  /// 持仓单价（每 1 单位，计价币种）。
  unitPrice,

  /// 手工总价值（房产、车辆等）。
  totalValue,
}

/// 估值记录：持仓价格或手工资产价值的时间序列。
class ValuationRecord {
  const ValuationRecord({
    required this.accountId,
    required this.date,
    required this.kind,
    this.unitPrice,
    this.totalValueMinor,
    this.source = 'manual',
    this.note,
  });

  final String accountId;
  final DateTime date;
  final ValuationKind kind;

  /// 每单位价格（有理数精确）。
  final Rational? unitPrice;
  final BigInt? totalValueMinor;
  final String source;
  final String? note;
}

/// 单账户的估值解析结果。
class ResolvedValuation {
  const ResolvedValuation({
    this.record,
    required this.asOfDate,
    this.staleDays,
  });

  /// 生效的最新估值；null 表示无估值。
  final ValuationRecord? record;

  /// 解析基准日（估值可能早于该日）。
  final DateTime asOfDate;

  /// 估值距基准日的天数；null 表示无估值。
  final int? staleDays;

  bool get missing => record == null;

  /// 估值过期阈值（天）——超过则 UI 显示“估值陈旧”。
  static const staleThresholdDays = 30;

  bool get isStale =>
      staleDays != null && staleDays! > staleThresholdDays;
}

class ValuationResolver {
  const ValuationResolver._();

  /// 取 [onOrBefore] 当天或之前最近的一条估值。
  static ResolvedValuation resolve(
    List<ValuationRecord> records,
    DateTime onOrBefore,
  ) {
    ValuationRecord? best;
    for (final r in records) {
      if (r.date.isAfter(onOrBefore)) continue;
      if (best == null || r.date.isAfter(best.date)) best = r;
    }
    if (best == null) {
      return ResolvedValuation(record: null, asOfDate: onOrBefore);
    }
    return ResolvedValuation(
      record: best,
      asOfDate: onOrBefore,
      staleDays: onOrBefore.difference(best.date).inDays,
    );
  }
}
