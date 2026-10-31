import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ledger_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'add_transaction_dialog.dart';
import 'transactions_page.dart' show txListProvider;

/// 交易详情：全部分录（复式记账透视）、来源、外部 ID、编辑与作废入口。
Future<void> showTxDetail(
  BuildContext context,
  WidgetRef ref,
  LedgerTransaction tx,
) async {
  final s = sessionOf(ref.read(vaultProvider));
  if (s == null) return;
  final accounts = await s.accounts.all();
  final nameOf = <String, String>{
    for (final a in accounts) a.id: a.name,
    for (final sys in Account.systemAccounts()) sys.id: sys.name,
  };
  if (!context.mounted) return;

  await showAppSheet<void>(
    context,
    scrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final t = AppLocalizations.of(ctx);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx.note ?? tx.counterparty ?? tx.kind.labelZh,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')} · ${tx.kind.labelZh} · ${tx.source.labelZh}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              if (tx.status == TxStatus.voided) ...[
                const SizedBox(height: 6),
                Chip(
                  label: Text(t.txVoidedBadge),
                  backgroundColor: AppColors.negativeOf(
                    theme.brightness,
                  ).withValues(alpha: 0.12),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                t.txPostingsTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              for (final p in tx.postings)
                StatRow(
                  label:
                      '${nameOf[p.accountId] ?? p.accountId}${p.memo != null ? ' · ${p.memo}' : ''}',
                  value: p.amountMinor != null
                      ? fmtMinor(p.amountMinor!, p.currencyCode ?? 'CNY')
                      : t.txShares(p.quantity!.toDecimalString(6)),
                  valueColor: p.amountMinor != null
                      ? (p.amountMinor!.isNegative
                            ? AppColors.negativeOf(theme.brightness)
                            : AppColors.positiveOf(theme.brightness))
                      : theme.hintColor,
                ),
              if (tx.externalId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    t.txExternalId(tx.externalId!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ),
              if (tx.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 6,
                    children: [for (final t in tx.tags) Chip(label: Text(t))],
                  ),
                ),
              if (tx.status != TxStatus.voided) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (LedgerService.isEditable(tx))
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(t.commonEdit),
                          onPressed: () async {
                            Navigator.pop(ctx); // 先关详情再开编辑，避免弹层叠层
                            final ok = await showAppDialog<bool>(
                              context,
                              builder: (_) => AddTransactionDialog(editing: tx),
                            );
                            if (ok == true) ref.invalidate(txListProvider);
                          },
                        ),
                      ),
                    if (LedgerService.isEditable(tx)) const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.undo, size: 18),
                        label: Text(t.commonVoid),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.negativeOf(
                            theme.brightness,
                          ),
                        ),
                        onPressed: () async {
                          final ok = await confirmDialog(
                            ctx,
                            title: t.txVoidConfirmTitle,
                            message: t.txVoidConfirmMessage,
                            confirmLabel: t.commonVoid,
                            destructive: true,
                          );
                          if (ok != true) return;
                          await s.ledger.voidTransaction(tx.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
