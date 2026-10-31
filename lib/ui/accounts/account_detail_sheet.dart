import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/money/money.dart';
import '../../domain/valuation/valuation.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'account_edit_dialog.dart';
import 'accounts_providers.dart';
import 'ai_valuation_section.dart';
import 'ownership.dart';
import 'location_dialog.dart';
import 'lot_section.dart';
import 'trade_dialogs.dart';

/// 账户详情 **本体**：资产页大屏右栏面板与小屏弹层共用。
///
/// 内容：操作按钮带（编辑资料 / 估值 / 期初 / 调整 / 持仓买卖 / 分红 /
/// 位置 / 归档）→ AI 估值段 → 持仓段 → 近期交易。
/// [onActionDone]：动作完成后的收尾（弹层形态 = 关弹层；面板形态传 null，
/// 靠 provider 失效刷新面板）。
class AccountDetailBody extends ConsumerWidget {
  const AccountDetailBody({
    super.key,
    required this.account,
    this.onActionDone,
  });

  final Account account;
  final VoidCallback? onActionDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = sessionOf(ref.watch(vaultProvider));
    if (s == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: (account.type == AccountType.liability
                          ? AppColors.negativeOf(theme.brightness)
                          : theme.colorScheme.primary)
                      .withValues(alpha: 0.12),
                ),
                child: Icon(
                  account.type == AccountType.liability
                      ? Icons.credit_card
                      : (account.isHolding
                          ? Icons.show_chart
                          : Icons.account_balance_wallet_outlined),
                  size: 21,
                  color: account.type == AccountType.liability
                      ? AppColors.negativeOf(theme.brightness)
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (account.institution?.isNotEmpty == true)
                          account.institution!,
                        account.assetSubtype?.labelZh ??
                            account.liabilitySubtype?.labelZh ??
                            '',
                        account.currencyCode,
                        if (account.effectiveOwnership != Rational.one)
                          t.accountMineShare(
                              fmtOwnership(account.effectiveOwnership)),
                      ].where((t) => t.isNotEmpty).join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (account.hasLocation)
                Tooltip(
                  message: account.locationName ?? t.accountLocated,
                  child: Icon(
                    Icons.location_on,
                    size: 18,
                    color: AppColors.brassOf(theme.brightness),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _ValueHeader(account: account),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DetailAction(
                icon: Icons.edit_outlined,
                label: t.accountEditProfile,
                emphasized: true,
                onTap: () => _editProfile(context, ref),
              ),
              if (account.valuationMethod == ValuationMethod.manualValue ||
                  account.valuationMethod == ValuationMethod.marketPrice)
                _DetailAction(
                  icon: Icons.publish_outlined,
                  label: t.accountUpdateValuation,
                  onTap: () => _editValuation(context, ref, s),
                ),
              _DetailAction(
                icon: Icons.flag_outlined,
                label: t.accountOpeningBalance,
                onTap: () => _openingBalance(context, ref, s),
              ),
              _DetailAction(
                icon: Icons.tune,
                label: t.accountReconcileAdjust,
                onTap: () => _adjust(context, ref, s),
              ),
              if (account.isHolding) ...[
                _DetailAction(
                  icon: Icons.north_east,
                  label: t.tradeBuy,
                  onTap: () => showTradeDialog(
                    context,
                    ref,
                    s,
                    account: account,
                    action: TradeAction.buy,
                  ),
                ),
                _DetailAction(
                  icon: Icons.south_west,
                  label: t.tradeSell,
                  onTap: () => showTradeDialog(
                    context,
                    ref,
                    s,
                    account: account,
                    action: TradeAction.sell,
                  ),
                ),
                _DetailAction(
                  icon: Icons.tag,
                  label: t.accountQuoteCode,
                  onTap: () => _editQuoteCode(context, ref, s),
                ),
              ],
              _DetailAction(
                icon: Icons.paid_outlined,
                label: t.tradeDividendInterest,
                onTap: () => showTradeDialog(
                  context,
                  ref,
                  s,
                  account: account,
                  action: TradeAction.dividend,
                ),
              ),
              _DetailAction(
                icon: Icons.pie_chart_outline,
                label: t.ownershipTitle,
                onTap: () async {
                  final saved = await showOwnershipDialog(
                    context,
                    ref,
                    s,
                    account,
                  );
                  if (saved) {
                    ref.invalidate(accountsViewProvider);
                    onActionDone?.call();
                  }
                },
              ),
              _DetailAction(
                icon: Icons.place_outlined,
                label: account.hasLocation ? t.locChange : t.locSet,
                onTap: () async {
                  await showLocationDialog(context, ref, s, account);
                  ref.invalidate(accountsViewProvider);
                  onActionDone?.call();
                },
              ),
              _DetailAction(
                icon: account.archived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
                label: account.archived ? t.accountUnarchive : t.accountArchive,
                onTap: () async {
                  await s.accounts.archive(
                    account.id,
                    archived: !account.archived,
                  );
                  ref.invalidate(accountsViewProvider);
                  onActionDone?.call();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (account.valuationMethod == ValuationMethod.manualValue) ...[
            AiValuationSection(account: account),
            const SizedBox(height: 10),
          ],
          if (account.isHolding) LotSection(account: account),
          _RecentTransactions(accountId: account.id),
        ],
      ),
    );
  }

  /// 编辑资料：名称/机构/位置/份额（类型与价值不可改，见弹窗注释）。
  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final ok = await showAppDialog<bool>(
      context,
      builder: (_) => AccountEditDialog(initial: account),
    );
    if (ok == true) onActionDone?.call();
  }

  Future<void> _editValuation(
    BuildContext context,
    WidgetRef ref,
    VaultUnlocked s,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    final ok = await showAppDialog<bool>(
      context,
      builder: (dctx) => AppDialog(
        title: l10n.accountUpdateValuation,
        content: AppAmountField(
          controller: ctrl,
          currencyCode: account.currencyCode,
          label: account.valuationMethod == ValuationMethod.marketPrice
              ? l10n.accountUnitPriceLabel
              : l10n.accountTotalValueLabel,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(l10n.cancel),
          ),
          ParticleFilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final now = DateTime.now();
    if (account.valuationMethod == ValuationMethod.marketPrice) {
      final t = ctrl.text.trim();
      if (t.isEmpty) return;
      await s.meta.saveValuation(
        ValuationRecord(
          accountId: account.id,
          date: now,
          kind: ValuationKind.unitPrice,
          unitPrice: Rational.parseDecimal(t),
        ),
      );
    } else {
      final v = Money.parse(
        ctrl.text,
        CurrencyInfo.parse(account.currencyCode),
      ).amountMinor;
      await s.meta.saveValuation(
        ValuationRecord(
          accountId: account.id,
          date: now,
          kind: ValuationKind.totalValue,
          totalValueMinor: v,
        ),
      );
    }
    ref.invalidate(accountsViewProvider);
    onActionDone?.call();
  }

  Future<void> _openingBalance(
    BuildContext context,
    WidgetRef ref,
    VaultUnlocked s,
  ) async {
    final t = AppLocalizations.of(context);
    await _simpleAmountDialog(
      context,
      ref,
      title: t.accountOpeningBalanceTitle,
      onConfirm: (amount, date) async {
        await s.ledger.post(
          TxBuilders.openingBalance(
            assetAccount: account,
            amountMinor: amount,
            date: date,
          ),
        );
        ref.invalidate(accountsViewProvider);
      },
    );
  }

  Future<void> _adjust(
    BuildContext context,
    WidgetRef ref,
    VaultUnlocked s,
  ) async {
    final t = AppLocalizations.of(context);
    await _simpleAmountDialog(
      context,
      ref,
      title: t.accountReconcileAdjustTitle,
      allowNegative: true,
      onConfirm: (amount, date) async {
        await s.ledger.post(
          TxBuilders.adjustment(
            account: account,
            signedChangeMinor: amount,
            date: date,
          ),
        );
        ref.invalidate(accountsViewProvider);
      },
    );
  }

  /// 修改行情代码：只更新 securities.code 元数据（直连行情源用），
  /// 不动 securityId 与历史分录——账本结构零影响。
  Future<void> _editQuoteCode(
    BuildContext context,
    WidgetRef ref,
    VaultUnlocked s,
  ) async {
    final t = AppLocalizations.of(context);
    if (account.securityId == null) return;
    final codes = await s.accounts.securityCodes();
    if (!context.mounted) return;
    final ctrl = TextEditingController(text: codes[account.securityId] ?? '');
    final ok = await showAppDialog<bool>(
      context,
      builder: (dctx) => AppDialog(
        title: t.accountQuoteCodeTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ParticleTextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: t.accountQuoteCodeHint,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t.accountQuoteCodeHelp,
              style: Theme.of(dctx).textTheme.bodySmall?.copyWith(
                color: Theme.of(dctx).hintColor,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(t.cancel),
          ),
          ParticleFilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(t.save),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final code = ctrl.text.trim();
    if (code.isEmpty) return;
    await s.accounts.updateSecurityCode(account.securityId!, code);
    ref.invalidate(accountsViewProvider);
    onActionDone?.call();
  }

  Future<void> _simpleAmountDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required Future<void> Function(BigInt, DateTime) onConfirm,
    bool allowNegative = false,
  }) async {
    final t = AppLocalizations.of(context);
    final amount = AppAmountField(
      controller: TextEditingController(),
      currencyCode: account.currencyCode,
      allowNegative: allowNegative,
    );
    final date = TextEditingController(text: dateToday());
    final ok = await showAppDialog<bool>(
      context,
      builder: (dctx) => AppDialog(
        title: title,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            amount,
            const SizedBox(height: 12),
            AppDateField(controller: date),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(t.cancel),
          ),
          ParticleFilledButton(
            onPressed: () {
              final v = amount.parseMinor();
              if (v != null) Navigator.pop(dctx, true);
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final v = amount.parseMinor();
    if (v == null) return;
    await onConfirm(v, DateTime.tryParse(date.text) ?? DateTime.now());
    onActionDone?.call();
  }
}

/// 详情操作钮：圆角胶囊带图标；[emphasized] 为主行动（编辑资料）。
class _DetailAction extends StatefulWidget {
  const _DetailAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  State<_DetailAction> createState() => _DetailActionState();
}

class _DetailActionState extends State<_DetailAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = widget.emphasized
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.chip),
            color: widget.emphasized
                ? tint.withValues(alpha: _hover ? 0.16 : 0.1)
                : (_hover
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.03)),
            border: widget.emphasized
                ? Border.all(color: tint.withValues(alpha: 0.4))
                : Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: tint),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: tint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 详情价值头部：本位币价值大数字 + 估值状态徽章（缺估值/过期/归档），
/// 外币账户附原币余额。
class _ValueHeader extends ConsumerWidget {
  const _ValueHeader({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final brightness = theme.brightness;
    final async = ref.watch(accountsViewProvider);
    final data = async.value;
    final item = data?.$2.items
        .where((i) => i.account.id == account.id)
        .firstOrNull;
    final base = data?.$2.baseCurrencyCode ?? 'CNY';
    final missing = item?.valuationMissing ?? false;
    final stale = item?.valuationStale ?? false;
    final value = item?.valueBaseMinor;
    final isLiability = account.type == AccountType.liability;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        color: theme.colorScheme.surfaceContainerLowest.withValues(
          alpha: theme.brightness == Brightness.light ? 1 : 0.45,
        ),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLiability
                      ? t.accountDebtBaseLabel
                      : t.accountValueBaseLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Odometer(
                  text: missing
                      ? t.accountValuationMissing
                      : fmtMinor(value ?? BigInt.zero, base),
                  style: theme.textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: missing
                        ? AppColors.warnOf(brightness)
                        : (isLiability
                              ? AppColors.negativeOf(brightness)
                              : theme.colorScheme.onSurface),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (!missing &&
                    item != null &&
                    item.balanceMinor != null &&
                    account.currencyCode != base) ...[
                  const SizedBox(height: 3),
                  Text(
                    t.accountOriginalBalance(
                        fmtMinor(item.balanceMinor!, account.currencyCode)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                if (account.effectiveOwnership != Rational.one &&
                    !missing &&
                    item != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    t.accountMyShareDetail(
                        fmtMinor(item.myValueBaseMinor, base),
                        fmtOwnership(account.effectiveOwnership)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (missing)
                _StatusBadge(
                  icon: Icons.error_outline,
                  label: t.accountValuationMissing,
                  color: AppColors.warnOf(brightness),
                  tooltip: t.accountMissingValuationHint,
                ),
              if (stale && !missing)
                _StatusBadge(
                  icon: Icons.schedule,
                  label: t.accountValuationStale,
                  color: AppColors.warnOf(brightness),
                  tooltip: t.accountStaleValuationHint,
                ),
              if (account.archived)
                _StatusBadge(
                  icon: Icons.archive_outlined,
                  label: t.accountArchived,
                  color: theme.hintColor,
                  tooltip: t.accountArchivedHint,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.tooltip,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: color.withValues(alpha: 0.12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 小屏/弹层形态：右缘侧滑（大屏，供地球标记等入口）或底部弹层。
Future<void> showAccountDetailSheet(
  BuildContext context,
  Account account,
) {
  return showAppSheet<void>(
    context,
    scrollControlled: true,
    builder: (sheetCtx) => SafeArea(
      child: AccountDetailBody(
        account: account,
        onActionDone: () => Navigator.of(sheetCtx).pop(),
      ),
    ),
  );
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
    final t = AppLocalizations.of(context);
    return FutureBuilder<List<LedgerTransaction>>(
      future: s.ledger.list(
        from: DateTime(2000),
        to: DateTime.now().add(const Duration(days: 1)),
      ),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final txs = snap.data!
            .where(
              (t) =>
                  t.status != TxStatus.voided &&
                  t.postings.any((p) => p.accountId == accountId),
            )
            .take(20)
            .toList();
        if (txs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            Text(
              t.accountRecentTransactions,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            for (final tx in txs)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  tx.note ?? tx.counterparty ?? tx.kind.labelZh,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')} · ${tx.kind.labelZh}',
                ),
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
