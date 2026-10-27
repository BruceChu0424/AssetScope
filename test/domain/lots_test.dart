import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/domain/invest/lots.dart';
import 'package:assetscope/domain/money/fx_rate.dart';

Rational _q(String s) => Rational.parseDecimal(s);

void main() {
  test('单批买入部分卖出：配对与剩余', () {
    final r = LotEngine.run([
      LotBuy(_q('100'), BigInt.from(10000), DateTime(2025, 1, 10)),
      LotSell(_q('60'), BigInt.from(7200), DateTime(2025, 3, 10)),
    ]);
    expect(r.realized, hasLength(1));
    final m = r.realized.single;
    expect(m.quantity, _q('60'));
    expect(m.proceedsMinor, BigInt.from(7200));
    expect(m.costMinor, BigInt.from(6000));
    expect(m.pnlMinor, BigInt.from(1200));
    expect(m.acquiredDate, DateTime(2025, 1, 10));
    expect(m.daysHeld, 59);

    expect(r.openLots, hasLength(1));
    final lot = r.openLots.single;
    expect(lot.remainingQuantity, _q('40'));
    expect(lot.remainingCostMinor, BigInt.from(4000));
    expect(lot.unitCost, _q('100'));
    expect(r.openQuantity, _q('40'));
    expect(r.openCostMinor, BigInt.from(4000));
    expect(r.averageOpenUnitCost, _q('100'));
    expect(r.shortfallQuantity.isZero, isTrue);
  });

  test('FIFO 跨批次配对：先买先卖', () {
    final r = LotEngine.run([
      LotBuy(_q('100'), BigInt.from(10000), DateTime(2025, 1, 10)), // 单价 100
      LotBuy(_q('100'), BigInt.from(20000), DateTime(2025, 2, 10)), // 单价 200
      LotSell(_q('150'), BigInt.from(22500), DateTime(2025, 4, 10)), // 单价 150
    ]);
    expect(r.realized, hasLength(2));
    final m1 = r.realized[0];
    expect(m1.quantity, _q('100'));
    expect(m1.costMinor, BigInt.from(10000));
    expect(m1.proceedsMinor, BigInt.from(15000));
    expect(m1.pnlMinor, BigInt.from(5000));
    final m2 = r.realized[1];
    expect(m2.quantity, _q('50'));
    expect(m2.costMinor, BigInt.from(10000)); // 200 × 50
    expect(m2.proceedsMinor, BigInt.from(7500));
    expect(m2.pnlMinor, BigInt.from(-2500));
    expect(r.totalRealizedPnlMinor, BigInt.from(2500));

    expect(r.openLots.single.remainingQuantity, _q('50'));
    expect(r.openLots.single.remainingCostMinor, BigInt.from(10000));
    expect(r.openLots.single.acquiredDate, DateTime(2025, 2, 10));
  });

  test('同一批次分两次卖光：尾差吸收，Σ成本 = 批次成本', () {
    final r = LotEngine.run([
      LotBuy(_q('100'), BigInt.from(10000), DateTime(2025, 1, 10)),
      LotSell(_q('30'), BigInt.from(3600), DateTime(2025, 2, 10)),
      LotSell(_q('70'), BigInt.from(6300), DateTime(2025, 3, 10)),
    ]);
    expect(r.openLots, isEmpty);
    expect(r.realized[0].costMinor, BigInt.from(3000));
    expect(r.realized[1].costMinor, BigInt.from(7000));
    expect(
        r.realized.fold(BigInt.zero, (s, m) => s + m.costMinor),
        BigInt.from(10000)); // 严格等于批次成本
    expect(
        r.realized.fold(BigInt.zero, (s, m) => s + m.proceedsMinor),
        BigInt.from(9900));
  });

  test('分数数量精确配对（1/2 买、1/4 卖）', () {
    final r = LotEngine.run([
      LotBuy(_q('0.5'), BigInt.from(1234), DateTime(2025, 1, 10)), // 单价 2468
      LotSell(_q('0.25'), BigInt.from(700), DateTime(2025, 6, 10)),
    ]);
    final m = r.realized.single;
    expect(m.quantity, _q('0.25'));
    expect(m.proceedsMinor, BigInt.from(700));
    expect(m.costMinor, BigInt.from(617)); // 2468 × 0.25 精确
    expect(m.pnlMinor, BigInt.from(83));
    expect(r.openLots.single.remainingQuantity, _q('0.25'));
    expect(r.openLots.single.remainingCostMinor, BigInt.from(617));
  });

  test('卖出超过已知批次：缺口以零成本配对并披露', () {
    final r = LotEngine.run([
      LotBuy(_q('100'), BigInt.from(10000), DateTime(2025, 1, 10)),
      LotSell(_q('150'), BigInt.from(18000), DateTime(2025, 3, 10)),
    ]);
    expect(r.shortfallQuantity, _q('50'));
    expect(r.realized, hasLength(2));
    final gap = r.realized[1];
    expect(gap.costMinor, BigInt.zero);
    expect(gap.proceedsMinor, BigInt.from(6000)); // 120 × 50
    expect(gap.pnlMinor, BigInt.from(6000));
    expect(r.openLots, isEmpty);
  });

  test('事件乱序传入按时间排序；零数量事件忽略', () {
    final r = LotEngine.run([
      LotSell(_q('10'), BigInt.from(1500), DateTime(2025, 3, 10)),
      LotBuy(_q('100'), BigInt.from(10000), DateTime(2025, 1, 10)),
      LotBuy(_q('0'), BigInt.from(500), DateTime(2025, 2, 10)),
    ]);
    // 先买 100@100，再卖 10@150。
    expect(r.realized.single.costMinor, BigInt.from(1000));
    expect(r.realized.single.pnlMinor, BigInt.from(500));
    expect(r.openLots.single.remainingQuantity, _q('90'));
  });

  test('按年汇总已实现损益', () {
    final r = LotEngine.run([
      LotBuy(_q('100'), BigInt.from(10000), DateTime(2024, 1, 10)),
      LotSell(_q('10'), BigInt.from(1500), DateTime(2024, 6, 10)), // +500
      LotSell(_q('10'), BigInt.from(1200), DateTime(2025, 6, 10)), // +200
    ]);
    final byYear = r.realizedPnlByYear();
    expect(byYear[2024], BigInt.from(500));
    expect(byYear[2025], BigInt.from(200));
    expect(r.totalRealizedPnlMinor, BigInt.from(700));
  });
}
