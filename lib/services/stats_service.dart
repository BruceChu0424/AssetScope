import '../data/repositories/accounts_repo.dart';
import '../data/repositories/ledger_repo.dart';
import '../data/repositories/meta_repo.dart';
import '../domain/ledger/account.dart';
import '../domain/ledger/ledger_math.dart';
import '../domain/ledger/transaction.dart';
import '../domain/money/fx_rate.dart';
import '../domain/reports/month_report.dart';
import '../domain/utils/dates.dart';
import '../domain/valuation/valuation.dart';

/// 单账户估值结果。
class AccountValuationItem {
  AccountValuationItem({
    required this.account,
    required this.valueBaseMinor,
    this.balanceMinor,
    this.valuationStale = false,
    this.valuationMissing = false,
  });

  final Account account;

  /// 本位币价值；估值缺失时为 0 且 [valuationMissing]=true。
  final BigInt valueBaseMinor;

  /// 账户币种余额（货币账户）。
  final BigInt? balanceMinor;
  final bool valuationStale;
  final bool valuationMissing;
}

/// 净资产构成。
class NetWorthBreakdown {
  NetWorthBreakdown({
    required this.asOf,
    required this.baseCurrencyCode,
    required this.items,
  });

  final DateTime asOf;
  final String baseCurrencyCode;
  final List<AccountValuationItem> items;

  BigInt get totalAssets => items
      .where((i) => i.account.type == AccountType.asset)
      .fold(BigInt.zero, (s, i) => s + i.valueBaseMinor);

  BigInt get totalLiabilities => items
      .where((i) => i.account.type == AccountType.liability)
      .fold(BigInt.zero, (s, i) => s + i.valueBaseMinor);

  BigInt get netWorth => totalAssets - totalLiabilities;

  int get missingValuations =>
      items.where((i) => i.valuationMissing).length;

  int get staleValuations => items.where((i) => i.valuationStale).length;
}

/// 月度统计与净资产归因服务。
class StatsService {
  StatsService(this._accounts, this._ledger, this._meta);

  final AccountsRepo _accounts;
  final LedgerRepo _ledger;
  final MetaRepo _meta;

  Future<String> baseCurrency() async =>
      await _meta.settingString('baseCurrency') ?? 'CNY';

  /// 某日的净资产构成（含估值新鲜度）。
  Future<NetWorthBreakdown> netWorthAt(DateTime date) async {
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final base = await baseCurrency();
    final accounts = await _accounts.all();
    final money = await _ledger.moneyBalancesAt(end);
    final qtys = await _ledger.quantityBalancesAt(end);
    final valuations = await _meta.valuations();
    final byAccount = <String, List<ValuationRecord>>{};
    for (final v in valuations) {
      byAccount.putIfAbsent(v.accountId, () => []).add(v);
    }

    Future<BigInt> toBase(BigInt minor, String ccy) async {
      if (ccy == base) return minor;
      final rate = await _meta.toBaseRate(ccy: ccy, base: base, onOrBefore: end);
      if (rate == null) return BigInt.zero; // 无汇率：计 0 并由缺口披露
      return (Rational.fromInt(minor) * rate.rate).rounded();
    }

    final items = <AccountValuationItem>[];
    for (final a in accounts) {
      if (a.archived || !a.includeInNetWorth) continue;
      switch (a.valuationMethod) {
        case ValuationMethod.ledger:
          final signed = money[a.id] ?? BigInt.zero;
          final bal = LedgerMath.displayBalance(a.type, signed);
          items.add(AccountValuationItem(
            account: a,
            valueBaseMinor: await toBase(bal, a.currencyCode),
            balanceMinor: bal,
          ));
        case ValuationMethod.manualValue:
          final r = ValuationResolver.resolve(byAccount[a.id] ?? const [], end);
          if (r.missing) {
            items.add(AccountValuationItem(
                account: a, valueBaseMinor: BigInt.zero, valuationMissing: true));
          } else {
            items.add(AccountValuationItem(
              account: a,
              valueBaseMinor:
                  await toBase(r.record!.totalValueMinor ?? BigInt.zero, a.currencyCode),
              valuationStale: r.isStale,
            ));
          }
        case ValuationMethod.marketPrice:
          final qty = qtys[a.id] ?? Rational.zero();
          final r = ValuationResolver.resolve(byAccount[a.id] ?? const [], end);
          if (qty.isZero) continue; // 空仓不列示
          if (r.missing) {
            items.add(AccountValuationItem(
                account: a, valueBaseMinor: BigInt.zero, valuationMissing: true));
          } else {
            final price = r.record!.unitPrice ?? Rational.zero();
            final ccyValue = (qty * price).rounded();
            items.add(AccountValuationItem(
              account: a,
              valueBaseMinor: await toBase(ccyValue, a.currencyCode),
              valuationStale: r.isStale,
            ));
          }
      }
    }
    return NetWorthBreakdown(
        asOf: date, baseCurrencyCode: base, items: items);
  }

  /// 最近 [months] 个月的月末净资产序列（含本月至今）。
  Future<List<(String, BigInt)>> netWorthSeries(int months,
      {DateTime? now}) async {
    final n = now ?? DateTime.now();
    final out = <(String, BigInt)>[];
    for (var k = months - 1; k >= 0; k--) {
      var d = DateTime(n.year, n.month - k + 1, 0); // 上月末
      if (k == 0) d = n;
      final nw = await netWorthAt(d);
      out.add((monthKey(DateTime(n.year, n.month - k)), nw.netWorth));
    }
    return out;
  }

  /// 月报：归因 + 收支分类 + 债务还款 + 待核对。
  Future<MonthReport> monthReport(int year, int month) async {
    final base = await baseCurrency();
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);
    final prevEnd = DateTime(year, month, 0, 23, 59, 59);

    final nwStart = await netWorthAt(prevEnd);
    final nwEnd = await netWorthAt(monthEnd);
    final accounts = await _accounts.all();
    final byId = {for (final a in accounts) a.id: a};

    final sums = await _ledger.postingSumsBetween(monthStart, monthEnd);

    Future<BigInt> toBaseNow(BigInt minor, String ccy) async {
      if (ccy == base) return minor;
      final rate =
          await _meta.toBaseRate(ccy: ccy, base: base, onOrBefore: monthEnd);
      if (rate == null) return BigInt.zero;
      return (Rational.fromInt(minor) * rate.rate).rounded();
    }

    // 分类收支（排除系统账户）
    final expenseByCategory = <String, BigInt>{};
    final incomeByCategory = <String, BigInt>{};
    BigInt regularExpense = BigInt.zero;
    BigInt regularIncome = BigInt.zero;
    BigInt realizedPnl = BigInt.zero;
    BigInt dividend = BigInt.zero;
    BigInt fxSysLine = BigInt.zero;
    BigInt correction = BigInt.zero;
    for (final e in sums.entries) {
      final acc = byId[e.key];
      if (acc == null) continue;
      final v = await toBaseNow(e.value, acc.currencyCode);
      switch (acc.type) {
        case AccountType.expense:
          if (acc.id == Account.sysExpenseFx || acc.id == Account.sysExpenseRounding) {
            // 汇兑/尾差单独归因：−Σpostings
            fxSysLine -= v;
          } else if (!acc.isSystem) {
            expenseByCategory[e.key] = (expenseByCategory[e.key] ?? BigInt.zero) + v;
            regularExpense += v;
          }
        case AccountType.income:
          if (acc.id == Account.sysIncomeRealizedPnl) {
            realizedPnl -= v;
          } else if (acc.id == Account.sysIncomeDividend) {
            dividend -= v;
          } else if (!acc.isSystem) {
            incomeByCategory[e.key] = (incomeByCategory[e.key] ?? BigInt.zero) + v;
            regularIncome -= v;
          }
        case AccountType.equity:
          correction -= v;
        default:
          break;
      }
    }

    // 未实现损益 U = 市值 − 成本
    Future<BigInt> unrealizedAt(DateTime t) async {
      final end = DateTime(t.year, t.month, t.day, 23, 59, 59);
      final money = await _ledger.moneyBalancesAt(end);
      final qtys = await _ledger.quantityBalancesAt(end);
      final valuations = await _meta.valuations();
      final byAcc = <String, List<ValuationRecord>>{};
      for (final v in valuations) {
        byAcc.putIfAbsent(v.accountId, () => []).add(v);
      }
      var total = BigInt.zero;
      for (final a in accounts) {
        if (!a.isHolding || a.costBasisAccountId == null) continue;
        final qty = qtys[a.id] ?? Rational.zero();
        if (qty.isZero) continue;
        final r = ValuationResolver.resolve(byAcc[a.id] ?? const [], end);
        final price = r.record?.unitPrice;
        if (price == null) continue; // 缺估值：不计入（披露在缺口）
        final mv = (qty * price).rounded();
        final cb = money[a.costBasisAccountId!] ?? BigInt.zero;
        final u = mv - cb;
        if (a.currencyCode == base) {
          total += u;
        } else {
          final rate = await _meta.toBaseRate(
              ccy: a.currencyCode, base: base, onOrBefore: end);
          total += rate == null ? BigInt.zero : (Rational.fromInt(u) * rate.rate).rounded();
        }
      }
      return total;
    }

    final uStart = await unrealizedAt(prevEnd);
    final uEnd = await unrealizedAt(monthEnd);

    // 汇率重估影响：期初外币头寸 × 汇率变动 + 换汇损益行
    final foreignAccounts = <ForeignBalanceStart>[];
    final foreignHoldings = <ForeignHoldingStart>[];
    final moneyStart = await _ledger.moneyBalancesAt(prevEnd);
    final qtyStart = await _ledger.quantityBalancesAt(prevEnd);
    for (final a in accounts) {
      if (a.currencyCode == base || a.archived || !a.includeInNetWorth) continue;
      final fxS = await _meta.toBaseRate(ccy: a.currencyCode, base: base, onOrBefore: prevEnd);
      final fxE = await _meta.toBaseRate(ccy: a.currencyCode, base: base, onOrBefore: monthEnd);
      if (fxS == null || fxE == null) continue;
      if (a.isHolding && a.costBasisAccountId != null) {
        final r = await _meta.valuations(accountId: a.id);
        final price = ValuationResolver.resolve(r, monthEnd).record?.unitPrice;
        if (price == null) continue;
        foreignHoldings.add(ForeignHoldingStart(
          accountId: a.id,
          qtyStart: qtyStart[a.id] ?? Rational.zero(),
          priceEnd: price,
          fxStart: fxS.rate,
          fxEnd: fxE.rate,
        ));
      } else if (a.type == AccountType.asset || a.type == AccountType.liability) {
        final sign = a.type == AccountType.asset ? BigInt.one : -BigInt.one;
        foreignAccounts.add(ForeignBalanceStart(
          accountId: a.id,
          balanceStartMinor: (moneyStart[a.id] ?? BigInt.zero) * sign,
          fxStart: fxS.rate,
          fxEnd: fxE.rate,
        ));
      }
    }
    final fxReval = fxEffectMinor(
        foreignAccounts: foreignAccounts, foreignHoldings: foreignHoldings);

    // 手工估值变动
    BigInt otherValuation = BigInt.zero;
    for (final a in accounts) {
      if (a.valuationMethod != ValuationMethod.manualValue ||
          a.archived ||
          !a.includeInNetWorth) {
        continue;
      }
      final vs = await _meta.valuations(accountId: a.id);
      final s = ValuationResolver.resolve(vs, prevEnd).record?.totalValueMinor;
      final e = ValuationResolver.resolve(vs, monthEnd).record?.totalValueMinor;
      if (s != null && e != null) {
        otherValuation += await toBaseNow(e - s, a.currencyCode);
      }
    }

    final attribution = MonthAttributor.compute(AttributionInput(
      nwStartBaseMinor: nwStart.netWorth,
      nwEndBaseMinor: nwEnd.netWorth,
      regularIncomeMinor: regularIncome,
      regularExpenseMinor: regularExpense,
      realizedPnlMinor: realizedPnl,
      dividendMinor: dividend,
      unrealizedStartMinor: uStart,
      unrealizedEndMinor: uEnd,
      fxEffectMinor: fxReval + fxSysLine,
      otherValuationChangeMinor: otherValuation,
      correctionMinor: correction,
    ));

    // 债务还款拆分（本金/利息）
    var principalRepaid = BigInt.zero;
    var interestPaid = BigInt.zero;
    final txs = await _ledger.list(from: monthStart, to: monthEnd);
    for (final tx in txs) {
      if (tx.kind != TxKind.loanRepay && tx.kind != TxKind.creditCardRepay) continue;
      for (final p in tx.postings) {
        final acc = byId[p.accountId];
        if (acc == null || p.amountMinor == null) continue;
        if (acc.type == AccountType.liability) {
          principalRepaid += p.amountMinor!;
        } else if (acc.type == AccountType.expense) {
          interestPaid += p.amountMinor!;
        }
      }
    }

    return MonthReport(
      year: year,
      month: month,
      baseCurrencyCode: base,
      attribution: attribution,
      incomeByCategory: incomeByCategory,
      expenseByCategory: expenseByCategory,
      debtPrincipalRepaidMinor: principalRepaid,
      debtInterestPaidMinor: interestPaid,
      nwStartBreakdown: nwStart,
      nwEndBreakdown: nwEnd,
    );
  }
}

/// 月报聚合结果。
class MonthReport {
  MonthReport({
    required this.year,
    required this.month,
    required this.baseCurrencyCode,
    required this.attribution,
    required this.incomeByCategory,
    required this.expenseByCategory,
    required this.debtPrincipalRepaidMinor,
    required this.debtInterestPaidMinor,
    required this.nwStartBreakdown,
    required this.nwEndBreakdown,
  });

  final int year;
  final int month;
  final String baseCurrencyCode;
  final MonthAttribution attribution;
  final Map<String, BigInt> incomeByCategory;
  final Map<String, BigInt> expenseByCategory;
  final BigInt debtPrincipalRepaidMinor;
  final BigInt debtInterestPaidMinor;
  final NetWorthBreakdown nwStartBreakdown;
  final NetWorthBreakdown nwEndBreakdown;
}
