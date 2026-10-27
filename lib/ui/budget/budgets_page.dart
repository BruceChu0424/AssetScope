import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/budget/budget.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/money.dart';
import '../../domain/utils/dates.dart';
import '../transactions/transactions_page.dart' show txAccountsProvider;
import '../widgets/common.dart';

/// 预算页：信封视图（额度/已花/剩余）。
class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_budgetEnvelopesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('预算')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await showDialog<bool>(
              context: context, builder: (_) => const _BudgetEditDialog());
          if (ok == true) ref.invalidate(_budgetEnvelopesProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('新建预算'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPlaceholder('加载失败：$e'),
        data: (data) {
          final (envs, base) = data;
          return envs.isEmpty
              ? const EmptyState(
                  icon: Icons.savings_outlined,
                  title: '还没有预算',
                  message: '从月度总预算开始，或给餐饮、购物等分类单独设额度，'
                      '首页会按当前消费速度预测月末是否超支。',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  children: [
                    for (final e in envs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _EnvelopeCard(
                            envelope: e, base: base, ref: ref),
                      ),
                  ],
                );
        },
      ),
    );
  }
}

/// 单个预算信封卡：进度条 + 额度/已花/剩余/计划占用。
class _EnvelopeCard extends StatelessWidget {
  const _EnvelopeCard({
    required this.envelope,
    required this.base,
    required this.ref,
  });

  final BudgetEnvelope envelope;
  final String base;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = envelope;
    final over = e.remainingMinor.isNegative;
    final ratio = e.limitMinor == BigInt.zero
        ? 0.0
        : (e.spentMinor.toDouble() / e.limitMinor.toDouble()).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(e.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Text(
                  over ? '超支 ${fmtMinor(-e.remainingMinor, base)}' : '剩余 ${fmtMinor(e.remainingMinor, base)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: over
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: '删除预算',
                  onPressed: () async {
                    final s = sessionOf(ref.read(vaultProvider));
                    if (s == null) return;
                    final ok = await confirmDialog(context,
                        title: '删除预算？',
                        message: '「${e.name}」的额度记录将被删除，已发生的消费不受影响。',
                        confirmLabel: '删除',
                        destructive: true);
                    if (ok != true) return;
                    await s.planning.deleteBudget(e.budgetId);
                    ref.invalidate(_budgetEnvelopesProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                color: over ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: AmountTile(
                        label: '额度',
                        amount: fmtMinor(e.limitMinor, base))),
                Expanded(
                    child: AmountTile(
                        label: '已花',
                        amount: fmtMinor(e.spentMinor, base))),
                Expanded(
                    child: AmountTile(
                        label: '未来计划占用',
                        amount: fmtMinor(e.plannedMinor, base))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final _budgetEnvelopesProvider =
    FutureProvider.autoDispose<(List<BudgetEnvelope>, String)>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) return (const <BudgetEnvelope>[], 'CNY');
  final base = await s.statsService.baseCurrency();
  final now = DateTime.now();
  final mk = monthKey(now);
  final budgets = (await s.planning.budgets())
      .where((b) => b.coversMonth(mk))
      .toList();

  // 本月分类已花（消费发生额，含退款冲减）。
  final monthStart = DateTime(now.year, now.month, 1);
  final txs = await s.ledger.list(from: monthStart, to: now);
  final spentByCategory = <String, BigInt>{};
  var totalSpent = BigInt.zero;
  for (final tx in txs) {
    if (tx.kind != TxKind.expense && tx.kind != TxKind.refund) continue;
    if (tx.categoryId == null) continue;
    for (final p in tx.postings) {
      if (p.accountId == tx.categoryId && p.amountMinor != null) {
        spentByCategory[tx.categoryId!] =
            (spentByCategory[tx.categoryId!] ?? BigInt.zero) + p.amountMinor!;
        if (!tx.categoryId!.startsWith('sys:')) {
          totalSpent += p.amountMinor!;
        }
      }
    }
  }

  // 本月计划占用（同一分类的计划事件金额）。
  final monthEnd = DateTime(now.year, now.month + 1, 0);
  final plannedByCategory = <String, BigInt>{};
  var totalPlanned = BigInt.zero;
  for (final e in await s.planning.scheduledEvents()) {
    for (final occ in e.expand(monthStart, monthEnd)) {
      if (occ.amountMinor >= BigInt.zero) continue;
      if (occ.date.isBefore(now)) continue;
      if (e.categoryId != null) {
        plannedByCategory[e.categoryId!] =
            (plannedByCategory[e.categoryId!] ?? BigInt.zero) + occ.amountMinor.abs();
      }
      totalPlanned += occ.amountMinor.abs();
    }
  }

  final envelopes = <BudgetEnvelope>[];
  for (final b in budgets) {
    final spent = b.scope == BudgetScope.total
        ? totalSpent
        : (spentByCategory[b.categoryId ?? ''] ?? BigInt.zero);
    final planned = b.scope == BudgetScope.total
        ? totalPlanned
        : (plannedByCategory[b.categoryId ?? ''] ?? BigInt.zero);
    envelopes.add(BudgetEnvelope(
      budgetId: b.id,
      name: b.name,
      monthKey: mk,
      limitMinor: b.limitMinor,
      carriedInMinor: BigInt.zero,
      spentMinor: spent,
      plannedMinor: planned,
      reservedMinor: BigInt.zero,
      overspentCarryMinor: BigInt.zero,
    ));
  }
  envelopes.sort((a, b) => b.limitMinor.compareTo(a.limitMinor));
  return (envelopes, base);
});

class _BudgetEditDialog extends ConsumerStatefulWidget {
  const _BudgetEditDialog();

  @override
  ConsumerState<_BudgetEditDialog> createState() => _BudgetEditDialogState();
}

class _BudgetEditDialogState extends ConsumerState<_BudgetEditDialog> {
  final _name = TextEditingController();
  final _limit = TextEditingController();
  BudgetScope _scope = BudgetScope.total;
  String? _categoryId;

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _limit.text.isEmpty) return;
    final now = DateTime.now();
    await s.planning.saveBudget(Budget(
      id: 'bud:${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      name: _name.text.isEmpty
          ? (_scope == BudgetScope.total ? '月度总预算' : '分类预算')
          : _name.text.trim(),
      scope: _scope,
      limitMinor: Money.parse(_limit.text, CurrencyInfo.cny).amountMinor,
      currencyCode: 'CNY',
      startMonthKey: monthKey(now),
      categoryId: _scope == BudgetScope.category ? _categoryId : null,
      rollover: RolloverPolicy.none,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(txAccountsProvider);
    return AlertDialog(
      title: const Text('新建预算'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<BudgetScope>(
              segments: const [
                ButtonSegment(value: BudgetScope.total, label: Text('总预算')),
                ButtonSegment(value: BudgetScope.category, label: Text('分类预算')),
              ],
              selected: {_scope},
              onSelectionChanged: (v) => setState(() => _scope = v.first),
            ),
            const SizedBox(height: 8),
            if (_scope == BudgetScope.category)
              accounts.maybeWhen(
                data: (list) => DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: '分类'),
                  items: [
                    for (final a in list.where((a) =>
                        a.type == AccountType.expense && !a.isSystem))
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            const SizedBox(height: 8),
            TextField(
                controller: _limit,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '每月额度（元）')),
            const SizedBox(height: 8),
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: '名称（可选）')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}
