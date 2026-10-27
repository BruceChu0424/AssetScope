/// 年度报告聚合（纯函数，输入由服务层从各月月报收集）。
///
/// 口径与月报一致：金额为本位币最小单位整数；
/// 结余 = 收入 − 消费与费用；储蓄率 = 结余 / 收入（收入为 0 时为 null）。
class MonthLite {
  const MonthLite({
    required this.month,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.debtPrincipalRepaidMinor,
    required this.debtInterestPaidMinor,
  });

  final int month;
  final BigInt incomeMinor;
  final BigInt expenseMinor;
  final Map<String, BigInt> expenseByCategory;
  final Map<String, BigInt> incomeByCategory;
  final BigInt debtPrincipalRepaidMinor;
  final BigInt debtInterestPaidMinor;
}

/// 年度月格（1–12 全量，无数据的月份 [hasData] 为 false）。
class YearMonthCell {
  const YearMonthCell({
    required this.month,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final int month;
  final BigInt incomeMinor;
  final BigInt expenseMinor;

  BigInt get surplusMinor => incomeMinor - expenseMinor;

  bool get hasData =>
      incomeMinor != BigInt.zero || expenseMinor != BigInt.zero;
}

/// 年度最大单笔消费。
class BiggestExpense {
  const BiggestExpense({
    required this.date,
    required this.label,
    required this.amountMinor,
    required this.categoryId,
  });

  final DateTime date;
  final String label;
  final BigInt amountMinor;
  final String categoryId;
}

/// 分类年度合计条目。
class CategoryTotal {
  const CategoryTotal(this.categoryId, this.name, this.totalMinor);
  final String categoryId;
  final String name;
  final BigInt totalMinor;
}

class YearReport {
  const YearReport({
    required this.year,
    required this.baseCurrencyCode,
    required this.months,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.categoryNames,
    required this.biggestExpense,
    required this.debtPrincipalRepaidMinor,
    required this.debtInterestPaidMinor,
  });

  final int year;
  final String baseCurrencyCode;

  /// 1–12 月全量格子。
  final List<YearMonthCell> months;

  /// 分类 → 年度累计（消费 / 收入）。
  final Map<String, BigInt> expenseByCategory;
  final Map<String, BigInt> incomeByCategory;

  /// 分类 ID → 展示名。
  final Map<String, String> categoryNames;
  final BiggestExpense? biggestExpense;
  final BigInt debtPrincipalRepaidMinor;
  final BigInt debtInterestPaidMinor;

  BigInt get totalIncomeMinor =>
      months.fold(BigInt.zero, (s, m) => s + m.incomeMinor);

  BigInt get totalExpenseMinor =>
      months.fold(BigInt.zero, (s, m) => s + m.expenseMinor);

  BigInt get totalSurplusMinor => totalIncomeMinor - totalExpenseMinor;

  /// 储蓄率 = 结余 / 收入；全年零收入时为 null（不除零）。
  /// （比率属展示口径，允许 double；金额本身始终为整数。）
  double? get savingsRate => totalIncomeMinor == BigInt.zero
      ? null
      : totalSurplusMinor.toDouble() / totalIncomeMinor.toDouble();

  /// 结余为正的月份数。
  int get savingsMonths =>
      months.where((m) => m.surplusMinor > BigInt.zero).length;

  /// 消费分类年度排行（降序）。
  List<CategoryTotal> get topExpenseCategories {
    final list = [
      for (final e in expenseByCategory.entries)
        CategoryTotal(e.key, categoryNames[e.key] ?? e.key, e.value)
    ]..sort((a, b) => b.totalMinor.compareTo(a.totalMinor));
    return list;
  }

  List<CategoryTotal> get topIncomeCategories {
    final list = [
      for (final e in incomeByCategory.entries)
        CategoryTotal(e.key, categoryNames[e.key] ?? e.key, e.value)
    ]..sort((a, b) => b.totalMinor.compareTo(a.totalMinor));
    return list;
  }
}

class YearReportBuilder {
  const YearReportBuilder._();

  static YearReport build({
    required int year,
    required String baseCurrencyCode,
    required List<MonthLite> monthLites,
    required Map<String, String> categoryNames,
    required BiggestExpense? biggestExpense,
  }) {
    final byMonth = {for (final m in monthLites) m.month: m};
    final months = [
      for (var m = 1; m <= 12; m++)
        YearMonthCell(
          month: m,
          incomeMinor: byMonth[m]?.incomeMinor ?? BigInt.zero,
          expenseMinor: byMonth[m]?.expenseMinor ?? BigInt.zero,
        ),
    ];
    final expenseByCategory = <String, BigInt>{};
    final incomeByCategory = <String, BigInt>{};
    var principal = BigInt.zero;
    var interest = BigInt.zero;
    for (final m in monthLites) {
      m.expenseByCategory.forEach((k, v) =>
          expenseByCategory[k] = (expenseByCategory[k] ?? BigInt.zero) + v);
      m.incomeByCategory.forEach((k, v) =>
          incomeByCategory[k] = (incomeByCategory[k] ?? BigInt.zero) + v);
      principal += m.debtPrincipalRepaidMinor;
      interest += m.debtInterestPaidMinor;
    }
    return YearReport(
      year: year,
      baseCurrencyCode: baseCurrencyCode,
      months: months,
      expenseByCategory: expenseByCategory,
      incomeByCategory: incomeByCategory,
      categoryNames: categoryNames,
      biggestExpense: biggestExpense,
      debtPrincipalRepaidMinor: principal,
      debtInterestPaidMinor: interest,
    );
  }
}
