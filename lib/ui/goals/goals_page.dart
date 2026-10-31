import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/money.dart';
import '../../domain/planning/recurrence.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 目标页 · 留钱墙：每只目标一张卡——环形进度（留了多少）+ 目标/缺口
/// /每月需 + 预留动作。大屏 400 定宽网格，小屏单列。
class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(_goalsProvider);
    final wide = MediaQuery.sizeOf(context).width >= PageMeasure.wide;
    return PageFrame(
      title: t.goalsPageTitle,
      maxWidth: wide ? AppMeasure.workbench : 980,
      fab: ParticleEdge(
        band: 12,
        extendBelow: 6,
        child: FloatingActionButton.extended(
          onPressed: () => _newGoal(context, ref),
          icon: const Icon(Icons.add),
          label: Text(t.goalNew),
        ),
      ),
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 36)),
        error: (e, _) => ErrorPlaceholder(t.wdgLoadFailed(e.toString())),
        data: (goals) {
          if (goals.isEmpty) {
            return EmptyState(
              icon: Icons.flag_outlined,
              title: t.goalEmptyTitle,
              message: t.goalEmptyMessage,
            );
          }
          if (wide) {
            final target = goals.fold(
              BigInt.zero, (s, g) => s + g.targetAmountMinor);
            final reserved = goals.fold(
              BigInt.zero, (s, g) => s + g.reservedAmountMinor);
            final gap = target - reserved;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 300,
                    child: SummaryPanel(
                      title: t.goalSummaryTitle,
                      hint: t.goalSummaryHint,
                      heroValue: fmtMinor(reserved, 'CNY'),
                      heroLabel: t.goalReserved,
                      rows: [
                        SummaryRow(t.goalTotalTarget, fmtMinor(target, 'CNY')),
                        SummaryRow(
                          t.goalTotalGap,
                          fmtMinor(gap.isNegative ? BigInt.zero : gap, 'CNY'),
                          color: gap > BigInt.zero
                              ? AppColors.warnOf(
                                  Theme.of(context).brightness,
                                )
                              : null,
                        ),
                        SummaryRow(t.goalCount, t.goalItems(goals.length)),
                      ],
                    ),
                  ),
                  const SizedBox(width: PageMeasure.gutter),
                  Expanded(
                    child: CardWrap(
                      tileWidth: 400,
                      children: [for (final g in goals) _GoalCard(goal: g)],
                    ),
                  ),
                ],
              ),
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

  Future<void> _newGoal(BuildContext context, WidgetRef ref) async {
    final ok = await showAppDialog<bool>(
      context,
      builder: (_) => const _GoalEditDialog(),
    );
    if (ok == true) ref.invalidate(_goalsProvider);
  }
}

/// 单只目标卡：左环右文。环=已留比例；缺口/每月需用 AmountTile 行。
class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
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
                ParticleMenuButton<String>(
                  tooltip: t.goalActions,
                  onSelected: (a) => _onAction(context, ref, a),
                  items: [
                    ParticleMenuEntry(
                      value: 'reserve',
                      label: t.goalAddReserve,
                      icon: Icons.savings_outlined,
                    ),
                    ParticleMenuEntry(
                      value: 'delete',
                      label: t.goalDelete,
                      icon: Icons.delete_outline,
                      destructive: true,
                    ),
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
                        label: t.goalTarget,
                        amount: fmtMinor(goal.targetAmountMinor, 'CNY'),
                      ),
                      const SizedBox(height: 8),
                      AmountTile(
                        label: t.goalReserved,
                        amount: fmtMinor(goal.reservedAmountMinor, 'CNY'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      AmountTile(
                        label: t.goalGap,
                        amount: fmtMinor(gap, 'CNY'),
                        color: gap > BigInt.zero
                            ? AppColors.warnOf(theme.brightness)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      AmountTile(
                        label: t.goalMonthlyNeed,
                        amount: monthly == null ? '—' : fmtMinor(monthly, 'CNY'),
                        tooltip: monthly == null
                            ? t.goalMonthlyNeedTooltip
                            : null,
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
                  daysLeft >= 0
                      ? t.goalDaysLeft(daysLeft)
                      : t.goalOverdueBy(-daysLeft),
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
                      label: Text(t.goalAddReserve),
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
    final t = AppLocalizations.of(context);
    if (action == 'reserve') return _addReserved(context, ref);
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final ok = await confirmDialog(
      context,
      title: t.goalDeleteConfirmTitle,
      message: t.goalDeleteConfirmMessage(goal.name),
      confirmLabel: t.wdgDelete,
      destructive: true,
    );
    if (ok != true) return;
    await s.planning.deleteGoal(goal.id);
    ref.invalidate(_goalsProvider);
  }

  Future<void> _addReserved(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final ctrl = TextEditingController();
    final ok = await showAppDialog<bool>(
      context,
      builder: (dctx) => AppDialog(
        title: t.goalReserveTitle(goal.name),
        content: AppAmountField(
          controller: ctrl,
          currencyCode: 'CNY',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(t.wdgCancel),
          ),
          ParticleFilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(t.wdgSave),
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
    final t = AppLocalizations.of(context);
    return AppDialog(
      title: t.goalNew,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ParticleTextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: t.goalNameField),
          ),
          const SizedBox(height: 14),
          AppAmountField(
            controller: _amount,
            currencyCode: 'CNY',
            label: t.goalAmountField,
          ),
          const SizedBox(height: 14),
          AppDateField(controller: _date, label: t.goalDateField),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.wdgCancel),
        ),
        ParticleFilledButton(onPressed: _save, child: Text(t.wdgSave)),
      ],
    );
  }
}
