import '../money/fx_rate.dart';

/// 净资产归因与月报计算（纯函数）。
///
/// 核心恒等式（各分量互斥，见 docs/05-账务口径与算法.md）：
///
///   期末净资产 = 期初净资产
///     + 收支贡献            （收入 − 消费/费用，消费在发生时确认）
///     + 投资损益            （已实现 + 分红 + 未实现余额变化 ΔU）
///     + 汇兑影响            （期初外币头寸的汇率变动）
///     + 其他估值变化        （房产等手工估值调整）
///     + 范围/历史修正       （期初余额补录、对账调整）
///     + 待核对差额          （残差，应≈0；非 0 说明数据不完整）
///
/// “已实现 + ΔU”的设计保证：以前期间已经计入净资产的浮盈，
/// 本期卖出时只是从未实现变为已实现，不会被重复计为本期收益。
class AttributionInput {
  const AttributionInput({
    required this.nwStartBaseMinor,
    required this.nwEndBaseMinor,
    required this.regularIncomeMinor,
    required this.regularExpenseMinor,
    required this.realizedPnlMinor,
    required this.dividendMinor,
    required this.unrealizedStartMinor,
    required this.unrealizedEndMinor,
    required this.fxEffectMinor,
    required this.otherValuationChangeMinor,
    required this.correctionMinor,
  });

  /// 实际期初/期末净资产（本位币）。
  final BigInt nwStartBaseMinor;
  final BigInt nwEndBaseMinor;

  /// 常规收入/消费费用（非投资、非调整，本位币口径）。
  final BigInt regularIncomeMinor;
  final BigInt regularExpenseMinor;

  /// 已实现投资损益（正=收益）与分红。
  final BigInt realizedPnlMinor;
  final BigInt dividendMinor;

  /// 持仓未实现损益余额 U = 市值 − 成本（期初/期末）。
  final BigInt unrealizedStartMinor;
  final BigInt unrealizedEndMinor;

  /// 汇兑影响（期初外币头寸 × 汇率变动）。
  final BigInt fxEffectMinor;

  /// 房产等手工估值变化。
  final BigInt otherValuationChangeMinor;

  /// 期初补录 + 对账调整的净资产影响。
  final BigInt correctionMinor;
}

class MonthAttribution {
  const MonthAttribution({
    required this.nwStart,
    required this.nwEnd,
    required this.netChange,
    required this.incomeExpense,
    required this.investRealized,
    required this.investDividend,
    required this.investUnrealizedDelta,
    required this.fxEffect,
    required this.otherValuation,
    required this.correction,
    required this.residual,
  });

  final BigInt nwStart;
  final BigInt nwEnd;
  final BigInt netChange;
  final BigInt incomeExpense;
  final BigInt investRealized;
  final BigInt investDividend;
  final BigInt investUnrealizedDelta;
  final BigInt fxEffect;
  final BigInt otherValuation;
  final BigInt correction;

  /// 待核对差额：实际变化 − 各分量之和。非 0 表示数据缺口
  ///（缺估值、漏记、导入重复等），月报必须显式展示。
  final BigInt residual;

  BigInt get investTotal =>
      investRealized + investDividend + investUnrealizedDelta;

  bool get hasResidual => residual != BigInt.zero;
}

class MonthAttributor {
  const MonthAttributor._();

  static MonthAttribution compute(AttributionInput i) {
    final incomeExpense = i.regularIncomeMinor - i.regularExpenseMinor;
    final unrealizedDelta = i.unrealizedEndMinor - i.unrealizedStartMinor;
    final actual = i.nwEndBaseMinor - i.nwStartBaseMinor;
    final explained = incomeExpense +
        i.realizedPnlMinor +
        i.dividendMinor +
        unrealizedDelta +
        i.fxEffectMinor +
        i.otherValuationChangeMinor +
        i.correctionMinor;
    return MonthAttribution(
      nwStart: i.nwStartBaseMinor,
      nwEnd: i.nwEndBaseMinor,
      netChange: actual,
      incomeExpense: incomeExpense,
      investRealized: i.realizedPnlMinor,
      investDividend: i.dividendMinor,
      investUnrealizedDelta: unrealizedDelta,
      fxEffect: i.fxEffectMinor,
      otherValuation: i.otherValuationChangeMinor,
      correction: i.correctionMinor,
      residual: actual - explained,
    );
  }
}

/// 汇兑影响计算：期初持有的外币头寸在期末汇率下的重估。
///
/// inputs:
/// - 外币账户期初余额（账户币种）与其 期初/期末 → 本位币汇率；
/// - 持仓期初数量、期末价格（计价币种）与其计价币种汇率变动。
BigInt fxEffectMinor({
  required List<ForeignBalanceStart> foreignAccounts,
  required List<ForeignHoldingStart> foreignHoldings,
}) {
  var total = BigInt.zero;
  for (final a in foreignAccounts) {
    // startBal × (fxEnd − fxStart)
    total +=
        (Rational.fromInt(a.balanceStartMinor) * (a.fxEnd - a.fxStart)).rounded();
  }
  for (final h in foreignHoldings) {
    // qtyStart × priceEnd × (fxEnd − fxStart)
    total += (h.qtyStart * h.priceEnd * (h.fxEnd - h.fxStart)).rounded();
  }
  return total;
}

class ForeignBalanceStart {
  const ForeignBalanceStart({
    required this.accountId,
    required this.balanceStartMinor,
    required this.fxStart,
    required this.fxEnd,
  });

  final String accountId;

  /// 期初余额（账户币种最小单位）。
  final BigInt balanceStartMinor;

  /// 账户币种→本位币 汇率（期初/期末）。
  final Rational fxStart;
  final Rational fxEnd;
}

class ForeignHoldingStart {
  const ForeignHoldingStart({
    required this.accountId,
    required this.qtyStart,
    required this.priceEnd,
    required this.fxStart,
    required this.fxEnd,
  });

  final String accountId;
  final Rational qtyStart;

  /// 期末单价（计价币种）。
  final Rational priceEnd;
  final Rational fxStart;
  final Rational fxEnd;
}
