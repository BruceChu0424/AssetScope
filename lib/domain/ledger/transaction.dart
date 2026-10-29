import '../money/fx_rate.dart';
import 'account.dart';
import 'posting.dart';

/// 交易种类。每种类的分录构造规则见 [TxBuilders]，
/// 这些规则直接对应《账务口径》文档中的事件表，禁止绕过构造器手写分录。
enum TxKind {
  openingBalance('期初余额'),
  income('收入'),
  expense('消费'),
  refund('退款'),
  transfer('转账'),
  fxConversion('换汇'),
  creditCardRepay('信用卡还款'),
  borrow('借入'),
  loanRepay('贷款还款'),
  lend('借出'),
  receiveBack('收回借出'),
  buy('买入证券'),
  sell('卖出证券'),
  dividend('分红派息'),
  adjustment('对账调整');

  const TxKind(this.labelZh);
  final String labelZh;

  /// 是否属于“消费发生”（占用预算）。
  bool get occupiesBudget => this == expense;

  /// 是否为历史修正类（不计入当期收支，净资产归因单列）。
  bool get isAdjustmentKind => this == openingBalance || this == adjustment;
}

enum TxStatus { pending, posted, voided }

enum TxSource {
  manual('手动'),
  importAlipay('支付宝导入'),
  importWechat('微信导入'),
  importBank('银行账单导入'),
  importCsv('CSV 导入'),
  planGenerated('计划生成');

  const TxSource(this.labelZh);
  final String labelZh;
}

/// 交易草稿：由构造器生成，经守恒校验后过账。
class TransactionDraft {
  const TransactionDraft({
    required this.date,
    required this.kind,
    required this.postings,
    this.status = TxStatus.posted,
    this.note,
    this.counterparty,
    this.categoryId,
    this.tags = const [],
    this.externalId,
    this.source = TxSource.manual,
    this.importBatchId,
    this.isAdjustment = false,
  });

  final DateTime date;
  final TxKind kind;
  final TxStatus status;
  final List<Posting> postings;
  final String? note;
  final String? counterparty;

  /// 业务分类（指向 income/expense 类账户 id）。
  final String? categoryId;
  final List<String> tags;
  final String? externalId;
  final TxSource source;
  final String? importBatchId;
  final bool isAdjustment;
}

/// 已入账交易（含数据库标识）。
class LedgerTransaction {
  const LedgerTransaction({
    required this.id,
    required this.date,
    required this.kind,
    required this.status,
    required this.postings,
    this.note,
    this.counterparty,
    this.categoryId,
    this.tags = const [],
    this.externalId,
    this.source = TxSource.manual,
    this.importBatchId,
    this.isAdjustment = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final DateTime date;
  final TxKind kind;
  final TxStatus status;
  final List<Posting> postings;
  final String? note;
  final String? counterparty;
  final String? categoryId;
  final List<String> tags;
  final String? externalId;
  final TxSource source;
  final String? importBatchId;
  final bool isAdjustment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LedgerTransaction copyWith({
    TxStatus? status,
    String? note,
    List<Posting>? postings,
    String? categoryId,
  }) =>
      LedgerTransaction(
        id: id,
        date: date,
        kind: kind,
        status: status ?? this.status,
        note: note ?? this.note,
        postings: postings ?? this.postings,
        categoryId: categoryId ?? this.categoryId,
        tags: tags,
        externalId: externalId,
        source: source,
        importBatchId: importBatchId,
        isAdjustment: isAdjustment,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}

/// 各交易种类的分录构造器 —— 账务口径的唯一实现点。
///
/// 关键规则（与 docs/05-账务口径与算法.md 一一对应）：
/// - 借款到账：现金与负债同增，不是收入；
/// - 信用卡消费即确认消费并增加负债；还款只是现金与负债同减，不再确认消费；
/// - 贷款月供拆分本金/利息/费用；
/// - 买入/卖出证券不动用收支科目，损益在卖出时经“已实现投资损益”确认；
/// - 借出款挂应收资产，收回冲减应收，双方都不是收支。
class TxBuilders {
  TxBuilders._();

  /// 期初余额：补录早已拥有的资产。属于历史修正，不算当月收入。
  static TransactionDraft openingBalance({
    required Account assetAccount,
    required BigInt amountMinor,
    required DateTime date,
    String? note,
  }) {
    _require(assetAccount.type == AccountType.asset, '期初余额只能作用于资产账户');
    _requirePositive(amountMinor);
    return TransactionDraft(
      date: date,
      kind: TxKind.openingBalance,
      isAdjustment: true,
      note: note ?? '期初余额',
      postings: [
        Posting.money(
            accountId: assetAccount.id, amountMinor: amountMinor, currencyCode: assetAccount.currencyCode),
        Posting.money(
            accountId: Account.sysEquityOpening,
            amountMinor: -amountMinor,
            currencyCode: assetAccount.currencyCode),
      ],
    );
  }

  /// 收入。
  static TransactionDraft income({
    required Account destAsset,
    required Account incomeCategory,
    required BigInt amountMinor,
    required DateTime date,
    String? counterparty,
    String? note,
    List<String> tags = const [],
    TxSource source = TxSource.manual,
    String? externalId,
    String? importBatchId,
  }) {
    _require(destAsset.type == AccountType.asset, '收入必须进入资产账户');
    _require(incomeCategory.type == AccountType.income, '收入分类账户类型错误');
    _requirePositive(amountMinor);
    final c = destAsset.currencyCode;
    return TransactionDraft(
      date: date,
      kind: TxKind.income,
      counterparty: counterparty,
      categoryId: incomeCategory.id,
      note: note,
      tags: tags,
      source: source,
      externalId: externalId,
      importBatchId: importBatchId,
      postings: [
        Posting.money(accountId: destAsset.id, amountMinor: amountMinor, currencyCode: c),
        Posting.money(accountId: incomeCategory.id, amountMinor: -amountMinor, currencyCode: c),
      ],
    );
  }

  /// 消费。[payFrom] 可以是资产（现金/余额）或负债（信用卡/花呗）。
  static TransactionDraft expense({
    required Account payFrom,
    required Account expenseCategory,
    required BigInt amountMinor,
    required DateTime date,
    String? counterparty,
    String? note,
    List<String> tags = const [],
    TxSource source = TxSource.manual,
    String? externalId,
    String? importBatchId,
  }) {
    _require(payFrom.type == AccountType.asset || payFrom.type == AccountType.liability,
        '消费必须从资产或负债（信用卡）账户支付');
    _require(expenseCategory.type == AccountType.expense, '支出分类账户类型错误');
    _requirePositive(amountMinor);
    final c = payFrom.currencyCode;
    return TransactionDraft(
      date: date,
      kind: TxKind.expense,
      counterparty: counterparty,
      categoryId: expenseCategory.id,
      note: note,
      tags: tags,
      source: source,
      externalId: externalId,
      importBatchId: importBatchId,
      postings: [
        Posting.money(accountId: expenseCategory.id, amountMinor: amountMinor, currencyCode: c),
        Posting.money(accountId: payFrom.id, amountMinor: -amountMinor, currencyCode: c),
      ],
    );
  }

  /// 退款：冲减原支出分类，可部分、可多次、可退到其他账户。
  static TransactionDraft refund({
    required Account backTo,
    required Account originalExpenseCategory,
    required BigInt amountMinor,
    required DateTime date,
    String? note,
    String? originalExternalId,
  }) {
    _requirePositive(amountMinor);
    final c = backTo.currencyCode;
    return TransactionDraft(
      date: date,
      kind: TxKind.refund,
      categoryId: originalExpenseCategory.id,
      note: note,
      externalId: originalExternalId,
      postings: [
        Posting.money(accountId: backTo.id, amountMinor: amountMinor, currencyCode: c),
        Posting.money(accountId: originalExpenseCategory.id, amountMinor: -amountMinor, currencyCode: c),
      ],
    );
  }

  /// 同币种本人账户间转账：整体收支为零。
  static TransactionDraft transfer({
    required Account from,
    required Account to,
    required BigInt amountMinor,
    required DateTime date,
    String? note,
  }) {
    _require(from.type == AccountType.asset && to.type == AccountType.asset, '转账双方必须是资产账户');
    _require(from.currencyCode == to.currencyCode, '跨币种请使用换汇');
    _requirePositive(amountMinor);
    final c = from.currencyCode;
    return TransactionDraft(
      date: date,
      kind: TxKind.transfer,
      note: note ?? '${from.name} → ${to.name}',
      postings: [
        Posting.money(accountId: to.id, amountMinor: amountMinor, currencyCode: c),
        Posting.money(accountId: from.id, amountMinor: -amountMinor, currencyCode: c),
      ],
    );
  }

  /// 换汇：保留两端实际金额。系统汇兑账户在各币种内配平守恒，
  /// 汇率成本通过净资产归因的“汇兑影响”与该账户余额披露。
  static TransactionDraft fxConversion({
    required Account from,
    required Account to,
    required BigInt fromAmountMinor,
    required BigInt toAmountMinor,
    required DateTime date,
    String? note,
  }) {
    _require(from.type == AccountType.asset && to.type == AccountType.asset, '换汇双方必须是资产账户');
    _require(from.currencyCode != to.currencyCode, '同币种请使用转账');
    _requirePositive(fromAmountMinor);
    _requirePositive(toAmountMinor);
    return TransactionDraft(
      date: date,
      kind: TxKind.fxConversion,
      note: note,
      postings: [
        Posting.money(accountId: from.id, amountMinor: -fromAmountMinor, currencyCode: from.currencyCode),
        Posting.money(accountId: Account.sysExpenseFx, amountMinor: fromAmountMinor, currencyCode: from.currencyCode),
        Posting.money(accountId: to.id, amountMinor: toAmountMinor, currencyCode: to.currencyCode),
        Posting.money(accountId: Account.sysExpenseFx, amountMinor: -toAmountMinor, currencyCode: to.currencyCode),
      ],
    );
  }

  /// 信用卡还款：现金与负债同减，不再次确认消费。
  static TransactionDraft creditCardRepay({
    required Account card,
    required Account payFrom,
    required BigInt amountMinor,
    required DateTime date,
    String? note,
  }) {
    _require(card.type == AccountType.liability, '还款目标必须是负债账户');
    _require(payFrom.type == AccountType.asset, '还款来源必须是资产账户');
    _requirePositive(amountMinor);
    final c = payFrom.currencyCode;
    return TransactionDraft(
      date: date,
      kind: TxKind.creditCardRepay,
      note: note ?? '偿还 ${card.name}',
      postings: [
        Posting.money(accountId: card.id, amountMinor: amountMinor, currencyCode: c),
        Posting.money(accountId: payFrom.id, amountMinor: -amountMinor, currencyCode: c),
      ],
    );
  }

  /// 借款到账：现金与负债同增，不是收入。
  static TransactionDraft borrow({
    required Account loan,
    required Account toAsset,
    required BigInt principalMinor,
    required DateTime date,
    String? note,
  }) {
    _require(loan.type == AccountType.liability, '借入必须是负债账户');
    _require(toAsset.type == AccountType.asset, '借入必须进入资产账户');
    _requirePositive(principalMinor);
    final c = toAsset.currencyCode;
    return TransactionDraft(
      date: date,
      kind: TxKind.borrow,
      note: note,
      postings: [
        Posting.money(accountId: toAsset.id, amountMinor: principalMinor, currencyCode: c),
        Posting.money(accountId: loan.id, amountMinor: -principalMinor, currencyCode: c),
      ],
    );
  }

  /// 贷款/分期还款：拆分本金、利息与费用。
  /// 利息在支付时确认（收付实现制），已计提未支付的利息只出现在预测中，
  /// 因此支付时不会重复计费。
  static TransactionDraft loanRepay({
    required Account loan,
    required Account payFrom,
    required BigInt principalMinor,
    required BigInt interestMinor,
    required Account interestCategory,
    BigInt? feeMinor,
    Account? feeCategory,
    required DateTime date,
    String? note,
  }) {
    _require(loan.type == AccountType.liability, '贷款还款目标必须是负债账户');
    _require(payFrom.type == AccountType.asset, '还款来源必须是资产账户');
    final c = payFrom.currencyCode;
    final fee = feeMinor ?? BigInt.zero;
    final postings = <Posting>[
      Posting.money(accountId: loan.id, amountMinor: principalMinor, currencyCode: c),
      Posting.money(accountId: payFrom.id, amountMinor: -(principalMinor + interestMinor + fee), currencyCode: c),
    ];
    if (interestMinor > BigInt.zero) {
      postings.add(Posting.money(
          accountId: interestCategory.id, amountMinor: interestMinor, currencyCode: c));
    }
    if (fee > BigInt.zero) {
      postings.add(Posting.money(
          accountId: (feeCategory ?? interestCategory).id, amountMinor: fee, currencyCode: c));
    }
    return TransactionDraft(
      date: date,
      kind: TxKind.loanRepay,
      categoryId: interestCategory.id,
      note: note ?? '还款 ${loan.name}',
      postings: postings,
    );
  }

  /// 借出款：增加应收资产，不是消费。
  static TransactionDraft lend({
    required Account receivable,
    required Account fromAsset,
    required BigInt amountMinor,
    required DateTime date,
    String? counterparty,
    String? note,
  }) {
    _require(receivable.assetSubtype == AssetSubtype.receivable, '借出必须挂应收款账户');
    _requirePositive(amountMinor);
    final c = fromAsset.currencyCode;
    return TransactionDraft(
      date: date,
      kind: TxKind.lend,
      counterparty: counterparty,
      note: note,
      postings: [
        Posting.money(accountId: receivable.id, amountMinor: amountMinor, currencyCode: c),
        Posting.money(accountId: fromAsset.id, amountMinor: -amountMinor, currencyCode: c),
      ],
    );
  }

  /// 收回借出款：冲减应收，不是收入。支持部分收回。
  static TransactionDraft receiveBack({
    required Account receivable,
    required Account toAsset,
    required BigInt amountMinor,
    required DateTime date,
    String? counterparty,
    String? note,
  }) {
    _require(receivable.assetSubtype == AssetSubtype.receivable, '收回必须冲减应收款账户');
    _requirePositive(amountMinor);
    final c = toAsset.currencyCode;
    return TransactionDraft(
      date: date,
      kind: TxKind.receiveBack,
      counterparty: counterparty,
      note: note,
      postings: [
        Posting.money(accountId: toAsset.id, amountMinor: amountMinor, currencyCode: c),
        Posting.money(accountId: receivable.id, amountMinor: -amountMinor, currencyCode: c),
      ],
    );
  }

  /// 买入证券：总付金额（含费用）进入成本镜像账户，费用资本化计入成本。
  static TransactionDraft buy({
    required Account holdingAccount,
    required Account cashAccount,
    required Rational quantity,
    required BigInt totalPaidMinor,
    required DateTime date,
    String? note,
  }) {
    _require(holdingAccount.isHolding, '买入目标必须是持仓账户');
    _require(holdingAccount.costBasisAccountId != null, '持仓账户缺少成本镜像账户');
    _requirePositive(totalPaidMinor);
    final c = holdingAccount.currencyCode;
    return TransactionDraft(
      date: date,
      kind: TxKind.buy,
      note: note,
      postings: [
        Posting.money(
            accountId: holdingAccount.costBasisAccountId!,
            amountMinor: totalPaidMinor,
            currencyCode: c),
        Posting.money(accountId: cashAccount.id, amountMinor: -totalPaidMinor, currencyCode: c),
        Posting.quantity(
            accountId: holdingAccount.id,
            securityId: holdingAccount.securityId ?? holdingAccount.id,
            quantity: quantity),
      ],
    );
  }

  /// 卖出证券：净回款进入现金，按平均成本法冲减成本，
  /// 差额一次性经“已实现投资损益”确认（以前期间的浮盈不会重复计入本期收益）。
  static TransactionDraft sell({
    required Account holdingAccount,
    required Account cashAccount,
    required Rational quantitySold,
    required BigInt netProceedsMinor,
    required BigInt costBasisRemovedMinor,
    required DateTime date,
    String? note,
  }) {
    _require(holdingAccount.isHolding, '卖出必须针对持仓账户');
    _requirePositive(netProceedsMinor);
    final c = holdingAccount.currencyCode;
    final pnl = netProceedsMinor - costBasisRemovedMinor;
    return TransactionDraft(
      date: date,
      kind: TxKind.sell,
      note: note,
      postings: [
        Posting.money(accountId: cashAccount.id, amountMinor: netProceedsMinor, currencyCode: c),
        Posting.money(
            accountId: holdingAccount.costBasisAccountId!,
            amountMinor: -costBasisRemovedMinor,
            currencyCode: c),
        Posting.money(accountId: Account.sysIncomeRealizedPnl, amountMinor: -pnl, currencyCode: c),
        Posting.quantity(
            accountId: holdingAccount.id,
            securityId: holdingAccount.securityId ?? holdingAccount.id,
            quantity: -quantitySold),
      ],
    );
  }

  /// 分红派息：现金流入 + 投资收益。
  static TransactionDraft dividend({
    required Account cashAccount,
    required BigInt amountMinor,
    required DateTime date,
    String? note,
  }) {
    _requirePositive(amountMinor);
    final c = cashAccount.currencyCode;
    return TransactionDraft(
      date: date,
      kind: TxKind.dividend,
      note: note,
      postings: [
        Posting.money(accountId: cashAccount.id, amountMinor: amountMinor, currencyCode: c),
        Posting.money(accountId: Account.sysIncomeDividend, amountMinor: -amountMinor, currencyCode: c),
      ],
    );
  }

  /// 对账调整：把账本余额对齐真实余额，差额走权益调整，不进收支。
  static TransactionDraft adjustment({
    required Account account,
    required BigInt signedChangeMinor,
    required DateTime date,
    String? note,
  }) {
    _require(signedChangeMinor != BigInt.zero, '调整额不能为 0');
    return TransactionDraft(
      date: date,
      kind: TxKind.adjustment,
      isAdjustment: true,
      note: note ?? '对账调整',
      postings: [
        Posting.money(accountId: account.id, amountMinor: signedChangeMinor, currencyCode: account.currencyCode),
        Posting.money(
            accountId: Account.sysEquityAdjustment,
            amountMinor: -signedChangeMinor,
            currencyCode: account.currencyCode),
      ],
    );
  }

  static void _require(bool cond, String message) {
    if (!cond) throw ArgumentError(message);
  }

  static void _requirePositive(BigInt v) {
    if (v <= BigInt.zero) throw ArgumentError('金额必须为正: $v');
  }
}
