import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/money.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common.dart';
import 'transactions_page.dart' show txAccountsProvider;

/// 记一笔：覆盖常用种类（消费/收入/转账/还款/借入/借出/收回）。
///
/// [editing] 非空时为编辑模式：预填原交易字段，保存时经
/// LedgerService.editTx 重放分录（保留 id 与来源审计字段，不产生
/// "作废+重记"杂讯）。仅支持简单资金流类型（LedgerService.isEditable）。
class AddTransactionDialog extends ConsumerStatefulWidget {
  const AddTransactionDialog({super.key, this.editing});

  final LedgerTransaction? editing;

  @override
  ConsumerState<AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _date = TextEditingController(text: dateToday());
  TxKind _kind = TxKind.expense;
  String? _accountA;
  String? _accountB;
  String? _category;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) _prefill(e);
  }

  /// 从原交易推断表单初值：金额取首条用户账户货币分录的绝对值，
  /// 账户按"负 = 流出方、正 = 流入方"结合类型语义匹配（分录方向口径
  /// 见 docs/05 §2：正 = 借 = 资金流入该账户）。
  void _prefill(LedgerTransaction tx) {
    _kind = tx.kind;
    _date.text =
        '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
    _note.text = tx.note ?? '';
    _category = tx.categoryId;
    BigInt? amount;
    for (final p in tx.postings) {
      if (p.amountMinor == null) continue;
      final id = p.accountId;
      final isUser = !id.startsWith('sys:') && !id.startsWith('cat:');
      if (amount == null && isUser) amount = p.amountMinor!.abs();
      // 方向匹配账户。
      final neg = p.amountMinor!.isNegative;
      switch (tx.kind) {
        case TxKind.expense:
          if (isUser) _accountA = id;
        case TxKind.income:
          if (isUser && !neg) _accountA = id;
        case TxKind.transfer:
          if (isUser && neg) {
            _accountA = id;
          } else if (isUser) {
            _accountB = id;
          }
        case TxKind.creditCardRepay:
          if (neg) {
            _accountB = id; // 还款来源
          } else {
            _accountA = id; // 卡
          }
        case TxKind.borrow:
          if (isUser && !neg) {
            _accountA = id; // 借入到账
          } else if (!isUser) {
            _accountB = id; // 贷款账户（负债）
          }
        case TxKind.lend || TxKind.receiveBack:
          // 方向定账户：lend 应收(+) / receiveBack 应收(−) 在 A，现金在 B。
          if (isUser) {
            if ((tx.kind == TxKind.lend) != neg) {
              _accountA = id;
            } else {
              _accountB = id;
            }
          }
        default:
          break;
      }
    }
    if (amount != null) {
      // 保持分的精度（88.50 不得预填成 88）。
      final ccy = tx.postings
          .firstWhere(
            (p) => p.currencyCode != null && p.currencyCode!.isNotEmpty,
            orElse: () => tx.postings.first,
          )
          .currencyCode;
      _amount.text = fmtMinor(amount, ccy ?? 'CNY');
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final accountsAsync = ref.watch(txAccountsProvider);
    return AppDialog(
      title: widget.editing == null ? t.txAddTitle : t.txEditTitle,
      scroll: true,
      content: accountsAsync.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => SizedBox(height: 100, child: Text('$e')),
        data: (accounts) {
          final userAssets = accounts
              .where(
                (a) =>
                    a.type == AccountType.asset && !a.isSystem && !a.isHolding,
              )
              .toList();
          final liabilities = accounts
              .where((a) => a.type == AccountType.liability && !a.isSystem)
              .toList();
          final payables = [...userAssets, ...liabilities];
          final expenses = accounts
              .where((a) => a.type == AccountType.expense && !a.isSystem)
              .toList();
          final incomes = accounts
              .where((a) => a.type == AccountType.income && !a.isSystem)
              .toList();
          final receivables = accounts
              .where((a) => a.assetSubtype == AssetSubtype.receivable)
              .toList();

          _accountA ??= _defaultA(
            payables,
            userAssets,
            liabilities,
            receivables,
          );
          _accountB ??= userAssets.isEmpty ? null : userAssets.first.id;
          _category ??= expenses.isEmpty ? null : expenses.first.id;

          String labelA;
          List<Account> optionsA;
          switch (_kind) {
            case TxKind.expense:
              labelA = t.txAccountPayFrom;
              optionsA = payables;
            case TxKind.income:
              labelA = t.txAccountDeposit;
              optionsA = userAssets;
            case TxKind.transfer || TxKind.fxConversion:
              labelA = t.txAccountTransferFrom;
              optionsA = userAssets;
            case TxKind.creditCardRepay:
              labelA = t.txAccountRepayCard;
              optionsA = liabilities;
            case TxKind.loanRepay:
              labelA = t.txAccountLoan;
              optionsA = liabilities;
            case TxKind.borrow:
              labelA = t.txAccountBorrowTo;
              optionsA = userAssets;
            case TxKind.lend:
              labelA = t.txAccountLendReceivable;
              optionsA = receivables;
            case TxKind.receiveBack:
              labelA = t.txAccountReceiveBackTo;
              optionsA = receivables;
            default:
              labelA = t.txAccountLabel;
              optionsA = userAssets;
          }
          final categories = _kind == TxKind.income ? incomes : expenses;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ParticleDropdownField<TxKind>(
                  initialValue: _kind,
                  decoration: InputDecoration(labelText: t.fieldType),
                  items:
                      const [
                            TxKind.expense,
                            TxKind.income,
                            TxKind.transfer,
                            TxKind.creditCardRepay,
                            TxKind.loanRepay,
                            TxKind.borrow,
                            TxKind.lend,
                            TxKind.receiveBack,
                          ]
                          .map(
                            (k) => DropdownMenuItem(
                              value: k,
                              child: Text(k.labelZh),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() {
                    _kind = v!;
                    _accountA = null;
                    _accountB = null;
                  }),
                ),
                const SizedBox(height: 12),
                ParticleDropdownField<String>(
                  initialValue: _accountA,
                  decoration: InputDecoration(labelText: labelA),
                  items: [
                    for (final a in optionsA)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => _accountA = v),
                ),
                if (_needB()) ...[
                  const SizedBox(height: 12),
                  ParticleDropdownField<String>(
                    initialValue: _accountB,
                    decoration: InputDecoration(labelText: _labelB()),
                    items: [
                      for (final a in userAssets.where(
                        (x) => x.id != _accountA,
                      ))
                        DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    onChanged: (v) => setState(() => _accountB = v),
                  ),
                ],
                if (_kind == TxKind.loanRepay) ...[
                  const SizedBox(height: 12),
                  ParticleDropdownField<String>(
                    initialValue: _category,
                    decoration: InputDecoration(labelText: t.txInterestCategory),
                    items: [
                      for (final a in expenses)
                        DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ],
                if (_kind == TxKind.expense || _kind == TxKind.income) ...[
                  const SizedBox(height: 12),
                  ParticleDropdownField<String>(
                    initialValue: _category,
                        decoration: InputDecoration(labelText: t.txCategory),
                    items: [
                      for (final a in categories)
                        DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ],
                const SizedBox(height: 12),
                AppAmountField(
                  controller: _amount,
                  currencyCode: _currencyOf(accounts),
                ),
                const SizedBox(height: 12),
                AppDateField(controller: _date),
                const SizedBox(height: 12),
                ParticleTextField(
                  controller: _note,
                  decoration: InputDecoration(labelText: t.txNoteOptional),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.commonCancel),
        ),
        ParticleFilledButton(onPressed: _save, child: Text(t.commonSave)),
      ],
    );
  }

  String _currencyOf(List<Account> accounts) {
    for (final a in accounts) {
      if (a.id == _accountA) return a.currencyCode;
    }
    return 'CNY';
  }

  bool _needB() => switch (_kind) {
    TxKind.transfer ||
    TxKind.fxConversion ||
    TxKind.creditCardRepay ||
    TxKind.loanRepay ||
    TxKind.borrow ||
    TxKind.lend ||
    TxKind.receiveBack => true,
    _ => false,
  };

  String _labelB() {
    final t = AppLocalizations.of(context);
    return switch (_kind) {
      TxKind.transfer || TxKind.fxConversion => t.txAccountTransferTo,
      TxKind.creditCardRepay || TxKind.loanRepay => t.txAccountRepayFrom,
      TxKind.borrow => t.txAccountBorrowToAsset,
      TxKind.lend || TxKind.receiveBack => t.txAccountCounterpartyCash,
      _ => t.txAccountB,
    };
  }

  String? _defaultA(
    List<Account> payables,
    List<Account> assets,
    List<Account> liabilities,
    List<Account> receivables,
  ) {
    switch (_kind) {
      case TxKind.expense:
        return payables.isEmpty ? null : payables.first.id;
      case TxKind.income:
        return assets.isEmpty ? null : assets.first.id;
      case TxKind.creditCardRepay:
      case TxKind.loanRepay:
        return liabilities.isEmpty ? null : liabilities.first.id;
      case TxKind.lend:
      case TxKind.receiveBack:
        return receivables.isEmpty ? null : receivables.first.id;
      default:
        return assets.isEmpty ? null : assets.first.id;
    }
  }

  Future<void> _save() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final accs = await s.accounts.all();
    final byId = {for (final a in accs) a.id: a};
    final aA = _accountA == null ? null : byId[_accountA!];
    final aB = _accountB == null ? null : byId[_accountB!];
    final cat = _category == null ? null : byId[_category!];
    final date = DateTime.tryParse(_date.text) ?? DateTime.now();
    final amountText = _amount.text.trim();
    if (aA == null || amountText.isEmpty) return;
    final amount = Money.parse(
      amountText,
      CurrencyInfo.parse(aA.currencyCode),
    ).amountMinor;
    final note = _note.text.isEmpty ? null : _note.text;

    final draft = switch (_kind) {
      TxKind.expense => TxBuilders.expense(
        payFrom: aA,
        expenseCategory: cat ?? byId['cat:e:other']!,
        amountMinor: amount,
        date: date,
        note: note,
      ),
      TxKind.income => TxBuilders.income(
        destAsset: aA,
        incomeCategory: cat ?? byId['cat:i:other']!,
        amountMinor: amount,
        date: date,
        note: note,
      ),
      TxKind.transfer =>
        aB == null
            ? null
            : TxBuilders.transfer(
                from: aA,
                to: aB,
                amountMinor: amount,
                date: date,
                note: note,
              ),
      TxKind.creditCardRepay =>
        aB == null
            ? null
            : TxBuilders.creditCardRepay(
                card: aA,
                payFrom: aB,
                amountMinor: amount,
                date: date,
                note: note,
              ),
      TxKind.loanRepay =>
        aB == null
            ? null
            : TxBuilders.loanRepay(
                loan: aA,
                payFrom: aB,
                principalMinor: amount,
                interestMinor: BigInt.zero,
                interestCategory: cat ?? byId['cat:e:interest']!,
                date: date,
              ),
      TxKind.borrow =>
        aB == null
            ? null
            : TxBuilders.borrow(
                loan: aA,
                toAsset: aB,
                principalMinor: amount,
                date: date,
                note: note,
              ),
      TxKind.lend =>
        aB == null
            ? null
            : TxBuilders.lend(
                receivable: aA,
                fromAsset: aB,
                amountMinor: amount,
                date: date,
                note: note,
              ),
      TxKind.receiveBack =>
        aB == null
            ? null
            : TxBuilders.receiveBack(
                receivable: aA,
                toAsset: aB,
                amountMinor: amount,
                date: date,
                note: note,
              ),
      _ => null,
    };
    if (draft == null) return;
    final editingId = widget.editing?.id;
    if (editingId != null) {
      await s.ledgerService.editTx(editingId, draft);
    } else {
      await s.ledger.post(draft);
    }
    if (mounted) Navigator.pop(context, true);
  }
}
