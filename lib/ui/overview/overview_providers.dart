import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/budget/budget.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../../domain/utils/dates.dart';
import '../../services/stats_service.dart';

/// 沉浸式详情页数据层 · 其一。
///
/// 口径纪律（docs/16 数据一致性）：所有页面共享 [dashboardProvider] 的
/// 同一份聚合（净资产/月报/预测/序列），页面专属的深加工（日现金流、
/// 资产负债序列、情景重放、任务清单）在此独立成 provider，但全部走
/// 同一批服务与同一套指纹缓存——同一数字在任何页面都相同。

// ─────────────────────────────────────────────────────────────────────────
// 本月收支 · 日现金流与分类
// ─────────────────────────────────────────────────────────────────────────

/// 单日现金流（本位币最小单位，正数）。
class OvDailyCell {
  const OvDailyCell({
    required this.date,
    required this.income,
    required this.expense,
  });

  final DateTime date;
  final BigInt income;
  final BigInt expense;

  BigInt get net => income - expense;
}

/// 近期交易行（页面展示形态；tx 供详情弹层复用）。
class OvRecentTx {
  const OvRecentTx({
    required this.id,
    required this.date,
    required this.title,
    required this.amount,
    required this.income,
    required this.tx,
  });

  final String id;
  final DateTime date;
  final String title;

  /// 正数展示额（收入/支出绝对值）。
  final BigInt amount;
  final bool income;

  /// 原始交易（点击进详情弹层用）。
  final LedgerTransaction tx;
}

class OvCashFlowData {
  OvCashFlowData({
    required this.report,
    required this.prevReport,
    required this.daily,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.recent,
    required this.totalBudgetMinor,
  });

  final MonthReport report;
  final MonthReport? prevReport;

  /// 当月逐日（含空日，1 日至月末连续）。
  final List<OvDailyCell> daily;

  /// (分类名, 金额) 降序。
  final List<(String, BigInt)> expenseCategories;
  final List<(String, BigInt)> incomeCategories;
  final List<OvRecentTx> recent;

  /// 当月生效总预算额度（无则 0）。
  final BigInt totalBudgetMinor;

  BigInt get income =>
      report.incomeByCategory.values.fold(BigInt.zero, (a, b) => a + b);
  BigInt get expense =>
      report.expenseByCategory.values.fold(BigInt.zero, (a, b) => a + b);
  BigInt get surplus => income - expense;
  String get base => report.baseCurrencyCode;
}

/// 日现金流：月报口径的逐日展开（只计常规收支科目，排除系统科目与
/// 转账/投资买卖——与 [MonthReport] 完全同源）。
final cashFlowDetailProvider = FutureProvider.autoDispose
    .family<OvCashFlowData, (int, int)>((ref, ym) async {
      final s = sessionOf(ref.watch(vaultProvider));
      if (s == null) throw StateError('locked');
      final (year, month) = ym;
      final report = await s.statsService.monthReport(year, month);
      final prev = month > 1
          ? await s.statsService.monthReport(year, month - 1)
          : await s.statsService.monthReport(year - 1, 12);

      final accounts = await s.accounts.all();
      final byId = {for (final a in accounts) a.id: a};
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);
      final txs = await s.ledger.list(from: monthStart, to: monthEnd);

      final daysInMonth = DateTime(year, month + 1, 0).day;
      final incByDay = List<BigInt>.filled(daysInMonth, BigInt.zero);
      final expByDay = List<BigInt>.filled(daysInMonth, BigInt.zero);
      final recent = <OvRecentTx>[];
      for (final tx in txs) {
        if (tx.status == TxStatus.voided) continue;
        var inc = BigInt.zero;
        var exp = BigInt.zero;
        for (final p in tx.postings) {
          final amt = p.amountMinor;
          if (amt == null) continue;
          final acc = byId[p.accountId];
          if (acc == null || acc.isSystem) continue;
          if (acc.type == AccountType.income && amt.isNegative) {
            inc += -amt;
          } else if (acc.type == AccountType.expense && !amt.isNegative) {
            exp += amt;
          }
        }
        if (inc == BigInt.zero && exp == BigInt.zero) continue;
        final day = tx.date.day - 1;
        incByDay[day] += inc;
        expByDay[day] += exp;
        recent.add(
          OvRecentTx(
            id: tx.id,
            date: tx.date,
            title:
                (tx.counterparty?.trim().isNotEmpty == true
                    ? tx.counterparty!.trim()
                    : tx.note?.trim()) ??
                '',
            amount: inc > exp ? inc : exp,
            income: inc > exp,
            tx: tx,
          ),
        );
      }
      final daily = <OvDailyCell>[
        for (var d = 0; d < daysInMonth; d++)
          OvDailyCell(
            date: DateTime(year, month, d + 1),
            income: incByDay[d],
            expense: expByDay[d],
          ),
      ];

      List<(String, BigInt)> named(Map<String, BigInt> byCat) {
        final out = [
          for (final e in byCat.entries)
            (byId[e.key]?.name ?? e.key, e.value),
        ]..sort((a, b) => b.$2.compareTo(a.$2));
        return out;
      }

      var budgetTotal = BigInt.zero;
      for (final b in await s.planning.budgets()) {
        // 展示口径：总预算（category 级预算在预算页有完整信封）。
        if (b.scope == BudgetScope.total &&
            b.coversMonth(monthKey(DateTime(year, month)))) {
          budgetTotal = b.limitMinor;
          break;
        }
      }

      return OvCashFlowData(
        report: report,
        prevReport: prev,
        daily: daily,
        expenseCategories: named(report.expenseByCategory),
        incomeCategories: named(report.incomeByCategory),
        recent: recent.reversed.take(8).toList(),
        totalBudgetMinor: budgetTotal,
      );
    });

// ─────────────────────────────────────────────────────────────────────────
// 资产负债双序列
// ─────────────────────────────────────────────────────────────────────────

class OvBalancePoint {
  const OvBalancePoint(this.monthKey, this.assets, this.liabilities);

  final String monthKey;
  final BigInt assets;
  final BigInt liabilities;

  BigInt get net => assets - liabilities;
}

/// 近 [months] 个月月末的总资产/总负债序列（逐点走 netWorthAt 缓存，
/// 与首页走势同锚点）。
final balanceSeriesProvider = FutureProvider.autoDispose
    .family<List<OvBalancePoint>, int>((ref, months) async {
      final s = sessionOf(ref.watch(vaultProvider));
      if (s == null) throw StateError('locked');
      final n = DateTime.now();
      final out = <OvBalancePoint>[];
      for (var k = months - 1; k >= 0; k--) {
        var d = DateTime(n.year, n.month - k + 1, 0, 23, 59, 59); // 月末
        if (k == 0) d = n;
        final nw = await s.statsService.netWorthAt(d);
        out.add(
          OvBalancePoint(monthKey(DateTime(n.year, n.month - k)), nw.totalAssets, nw.totalLiabilities),
        );
      }
      return out;
    });
