import '../money/currency.dart';
import '../money/fx_rate.dart';
import '../money/money.dart';

/// 分录（过账）。签名约定：**正数 = 借方，负数 = 贷方**。
///
/// - 资产/费用账户：借方增加余额；
/// - 负债/权益/收入账户：贷方增加余额。
/// - 任一交易的所有货币分录按币种分组求和必须为 0（借贷必相等）；
///   数量分录按证券分组求和必须为 0。
///
/// 一条分录要么是货币分录（[amountMinor] + [currencyCode]），
/// 要么是数量分录（[securityId] + [quantity]）。
class Posting {
  const Posting.money({
    required this.accountId,
    required this.amountMinor,
    required this.currencyCode,
    this.memo,
  }) : securityId = null,
       quantity = null;

  const Posting.quantity({
    required this.accountId,
    required this.securityId,
    required this.quantity,
    this.memo,
  }) : amountMinor = null,
       currencyCode = null;

  final String accountId;

  /// 带符号最小单位金额；数量分录为 null。
  final BigInt? amountMinor;
  final String? currencyCode;

  /// 持仓数量（有符号）；货币分录为 null。
  final String? securityId;
  final Rational? quantity;
  final String? memo;

  bool get isQuantity => securityId != null;

  Posting negate() => isQuantity
      ? Posting.quantity(
          accountId: accountId,
          securityId: securityId!,
          quantity: -quantity!,
          memo: memo,
        )
      : Posting.money(
          accountId: accountId,
          amountMinor: -amountMinor!,
          currencyCode: currencyCode!,
          memo: memo,
        );

  /// 便于阅读的描述。
  String describe(Map<String, String> accountNames) {
    final side = (amountMinor ?? BigInt.zero).isNegative ? '贷' : '借';
    final name = accountNames[accountId] ?? accountId;
    if (isQuantity) {
      return '$side $name ${quantity!.n}/${quantity!.d} ($securityId)';
    }
    final m = Money.fromMinor(
      amountMinor!.abs(),
      CurrencyInfo.parse(currencyCode!),
    );
    return '$side $name ${m.format()}';
  }
}
