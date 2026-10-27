import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/analytics/recurring_detector.dart';
import '../../domain/planning/recurrence.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'plans_page.dart' show PlanEditDialog;

/// 周期识别建议弹层：流水里识别出的固定收支 → 一键固化为计划。
Future<void> showRecurringSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _RecurringSheet(),
  );
}

final _recurringProvider =
    FutureProvider.autoDispose<(List<RecurringSuggestion>, Set<String>)>(
        (ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) return const (<RecurringSuggestion>[], <String>{});
  final suggestions = await s.insightService.recurringSuggestions();
  final existing = (await s.planning.scheduledEvents())
      .map((e) => e.name)
      .toSet();
  return (suggestions, existing);
});

class _RecurringSheet extends ConsumerWidget {
  const _RecurringSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(_recurringProvider);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text('识别到的固定收支',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '从近 18 个月流水中识别（同对手方、间隔规整、≥3 次）。'
              '转为计划后将计入现金预测与预算的"已计划"。',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor, height: 1.5),
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorPlaceholder('加载失败：$e'),
              data: (data) {
                final (suggestions, existing) = data;
                if (suggestions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '暂未识别到固定收支。多记录几个月的房租/订阅/工资等\n规律流水后再来试试。',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.hintColor, height: 1.6),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: suggestions.length,
                  itemBuilder: (_, i) => _SuggestionTile(
                    suggestion: suggestions[i],
                    exists: existing.contains(suggestions[i].label),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends ConsumerWidget {
  const _SuggestionTile({required this.suggestion, required this.exists});

  final RecurringSuggestion suggestion;
  final bool exists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = suggestion;
    final now = DateTime.now();
    return ListTile(
      leading: Icon(
        s.direction ? Icons.arrow_downward : Icons.arrow_outward,
        color: s.direction ? theme.colorScheme.primary : AppColors.negative,
      ),
      title: Text(s.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${s.cadenceLabel} · ${s.occurrences} 次 · 置信 ${(s.confidence * 100).toStringAsFixed(0)}%\n'
        '中位 ${fmtMinor(s.medianAmountMinor, 'CNY')} · 下次预计 ${s.nextExpected(now).month}/${s.nextExpected(now).day}',
        style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
      ),
      isThreeLine: true,
      trailing: exists
          ? Chip(
              label: const Text('已建计划'),
              visualDensity: VisualDensity.compact,
              labelStyle: theme.textTheme.bodySmall,
            )
          : FilledButton.tonal(
              onPressed: () => _convert(context, ref),
              child: const Text('转计划'),
            ),
    );
  }

  Future<void> _convert(BuildContext context, WidgetRef ref) async {
    final session = sessionOf(ref.read(vaultProvider));
    if (session == null) return;
    final now = DateTime.now();
    final (cadence, intervalValue) = suggestion.planCadence(now);
    final draft = ScheduledEvent(
      id: 'evt:${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      name: suggestion.label,
      direction:
          suggestion.direction ? EventDirection.inflow : EventDirection.outflow,
      currencyCode: 'CNY',
      cadence: cadence,
      intervalValue: intervalValue,
      anchorDate: suggestion.nextExpected(now),
      amountMinor: suggestion.medianAmountMinor,
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => PlanEditDialog(initial: draft),
    );
    if (ok == true) ref.invalidate(_recurringProvider);
  }
}
