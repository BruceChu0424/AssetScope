import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/domain/planning/recurrence.dart';
import 'package:assetscope/domain/utils/dates.dart';

void main() {
  test('每月 31 日锚点：2 月落在月末，闰年 29 日', () {
    final e = ScheduledEvent(
      id: 'e1',
      name: '房租',
      direction: EventDirection.outflow,
      currencyCode: 'CNY',
      cadence: Cadence.monthly,
      anchorDate: DateTime(2024, 1, 31),
      amountMinor: BigInt.from(300000),
    );
    final occ = e.expand(DateTime(2024, 1, 1), DateTime(2024, 4, 30));
    expect(occ.length, 4);
    expect(occ[0].date, DateTime(2024, 1, 31));
    expect(occ[1].date, DateTime(2024, 2, 29)); // 2024 闰年
    expect(occ[2].date, DateTime(2024, 3, 31));
    expect(occ[3].date, DateTime(2024, 4, 30));
  });

  test('非闰年 2 月末为 28 日', () {
    final d = addMonthsClamped(DateTime(2026, 1, 31), 1);
    expect(d, DateTime(2026, 2, 28));
  });

  test('跳过月份与金额覆盖（涨租）', () {
    final e = ScheduledEvent(
      id: 'e2',
      name: '房租',
      direction: EventDirection.outflow,
      currencyCode: 'CNY',
      cadence: Cadence.monthly,
      anchorDate: DateTime(2026, 1, 5),
      amountMinor: BigInt.from(300000),
      skippedMonthKeys: {'2026-02'},
      amountOverrides: {'2026-04': BigInt.from(350000)},
    );
    final occ = e.expand(DateTime(2026, 1, 1), DateTime(2026, 5, 31));
    // 1月 3000、2月跳过、3月 3000、4月起 3500、5月 3500
    expect(occ.length, 4);
    expect(occ.any((o) => monthKey(o.date) == '2026-02'), isFalse);
    expect(occ[2].amountMinor, -BigInt.from(350000));
    expect(occ[3].amountMinor, -BigInt.from(350000));
  });

  test('区间估算：取中位数并标记 isEstimate', () {
    final e = ScheduledEvent(
      id: 'e3',
      name: '水电',
      direction: EventDirection.outflow,
      currencyCode: 'CNY',
      cadence: Cadence.monthly,
      anchorDate: DateTime(2026, 1, 15),
      amountLowMinor: BigInt.from(10000),
      amountHighMinor: BigInt.from(50000),
    );
    final occ = e.expand(DateTime(2026, 1, 1), DateTime(2026, 2, 28));
    expect(occ.first.isEstimate, isTrue);
    expect(occ.first.amountMinor, -BigInt.from(30000));
  });

  test('单次计划只在锚点日发生', () {
    final e = ScheduledEvent(
      id: 'e4',
      name: '年付保险',
      direction: EventDirection.outflow,
      currencyCode: 'CNY',
      cadence: Cadence.once,
      anchorDate: DateTime(2026, 3, 20),
      amountMinor: BigInt.from(3000000),
    );
    expect(e.expand(DateTime(2026, 1, 1), DateTime(2026, 12, 31)).length, 1);
    expect(e.expand(DateTime(2026, 4, 1), DateTime(2026, 12, 31)), isEmpty);
  });

  test('暂停的计划不产生预期', () {
    final e = ScheduledEvent(
      id: 'e5',
      name: '订阅',
      direction: EventDirection.outflow,
      currencyCode: 'CNY',
      cadence: Cadence.monthly,
      anchorDate: DateTime(2026, 1, 1),
      amountMinor: BigInt.from(1500),
      status: PlanStatus.paused,
    );
    expect(e.expand(DateTime(2026, 1, 1), DateTime(2026, 6, 30)), isEmpty);
  });

  test('单次跳过某日：该次不产生预期，同月其他次保留', () {
    final e = ScheduledEvent(
      id: 'e6',
      name: '保洁',
      direction: EventDirection.outflow,
      currencyCode: 'CNY',
      cadence: Cadence.weekly,
      anchorDate: DateTime(2026, 3, 2), // 周一
      amountMinor: BigInt.from(20000),
      skippedDateKeys: {dateKey(DateTime(2026, 3, 16))},
    );
    final occ = e.expand(DateTime(2026, 3, 1), DateTime(2026, 3, 31));
    // 3 月的周一：2/9/16/23/30，跳过 16 日 → 4 次
    expect(occ.length, 4);
    expect(occ.any((o) => dateKey(o.date) == '2026-03-16'), isFalse);
  });

  test('copyWith 保留未改字段（改状态不丢跳过与覆盖配置）', () {
    final e = ScheduledEvent(
      id: 'e7',
      name: '房租',
      direction: EventDirection.outflow,
      currencyCode: 'CNY',
      cadence: Cadence.monthly,
      anchorDate: DateTime(2026, 1, 5),
      amountMinor: BigInt.from(300000),
      paymentAccountId: 'acc:cash',
      categoryId: 'cat:e:rent',
      skippedMonthKeys: {'2026-02'},
      amountOverrides: {'2026-04': BigInt.from(350000)},
    );
    final paused = e.copyWith(status: PlanStatus.paused);
    expect(paused.id, e.id);
    expect(paused.name, '房租');
    expect(paused.amountMinor, BigInt.from(300000));
    expect(paused.paymentAccountId, 'acc:cash');
    expect(paused.categoryId, 'cat:e:rent');
    expect(paused.skippedMonthKeys, {'2026-02'});
    expect(paused.amountOverrides, {'2026-04': BigInt.from(350000)});
    expect(paused.status, PlanStatus.paused);
    // copyWith 语义：只覆盖显式传入的字段，其余原样保留。
    final renamed = e.copyWith(name: '月租');
    expect(renamed.name, '月租');
    expect(renamed.anchorDate, e.anchorDate);
  });

  test('目标每月预留计算（向上取整）与过期处理', () {
    final g = SavingsGoal(
      id: 'g1',
      name: '旅行',
      targetAmountMinor: BigInt.from(1000000),
      targetDate: DateTime(2026, 12, 31),
      reservedAmountMinor: BigInt.from(400000),
    );
    final need = g.monthlyNeedMinor(DateTime(2026, 7, 1));
    // 缺口 6000，剩余 6 个月（7-12 月）→ 每月 1000
    expect(need, BigInt.from(100000));
    final expired = SavingsGoal(
      id: 'g2',
      name: '过期',
      targetAmountMinor: BigInt.from(100000),
      targetDate: DateTime(2026, 1, 1),
      reservedAmountMinor: BigInt.zero,
    );
    expect(expired.monthlyNeedMinor(DateTime(2026, 7, 1)), isNull);
    expect(expired.gapMinor, BigInt.from(100000));
  });
}
