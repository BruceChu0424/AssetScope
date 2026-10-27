import '../data/repositories/accounts_repo.dart';
import '../data/repositories/ledger_repo.dart';
import '../domain/ledger/account.dart';
import '../domain/ledger/transaction.dart';
import '../domain/reports/year_report.dart';
import 'stats_service.dart';

/// 年度报告服务：12 个月月报聚合（口径不变，见 docs/05 §3）
/// + 全年最大单笔消费扫描。纯聚合层，domain 逻辑在
/// `domain/reports/year_report.dart` 的 YearReportBuilder。
class YearReportService {
  YearReportService(this._accounts, this._ledger, this._stats);

  final AccountsRepo _accounts;
  final LedgerRepo _ledger;
  final StatsService _stats;

  Future<YearReport> yearReport(int year) async {
    final base = await _stats.baseCurrency();
    final lites = <MonthLite>[];
    for (var m = 1; m <= 12; m++) {
      final r = await _stats.monthReport(year, m);
      final income =
          r.incomeByCategory.values.fold(BigInt.zero, (a, b) => a + b);
      final expense =
          r.expenseByCategory.values.fold(BigInt.zero, (a, b) => a + b);
      lites.add(MonthLite(
        month: m,
        incomeMinor: income,
        expenseMinor: expense,
        expenseByCategory: r.expenseByCategory,
        incomeByCategory: r.incomeByCategory,
        debtPrincipalRepaidMinor: r.debtPrincipalRepaidMinor,
        debtInterestPaidMinor: r.debtInterestPaidMinor,
        realizedPnlMinor: r.attribution.investRealized,
        dividendMinor: r.attribution.investDividend,
      ));
    }

    // 全年最大单笔消费（按分类分录金额；排除系统分类）。
    final accounts = await _accounts.all();
    final byId = {for (final a in accounts) a.id: a};
    BiggestExpense? biggest;
    final txs = await _ledger.list(
        from: DateTime(year, 1, 1), to: DateTime(year, 12, 31, 23, 59, 59));
    for (final tx in txs) {
      if (tx.kind != TxKind.expense) continue;
      for (final p in tx.postings) {
        final acc = byId[p.accountId];
        if (acc == null ||
            acc.type != AccountType.expense ||
            acc.isSystem ||
            p.amountMinor == null) {
          continue;
        }
        final amount = p.amountMinor!.abs();
        if (biggest == null || amount > biggest.amountMinor) {
          biggest = BiggestExpense(
            date: tx.date,
            label: (tx.counterparty?.trim().isNotEmpty == true
                    ? tx.counterparty!.trim()
                    : tx.note?.trim()) ??
                tx.kind.labelZh,
            amountMinor: amount,
            categoryId: acc.id,
          );
        }
        break; // 每笔只看第一条分类分录
      }
    }

    final names = <String, String>{};
    for (final a in accounts) {
      names[a.id] = a.name;
    }
    return YearReportBuilder.build(
      year: year,
      baseCurrencyCode: base,
      monthLites: lites,
      categoryNames: names,
      biggestExpense: biggest,
    );
  }
}
