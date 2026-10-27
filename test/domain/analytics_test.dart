import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/domain/analytics/anomaly.dart';
import 'package:assetscope/domain/analytics/health.dart';
import 'package:assetscope/domain/analytics/recurring_detector.dart';
import 'package:assetscope/domain/analytics/spending_pace.dart';
import 'package:assetscope/domain/import/category_rules.dart';
import 'package:assetscope/domain/planning/recurrence.dart';

void main() {
  group('SpendingPace 消费配速', () {
    test('月中外推月末总额与剩余日均可用', () {
      final now = DateTime(2026, 5, 15); // 5 月 31 天，已过 15 天剩 16 天
      final spent = BigInt.from(300000); // 3000.00 元
      final pace = SpendingPace.of(now: now, spentMinor: spent);
      expect(pace.daysElapsed, 15);
      expect(pace.daysRemaining, 16);
      expect(pace.dailyAvgMinor, BigInt.from(20000)); // 200 元/天
      expect(pace.projectedMinor, BigInt.from(620000)); // 3000 + 200×16
      final p = pace.versus(BigInt.from(500000)); // 额度 5000
      expect(p.overPace, isTrue);
      expect(p.projectedDeltaMinor, BigInt.from(-120000));
      expect(p.safeDailyMinor, BigInt.zero);
    });

    test('配速内：剩余每日可花为正', () {
      final now = DateTime(2026, 5, 15);
      final pace = SpendingPace.of(now: now, spentMinor: BigInt.from(200000));
      final p = pace.versus(BigInt.from(1000000));
      expect(p.overPace, isFalse);
      expect(p.safeDailyMinor, greaterThan(BigInt.zero));
    });
  });

  group('RecurringDetector 周期识别', () {
    test('识别月付房租（间隔 30±2 天）', () {
      final monthly = <RecurringTx>[
        RecurringTx(
            date: DateTime(2026, 1, 5),
            amountMinor: BigInt.from(35000000),
            label: '房租',
            direction: false),
        RecurringTx(
            date: DateTime(2026, 2, 5),
            amountMinor: BigInt.from(35000000),
            label: '房租',
            direction: false),
        RecurringTx(
            date: DateTime(2026, 3, 5),
            amountMinor: BigInt.from(35000000),
            label: '房租',
            direction: false),
        RecurringTx(
            date: DateTime(2026, 4, 5),
            amountMinor: BigInt.from(35000000),
            label: '房租',
            direction: false),
      ];
      final now = DateTime(2026, 4, 20);
      final out = RecurringDetector.detect(monthly, now: now);
      expect(out, hasLength(1));
      expect(out.first.label, '房租');
      expect(out.first.intervalDays, inInclusiveRange(28, 32));
      expect(out.first.amountStable, isTrue);
      expect(out.first.cadenceLabel, '每月');
      expect(out.first.nextExpected(now), DateTime(2026, 5, 5));
    });

    test('不规则消费不误报', () {
      final now = DateTime(2026, 4, 20);
      final random = <RecurringTx>[
        RecurringTx(
            date: DateTime(2026, 1, 2),
            amountMinor: BigInt.from(1500),
            label: '超市',
            direction: false),
        RecurringTx(
            date: DateTime(2026, 1, 18),
            amountMinor: BigInt.from(8800),
            label: '超市',
            direction: false),
        RecurringTx(
            date: DateTime(2026, 2, 9),
            amountMinor: BigInt.from(32000),
            label: '超市',
            direction: false),
        RecurringTx(
            date: DateTime(2026, 3, 30),
            amountMinor: BigInt.from(5100),
            label: '超市',
            direction: false),
      ];
      expect(RecurringDetector.detect(random, now: now), isEmpty);
    });

    test('已断档超过两个周期不再建议', () {
      final now = DateTime(2026, 12, 1);
      final stale = <RecurringTx>[
        RecurringTx(
            date: DateTime(2026, 1, 1),
            amountMinor: BigInt.from(100000),
            label: '会员',
            direction: false),
        RecurringTx(
            date: DateTime(2026, 2, 1),
            amountMinor: BigInt.from(100000),
            label: '会员',
            direction: false),
        RecurringTx(
            date: DateTime(2026, 3, 1),
            amountMinor: BigInt.from(100000),
            label: '会员',
            direction: false),
      ];
      expect(RecurringDetector.detect(stale, now: now), isEmpty);
    });

    test('planCadence：间隔桶映射到计划周期', () {
      RecurringSuggestion s(int intervalDays) => RecurringSuggestion(
          label: '测试',
          intervalDays: intervalDays,
          direction: false,
          medianAmountMinor: BigInt.from(1000),
          lastDate: DateTime(2026, 10, 1),
          occurrences: 4,
          amountStable: true,
          confidence: 0.9);
      expect(s(365).planCadence(DateTime(2026, 11, 1)),
          (Cadence.yearly, 1));
      expect(s(30).planCadence(DateTime(2026, 11, 1)),
          (Cadence.monthly, 1));
      expect(s(14).planCadence(DateTime(2026, 11, 1)),
          (Cadence.biweekly, 1));
      expect(s(7).planCadence(DateTime(2026, 11, 1)), (Cadence.weekly, 1));
      expect(s(10).planCadence(DateTime(2026, 11, 1)),
          (Cadence.customInterval, 10));
    });
  });

  group('AnomalyDetector 异常检测', () {
    test('稳定基线上的激增被识别', () {
      final anomalies = AnomalyDetector.detect(
        categoryNames: {'cat:e:dining': '餐饮'},
        historyByCategory: {
          'cat:e:dining': [
            BigInt.from(100000),
            BigInt.from(100000),
            BigInt.from(100000),
          ],
        },
        currentByCategory: {'cat:e:dining': BigInt.from(1000000)},
      );
      expect(anomalies, hasLength(1));
      expect(anomalies.first.spendUp, isTrue);
      expect(anomalies.first.robustZ, greaterThan(3));
      expect(anomalies.first.categoryName, '餐饮');
    });

    test('单月历史大额不污染基线（中位数稳健）', () {
      final anomalies = AnomalyDetector.detect(
        categoryNames: const {},
        historyByCategory: {
          'c': [
            BigInt.from(100000),
            BigInt.from(100000),
            BigInt.from(9800000), // 年缴保费式的离群
            BigInt.from(100000),
            BigInt.from(100000),
          ],
        },
        currentByCategory: {'c': BigInt.from(120000)},
      );
      // 基线中位数 1000 元，本月 1200 → z 偏低不报警。
      expect(anomalies, isEmpty);
    });
  });

  group('财务健康与里程碑', () {
    test('储蓄率/应急月数/资产负债率', () {
      final h = computeHealth(
        incomeMinor: BigInt.from(2000000),
        expenseMinor: BigInt.from(1200000),
        liquidAssetsMinor: BigInt.from(6000000),
        avgMonthlyEssentialMinor: BigInt.from(1000000),
        totalAssetsMinor: BigInt.from(20000000),
        totalLiabilitiesMinor: BigInt.from(5000000),
        fixedIncomeMonthlyMinor: BigInt.from(2000000),
        fixedExpenseMonthlyMinor: BigInt.from(800000),
      );
      expect(h.savingsRate, closeTo(0.4, 1e-9));
      expect(h.emergencyMonths, closeTo(6.0, 1e-9));
      expect(h.debtToAsset, closeTo(0.25, 1e-9));
      expect(h.passiveCushion, closeTo(2.5, 1e-9));
    });

    test('零收入时储蓄率为 null（不产生假 0%）', () {
      final h = computeHealth(
        incomeMinor: BigInt.zero,
        expenseMinor: BigInt.from(100),
        liquidAssetsMinor: BigInt.zero,
        avgMonthlyEssentialMinor: BigInt.zero,
        totalAssetsMinor: BigInt.zero,
        totalLiabilitiesMinor: BigInt.zero,
        fixedIncomeMonthlyMinor: BigInt.zero,
        fixedExpenseMonthlyMinor: BigInt.zero,
      );
      expect(h.savingsRate, isNull);
      expect(h.emergencyMonths, isNull);
    });

    test('Theil-Sen 里程碑预测抗离群点', () {
      // 稳定 +1000 元/月，中间一个月暴跌（一次性大额支出）。
      final series = <BigInt>[
        BigInt.from(1000000),
        BigInt.from(1100000),
        BigInt.from(1200000),
        BigInt.from(200000), // 离群
        BigInt.from(1400000),
        BigInt.from(1500000),
      ];
      final m = NetWorthMilestone.predict(
        series: series,
        targetMinor: BigInt.from(2000000),
        asOf: DateTime(2026, 4, 30),
      );
      expect(m, isNotNull);
      // 两两斜率中位数 ≈ 100000/月 → 5000 分 = 5 个月左右。
      expect(m!.monthsToTarget, inInclusiveRange(4, 6));
      expect(m.targetDate, DateTime(2026, 9)); // 月粒度：4 月 + 5 个月
    });

    test('趋势向下不预测', () {
      final m = NetWorthMilestone.predict(
        series: [
          BigInt.from(1500000),
          BigInt.from(1400000),
          BigInt.from(1300000),
          BigInt.from(1200000),
        ],
        targetMinor: BigInt.from(2000000),
        asOf: DateTime(2026, 4, 30),
      );
      expect(m, isNull);
    });
  });

  group('CategoryRulesEngine 分类规则', () {
    test('显式规则最长关键词优先', () {
      final engine = CategoryRulesEngine(rules: const [
        CategoryRule(keyword: '美团', categoryId: 'cat:e:dining'),
        CategoryRule(keyword: '美团外卖', categoryId: 'cat:e:takeout'),
      ]);
      final m = engine.match('美团外卖-午餐订单');
      expect(m!.categoryId, 'cat:e:takeout');
      expect(m.source, RuleSource.keywordRule);
      expect(m.confidence, 1.0);
    });

    test('历史精确对手方按多数投票', () {
      final engine = CategoryRulesEngine(history: const [
        CategoryHistoryEntry(counterparty: '饿了么', categoryId: 'cat:e:dining', count: 3),
        CategoryHistoryEntry(counterparty: '饿了么', categoryId: 'cat:e:takeout', count: 1),
      ]);
      final m = engine.match('饿了么');
      expect(m!.categoryId, 'cat:e:dining');
      expect(m.source, RuleSource.exactHistory);
      expect(m.confidence, greaterThan(0.5));
    });

    test('模糊匹配（子串共享）兜底且封顶 0.85', () {
      final engine = CategoryRulesEngine(history: const [
        CategoryHistoryEntry(counterparty: '滴滴出行', categoryId: 'cat:e:transport', count: 2),
      ]);
      final m = engine.match('滴滴出行-快车');
      expect(m!.categoryId, 'cat:e:transport');
      expect(m.source, RuleSource.fuzzyHistory);
      expect(m.confidence <= 0.85, isTrue);
      expect(m.confidence >= 0.5, isTrue);
    });

    test('规则 JSON 编解码 roundtrip', () {
      const rules = [
        CategoryRule(keyword: '美团', categoryId: 'cat:e:dining'),
        CategoryRule(keyword: 'NETFLIX', categoryId: 'cat:e:subs', caseSensitive: true),
      ];
      final decoded = CategoryRulesEngine.decodeRules(
          CategoryRulesEngine.encodeRules(rules));
      expect(decoded.length, 2);
      expect(decoded[1].keyword, 'NETFLIX');
      expect(decoded[1].caseSensitive, isTrue);
    });

    test('无匹配返回 null', () {
      const engine = CategoryRulesEngine();
      expect(engine.match('完全陌生的商户'), isNull);
      expect(engine.match(''), isNull);
    });
  });
}
