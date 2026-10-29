import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/ledger/account.dart';
import '../../domain/money/fx_rate.dart';
import '../../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'account_detail_sheet.dart';
import 'ownership.dart';
import 'account_edit_dialog.dart';
import 'accounts_providers.dart';

/// 账户页：资产/负债分组列表 + 净值展示 + 地球入口。
class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(accountsViewProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('账户'),
        actions: [
          IconButton(
            tooltip: '资产地球',
            icon: const Icon(Icons.public_outlined),
            onPressed: () => context.go('/globe'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showDialog<bool>(
            context: context,
            builder: (_) => const AccountEditDialog(),
          );
          if (created == true) ref.invalidate(accountsViewProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('新建账户'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPlaceholder('加载失败：$e'),
        data: (data) {
          final (list, nw) = data;
          final values = {for (final i in nw.items) i.account.id: i};
          final visible = list
              .where((a) => !a.isSystem)
              .where((a) =>
                  a.type == AccountType.asset || a.type == AccountType.liability)
              .where((a) => !a.archived);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _TotalBar(nw: nw),
              const SizedBox(height: 6),
              ..._group(context, ref,
                  visible.where((a) => a.type == AccountType.asset),
                  values, '资产', nw),
              ..._group(context, ref,
                  visible.where((a) => a.type == AccountType.liability),
                  values, '负债', nw),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _group(
    BuildContext context,
    WidgetRef ref,
    Iterable<Account> accounts,
    Map<String, AccountValuationItem> values,
    String title,
    NetWorthBreakdown nw,
  ) {
    final theme = Theme.of(context);
    final items = accounts.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
        child: Text(title,
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      ),
      if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(title == '资产' ? '还没有资产账户，点右下角新建' : '还没有负债账户',
              style:
                  theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
        ),
      for (final a in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: ListTile(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: _AccountAvatar(account: a),
              title: Row(
                children: [
                  Flexible(child: Text(a.name, overflow: TextOverflow.ellipsis)),
                  if (a.effectiveOwnership != Rational.one) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: '本人份额 ${fmtOwnership(a.effectiveOwnership)}%',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.brassOf(theme.brightness)
                              .withValues(alpha: 0.14),
                        ),
                        child: Text(
                            '我 ${fmtOwnership(a.effectiveOwnership)}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                    AppColors.brassOf(theme.brightness))),
                      ),
                    ),
                  ],
                  if (a.hasLocation) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.location_on, size: 14, color: AppColors.brassOf(theme.brightness)),
                  ],
                ],
              ),
              subtitle: Text(
                '${a.assetSubtype?.labelZh ?? a.liabilitySubtype?.labelZh ?? ''} · ${a.currencyCode}'
                '${values[a.id]?.valuationMissing == true ? ' · 缺估值' : ''}'
                '${values[a.id]?.valuationStale == true ? ' · 估值过期' : ''}',
              ),
              trailing: values[a.id] == null
                  ? const Text('—')
                  : MoneyText(values[a.id]!.valueBaseMinor,
                      currencyCode: nw.baseCurrencyCode, size: MoneySize.md),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (_) => AccountDetailSheet(account: a),
              ),
            ),
          ),
        ),
    ];
  }
}

/// 顶部汇总条：资产/负债/净资产一行。
class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.nw});

  final NetWorthBreakdown nw;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: AmountTile(
                        label: '总资产',
                        amount: fmtMinor(nw.totalAssets, nw.baseCurrencyCode))),
                Expanded(
                    child: AmountTile(
                        label: '总负债',
                        amount:
                            fmtMinor(nw.totalLiabilities, nw.baseCurrencyCode))),
                Expanded(
                    child: AmountTile(
                        label: '净资产',
                        amount: fmtMinor(nw.netWorth, nw.baseCurrencyCode),
                        color: theme.colorScheme.primary)),
              ],
            ),
            if (nw.hasSharedAccounts)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.group_outlined,
                        size: 14, color: AppColors.brassOf(theme.brightness)),
                    const SizedBox(width: 6),
                    Text(
                        '我的份额净资产 ${fmtMinor(nw.myNetWorth, nw.baseCurrencyCode)}'
                        '（账户归属见列表标注）',
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontFeatures: [FontFeature.tabularFigures()])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 账户图标圆片：按子类型选图标，统一视觉尺寸。
class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (account.assetSubtype) {
      AssetSubtype.cash ||
      AssetSubtype.alipay ||
      AssetSubtype.wechat =>
        Icons.payments_outlined,
      AssetSubtype.bank || AssetSubtype.timeDeposit => Icons.account_balance,
      AssetSubtype.brokerCash => Icons.business_center_outlined,
      AssetSubtype.stock ||
      AssetSubtype.fund ||
      AssetSubtype.bond ||
      AssetSubtype.preciousMetal ||
      AssetSubtype.crypto =>
        Icons.show_chart,
      AssetSubtype.realEstate => Icons.home_work_outlined,
      AssetSubtype.vehicle => Icons.directions_car_outlined,
      AssetSubtype.receivable => Icons.handshake_outlined,
      AssetSubtype.pension ||
      AssetSubtype.providentFund ||
      AssetSubtype.insuranceCashValue =>
        Icons.shield_outlined,
      _ => Icons.savings_outlined,
    };
    final isLiability = account.type == AccountType.liability;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (isLiability
                ? AppColors.negativeOf(theme.brightness)
                : theme.colorScheme.primary)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isLiability ? Icons.credit_card : icon,
        size: 20,
        color: isLiability
            ? AppColors.negativeOf(theme.brightness)
            : theme.colorScheme.primary,
      ),
    );
  }
}
