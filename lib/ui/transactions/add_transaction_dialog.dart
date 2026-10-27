import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/money.dart';
import '../widgets/common.dart';
import 'transactions_page.dart' show txAccountsProvider;

/// 记一笔：覆盖常用种类（消费/收入/转账/还款/借入/借出/收回）。
class AddTransactionDialog extends ConsumerStatefulWidget {
  const AddTransactionDialog({super.key});

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
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(txAccountsProvider);
    return AlertDialog(
      title: const Text('记一笔'),
      content: accountsAsync.when(
        loading: () => const SizedBox(
            height: 200, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => SizedBox(height: 100, child: Text('$e')),
        data: (accounts) {
          final userAssets = accounts
              .where((a) =>
                  a.type == AccountType.asset && !a.isSystem && !a.isHolding)
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

          _accountA ??=
              _defaultA(payables, userAssets, liabilities, receivables);
          _accountB ??= userAssets.isEmpty ? null : userAssets.first.id;
          _category ??= expenses.isEmpty ? null : expenses.first.id;

          String labelA;
          List<Account> optionsA;
          switch (_kind) {
            case TxKind.expense:
              labelA = '支付账户';
              optionsA = payables;
            case TxKind.income:
              labelA = '入账账户';
              optionsA = userAssets;
            case TxKind.transfer || TxKind.fxConversion:
              labelA = '转出账户';
              optionsA = userAssets;
            case TxKind.creditCardRepay:
              labelA = '偿还卡片';
              optionsA = liabilities;
            case TxKind.loanRepay:
              labelA = '贷款账户';
              optionsA = liabilities;
            case TxKind.borrow:
              labelA = '借入到';
              optionsA = userAssets;
            case TxKind.lend:
              labelA = '借出（挂应收）';
              optionsA = receivables;
            case TxKind.receiveBack:
              labelA = '收回至';
              optionsA = receivables;
            default:
              labelA = '账户';
              optionsA = userAssets;
          }
          final categories = _kind == TxKind.income ? incomes : expenses;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TxKind>(
                  initialValue: _kind,
                  decoration: const InputDecoration(labelText: '类型'),
                  items: const [
                    TxKind.expense, TxKind.income, TxKind.transfer,
                    TxKind.creditCardRepay, TxKind.loanRepay, TxKind.borrow,
                    TxKind.lend, TxKind.receiveBack,
                  ].map((k) => DropdownMenuItem(value: k, child: Text(k.labelZh))).toList(),
                  onChanged: (v) => setState(() {
                    _kind = v!;
                    _accountA = null;
                    _accountB = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
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
                  DropdownButtonFormField<String>(
                    initialValue: _accountB,
                    decoration: InputDecoration(
                        labelText: _labelB()),
                    items: [
                      for (final a in userAssets.where((x) => x.id != _accountA))
                        DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    onChanged: (v) => setState(() => _accountB = v),
                  ),
                ],
                if (_kind == TxKind.loanRepay) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: '利息分类'),
                    items: [
                      for (final a in expenses)
                        DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ],
                if (_kind == TxKind.expense || _kind == TxKind.income) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: '分类'),
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
                    currencyCode: _currencyOf(accounts)),
                const SizedBox(height: 12),
                AppDateField(controller: _date),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: '备注（可选）'),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('保存')),
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
        TxKind.receiveBack =>
          true,
        _ => false,
      };

  String _labelB() => switch (_kind) {
        TxKind.transfer || TxKind.fxConversion => '转入账户',
        TxKind.creditCardRepay || TxKind.loanRepay => '还款来源',
        TxKind.borrow => '借入到账账户（资产）',
        TxKind.lend || TxKind.receiveBack => '对方现金账户',
        _ => '账户 B',
      };

  String? _defaultA(List<Account> payables, List<Account> assets,
      List<Account> liabilities, List<Account> receivables) {
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
    final amount =
        Money.parse(amountText, CurrencyInfo.parse(aA.currencyCode)).amountMinor;

    switch (_kind) {
      case TxKind.expense:
        await s.ledger.post(TxBuilders.expense(
            payFrom: aA,
            expenseCategory: cat ?? byId['cat:e:other']!,
            amountMinor: amount,
            date: date,
            note: _note.text.isEmpty ? null : _note.text));
      case TxKind.income:
        await s.ledger.post(TxBuilders.income(
            destAsset: aA,
            incomeCategory: cat ?? byId['cat:i:other']!,
            amountMinor: amount,
            date: date,
            note: _note.text.isEmpty ? null : _note.text));
      case TxKind.transfer:
        if (aB == null) return;
        await s.ledger.post(TxBuilders.transfer(
            from: aA, to: aB, amountMinor: amount, date: date));
      case TxKind.creditCardRepay:
        if (aB == null) return;
        await s.ledger.post(TxBuilders.creditCardRepay(
            card: aA, payFrom: aB, amountMinor: amount, date: date));
      case TxKind.loanRepay:
        if (aB == null) return;
        await s.ledger.post(TxBuilders.loanRepay(
            loan: aA,
            payFrom: aB,
            principalMinor: amount,
            interestMinor: BigInt.zero,
            interestCategory: cat ?? byId['cat:e:interest']!,
            date: date));
      case TxKind.borrow:
        if (aB == null) return;
        await s.ledger.post(
            TxBuilders.borrow(loan: aA, toAsset: aB, principalMinor: amount, date: date));
      case TxKind.lend:
        if (aB == null) return;
        await s.ledger.post(TxBuilders.lend(
            receivable: aA, fromAsset: aB, amountMinor: amount, date: date));
      case TxKind.receiveBack:
        if (aB == null) return;
        await s.ledger.post(TxBuilders.receiveBack(
            receivable: aA, toAsset: aB, amountMinor: amount, date: date));
      default:
        return;
    }
    if (mounted) Navigator.pop(context, true);
  }
}

