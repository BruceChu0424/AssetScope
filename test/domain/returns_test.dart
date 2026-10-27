import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/domain/invest/returns.dart';

void main() {
  test('TWR：无外部现金流时等于持有期收益率', () {
    final r = TwrCalculator.twr(
      valuations: [
        TwrValuation(DateTime(2026, 1, 1), BigInt.from(1000000)),
        TwrValuation(DateTime(2026, 6, 30), BigInt.from(1100000)),
      ],
      flows: const [],
    );
    expect(r!, closeTo(0.10, 1e-9));
  });

  test('TWR：中途回撤 + 入金不影响期间收益率', () {
    // 1/1 市值 100 万；3/31 市值 90 万；4/1 入金 20 万；
    // 6/30 市值 125 万。
    // r1 = 90/100 − 1 = −10%；r2 = (125 − 20)/90 − 1 = +16.67%
    final r = TwrCalculator.twr(
      valuations: [
        TwrValuation(DateTime(2026, 1, 1), BigInt.from(1000000)),
        TwrValuation(DateTime(2026, 3, 31), BigInt.from(900000)),
        TwrValuation(DateTime(2026, 6, 30), BigInt.from(1250000)),
      ],
      flows: [TwrFlow(DateTime(2026, 4, 1), BigInt.from(200000))],
    );
    final expect1 = 0.9 * (1050000 / 900000) - 1;
    expect(r!, closeTo(expect1, 1e-6));
    // 且 ≠ 简单市值比 25%
    expect(r, lessThan(0.25));
  });

  test('XIRR：已知解收敛（一年前投 100，今天回 110 → ≈10%）', () {
    final r = xirr([
      XirrFlow(DateTime(2025, 1, 1), -BigInt.from(100000)),
      XirrFlow(DateTime(2026, 1, 1), BigInt.from(110000)),
    ]);
    expect(r!, closeTo(0.10, 1e-4));
  });

  test('XIRR：多笔现金流（半年期 + 一年期）', () {
    final r = xirr([
      XirrFlow(DateTime(2025, 1, 1), -BigInt.from(1000000)),
      XirrFlow(DateTime(2025, 7, 1), BigInt.from(300000)),
      XirrFlow(DateTime(2026, 1, 1), BigInt.from(850000)),
    ]);
    // 净收益 15 万；半年回款使 IRR 略高于简单收益率（≈17.6%）
    expect(r!, greaterThan(0.15));
    expect(r, lessThan(0.19));
  });

  test('XIRR：现金流同号无解返回 null', () {
    expect(
        xirr([
          XirrFlow(DateTime(2025, 1, 1), -BigInt.from(100)),
          XirrFlow(DateTime(2026, 1, 1), -BigInt.from(50)),
        ]),
        isNull);
  });

  test('XIRR：组合内部买卖不算外部现金流（口径约定）', () {
    // 只有入金 100 万和期末市值 120 万 → 20%；
    // 组合内部买卖在构造输入时不应作为 flows 出现。
    final r = xirr([
      XirrFlow(DateTime(2025, 1, 1), -BigInt.from(1000000)),
      XirrFlow(DateTime(2026, 1, 1), BigInt.from(1200000)),
    ]);
    expect(r!, closeTo(0.2, 1e-4));
  });
}
