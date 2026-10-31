import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ledger/account.dart';
import '../../domain/money/fx_rate.dart';
import '../../l10n/app_localizations.dart';
import '../../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'account_detail_sheet.dart';
import 'account_edit_dialog.dart';
import 'accounts_providers.dart';
import 'ownership.dart';

/// 资产页（/assets）· 资产负债工作台。
///
/// 「添加的资产在哪里看、怎么编辑」的答案页：
/// - 顶部：净资产 hero 带（净资产大字 + 资产/负债合计 + 估值状态）。
/// - 大屏：左 = 分组账户清单（现金/稳健/持仓/实物 + 负债，组头带小计），
///   右 = 400px 详情面板（价值/操作/持仓/近期交易，选中行切换 150ms
///   淡入）。小屏：清单点行 → 底部弹层详情。
/// - 添加（页头主行动）→ [AccountEditDialog]；编辑 → 详情面板「编辑资料」。
class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= PageMeasure.wide;
    final async = ref.watch(accountsViewProvider);
    final t = AppLocalizations.of(context);
    return PageFrame(
      title: t.assetsTitle,
      titleHint: t.assetsTitleHint,
      maxWidth: AppMeasure.workbench,
      actions: [
        ParticleFilledButton.icon(
          onPressed: () => _add(context),
          icon: const Icon(Icons.add, size: 19),
          label: Text(t.assetAdd),
        ),
        const SizedBox(width: 6),
      ],
      fab: wide
          ? null
          : ParticleEdge(
              band: 12,
              extendBelow: 6,
              child: FloatingActionButton.extended(
                onPressed: () => _add(context),
                icon: const Icon(Icons.add),
                label: Text(t.assetAdd),
              ),
            ),
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 36)),
        error: (e, _) => ErrorPlaceholder(t.loadFailed(e.toString())),
        data: (data) {
          final (accounts, nw) = data;
          final visible = accounts
              .where(
                (a) =>
                    !a.isSystem &&
                    (a.type == AccountType.asset ||
                        a.type == AccountType.liability),
              )
              .toList();
          if (visible.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_outlined,
              title: t.assetsEmptyTitle,
              message: t.assetsEmptyMessage,
              action: ParticleFilledButton.icon(
                onPressed: () => _add(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(t.assetAdd),
              ),
            );
          }
          final groups = _group(visible, nw, t);
          final base = nw.baseCurrencyCode;
          // 选中态兜底：选中项被归档/删除后回退到第一个账户。
          final selected = _selectedId == null ||
                  !visible.any((a) => a.id == _selectedId)
              ? groups.firstOrNull?.rows.firstOrNull?.account
              : visible.firstWhere((a) => a.id == _selectedId);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: _NetWorthBand(nw: nw),
              ),
              Expanded(
                child: wide
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _AccountGroupsCard(
                                groups: groups,
                                base: base,
                                selectedId: selected?.id,
                                onSelect: (id) =>
                                    setState(() => _selectedId = id),
                              ),
                            ),
                            const SizedBox(width: PageMeasure.gutter),
                            SizedBox(
                              width: 400,
                              child: _DetailPanelCard(account: selected),
                            ),
                          ],
                        ),
                      )
                    : _AccountGroupsCard(
                        groups: groups,
                        base: base,
                        selectedId: null,
                        onSelect: (id) {
                          final a = visible.firstWhere((a) => a.id == id);
                          showAccountDetailSheet(context, a);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    await showAppDialog<bool>(
      context,
      builder: (_) => const AccountEditDialog(),
    );
    ref.invalidate(accountsViewProvider);
  }
}

// ── 分组 ───────────────────────────────────────────────────────────────

class _Group {
  const _Group(this.label, this.icon, this.rows);
  final String label;
  final IconData icon;
  final List<_AccountRow> rows;

  BigInt get subtotal => rows.fold(
    BigInt.zero,
    (s, r) => s + (r.item?.valueBaseMinor ?? BigInt.zero),
  );
}

class _AccountRow {
  const _AccountRow(this.account, this.item);
  final Account account;
  final AccountValuationItem? item;
}

/// 资产按流动性分组（现金与活期 / 稳健理财 / 持仓 / 实物与权益），
/// 负债单列；组内按本位币价值降序，归档垫底。
List<_Group> _group(List<Account> accounts, NetWorthBreakdown nw, AppLocalizations t) {
  final byId = {for (final i in nw.items) i.account.id: i};
  List<_AccountRow> mk(bool Function(Account) test) {
    final rows = [
          for (final a in accounts.where(test)) _AccountRow(a, byId[a.id]),
        ];
    rows.sort((a, b) {
      if (a.account.archived != b.account.archived) {
        return a.account.archived ? 1 : -1;
      }
      final av = a.item?.valueBaseMinor ?? BigInt.zero;
      final bv = b.item?.valueBaseMinor ?? BigInt.zero;
      return bv.compareTo(av);
    });
    return rows;
  }

  bool isCash(Account a) => switch (a.assetSubtype) {
    AssetSubtype.cash ||
    AssetSubtype.alipay ||
    AssetSubtype.wechat ||
    AssetSubtype.bank ||
    AssetSubtype.brokerCash => true,
    _ => false,
  };
  bool isSteady(Account a) => switch (a.assetSubtype) {
    AssetSubtype.timeDeposit ||
    AssetSubtype.moneyFund ||
    AssetSubtype.wealthMgmt ||
    AssetSubtype.insuranceCashValue ||
    AssetSubtype.pension ||
    AssetSubtype.providentFund => true,
    _ => false,
  };

  return [
    _Group(t.accountGroupCash, Icons.account_balance_wallet_outlined, mk(
      (a) => a.type == AccountType.asset && isCash(a),
    )),
    _Group(t.accountGroupSteady, Icons.savings_outlined, mk(
      (a) => a.type == AccountType.asset && isSteady(a),
    )),
    _Group(t.accountGroupHoldings, Icons.show_chart, mk(
      (a) => a.type == AccountType.asset && a.isHolding,
    )),
    _Group(t.accountGroupReal, Icons.home_work_outlined, mk(
      (a) =>
          a.type == AccountType.asset &&
          !a.isHolding &&
          !isCash(a) &&
          !isSteady(a),
    )),
    _Group(t.accountGroupLiabilities, Icons.credit_card_outlined, mk(
      (a) => a.type == AccountType.liability,
    )),
  ].where((g) => g.rows.isNotEmpty).toList();
}

// ── 净资产 hero 带 ─────────────────────────────────────────────────────

class _NetWorthBand extends StatelessWidget {
  const _NetWorthBand({required this.nw});

  final NetWorthBreakdown nw;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final brightness = theme.brightness;
    final shared = nw.hasSharedAccounts;
    final netWorth = shared ? nw.myNetWorth : nw.netWorth;
    return ParticleEdge(
      band: 22,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.dividerColor),
        ),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        shared ? t.netWorthMyShare : t.netWorth,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (shared) ...[
                        const SizedBox(width: 5),
                        InfoHint(message: t.netWorthMyShareHint),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Odometer(
                    text: fmtMinor(netWorth, nw.baseCurrencyCode),
                    style: theme.textTheme.headlineLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            _BandFigure(
              label: t.totalAssets,
              value: fmtMinor(nw.totalAssets, nw.baseCurrencyCode),
            ),
            const SizedBox(width: 14),
            Container(width: 1, height: 40, color: theme.dividerColor),
            const SizedBox(width: 14),
            _BandFigure(
              label: t.totalLiabilities,
              value: fmtMinor(nw.totalLiabilities, nw.baseCurrencyCode),
              color: nw.totalLiabilities > BigInt.zero
                  ? AppColors.negativeOf(brightness)
                  : null,
            ),
            const SizedBox(width: 14),
            Container(width: 1, height: 40, color: theme.dividerColor),
            const SizedBox(width: 14),
            _BandFigure(
              label: t.valuationStatusLabel,
              value: _valuationLabel(t, nw),
              warn: nw.missingValuations > 0,
            ),
          ],
        ),
      ),
    );
  }

  String _valuationLabel(AppLocalizations t, NetWorthBreakdown nw) {
    final missing = nw.missingValuations, stale = nw.staleValuations;
    if (missing > 0) return t.itemsMissingValuation(missing);
    if (stale > 0) return t.itemsStaleValuation(stale);
    return t.allReady;
  }
}

class _BandFigure extends StatelessWidget {
  const _BandFigure({required this.label, required this.value, this.color, this.warn = false});

  final String label;
  final String value;
  final Color? color;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: warn ? AppColors.warnOf(theme.brightness) : color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 分组清单卡 ─────────────────────────────────────────────────────────

class _AccountGroupsCard extends StatelessWidget {
  const _AccountGroupsCard({
    required this.groups,
    required this.base,
    required this.selectedId,
    required this.onSelect,
  });

  final List<_Group> groups;
  final String base;
  final String? selectedId;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ParticleEdge(
      band: 22,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.dividerColor),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: groups.length,
          itemBuilder: (context, gi) {
            final g = groups[gi];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GroupHeader(group: g, base: base),
                for (final r in g.rows)
                  _AccountListTile(
                    row: r,
                    base: base,
                    selected: r.account.id == selectedId,
                    onTap: () => onSelect(r.account.id),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group, required this.base});

  final _Group group;
  final String base;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isLiability = group.label == t.accountGroupLiabilities;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      child: Row(
        children: [
          Icon(
            group.icon,
            size: 15,
            color: isLiability
                ? AppColors.negativeOf(theme.brightness)
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 7),
          Text(
            group.label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${group.rows.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          Odometer(
            text: fmtMinor(group.subtotal, base),
            style: theme.textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.hintColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// 账户行：图标位 + 名称（+机构） + 本位币价值 + 估值状态点。
/// 选中态：左缘 3px 香槟金指示 + 底色；hover 提亮。
class _AccountListTile extends StatefulWidget {
  const _AccountListTile({
    required this.row,
    required this.base,
    required this.selected,
    required this.onTap,
  });

  final _AccountRow row;
  final String base;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AccountListTile> createState() => _AccountListTileState();
}

class _AccountListTileState extends State<_AccountListTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final brightness = theme.brightness;
    final a = widget.row.account;
    final item = widget.row.item;
    final missing = item?.valuationMissing ?? false;
    final stale = item?.valuationStale ?? false;
    final isLiability = a.type == AccountType.liability;
    final tint = isLiability
        ? AppColors.negativeOf(brightness)
        : theme.colorScheme.primary;
    final selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.chip),
            color: selected
                ? tint.withValues(alpha: 0.09)
                : (_hover
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.04)
                    : Colors.transparent),
            border: Border.all(
              color: selected ? tint.withValues(alpha: 0.35) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: 3,
                height: 26,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: selected ? AppColors.brassOf(brightness) : Colors.transparent,
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: tint.withValues(alpha: 0.12),
                ),
                child: Icon(
                  a.isHolding
                      ? Icons.show_chart
                      : (isLiability
                          ? Icons.credit_card
                          : Icons.account_balance_wallet_outlined),
                  size: 15,
                  color: tint,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            a.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w500,
                              color: a.archived ? theme.hintColor : null,
                            ),
                          ),
                        ),
                        if (a.archived) ...[
                          const SizedBox(width: 6),
                          Text(
                            t.accountArchived,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (a.institution?.isNotEmpty == true ||
                        a.effectiveOwnership != Rational.one)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          [
                            if (a.institution?.isNotEmpty == true) a.institution!,
                            if (a.effectiveOwnership != Rational.one)
                              t.accountMineShare(
                                  fmtOwnership(a.effectiveOwnership)),
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (missing)
                Tooltip(
                  message: t.accountMissingValuationTip,
                  child: Icon(
                    Icons.error_outline,
                    size: 15,
                    color: AppColors.warnOf(brightness),
                  ),
                )
              else if (stale)
                Tooltip(
                  message: t.accountStaleValuationTip,
                  child: Icon(
                    Icons.schedule,
                    size: 15,
                    color: AppColors.warnOf(brightness),
                  ),
                )
              else ...[
                const SizedBox(width: 15),
              ],
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: Text(
                  missing ? '—' : fmtMinor(item!.valueBaseMinor, widget.base),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: missing ? AppColors.warnOf(brightness) : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 大屏详情面板 ───────────────────────────────────────────────────────

/// 右侧详情面板：独立滚动的卡，选中变化 150ms 淡入（高频操作，快而轻）。
class _DetailPanelCard extends ConsumerWidget {
  const _DetailPanelCard({required this.account});

  final Account? account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final acct = account;
    return ParticleEdge(
      band: 22,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.dividerColor),
        ),
        child: acct == null
            ? Center(
                child: Text(
                  t.selectAccountHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              )
            : AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                child: KeyedSubtree(
                  key: ValueKey(acct.id),
                  child: AccountDetailBody(account: acct),
                ),
              ),
      ),
    );
  }
}
