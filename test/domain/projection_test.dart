import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/domain/money/fx_rate.dart';
import 'package:assetscope/domain/planning/cash_projection.dart';

void main() {
  final bank = CashAccountSnapshot(
    accountId: 'bank',
    name: '招行',
    currencyCode: 'CNY',
    balanceMinor: BigInt.from(1000000), // 1 万
    toBaseRate: Rational.one,
  );

  CashEvent ev(int day, BigInt amount, {String? account, String label = ''}) =>
      CashEvent(
        date: DateTime(2026, 6, day),
        amountBaseMinor: amount,
        label: label,
        accountId: account,
      );

  test('月底有钱但月中缺钱：识别透支与最低点', () {
    final proj = CashProjector.project(ProjectionInput(
      baseCurrencyCode: 'CNY',
      accounts: [bank],
      events: [
        ev(5, -BigInt.from(500000), label: '房租'), // -5000
        ev(10, -BigInt.from(800000), label: '大额'), // -8000 → 余额 -3000
        ev(30, BigInt.from(2000000), label: '工资'), // +2 万
      ],
      reserveBaseMinor: BigInt.zero,
      baselineMinCashBaseMinor: BigInt.zero,
      fromDate: DateTime(2026, 6, 1),
      horizonDays: 30,
    ));
    expect(proj.hasShortfall, isTrue);
    expect(proj.minBalanceBaseMinor, -BigInt.from(300000));
    expect(proj.minBalanceDate, DateTime(2026, 6, 10));
    // 计划外可支配 = 0（已透支）
    expect(proj.discretionaryBaseMinor, BigInt.zero);
  });

  test('可支配额公式：max(0, min_t[C − R − B])', () {
    final proj = CashProjector.project(ProjectionInput(
      baseCurrencyCode: 'CNY',
      accounts: [bank],
      events: [
        ev(5, -BigInt.from(200000), label: '订阅'),
      ],
      reserveBaseMinor: BigInt.from(300000), // 准备金 3000
      baselineMinCashBaseMinor: BigInt.from(200000), // 底线 2000
      fromDate: DateTime(2026, 6, 1),
      horizonDays: 30,
    ));
    // C 最低点 = 8000；min_t[C−R−B] = 8000 − 3000 − 2000 = 3000
    expect(proj.discretionaryBaseMinor, BigInt.from(300000));
    expect(proj.hasShortfall, isFalse);
  });

  test('准备金已含在现金中：只扣一次（不双扣）', () {
    // 期初现金 1 万，其中 3000 已预留；月底计划支付该预留支出 3000。
    final proj = CashProjector.project(ProjectionInput(
      baseCurrencyCode: 'CNY',
      accounts: [bank],
      events: [
        ev(28, -BigInt.from(300000), label: '旅游付款（已预留）'),
      ],
      reserveBaseMinor: BigInt.from(300000),
      reserveReleases: [
        ReserveRelease(
            date: DateTime(2026, 6, 28), amountBaseMinor: BigInt.from(300000)),
      ],
      baselineMinCashBaseMinor: BigInt.zero,
      fromDate: DateTime(2026, 6, 1),
      horizonDays: 30,
    ));
    // 支付前：C=1万，扣准备金后可支配 7000；
    // 支付后：C=7000，准备金同步释放 → 仍 7000。min = 7000。
    expect(proj.discretionaryBaseMinor, BigInt.from(700000));
    expect(proj.hasShortfall, isFalse);
  });

  test('单账户维度：总现金充足但扣款卡不足会被发现', () {
    final alipayLow = CashAccountSnapshot(
      accountId: 'alipay',
      name: '支付宝',
      currencyCode: 'CNY',
      balanceMinor: BigInt.from(10000), // 100 元
      toBaseRate: Rational.one,
    );
    final proj = CashProjector.project(ProjectionInput(
      baseCurrencyCode: 'CNY',
      accounts: [bank, alipayLow],
      events: [
        ev(3, -BigInt.from(50000), account: 'alipay', label: '自动扣款'),
      ],
      reserveBaseMinor: BigInt.zero,
      baselineMinCashBaseMinor: BigInt.zero,
      fromDate: DateTime(2026, 6, 1),
      horizonDays: 30,
    ));
    expect(
        proj.shortfalls.any((s) => s.accountId == 'alipay'), isTrue,
        reason: '支付宝余额 100 元不足以支付 500 元扣款');
  });
}
