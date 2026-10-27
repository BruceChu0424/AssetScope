import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/domain/money/fx_rate.dart';
import 'package:assetscope/domain/reports/month_report.dart';

/// 净资产归因恒等式验收：
/// 期末净资产 = 期初 + 收支 + 投资(已实现+分红+Δ未实现) + 汇兑 + 其他估值 + 修正 + 残差
void main() {
  test('纯收支月份：恒等式成立且残差为 0', () {
    final a = MonthAttributor.compute(AttributionInput(
      nwStartBaseMinor: BigInt.from(10000000), // 10 万
      nwEndBaseMinor: BigInt.from(10300000), // 10.3 万
      regularIncomeMinor: BigInt.from(500000),
      regularExpenseMinor: BigInt.from(200000),
      realizedPnlMinor: BigInt.zero,
      dividendMinor: BigInt.zero,
      unrealizedStartMinor: BigInt.zero,
      unrealizedEndMinor: BigInt.zero,
      fxEffectMinor: BigInt.zero,
      otherValuationChangeMinor: BigInt.zero,
      correctionMinor: BigInt.zero,
    ));
    expect(a.incomeExpense, BigInt.from(300000));
    expect(a.residual, BigInt.zero);
    expect(a.netChange, BigInt.from(300000));
  });

  test('关键验收：浮盈卖出不重复计收益', () {
    // 场景：
    //  上月末：持仓成本 10000，市价 12000（浮盈 2000 已计入上月净资产）
    //  本月：以 12500 卖出（净回款）
    //  正确口径：本月投资贡献 = 已实现 2500 + ΔU(0−2000) = 500
    //            （即本月价格从 12000 涨到 12500 的部分），而非 2500+2000。
    final realized = BigInt.from(1250000) - BigInt.from(1000000); // 2500 元 = 250000 分
    final uStart = BigInt.from(200000); // 上月末浮盈 2000
    final uEnd = BigInt.zero;
    final a = MonthAttributor.compute(AttributionInput(
      nwStartBaseMinor: BigInt.from(1000000) + uStart, // 现金 0 + 市值 12000
      nwEndBaseMinor: BigInt.from(1250000), // 卖出后现金 12500
      regularIncomeMinor: BigInt.zero,
      regularExpenseMinor: BigInt.zero,
      realizedPnlMinor: realized,
      dividendMinor: BigInt.zero,
      unrealizedStartMinor: uStart,
      unrealizedEndMinor: uEnd,
      fxEffectMinor: BigInt.zero,
      otherValuationChangeMinor: BigInt.zero,
      correctionMinor: BigInt.zero,
    ));
    expect(a.investRealized, BigInt.from(250000));
    expect(a.investUnrealizedDelta, -BigInt.from(200000));
    expect(a.investTotal, BigInt.from(50000)); // 只计一次
    expect(a.residual, BigInt.zero);
    expect(a.netChange, BigInt.from(50000));
  });

  test('买入按市价成交：不产生虚假收益', () {
    // 上月末：现金 20000，无持仓。本月 15000 买入（市价成交），月末市值 15000。
    final a = MonthAttributor.compute(AttributionInput(
      nwStartBaseMinor: BigInt.from(2000000),
      nwEndBaseMinor: BigInt.from(2000000), // 现金 5000 + 市值 15000
      regularIncomeMinor: BigInt.zero,
      regularExpenseMinor: BigInt.zero,
      realizedPnlMinor: BigInt.zero,
      dividendMinor: BigInt.zero,
      unrealizedStartMinor: BigInt.zero,
      unrealizedEndMinor: BigInt.zero, // U = MV − CB = 0
      fxEffectMinor: BigInt.zero,
      otherValuationChangeMinor: BigInt.zero,
      correctionMinor: BigInt.zero,
    ));
    expect(a.investTotal, BigInt.zero);
    expect(a.residual, BigInt.zero);
  });

  test('外币头寸汇率重估：fxEffect 计算正确', () {
    final effect = fxEffectMinor(
      foreignAccounts: [
        ForeignBalanceStart(
          accountId: 'usd',
          balanceStartMinor: BigInt.from(100000), // $1000
          fxStart: Rational.parseDecimal('7.0'),
          fxEnd: Rational.parseDecimal('7.2'),
        ),
      ],
      foreignHoldings: [],
    );
    // 1000 × (7.2 − 7.0) = +200 元
    expect(effect, BigInt.from(20000));
  });

  test('历史修正单列：不混入当期收支', () {
    final a = MonthAttributor.compute(AttributionInput(
      nwStartBaseMinor: BigInt.from(1000000),
      nwEndBaseMinor: BigInt.from(1100000),
      regularIncomeMinor: BigInt.zero,
      regularExpenseMinor: BigInt.zero,
      realizedPnlMinor: BigInt.zero,
      dividendMinor: BigInt.zero,
      unrealizedStartMinor: BigInt.zero,
      unrealizedEndMinor: BigInt.zero,
      fxEffectMinor: BigInt.zero,
      otherValuationChangeMinor: BigInt.zero,
      correctionMinor: BigInt.from(100000), // 补录 1 万旧资产
    ));
    expect(a.correction, BigInt.from(100000));
    expect(a.residual, BigInt.zero);
    expect(a.hasResidual, isFalse);
  });

  test('残差显式暴露数据缺口', () {
    final a = MonthAttributor.compute(AttributionInput(
      nwStartBaseMinor: BigInt.from(1000000),
      nwEndBaseMinor: BigInt.from(1050000),
      regularIncomeMinor: BigInt.from(10000),
      regularExpenseMinor: BigInt.zero,
      realizedPnlMinor: BigInt.zero,
      dividendMinor: BigInt.zero,
      unrealizedStartMinor: BigInt.zero,
      unrealizedEndMinor: BigInt.zero,
      fxEffectMinor: BigInt.zero,
      otherValuationChangeMinor: BigInt.zero,
      correctionMinor: BigInt.zero,
    ));
    expect(a.hasResidual, isTrue);
    expect(a.residual, BigInt.from(40000)); // 5000 − 1000，未解释的 400 元
  });
}
