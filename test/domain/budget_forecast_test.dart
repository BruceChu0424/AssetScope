import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/domain/budget/budget_forecast.dart';

/// 预算信封月中预测口径测试。
void main() {
  test('月中配速线性外推：15 天花一半 → 预测 = 全月翻倍', () {
    final f = BudgetForecast.of(
      spentMinor: BigInt.from(5000),
      limitMinor: BigInt.from(12000),
      daysElapsed: 15,
      daysInMonth: 30,
    );
    expect(f!.projectedMinor, BigInt.from(10000));
    expect(f.willExceed, isFalse);
    expect(f.daysLeft, 15);
  });

  test('预测超支：willExceed 且建议日均只按剩余额度给', () {
    final f = BudgetForecast.of(
      spentMinor: BigInt.from(9000),
      limitMinor: BigInt.from(10000),
      daysElapsed: 15,
      daysInMonth: 30,
    );
    expect(f!.projectedMinor, BigInt.from(18000));
    expect(f.willExceed, isTrue);
    // 剩余 1000 分 ÷ 15 天 ≈ 66.67 → 67。
    expect(f.suggestedDailyMinor, BigInt.from(67));
  });

  test('已超支：建议日均 0', () {
    final f = BudgetForecast.of(
      spentMinor: BigInt.from(15000),
      limitMinor: BigInt.from(10000),
      daysElapsed: 15,
      daysInMonth: 30,
    );
    expect(f!.suggestedDailyMinor, BigInt.zero);
    expect(f.willExceed, isTrue);
  });

  test('月初（daysElapsed=0）无法外推返回 null', () {
    expect(
        BudgetForecast.of(
          spentMinor: BigInt.zero,
          limitMinor: BigInt.from(10000),
          daysElapsed: 0,
          daysInMonth: 30,
        ),
        isNull);
  });

  test('月末（daysLeft=0）：预测 = 已花', () {
    final f = BudgetForecast.of(
      spentMinor: BigInt.from(8000),
      limitMinor: BigInt.from(10000),
      daysElapsed: 31,
      daysInMonth: 31,
    );
    expect(f!.projectedMinor, BigInt.from(8000));
    expect(f.suggestedDailyMinor, BigInt.zero);
    expect(f.daysLeft, 0);
  });

  test('31 天大月的月中外推分母正确', () {
    final f = BudgetForecast.of(
      spentMinor: BigInt.from(3100),
      limitMinor: BigInt.from(6200),
      daysElapsed: 10,
      daysInMonth: 31,
    );
    expect(f!.projectedMinor, BigInt.from(9610));
  });
}
