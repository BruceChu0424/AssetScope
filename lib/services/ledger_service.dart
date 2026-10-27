import '../data/repositories/accounts_repo.dart';
import '../data/repositories/ledger_repo.dart';
import '../domain/ledger/account.dart';
import '../domain/ledger/transaction.dart';
import '../domain/money/fx_rate.dart';

/// 账务服务：面向用例的交易录入入口。
/// 所有过账都经 [TxBuilders] 构造分录，禁止手写 Posting。
class LedgerService {
  LedgerService(this.accounts, this.ledger);

  final AccountsRepo accounts;
  final LedgerRepo ledger;

  Future<LedgerTransaction> post(TransactionDraft draft) =>
      ledger.post(draft);

  Future<void> voidTx(String id) => ledger.voidTransaction(id);

  /// 卖出：按平均成本法自动计算应结转的成本与已实现损益。
  Future<LedgerTransaction> sellSecurity({
    required String holdingAccountId,
    required String cashAccountId,
    required Rational quantitySold,
    required BigInt netProceedsMinor,
    required DateTime date,
    String? note,
  }) async {
    final holding = await accounts.byId(holdingAccountId);
    if (holding == null || !holding.isHolding) {
      throw ArgumentError('持仓账户不存在: $holdingAccountId');
    }
    final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final cbBalance = (await ledger.moneyBalancesAt(dateEnd,
            accountIds: {holding.costBasisAccountId!}))[holding.costBasisAccountId!] ??
        BigInt.zero;
    final qtyBalance = (await ledger.quantityBalancesAt(dateEnd))[holdingAccountId] ??
        Rational.zero();
    if (qtyBalance.isZero || qtyBalance.isNegative) {
      throw StateError('持仓数量异常: $qtyBalance');
    }
    if (quantitySold > qtyBalance) {
      throw ArgumentError('卖出数量 $quantitySold 超过持仓 $qtyBalance');
    }
    // 平均成本 × 卖出数量（有理数精确，再舍入到最小单位）。
    final costRemoved =
        (Rational.fromInt(cbBalance) * quantitySold / qtyBalance).rounded();
    return ledger.post(TxBuilders.sell(
      holdingAccount: holding,
      cashAccount: (await _requireAccount(cashAccountId, AccountType.asset))!,
      quantitySold: quantitySold,
      netProceedsMinor: netProceedsMinor,
      costBasisRemovedMinor: costRemoved,
      date: date,
      note: note,
    ));
  }

  /// 买入（简化入口：金额与数量直接给出）。
  Future<LedgerTransaction> buySecurity({
    required String holdingAccountId,
    required String cashAccountId,
    required Rational quantity,
    required BigInt totalPaidMinor,
    required DateTime date,
    String? note,
  }) async {
    final holding = await accounts.byId(holdingAccountId);
    if (holding == null || !holding.isHolding) {
      throw ArgumentError('持仓账户不存在: $holdingAccountId');
    }
    return ledger.post(TxBuilders.buy(
      holdingAccount: holding,
      cashAccount: (await _requireAccount(cashAccountId, AccountType.asset))!,
      quantity: quantity,
      totalPaidMinor: totalPaidMinor,
      date: date,
      note: note,
    ));
  }

  Future<Account?> _requireAccount(String id, AccountType type) async {
    final a = await accounts.byId(id);
    if (a == null) throw ArgumentError('账户不存在: $id');
    return a;
  }
}
