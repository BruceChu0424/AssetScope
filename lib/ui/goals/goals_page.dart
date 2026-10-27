import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/money.dart';
import '../../domain/planning/recurrence.dart';
import '../widgets/common.dart';

/// 目标与准备金（旅游、保险年费、装修等）。
class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_goalsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('目标与准备金')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await showDialog<bool>(
              context: context, builder: (_) => const _GoalEditDialog());
          if (ok == true) ref.invalidate(_goalsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('新建目标'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPlaceholder('加载失败：$e'),
        data: (goals) => goals.isEmpty
            ? const ErrorPlaceholder('用目标为大额支出提前留钱：旅行、保费、学费、设备……')
            : ListView(
                children: [
                  for (final g in goals)
                    Card(
                      child: ListTile(
                        title: Text(g.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: g.targetAmountMinor == BigInt.zero
                                  ? 0
                                  : (g.reservedAmountMinor.toDouble() /
                                          g.targetAmountMinor.toDouble())
                                      .clamp(0, 1),
                              minHeight: 6,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '目标 ${fmtMinor(g.targetAmountMinor, 'CNY')} · 已留 ${fmtMinor(g.reservedAmountMinor, 'CNY')} · 缺口 ${fmtMinor(g.gapMinor < BigInt.zero ? BigInt.zero : g.gapMinor, 'CNY')}'
                              '${g.monthlyNeedMinor(DateTime.now()) != null ? ' · 每月需 ${fmtMinor(g.monthlyNeedMinor(DateTime.now())!, 'CNY')}' : ''}',
                              style: const TextStyle(
                                  fontFeatures: [FontFeature.tabularFigures()]),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              tooltip: '增加预留',
                              onPressed: () => _addReserved(context, ref, g),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final s = sessionOf(ref.read(vaultProvider));
                                if (s == null) return;
                                await s.planning.deleteGoal(g.id);
                                ref.invalidate(_goalsProvider);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _addReserved(
      BuildContext context, WidgetRef ref, SavingsGoal g) async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('为「${g.name}」增加预留'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: '金额（元）'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('保存')),
        ],
      ),
    );
    if (ok != true) return;
    final add = Money.parse(ctrl.text, CurrencyInfo.cny).amountMinor;
    await s.planning.saveGoal(SavingsGoal(
      id: g.id,
      name: g.name,
      targetAmountMinor: g.targetAmountMinor,
      targetDate: g.targetDate,
      priority: g.priority,
      reservedAmountMinor: g.reservedAmountMinor + add,
      fundingAccountIds: g.fundingAccountIds,
      notes: g.notes,
      status: g.status,
    ));
    ref.invalidate(_goalsProvider);
  }
}

final _goalsProvider = FutureProvider.autoDispose<List<SavingsGoal>>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) return const [];
  return s.planning.goals();
});

class _GoalEditDialog extends ConsumerStatefulWidget {
  const _GoalEditDialog();

  @override
  ConsumerState<_GoalEditDialog> createState() => _GoalEditDialogState();
}

class _GoalEditDialogState extends ConsumerState<_GoalEditDialog> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _date = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _name.text.isEmpty || _amount.text.isEmpty) return;
    final target = DateTime.tryParse(_date.text) ??
        DateTime.now().add(const Duration(days: 180));
    await s.planning.saveGoal(SavingsGoal(
      id: 'goal:${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      name: _name.text.trim(),
      targetAmountMinor: Money.parse(_amount.text, CurrencyInfo.cny).amountMinor,
      targetDate: target,
      reservedAmountMinor: BigInt.zero,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建目标'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: '名称')),
          const SizedBox(height: 8),
          TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '目标金额（元）')),
          const SizedBox(height: 8),
          TextField(
              controller: _date,
              decoration: const InputDecoration(labelText: '目标日期 (yyyy-mm-dd)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}
