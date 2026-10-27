import '../money/fx_rate.dart';
import 'account.dart';
import 'posting.dart';

/// 账本数学：守恒校验与余额计算。
class LedgerMath {
  LedgerMath._();

  /// 校验一组货币分录满足守恒：每个币种的分录之和为 0（借贷相等）。
  ///
  /// 数量账（持仓）不做单笔守恒：买入是单边 +q、卖出单边 −q，
  /// 其不变量在账户层面维护（累计净额 = 持仓数量；卖出超持仓由
  /// LedgerService.sellSchool 校验）。返回违例描述；通过返回 null。
  static String? checkConservation(Iterable<Posting> postings) {
    final moneyByCurrency = <String, BigInt>{};
    for (final p in postings) {
      if (p.isQuantity) continue;
      final key = p.currencyCode!;
      moneyByCurrency[key] = (moneyByCurrency[key] ?? BigInt.zero) + p.amountMinor!;
    }
    for (final e in moneyByCurrency.entries) {
      if (e.value != BigInt.zero) {
        return '币种 ${e.key} 分录合计 ${e.value} ≠ 0（借贷不相等）';
      }
    }
    return null;
  }

  /// 账户的带符号分录合计（借方为正）。
  static BigInt signedSum(Iterable<Posting> postings, String accountId) {
    var sum = BigInt.zero;
    for (final p in postings) {
      if (p.accountId == accountId && p.amountMinor != null) {
        sum += p.amountMinor!;
      }
    }
    return sum;
  }

  static Rational quantitySum(Iterable<Posting> postings, String accountId) {
    var sum = Rational.zero();
    for (final p in postings) {
      if (p.accountId == accountId && p.quantity != null) {
        sum = sum + p.quantity!;
      }
    }
    return sum;
  }

  /// 展示口径余额：资产/费用取借方净额；负债/权益/收入取贷方净额（正数=欠款/已挣）。
  static BigInt displayBalance(AccountType type, BigInt signedTotal) =>
      type == AccountType.asset || type == AccountType.expense ? signedTotal : -signedTotal;

  /// 该交易是否触及给定账户。
  static bool touches(Iterable<Posting> postings, String accountId) =>
      postings.any((p) => p.accountId == accountId);
}
