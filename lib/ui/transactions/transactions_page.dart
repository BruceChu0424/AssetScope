import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../widgets/common.dart';
import 'add_transaction_dialog.dart';
import 'import_wizard.dart';
import 'tx_detail_sheet.dart';

final txListProvider =
    StreamProvider.autoDispose<List<LedgerTransaction>>((ref) {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) return Stream.value(const []);
  return s.ledger.watchLatest(limit: 500);
});

final txAccountsProvider = FutureProvider.autoDispose<List<Account>>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) return const [];
  return s.accounts.all();
});

/// 流水筛选维度。
enum TxFilter { all, flow, transfer, invest, debt }

/// 流水页：搜索、类型筛选、详情透视、记一笔、导入账单。
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
        return tx.kind == TxKind.transfer ||
            tx.kind == TxKind.fxConversion;
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
    final async = ref.watch(txListProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('流水'),
        actions: [
          IconButton(
            tooltip: '导出 CSV（明文，自选位置）',
            icon: const Icon(Icons.save_alt),
            onPressed: () => _exportCsv(context),
          ),
          IconButton(
            tooltip: '导入账单 CSV',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => showImportWizard(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => const AddTransactionDialog(),
          );
          if (ok == true) ref.invalidate(txListProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (txs) {
          final visible = txs
              .where((t) => t.status != TxStatus.voided)
              .where(_accepts)
              .where((t) {
                if (_query.isEmpty) return true;
                final q = _query.toLowerCase();
                return (t.note ?? '').toLowerCase().contains(q) ||
                    (t.counterparty ?? '').toLowerCase().contains(q) ||
                    t.kind.labelZh.contains(q);
              })
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 20),
                    hintText: '搜索备注、对方、类型',
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final f in TxFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_labelOf(f)),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text('没有匹配的交易',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.hintColor)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 96),
                        itemCount: visible.length,
                        itemBuilder: (context, i) {
                          final tx = visible[i];
                          return _TxTile(
                            tx: tx,
                            onTap: () async {
                              await showTxDetail(context, ref, tx);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _labelOf(TxFilter f) => switch (f) {
        TxFilter.all => '全部',
        TxFilter.flow => '收支',
        TxFilter.transfer => '转账',
        TxFilter.invest => '投资',
        TxFilter.debt => '借贷还款',
      };

  /// 导出全部流水为明文 CSV（用户自选保存位置，与加密备份互补）。
  Future<void> _exportCsv(BuildContext context) async {
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
      const SnackBar(content: Text('已导出流水 CSV（含 BOM，Excel 可直接打开）')),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx, required this.onTap});

  final LedgerTransaction tx;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _kindIcon(tx.kind),
      title: Text(
        tx.note ?? tx.counterparty ?? tx.kind.labelZh,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
          '${tx.date.month}/${tx.date.day} · ${tx.kind.labelZh}'),
      trailing: Text(
        _signedAmountOf(tx),
        style: const TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w600),
      ),
      onTap: () => onTap(),
    );
  }

  String _signedAmountOf(LedgerTransaction tx) {
    // 第一条触及用户资产/负债账户的货币分录作为展示金额。
    for (final p in tx.postings) {
      if (p.accountId.startsWith('sys:') || p.accountId.startsWith('cat:')) {
        continue;
      }
      if (p.amountMinor != null && p.currencyCode != null) {
        return fmtMinor(p.amountMinor!.abs(), p.currencyCode!);
      }
    }
    final any = tx.postings.firstWhere(
        (p) => p.amountMinor != null,
        orElse: () => tx.postings.first);
    return any.amountMinor == null || any.currencyCode == null
        ? '—'
        : fmtMinor(any.amountMinor!.abs(), any.currencyCode!);
  }

  Widget _kindIcon(TxKind k) => switch (k) {
        TxKind.income => const Icon(Icons.south_west, color: Color(0xFF2E7D5B)),
        TxKind.expense =>
          const Icon(Icons.north_east, color: Color(0xFFB3402E)),
        TxKind.refund => const Icon(Icons.replay, color: Color(0xFF9A6B1F)),
        TxKind.transfer || TxKind.fxConversion => const Icon(Icons.swap_horiz),
        TxKind.creditCardRepay || TxKind.loanRepay =>
          const Icon(Icons.credit_score),
        TxKind.borrow => const Icon(Icons.south_east, color: Color(0xFFB3402E)),
        TxKind.lend || TxKind.receiveBack => const Icon(Icons.handshake),
        TxKind.buy || TxKind.sell => const Icon(Icons.show_chart),
        TxKind.dividend => const Icon(Icons.paid, color: Color(0xFF2E7D5B)),
        TxKind.openingBalance || TxKind.adjustment => const Icon(Icons.flag),
      };
}
