import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/money.dart';
import '../../domain/planning/recurrence.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 目标页 · 留钱墙：每只目标一张卡——环形进度（留了多少）+ 目标/缺口
/// /每月需 + 预留动作。大屏 400 定宽网格，小屏单列。
class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_goalsProvider);
    return PageFrame(
      title: '目标与准备金',
      maxWidth: 980,
      fab: ParticleEdge(
        band: 12,
        extendBelow: 6,
        child: FloatingActionButton.extended(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => const _GoalEditDialog(),
            );
            if (ok == true) ref.invalidate(_goalsProvider);
          },
          icon: const Icon(Icons.add),
          label: const Text('新建目标'),
        ),
      ),
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 36)),
        error: (e, _) => ErrorPlaceholder('加载失败：$e'),
        data: (goals) {
          if (goals.isEmpty) {
            return const EmptyState(
              icon: Icons.flag_outlined,
              title: '还没有目标',
              message: '用目标为大额支出提前留钱：旅行、保费、学费、设备……',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              CardWrap(
                tileWidth: 400,
                children: [for (final g in goals) _GoalCard(goal: g)],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 单只目标卡：左环右文。环=已留比例；缺口/每月需用 AmountTile 行。
class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final ratio = goal.targetAmountMinor == BigInt.zero
        ? 0.0
        : goal.reservedAmountMinor.toDouble() /
              goal.targetAmountMinor.toDouble();
    final gap = goal.gapMinor < BigInt.zero ? BigInt.zero : goal.gapMinor;
    final monthly = goal.monthlyNeedMinor(now);
    final daysLeft = goal.targetDate.difference(now).inDays;
    // 底缘光尘（docs/12 §9 卡片规范）：目标卡与区块卡同一家族。
    return ParticleEdge(
      band: 22,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: theme.hintColor),
                  tooltip: '目标操作',
                  onSelected: (a) => _onAction(context, ref, a),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'reserve', child: Text('增加预留')),
                    PopupMenuItem(value: 'delete', child: Text('删除目标')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RingProgress(ratio: ratio),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      AmountTile(
                        label: '目标',
                        amount: fmtMinor(goal.targetAmountMinor, 'CNY'),
                      ),
                      const SizedBox(height: 8),
                      AmountTile(
                        label: '已留',
                        amount: fmtMinor(goal.reservedAmountMinor, 'CNY'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      AmountTile(
                        label: '缺口',
                        amount: fmtMinor(gap, 'CNY'),
                        color: gap > BigInt.zero
                            ? AppColors.warnOf(theme.brightness)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      AmountTile(
                        label: '每月需留',
                        amount: monthly == null ? '—' : fmtMinor(monthly, 'CNY'),
                        tooltip: monthly == null ? '目标日已过或已留满，无需再留' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 14,
                  color: theme.hintColor,
                ),
                const SizedBox(width: 6),
                Text(
                  daysLeft >= 0 ? '还有 $daysLeft 天' : '已过期 ${-daysLeft} 天',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: daysLeft >= 30
                        ? theme.hintColor
                        : AppColors.warnOf(theme.brightness),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _addReserved(context, ref),
                  icon: const Icon(Icons.add_circle_outline, size: 17),
                  label: const Text('增加预留'),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    if (action == 'reserve') return _addReserved(context, ref);
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final ok = await confirmDialog(
      context,
      title: '删除目标？',
      message: '「${goal.name}」的预留记录将删除，已发生的转账不受影响。',
      confirmLabel: '删除',
      destructive: true,
    );
    if (ok != true) return;
    await s.planning.deleteGoal(goal.id);
    ref.invalidate(_goalsProvider);
  }

  Future<void> _addReserved(BuildContext context, WidgetRef ref) async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('为「${goal.name}」增加预留'),
        content: ParticleTextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: '金额（元）'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ParticleFilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final add = Money.parse(ctrl.text, CurrencyInfo.cny).amountMinor;
    await s.planning.saveGoal(
      SavingsGoal(
        id: goal.id,
        name: goal.name,
        targetAmountMinor: goal.targetAmountMinor,
        targetDate: goal.targetDate,
        priority: goal.priority,
        reservedAmountMinor: goal.reservedAmountMinor + add,
        fundingAccountIds: goal.fundingAccountIds,
        notes: goal.notes,
        status: goal.status,
      ),
    );
    ref.invalidate(_goalsProvider);
  }
}

final _goalsProvider = FutureProvider.autoDispose<List<SavingsGoal>>((
  ref,
) async {
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
    final target =
        DateTime.tryParse(_date.text) ??
        DateTime.now().add(const Duration(days: 180));
    await s.planning.saveGoal(
      SavingsGoal(
        id: 'goal:${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
        name: _name.text.trim(),
        targetAmountMinor: Money.parse(
          _amount.text,
          CurrencyInfo.cny,
        ).amountMinor,
        targetDate: target,
        reservedAmountMinor: BigInt.zero,
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建目标'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ParticleTextField(
            controller: _name,
            decoration: const InputDecoration(labelText: '名称'),
          ),
          const SizedBox(height: 8),
          ParticleTextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '目标金额（元）'),
          ),
          const SizedBox(height: 8),
          ParticleTextField(
            controller: _date,
            decoration: const InputDecoration(labelText: '目标日期 (yyyy-mm-dd)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        ParticleFilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}
