import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/money/money.dart';
import '../../services/insight_service.dart';
import '../widgets/common.dart';
import 'accounts_providers.dart';

enum TradeAction { buy, sell, dividend }

/// 持仓交易对话框：买入 / 卖出（平均成本自动结转）/ 分红利息。
Future<void> showTradeDialog(
  BuildContext context,
  WidgetRef ref,
  VaultUnlocked s, {
  required Account account,
  required TradeAction action,
}) async {
  final isDividend = action == TradeAction.dividend;
  final amountCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final dateCtrl = TextEditingController(text: dateToday());
  final noteCtrl = TextEditingController();
  String? cashAccountId;

  final accounts = await s.accounts.all();
  final cashAccounts = accounts
      .where((a) =>
          a.type == AccountType.asset &&
          !a.isSystem &&
          !a.isHolding &&
          a.assetSubtype != AssetSubtype.receivable)
      .toList();
  if (cashAccounts.isNotEmpty) cashAccountId = cashAccounts.first.id;

  final holdings = isDividend
      ? const <HoldingSnapshot>[]
      : await s.insightService.holdings();
  final snapshot =
      holdings.where((h) => h.account.id == account.id).firstOrNull;
  if (!context.mounted) return;

  final ok = await showDialog<bool>(
    context: context,
    builder: (dctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(switch (action) {
          TradeAction.buy => '买入 · ${account.name}',
          TradeAction.sell => '卖出 · ${account.name}',
          TradeAction.dividend => '分红/利息入账',
        }),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDividend && snapshot != null) ...[
                Text(
                  '持有 ${snapshot.quantity.toDecimalString(6)} 份 · 成本 ${fmtMinor(snapshot.costMinor, account.currencyCode)}',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).hintColor),
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                initialValue: cashAccountId,
                decoration: InputDecoration(
                    labelText: isDividend ? '入账现金账户' : '现金账户'),
                items: [
                  for (final a in cashAccounts)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setState(() => cashAccountId = v),
              ),
              const SizedBox(height: 12),
              if (!isDividend) ...[
                TextField(
                  controller: qtyCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '数量（份）'),
                ),
                const SizedBox(height: 12),
              ],
              AppAmountField(
                controller: amountCtrl,
                currencyCode: account.currencyCode,
                label: switch (action) {
                  TradeAction.buy => '总花费（含费用）',
                  TradeAction.sell => '净到账金额',
                  _ => '分红/利息金额',
                },
              ),
              const SizedBox(height: 12),
              AppDateField(controller: dateCtrl),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: '备注（可选）'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: const Text('保存')),
        ],
      ),
    ),
  );
  if (ok != true || cashAccountId == null) return;

  final date = DateTime.tryParse(dateCtrl.text) ?? DateTime.now();
  final ccy = CurrencyInfo.parse(account.currencyCode);
  final amount = amountCtrl.text.trim().isEmpty
      ? null
      : Money.parse(amountCtrl.text.trim(), ccy).amountMinor;
  if (amount == null) return;

  switch (action) {
    case TradeAction.buy:
      final qty = _parseRational(qtyCtrl.text);
      if (qty == null) return;
      await s.ledgerService.buySecurity(
        holdingAccountId: account.id,
        cashAccountId: cashAccountId!,
        quantity: qty,
        totalPaidMinor: amount,
        date: date,
        note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
      );
    case TradeAction.sell:
      final qty = _parseRational(qtyCtrl.text);
      if (qty == null) return;
      await s.ledgerService.sellSecurity(
        holdingAccountId: account.id,
        cashAccountId: cashAccountId!,
        quantitySold: qty,
        netProceedsMinor: amount,
        date: date,
        note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
      );
    case TradeAction.dividend:
      final cash = await s.accounts.byId(cashAccountId!);
      if (cash == null) return;
      await s.ledger.post(TxBuilders.dividend(
        cashAccount: cash,
        amountMinor: amount,
        date: date,
        note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
      ));
  }
  ref.invalidate(accountsViewProvider);
  ref.invalidate(holdingsProvider);
  if (context.mounted) Navigator.of(context).pop();
}

Rational? _parseRational(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  try {
    return Rational.parseDecimal(t);
  } on FormatException {
    return null;
  }
}

