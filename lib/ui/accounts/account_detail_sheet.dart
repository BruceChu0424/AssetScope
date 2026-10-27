import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/money/money.dart';
import '../../domain/valuation/valuation.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'accounts_providers.dart';
import 'location_dialog.dart';
import 'lot_section.dart';
import 'trade_dialogs.dart';

/// 账户详情弹层：估值 / 期初 / 调整 / 持仓买卖 / 分红 / 位置 / 历史 / 归档。
class AccountDetailSheet extends ConsumerWidget {
  const AccountDetailSheet({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = sessionOf(ref.watch(vaultProvider));
    if (s == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '${account.institution ?? ''} ${account.assetSubtype?.labelZh ?? account.liabilitySubtype?.labelZh ?? ''} · ${account.currencyCode}'
                        '${account.hasLocation ? ' · ${account.locationName ?? '已定位'}' : ''}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                if (account.hasLocation)
                  Icon(Icons.location_on,
                      size: 18, color: AppColors.brassOf(theme.brightness)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (account.valuationMethod == ValuationMethod.manualValue ||
                    account.valuationMethod == ValuationMethod.marketPrice)
                  ActionChip(
                    label: const Text('更新估值'),
                    onPressed: () => _editValuation(context, ref, s),
                  ),
                ActionChip(
                  label: const Text('期初余额'),
                  onPressed: () => _openingBalance(context, ref, s),
                ),
                ActionChip(
                  label: const Text('对账调整'),
                  onPressed: () => _adjust(context, ref, s),
                ),
                if (account.isHolding) ...[
                  ActionChip(
                    label: const Text('买入'),
                    onPressed: () => showTradeDialog(context, ref, s,
                        account: account, action: TradeAction.buy),
                  ),
                  ActionChip(
                    label: const Text('卖出'),
                    onPressed: () => showTradeDialog(context, ref, s,
                        account: account, action: TradeAction.sell),
                  ),
                ],
                ActionChip(
                  label: const Text('分红/利息'),
                  onPressed: () => showTradeDialog(context, ref, s,
                      account: account, action: TradeAction.dividend),
                ),
                ActionChip(
                  label: Text(account.hasLocation ? '修改位置' : '设置位置'),
                  onPressed: () async {
                    await showLocationDialog(context, ref, s, account);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
                ActionChip(
                  label: Text(account.archived ? '取消归档' : '归档'),
                  onPressed: () async {
                    await s.accounts
                        .archive(account.id, archived: !account.archived);
                    ref.invalidate(accountsViewProvider);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (account.isHolding) LotSection(account: account),
            _RecentTransactions(accountId: account.id),
          ],
        ),
      ),
    );
  }

  Future<void> _editValuation(
      BuildContext context, WidgetRef ref, VaultUnlocked s) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('更新估值'),
        content: AppAmountField(
          controller: ctrl,
          currencyCode: account.currencyCode,
          label: account.valuationMethod == ValuationMethod.marketPrice
              ? '单价（每单位）'
              : '当前总价值',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('保存')),
        ],
      ),
    );
    if (ok != true) return;
    final now = DateTime.now();
    if (account.valuationMethod == ValuationMethod.marketPrice) {
      final t = ctrl.text.trim();
      if (t.isEmpty) return;
      await s.meta.saveValuation(ValuationRecord(
        accountId: account.id,
        date: now,
        kind: ValuationKind.unitPrice,
        unitPrice: Rational.parseDecimal(t),
      ));
    } else {
      final v = Money.parse(ctrl.text, CurrencyInfo.parse(account.currencyCode))
          .amountMinor;
      await s.meta.saveValuation(ValuationRecord(
        accountId: account.id,
        date: now,
        kind: ValuationKind.totalValue,
        totalValueMinor: v,
      ));
    }
    ref.invalidate(accountsViewProvider);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _openingBalance(
      BuildContext context, WidgetRef ref, VaultUnlocked s) async {
    await _simpleAmountDialog(
      context,
      ref,
      title: '记期初余额（历史补录，不算当月收入）',
      onConfirm: (amount, date) async {
        await s.ledger.post(
          TxBuilders.openingBalance(
              assetAccount: account, amountMinor: amount, date: date),
        );
        ref.invalidate(accountsViewProvider);
      },
    );
  }

  Future<void> _adjust(
      BuildContext context, WidgetRef ref, VaultUnlocked s) async {
    await _simpleAmountDialog(
      context,
      ref,
      title: '对账调整（填差额，可负）',
      allowNegative: true,
      onConfirm: (amount, date) async {
        await s.ledger.post(
          TxBuilders.adjustment(
              account: account, signedChangeMinor: amount, date: date),
        );
        ref.invalidate(accountsViewProvider);
      },
    );
  }

  Future<void> _simpleAmountDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required Future<void> Function(BigInt, DateTime) onConfirm,
    bool allowNegative = false,
  }) async {
    final amount = AppAmountField(
      controller: TextEditingController(),
      currencyCode: account.currencyCode,
      allowNegative: allowNegative,
    );
    final date = TextEditingController(text: dateToday());
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            amount,
            const SizedBox(height: 10),
            AppDateField(controller: date),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final v = amount.parseMinor();
              if (v != null) Navigator.pop(dctx, true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final v = amount.parseMinor();
    if (v == null) return;
    await onConfirm(v, DateTime.tryParse(date.text) ?? DateTime.now());
    if (context.mounted) Navigator.of(context).pop();
  }
}

/// 账户近 20 笔涉及本账户的交易。
class _RecentTransactions extends ConsumerWidget {
  const _RecentTransactions({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = sessionOf(ref.watch(vaultProvider));
    if (s == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return FutureBuilder<List<LedgerTransaction>>(
      future: s.ledger.list(
          from: DateTime(2000),
          to: DateTime.now().add(const Duration(days: 1))),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final txs = snap.data!
            .where((t) =>
                t.status != TxStatus.voided &&
                t.postings.any((p) => p.accountId == accountId))
            .take(20)
            .toList();
        if (txs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            Text('近期交易',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            for (final tx in txs)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(tx.note ?? tx.counterparty ?? tx.kind.labelZh,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')} · ${tx.kind.labelZh}'),
                trailing: _signedAmount(context, tx),
              ),
          ],
        );
      },
    );
  }

  Widget _signedAmount(BuildContext context, LedgerTransaction tx) {
    final p = tx.postings
        .where((p) => p.accountId == accountId && p.amountMinor != null)
        .firstOrNull;
    if (p == null) return const Text('—');
    final theme = Theme.of(context);
    final v = p.amountMinor!;
    return Text(
      '${v.isNegative ? '' : '+'}${fmtMinor(v.abs(), p.currencyCode ?? 'CNY')}',
      style: TextStyle(
        color: v.isNegative
            ? AppColors.negativeOf(theme.brightness)
            : AppColors.positiveOf(theme.brightness),
        fontFeatures: const [FontFeature.tabularFigures()],
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

