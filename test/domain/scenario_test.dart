import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/domain/money/fx_rate.dart';
import 'package:assetscope/domain/planning/cash_projection.dart';
import 'package:assetscope/domain/planning/scenario.dart';

CashEvent _ev(DateTime d, BigInt amount,
        {CashEventKind kind = CashEventKind.planned,
        String label = 'e',
        String? accountId}) =>
    CashEvent(
        date: d,
        amountBaseMinor: amount,
        label: label,
        accountId: accountId,
        kind: kind);

void main() {
  final from = DateTime(2026, 1, 1);
  final yuan = BigInt.from(100);
  BigInt y(int v) => BigInt.from(v) * yuan;

  group('ScenarioEngine.apply', () {
    test('空情景恒等', () {
      final events = [_ev(from, BigInt.from(100))];
      final out = ScenarioEngine.apply(
          events, const ScenarioSpec(name: '空', components: []), from);
      expect(out.length, 1);
      expect(out.first.amountBaseMinor, BigInt.from(100));
    });

    test('收入中断：窗口内收入清零，窗口外与支出不受影响', () {
      final events = [
        _ev(DateTime(2026, 1, 5), y(10000),
            kind: CashEventKind.incomeExpected),
        _ev(DateTime(2026, 2, 5), y(10000),
            kind: CashEventKind.incomeExpected),
        _ev(DateTime(2026, 3, 5), y(10000),
            kind: CashEventKind.incomeExpected), // 窗口外（1/1+2月=3/1）
        _ev(DateTime(2026, 1, 5), -y(3000)),
        _ev(DateTime(2026, 1, 10), -y(2500),
            kind: CashEventKind.debtRepay),
      ];
      final out = ScenarioEngine.apply(
          events,
          ScenarioSpec(name: '失业', components: [
            IncomeShock(drop: Rational.one, months: 2)
          ]),
          from);
      expect(out[0].amountBaseMinor, BigInt.zero); // 1 月收入 → 0
      expect(out[1].amountBaseMinor, BigInt.zero); // 2 月收入 → 0
      expect(out[2].amountBaseMinor, y(10000)); // 3 月不动
      expect(out[3].amountBaseMinor, -y(3000)); // 支出不动
      expect(out[4].amountBaseMinor, -y(2500)); // 还款不动
    });

    test('降三成：收入 ×0.7（halfEven 舍入）', () {
      final events = [
        _ev(DateTime(2026, 1, 5), y(9999) + BigInt.from(50),
            kind: CashEventKind.incomeExpected),
      ];
      final out = ScenarioEngine.apply(
          events,
          ScenarioSpec(name: '降薪', components: [
            IncomeShock(
                drop: Rational.fromFrac(BigInt.from(3), BigInt.from(10)),
                months: 1)
          ]),
          from);
      // 999950 × 0.7 = 699965（整数，无舍入差）
      expect(out[0].amountBaseMinor, BigInt.from(699965));
    });

    test('工资延发：收入事件推迟 delayDays，支出不动', () {
      final events = [
        _ev(DateTime(2026, 1, 5), y(10000),
            kind: CashEventKind.incomeExpected),
        _ev(DateTime(2026, 1, 5), -y(3000)),
      ];
      final out = ScenarioEngine.apply(
          events,
          ScenarioSpec(name: '延发', components: [
            IncomeDelay(delayDays: 30, months: 1)
          ]),
          from);
      expect(out[0].date, DateTime(2026, 2, 4));
      expect(out[1].date, DateTime(2026, 1, 5));
    });

    test('支出激增：planned ×1.2，debtRepay 与收入不动', () {
      final events = [
        _ev(DateTime(2026, 1, 5), -y(5000)),
        _ev(DateTime(2026, 1, 5), -y(2500),
            kind: CashEventKind.debtRepay),
        _ev(DateTime(2026, 1, 5), y(8000),
            kind: CashEventKind.incomeExpected),
      ];
      final out = ScenarioEngine.apply(
          events,
          ScenarioSpec(name: '通胀', components: [
            ExpenseSurge(
                surge: Rational.fromFrac(BigInt.one, BigInt.from(5)),
                months: 1)
          ]),
          from);
      expect(out[0].amountBaseMinor, -y(6000));
      expect(out[1].amountBaseMinor, -y(2500));
      expect(out[2].amountBaseMinor, y(8000));
    });

    test('一次性支出：按 afterDays 追加负事件', () {
      final out = ScenarioEngine.apply(
          const [],
          ScenarioSpec(name: '医疗', components: [
            OneOffEvent(
                afterDays: 15,
                amountBaseMinor: BigInt.from(-500000),
                label: '医疗')
          ]),
          from);
      expect(out.length, 1);
      expect(out.first.date, DateTime(2026, 1, 16));
      expect(out.first.amountBaseMinor, BigInt.from(-500000));
      expect(out.first.kind, CashEventKind.other);
    });

    test('额外月支出：月末锚点 clamp（1/31 → 2/28）', () {
      final out = ScenarioEngine.apply(
          const [],
          ScenarioSpec(name: '房租', components: [
            ExtraMonthlyOutflow(
                monthlyMinor: BigInt.from(300000), months: 2, label: '房租')
          ]),
          DateTime(2026, 1, 31));
      expect(out.length, 2);
      expect(out[0].date, DateTime(2026, 1, 31));
      expect(out[1].date, DateTime(2026, 2, 28));
      expect(out[1].amountBaseMinor, BigInt.from(-300000));
    });

    test('组合：冲击按顺序串联（先降三成再延发）', () {
      final events = [
        _ev(DateTime(2026, 1, 5), y(10000),
            kind: CashEventKind.incomeExpected),
      ];
      final out = ScenarioEngine.apply(
          events,
          ScenarioSpec(name: '组合', components: [
            IncomeShock(
                drop: Rational.fromFrac(BigInt.from(3), BigInt.from(10)),
                months: 1),
            IncomeDelay(delayDays: 10, months: 1),
          ]),
          from);
      // 先 10000→7000，再日期 +10 天
      expect(out[0].amountBaseMinor, y(7000));
      expect(out[0].date, DateTime(2026, 1, 15));
    });
  });

  group('ScenarioComparison（CashProjector 全链路）', () {
    ProjectionInput inputFor(List<CashEvent> events,
            {BigInt? start, BigInt? reserve, int horizonDays = 30}) =>
        ProjectionInput(
          baseCurrencyCode: 'CNY',
          accounts: [
            CashAccountSnapshot(
                accountId: 'bank',
                name: 'bank',
                currencyCode: 'CNY',
                balanceMinor: start ?? BigInt.zero,
                toBaseRate: Rational.one),
          ],
          events: events,
          reserveBaseMinor: reserve ?? BigInt.zero,
          baselineMinCashBaseMinor: BigInt.zero,
          fromDate: from,
          horizonDays: horizonDays,
        );

    ScenarioComparison compare(
        List<CashEvent> baselineEvents, List<CashEvent> scenarioEvents,
        {BigInt? start}) {
      return ScenarioComparison(
        baseline: CashProjector.project(inputFor(baselineEvents, start: start)),
        scenario: CashProjector.project(inputFor(scenarioEvents, start: start)),
        fromDate: from,
      );
    }

    test('可承受情景：无新增缺口、未耗尽', () {
      final base = [_ev(DateTime(2026, 1, 10), -y(2000))];
      final sc = [
        _ev(DateTime(2026, 1, 5), -y(1000),
            kind: CashEventKind.other),
        ...base,
      ];
      final c = compare(base, sc, start: y(10000));
      expect(c.survives, isTrue);
      expect(c.baseline.minBalanceBaseMinor, y(8000));
      expect(c.scenario.minBalanceBaseMinor, y(7000));
      expect(c.minBalanceDelta, -y(1000));
      expect(c.worstDailyDelta, -y(1000));
      expect(c.firstCashOutDate, isNull);
    });

    test('现金耗尽：首日 <0 与天数定位', () {
      final base = [_ev(DateTime(2026, 1, 10), -y(2000))];
      final sc = [
        _ev(DateTime(2026, 1, 5), -y(15000),
            kind: CashEventKind.other),
        ...base,
      ];
      final c = compare(base, sc, start: y(10000));
      expect(c.survives, isFalse);
      expect(c.firstCashOutDate, DateTime(2026, 1, 5));
      expect(c.daysToCashOut, 4); // 1/1 起点，1/5 耗尽（间隔 4 天）
      expect(c.minBalanceDelta, -y(15000));
      expect(c.newShortfalls, isNotEmpty);
    });

    test('准备金缺口：负余额前先触发"低于准备金与底线"', () {
      // 基线：余额 1000，准备金 0 → 无缺口；
      // 情景：准备金 800，余额 1000 - 500 = 500 < 800 → 缺口 300。
      final ev = [_ev(DateTime(2026, 1, 10), -y(500))];
      final c = ScenarioComparison(
        baseline: CashProjector.project(inputFor(ev, start: y(1000))),
        scenario: CashProjector.project(ProjectionInput(
          baseCurrencyCode: 'CNY',
          accounts: [
            CashAccountSnapshot(
                accountId: 'bank',
                name: 'bank',
                currencyCode: 'CNY',
                balanceMinor: y(1000),
                toBaseRate: Rational.one),
          ],
          events: ev,
          reserveBaseMinor: y(800),
          baselineMinCashBaseMinor: BigInt.zero,
          fromDate: from,
          horizonDays: 30,
        )),
        fromDate: from,
      );
      expect(c.survives, isFalse);
      // 逐日记录缺口（1/10 起每天一条），金额恒为 −300。
      expect(c.newShortfalls, isNotEmpty);
      expect(c.newShortfalls.first.date, DateTime(2026, 1, 10));
      expect(c.newShortfalls.first.amountBaseMinor, -y(300));
      expect(
          c.newShortfalls.every((s) => s.amountBaseMinor == -y(300)), isTrue);
    });
  });
}
