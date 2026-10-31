import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/runtime_l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'add_transaction_dialog.dart';
import 'import_wizard.dart';
import 'tx_detail_sheet.dart';

final txListProvider = StreamProvider.autoDispose<List<LedgerTransaction>>((
  ref,
) {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) return Stream.value(const []);
  return s.ledger.watchLatest(limit: 500);
});

/// 搜索走全账本（SQL LIKE 下推），不受最近 500 条限制。
final txSearchProvider = FutureProvider.autoDispose
    .family<List<LedgerTransaction>, String>((ref, query) async {
      final s = sessionOf(ref.watch(vaultProvider));
      if (s == null || query.isEmpty) return const [];
      return s.ledger.search(query);
    });

final txAccountsProvider = FutureProvider.autoDispose<List<Account>>((
  ref,
) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) return const [];
  return s.accounts.all();
});

/// 流水筛选维度。
enum TxFilter { all, flow, transfer, invest, debt }

/// 流水筛选维度的中文标签。
String _filterLabel(TxFilter f) => switch (f) {
  TxFilter.all => rt('全部'),
  TxFilter.flow => rt('收支'),
  TxFilter.transfer => rt('转账'),
  TxFilter.invest => rt('投资'),
  TxFilter.debt => rt('借贷还款'),
};

/// 流水页 · 台账：统计带（本月收支）→ 搜索与筛选 → 按日分组的账本行
/// （日头带当日净额）。小屏单列纵读；大屏工作台见类注释。
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  String _query = '';
  TxFilter _filter = TxFilter.all;

  bool _accepts(LedgerTransaction tx) {
    switch (_filter) {
      case TxFilter.all:
        return true;
      case TxFilter.flow:
        return tx.kind == TxKind.expense ||
            tx.kind == TxKind.income ||
            tx.kind == TxKind.refund;
      case TxFilter.transfer:
        return tx.kind == TxKind.transfer || tx.kind == TxKind.fxConversion;
      case TxFilter.invest:
        return tx.kind == TxKind.buy ||
            tx.kind == TxKind.sell ||
            tx.kind == TxKind.dividend;
      case TxFilter.debt:
        return tx.kind == TxKind.loanRepay ||
            tx.kind == TxKind.creditCardRepay ||
            tx.kind == TxKind.borrow ||
            tx.kind == TxKind.lend ||
            tx.kind == TxKind.receiveBack;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final async = _query.isEmpty
        ? ref.watch(txListProvider)
        : ref.watch(txSearchProvider(_query));
    final wide = MediaQuery.sizeOf(context).width >= PageMeasure.wide;
    return PageFrame(
      title: t.txPageTitle,
      maxWidth: wide ? AppMeasure.workbench : 880,
      actions: [
        ActionIcon(
          tooltip: t.txExportCsvTooltip,
          icon: Icons.save_alt_outlined,
          onTap: () => _exportCsv(context),
        ),
        const SizedBox(width: 6),
        ActionIcon(
          tooltip: t.txImportCsvTooltip,
          icon: Icons.file_upload_outlined,
          onTap: () => showImportWizard(context, ref),
        ),
      ],
      fab: ParticleEdge(
        band: 12,
        extendBelow: 6,
        child: FloatingActionButton.extended(
          onPressed: () async {
            final ok = await showAppDialog<bool>(
              context,
              builder: (_) => const AddTransactionDialog(),
            );
            if (ok == true) ref.invalidate(txListProvider);
          },
          icon: const Icon(Icons.add),
          label: Text(t.txAddTitle),
        ),
      ),
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 36)),
        error: (e, _) => ErrorPlaceholder(t.loadFailed('$e')),
        data: (txs) {
          final visible = txs
              .where((t) => t.status != TxStatus.voided)
              .where(_accepts)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          if (!wide) {
            // 小屏：统计带 + 搜索/筛选行 + 台账（原形态）。
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _MonthBand(txs: txs),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ParticleTextField(
                          onChanged: (v) => setState(() => _query = v.trim()),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 20),
                            hintText: t.txSearchHint,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final f in TxFilter.values)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(_filterLabel(f)),
                                    selected: _filter == f,
                                    onSelected: (_) =>
                                        setState(() => _filter = f),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: _query.isEmpty
                              ? t.txEmptyTitle
                              : t.txNoMatchTitle,
                          message: _query.isEmpty
                              ? t.txEmptyHint
                              : t.txNoMatchHint,
                        )
                      : _LedgerList(
                          visible: visible,
                          onRowTap: (tx) => showTxDetail(context, ref, tx),
                        ),
                ),
              ],
            );
          }
          // 大屏工作台：主区 = 搜索 + 台账；右栏 = 本月概览 + 类型筛选。
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ParticleTextField(
                          onChanged: (v) => setState(() => _query = v.trim()),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 20),
                            hintText: t.txSearchHint,
                          ),
                        ),
                      ),
                      Expanded(
                        child: visible.isEmpty
                            ? EmptyState(
                                icon: Icons.receipt_long_outlined,
                                title: _query.isEmpty
                                    ? t.txEmptyTitle
                                    : t.txNoMatchTitle,
                                message: _query.isEmpty
                                    ? t.txEmptyHint
                                    : t.txNoMatchHintWide,
                              )
                            : _LedgerList(
                                visible: visible,
                                onRowTap: (tx) => showTxDetail(context, ref, tx),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PageMeasure.gutter),
                SizedBox(
                  width: 300,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _SideMonthPanel(txs: txs),
                        const SizedBox(height: PageMeasure.gutter),
                        _FilterPanel(
                          selected: _filter,
                          onSelect: (f) => setState(() => _filter = f),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 导出全部流水为明文 CSV（用户自选保存位置，与加密备份互补）。
  Future<void> _exportCsv(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final csv = await s.exportService.transactionsCsv();
    final loc = await getSaveLocation(
      suggestedName: 'assetscope-ledger-${dateToday()}.csv',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'CSV', extensions: ['csv']),
      ],
    );
    if (loc == null) return;
    await File(loc.path).writeAsString(csv, flush: true);
    if (!mounted) return;
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(content: Text(t.txExportedToast)),
    );
  }
}

/// 本月收支统计带（仅人民币；外币流水不入带，避免混币求和失真）。
class _MonthBand extends StatelessWidget {
  const _MonthBand({required this.txs});

  final List<LedgerTransaction> txs;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (expense, income, surplus) = _monthFigures(txs);
    final brightness = Theme.of(context).brightness;
    return StatBand(
      items: [
        StatBandItem(t.monthExpense, fmtMinor(expense, 'CNY')),
        StatBandItem(t.monthIncome, fmtMinor(income, 'CNY')),
        StatBandItem(
          t.monthSurplus,
          fmtMinor(surplus, 'CNY', sign: true),
          color: surplus.isNegative
              ? AppColors.negativeOf(brightness)
              : AppColors.positiveOf(brightness),
          tooltip: t.monthCnyOnlyTooltip,
        ),
      ],
    );
  }
}

/// 本月收支（支出、收入、结余；仅人民币）。
(BigInt, BigInt, BigInt) _monthFigures(List<LedgerTransaction> txs) {
  final now = DateTime.now();
  BigInt expense = BigInt.zero, income = BigInt.zero;
  for (final t in txs) {
    if (t.status == TxStatus.voided) continue;
    if (t.date.year != now.year || t.date.month != now.month) continue;
    final (cur, minor) = _userAmount(t);
    if (cur != 'CNY' || minor == null) continue;
    if (t.kind == TxKind.expense) {
      expense += minor.abs();
    } else if (t.kind == TxKind.income || t.kind == TxKind.refund) {
      income += minor.abs();
    }
  }
  return (expense, income, income - expense);
}

/// 大屏右栏「本月」面板：主数 = 本月支出，明细 = 收入/结余。
class _SideMonthPanel extends StatelessWidget {
  const _SideMonthPanel({required this.txs});

  final List<LedgerTransaction> txs;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (expense, income, surplus) = _monthFigures(txs);
    final brightness = Theme.of(context).brightness;
    return SummaryPanel(
      title: t.monthThis,
      heroValue: fmtMinor(expense, 'CNY'),
      heroLabel: t.monthSpent,
      rows: [
        SummaryRow(t.monthIncome, fmtMinor(income, 'CNY')),
        SummaryRow(
          t.monthSurplus,
          fmtMinor(surplus, 'CNY', sign: true),
          color: surplus.isNegative
              ? AppColors.negativeOf(brightness)
              : AppColors.positiveOf(brightness),
          tooltip: t.monthCnyOnlyTooltip,
        ),
      ],
    );
  }
}

/// 大屏右栏「类型」筛选：纵向单选清单（高频操作，切换即时无动画）。
class _FilterPanel extends StatelessWidget {
  const _FilterPanel({required this.selected, required this.onSelect});

  final TxFilter selected;
  final ValueChanged<TxFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SummaryPanel(
      title: t.fieldType,
      hint: t.filterPanelHint,
      child: Column(
        children: [
          for (final f in TxFilter.values)
            _FilterTile(
              icon: _iconOf(f),
              label: _filterLabel(f),
              selected: f == selected,
              onTap: () => onSelect(f),
            ),
        ],
      ),
    );
  }

  IconData _iconOf(TxFilter f) => switch (f) {
    TxFilter.all => Icons.list_alt_outlined,
    TxFilter.flow => Icons.swap_vert,
    TxFilter.transfer => Icons.swap_horiz,
    TxFilter.invest => Icons.show_chart,
    TxFilter.debt => Icons.handshake_outlined,
  };
}

class _FilterTile extends StatefulWidget {
  const _FilterTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FilterTile> createState() => _FilterTileState();
}

class _FilterTileState extends State<_FilterTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = theme.colorScheme.primary;
    final selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.chip),
            color: selected
                ? tint.withValues(alpha: 0.1)
                : (_hover
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.04)
                    : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 17,
                color: selected ? tint : theme.hintColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? tint : null,
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: selected ? 1 : 0,
                child: Icon(Icons.check, size: 16, color: tint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 按日分组台账。日头带当日净额（同币种才求和；混币日不显示净额）。
class _LedgerList extends StatelessWidget {
  const _LedgerList({required this.visible, required this.onRowTap});

  final List<LedgerTransaction> visible;
  final void Function(LedgerTransaction) onRowTap;

  @override
  Widget build(BuildContext context) {
    // 分组（visible 已按日期倒序）。
    final days = <DateTime, List<LedgerTransaction>>{};
    for (final t in visible) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      days.putIfAbsent(day, () => []).add(t);
    }
    final entries = days.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final day = entries[i].key;
        final list = entries[i].value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DayNetHeader(day: day, list: list),
            for (final tx in list) _TxRow(tx: tx, onTap: () => onRowTap(tx)),
          ],
        );
      },
    );
  }
}

class _DayNetHeader extends StatelessWidget {
  const _DayNetHeader({required this.day, required this.list});

  final DateTime day;
  final List<LedgerTransaction> list;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    // 仅收支类参与净额；同币种才求和。
    BigInt net = BigInt.zero;
    String? currency;
    var mixed = false;
    for (final t in list) {
      final kind = t.kind;
      if (kind != TxKind.expense &&
          kind != TxKind.income &&
          kind != TxKind.refund) {
        continue;
      }
      final (cur, minor) = _userAmount(t);
      if (cur == null || minor == null) continue;
      if (currency == null) {
        currency = cur;
      } else if (cur != currency) {
        mixed = true;
      }
      net += kind == TxKind.expense ? -minor.abs() : minor.abs();
    }
    final brightness = Theme.of(context).brightness;
    final showNet = !mixed && currency != null && net != BigInt.zero;
    return DayHeader(
      date: day,
      netLabel: !showNet
          ? ''
          : '${net.isNegative ? '${t.dirExpense} ' : '${t.dirIncome} '}${fmtMinor(net.abs(), currency)}',
      netColor: net.isNegative
          ? AppColors.negativeOf(brightness)
          : AppColors.positiveOf(brightness),
    );
  }
}

/// 台账行：图标位 + 标题/副行 + 右缘带符号金额。点击出详情透视。
class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx, required this.onTap});

  final LedgerTransaction tx;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final (cur, minor) = _userAmount(tx);
    final amount = minor == null || cur == null
        ? '—'
        : fmtMinor(minor.abs(), cur, sign: false);
    final signed = switch (tx.kind) {
      TxKind.income || TxKind.refund || TxKind.dividend => '+$amount',
      TxKind.expense || TxKind.borrow => '−$amount',
      _ => amount,
    };
    final color = switch (tx.kind) {
      TxKind.income ||
      TxKind.refund ||
      TxKind.dividend => AppColors.positiveOf(brightness),
      TxKind.expense || TxKind.borrow => AppColors.negativeOf(brightness),
      _ => null,
    };
    final title = tx.note ?? tx.counterparty ?? tx.kind.labelZh;
    final sub = tx.note != null && tx.counterparty != null
        ? '${tx.kind.labelZh} · ${tx.counterparty}'
        : tx.kind.labelZh;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: (color ?? Theme.of(context).colorScheme.primary).withValues(
            alpha: 0.12,
          ),
        ),
        child: _kindIcon(tx.kind, brightness),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(sub),
      trailing: Text(
        signed,
        style: TextStyle(
          fontFeatures: const [FontFeature.tabularFigures()],
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _kindIcon(TxKind k, Brightness b) => switch (k) {
    TxKind.income => Icon(Icons.south_west, size: 18, color: AppColors.positiveOf(b)),
    TxKind.expense => Icon(Icons.north_east, size: 18, color: AppColors.negativeOf(b)),
    TxKind.refund => Icon(Icons.replay, size: 18, color: AppColors.brassOf(b)),
    TxKind.transfer || TxKind.fxConversion => const Icon(Icons.swap_horiz, size: 18),
    TxKind.creditCardRepay || TxKind.loanRepay => const Icon(Icons.credit_score, size: 18),
    TxKind.borrow => Icon(Icons.south_east, size: 18, color: AppColors.negativeOf(b)),
    TxKind.lend || TxKind.receiveBack => const Icon(Icons.handshake, size: 18),
    TxKind.buy || TxKind.sell => const Icon(Icons.show_chart, size: 18),
    TxKind.dividend => Icon(Icons.paid, size: 18, color: AppColors.positiveOf(b)),
    TxKind.openingBalance || TxKind.adjustment => const Icon(Icons.flag, size: 18),
  };
}

/// 第一条触及用户资产/负债账户的货币分录（币种, 最小单位金额）。
(String?, BigInt?) _userAmount(LedgerTransaction tx) {
  for (final p in tx.postings) {
    if (p.accountId.startsWith('sys:') || p.accountId.startsWith('cat:')) {
      continue;
    }
    if (p.amountMinor != null && p.currencyCode != null) {
      return (p.currencyCode, p.amountMinor);
    }
  }
  for (final p in tx.postings) {
    if (p.amountMinor != null && p.currencyCode != null) {
      return (p.currencyCode, p.amountMinor);
    }
  }
  return (null, null);
}
