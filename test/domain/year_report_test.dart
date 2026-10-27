import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/domain/reports/year_report.dart';

/// 年度报告聚合：月格合并、总收支、储蓄率、储蓄月数、分类年度排行。
void main() {
  test('全年聚合：总收支、储蓄率、储蓄月数、分类合并', () {
    final report = YearReportBuilder.build(
      year: 2026,
      baseCurrencyCode: 'CNY',
      monthLites: [
        MonthLite(
          month: 1,
          incomeMinor: BigInt.from(2000000),
          expenseMinor: BigInt.from(1500000),
          expenseByCategory: {
            'cat:e:food': BigInt.from(800000),
            'cat:e:home': BigInt.from(700000),
          },
          incomeByCategory: {'cat:i:salary': BigInt.from(2000000)},
          debtPrincipalRepaidMinor: BigInt.from(300000),
          debtInterestPaidMinor: BigInt.from(50000),
        ),
        MonthLite(
          month: 2,
          incomeMinor: BigInt.from(2000000),
          expenseMinor: BigInt.from(2200000), // 超支月
          expenseByCategory: {'cat:e:food': BigInt.from(1200000)},
          incomeByCategory: {'cat:i:salary': BigInt.from(2000000)},
          debtPrincipalRepaidMinor: BigInt.from(300000),
          debtInterestPaidMinor: BigInt.from(48000),
        ),
      ],
      categoryNames: const {
        'cat:e:food': '餐饮',
        'cat:e:home': '居住',
        'cat:i:salary': '工资',
      },
      biggestExpense: BiggestExpense(
        date: DateTime(2026, 2, 14),
        label: '某电商平台',
        amountMinor: BigInt.from(900000),
        categoryId: 'cat:e:other',
      ),
    );

    expect(report.totalIncomeMinor, BigInt.from(4000000));
    expect(report.totalExpenseMinor, BigInt.from(3700000));
    expect(report.totalSurplusMinor, BigInt.from(300000));
    expect(report.savingsRate, closeTo(0.075, 1e-9));
    expect(report.savingsMonths, 1); // 仅 1 月结余为正
    expect(report.months, hasLength(12));
    expect(report.months[0].hasData, isTrue);
    expect(report.months[2].hasData, isFalse); // 3 月无数据
    expect(report.expenseByCategory['cat:e:food'], BigInt.from(2000000));
    expect(report.debtPrincipalRepaidMinor, BigInt.from(600000));
    expect(report.debtInterestPaidMinor, BigInt.from(98000));
    expect(report.biggestExpense!.amountMinor, BigInt.from(900000));
    // 分类排行按金额降序
    expect(report.topExpenseCategories.first.categoryId, 'cat:e:food');
  });

  test('零收入年：储蓄率为 null 而非除零', () {
    final report = YearReportBuilder.build(
      year: 2026,
      baseCurrencyCode: 'CNY',
      monthLites: const [],
      categoryNames: const {},
      biggestExpense: null,
    );
    expect(report.savingsRate, isNull);
    expect(report.totalSurplusMinor, BigInt.zero);
    expect(report.topExpenseCategories, isEmpty);
  });
}
