import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/domain/ledger/account.dart';
import 'package:assetscope/domain/ledger/ledger_math.dart';
import 'package:assetscope/domain/ledger/transaction.dart';
import 'package:assetscope/domain/money/fx_rate.dart';

/// 核心账务口径验收：每个用例对应《验收清单》的一条硬性规则。
void main() {
  final d = DateTime(2026, 5, 10);

  final bank = Account(
      id: 'bank', name: '招行', type: AccountType.asset, assetSubtype: AssetSubtype.bank, currencyCode: 'CNY');
  final alipay = Account(
      id: 'alipay', name: '支付宝', type: AccountType.asset, assetSubtype: AssetSubtype.alipay, currencyCode: 'CNY');
  final card = Account(
      id: 'card',
      name: '信用卡',
      type: AccountType.liability,
      liabilitySubtype: LiabilitySubtype.creditCard,
      currencyCode: 'CNY');
  final loan = Account(
      id: 'loan',
      name: '房贷',
      type: AccountType.liability,
      liabilitySubtype: LiabilitySubtype.mortgage,
      currencyCode: 'CNY');
  final receivable = Account(
      id: 'recv',
      name: '借出款',
      type: AccountType.asset,
      assetSubtype: AssetSubtype.receivable,
      currencyCode: 'CNY');
  final dining = Account(
      id: 'cat:e:dining', name: '餐饮', type: AccountType.expense, currencyCode: 'CNY');
  final interest = Account(
      id: 'cat:e:interest', name: '利息', type: AccountType.expense, currencyCode: 'CNY');
  final salary = Account(
      id: 'cat:i:salary', name: '工资', type: AccountType.income, currencyCode: 'CNY');
  final holding = Account(
      id: 'hold',
      name: '510300',
      type: AccountType.asset,
      assetSubtype: AssetSubtype.fund,
      currencyCode: 'CNY',
      costBasisAccountId: 'sys:cost:510300',
      securityId: 'sec:510300');

  BigInt sum(List<dynamic> postings, Object accountId) =>
      LedgerMath.signedSum(postings.cast(),
          accountId is Account ? accountId.id : accountId.toString());

  test('所有构造器生成的分录满足守恒', () {
    final drafts = [
      TxBuilders.openingBalance(assetAccount: bank, amountMinor: BigInt.from(1000000), date: d),
      TxBuilders.income(
          destAsset: bank, incomeCategory: salary, amountMinor: BigInt.from(50000), date: d),
      TxBuilders.expense(
          payFrom: alipay, expenseCategory: dining, amountMinor: BigInt.from(3500), date: d),
      TxBuilders.expense(
          payFrom: card, expenseCategory: dining, amountMinor: BigInt.from(1200), date: d),
      TxBuilders.transfer(
          from: alipay, to: bank, amountMinor: BigInt.from(20000), date: d),
      TxBuilders.creditCardRepay(
          card: card, payFrom: bank, amountMinor: BigInt.from(1200), date: d),
      TxBuilders.borrow(
          loan: loan, toAsset: bank, principalMinor: BigInt.from(800000), date: d),
      TxBuilders.loanRepay(
          loan: loan,
          payFrom: bank,
          principalMinor: BigInt.from(1000),
          interestMinor: BigInt.from(2560),
          interestCategory: interest,
          date: d),
      TxBuilders.lend(
          receivable: receivable, fromAsset: bank, amountMinor: BigInt.from(50000), date: d),
      TxBuilders.receiveBack(
          receivable: receivable, toAsset: bank, amountMinor: BigInt.from(20000), date: d),
      TxBuilders.buy(
          holdingAccount: holding,
          cashAccount: bank,
          quantity: Rational.one,
          totalPaidMinor: BigInt.from(10003),
          date: d),
      TxBuilders.sell(
          holdingAccount: holding,
          cashAccount: bank,
          quantitySold: Rational.one,
          netProceedsMinor: BigInt.from(11000),
          costBasisRemovedMinor: BigInt.from(10003),
          date: d),
      TxBuilders.dividend(cashAccount: bank, amountMinor: BigInt.from(500), date: d),
      TxBuilders.fxConversion(
          from: bank,
          to: Account(
              id: 'usdacc',
              name: '美元卡',
              type: AccountType.asset,
              assetSubtype: AssetSubtype.bank,
              currencyCode: 'USD'),
          fromAmountMinor: BigInt.from(72000),
          toAmountMinor: BigInt.from(10000),
          date: d),
    ];
    for (final draft in drafts) {
      expect(LedgerMath.checkConservation(draft.postings), isNull,
          reason: '${draft.kind} 分录不守恒');
    }
  });

  test('转账不影响收支，也不改变净资产', () {
    final t = TxBuilders.transfer(
        from: alipay, to: bank, amountMinor: BigInt.from(20000), date: d);
    final expenseAccounts = t.postings
        .where((p) => p.accountId.startsWith('cat:e:'))
        .toList();
    final incomeAccounts = t.postings
        .where((p) => p.accountId.startsWith('cat:i:'))
        .toList();
    expect(expenseAccounts, isEmpty);
    expect(incomeAccounts, isEmpty);
    expect(sum(t.postings, alipay), -BigInt.from(20000));
    expect(sum(t.postings, bank), BigInt.from(20000));
  });

  test('信用卡消费即确认消费并增加负债；还款不再确认消费', () {
    final consume = TxBuilders.expense(
        payFrom: card, expenseCategory: dining, amountMinor: BigInt.from(1200), date: d);
    expect(sum(consume.postings, dining), BigInt.from(1200));
    expect(sum(consume.postings, card), -BigInt.from(1200)); // 负债 +

    final repay = TxBuilders.creditCardRepay(
        card: card, payFrom: bank, amountMinor: BigInt.from(1200), date: d);
    // 还款不触碰任何收支科目
    expect(repay.postings.any((p) => p.accountId.startsWith('cat:')), isFalse);
    expect(sum(repay.postings, card), BigInt.from(1200)); // 负债 −
    expect(sum(repay.postings, bank), -BigInt.from(1200));

    // 两个月合计：消费只计一次
    final all = [...consume.postings, ...repay.postings];
    expect(sum(all, dining), BigInt.from(1200));
  });

  test('借款到账不是收入；还本拆分正确', () {
    final borrow = TxBuilders.borrow(
        loan: loan, toAsset: bank, principalMinor: BigInt.from(800000), date: d);
    expect(borrow.postings.any((p) => p.accountId.startsWith('cat:i:')), isFalse);
    expect(sum(borrow.postings, bank), BigInt.from(800000));
    expect(sum(borrow.postings, loan), -BigInt.from(800000));

    final repay = TxBuilders.loanRepay(
        loan: loan,
        payFrom: bank,
        principalMinor: BigInt.from(2000),
        interestMinor: BigInt.from(2560),
        interestCategory: interest,
        date: d);
    expect(sum(repay.postings, loan), BigInt.from(2000)); // 本金
    expect(sum(repay.postings, interest), BigInt.from(2560)); // 利息
    expect(sum(repay.postings, bank), -BigInt.from(4560)); // 现金流出=本+息
  });

  test('借出款挂应收不是消费；收回冲减应收不是收入', () {
    final lend = TxBuilders.lend(
        receivable: receivable, fromAsset: bank, amountMinor: BigInt.from(50000), date: d);
    expect(lend.postings.any((p) => p.accountId.startsWith('cat:')), isFalse);
    expect(sum(lend.postings, receivable), BigInt.from(50000));

    final back = TxBuilders.receiveBack(
        receivable: receivable, toAsset: bank, amountMinor: BigInt.from(20000), date: d);
    expect(back.postings.any((p) => p.accountId.startsWith('cat:')), isFalse);
    expect(sum(back.postings, receivable), -BigInt.from(20000));
  });

  test('期初余额走权益，不进当月收支（补录旧资产不算新赚）', () {
    final t = TxBuilders.openingBalance(
        assetAccount: bank, amountMinor: BigInt.from(1000000), date: DateTime(2024, 1, 1));
    expect(t.isAdjustment, isTrue);
    expect(t.postings.any((p) => p.accountId.startsWith('cat:')), isFalse);
    expect(sum(t.postings, Account.sysEquityOpening), -BigInt.from(1000000));
  });

  test('买入卖出：成本资本化，已实现损益单独确认', () {
    final buy = TxBuilders.buy(
        holdingAccount: holding,
        cashAccount: bank,
        quantity: Rational.one,
        totalPaidMinor: BigInt.from(10003),
        date: d);
    // 买入不进收支科目
    expect(buy.postings.any((p) => p.accountId.startsWith('cat:')), isFalse);
    expect(sum(buy.postings, 'sys:cost:510300'), BigInt.from(10003));
    final qty = LedgerMath.quantitySum(buy.postings, holding.id);
    expect(qty, Rational.one);

    final sell = TxBuilders.sell(
        holdingAccount: holding,
        cashAccount: bank,
        quantitySold: Rational.one,
        netProceedsMinor: BigInt.from(11000),
        costBasisRemovedMinor: BigInt.from(10003),
        date: d);
    // 已实现收益 = 11000 − 10003 = 997，贷方计入系统收益账户
    expect(sum(sell.postings, Account.sysIncomeRealizedPnl),
        -BigInt.from(997));
    expect(LedgerMath.quantitySum(sell.postings, holding.id), -Rational.one);
  });

  test('构造器参数校验拒绝非法操作', () {
    expect(
        () => TxBuilders.transfer(
            from: bank,
            to: card, // 负债不能作为转账对象
            amountMinor: BigInt.one,
            date: d),
        throwsArgumentError);
    expect(
        () => TxBuilders.expense(
            payFrom: salary, // 收入分类不能支付
            expenseCategory: dining,
            amountMinor: BigInt.one,
            date: d),
        throwsArgumentError);
  });
}


