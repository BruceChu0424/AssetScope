import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/money.dart';
import '../../domain/planning/recurrence.dart';
import '../../domain/utils/dates.dart';
import '../widgets/common.dart';
import 'recurring_sheet.dart';
import 'scenario_sheet.dart';

/// 固定开销与预定支出计划。
class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_plansProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('固定开销 / 计划'),
        actions: [
          IconButton(
            tooltip: '情景模拟 · 现金压力测试',
            icon: const Icon(Icons.shield_outlined),
            onPressed: () => showScenarioSheet(context, ref),
          ),
          IconButton(
            tooltip: '从流水识别固定收支',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () async {
              await showRecurringSheet(context, ref);
              ref.invalidate(_plansProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await showDialog<bool>(
              context: context, builder: (_) => const PlanEditDialog());
          if (ok == true) ref.invalidate(_plansProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('新建计划'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPlaceholder('加载失败：$e'),
        data: (data) {
          final (events, occurrences) = data;
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text('未来 30 天'),
              ),
              for (final o in occurrences.take(12))
                ListTile(
                  dense: true,
                  leading: Text(dateKey(o.date).substring(5)),
                  title: Text(o.eventName),
                  trailing: Text(
                    '${o.amountMinor.isNegative ? '-' : '+'}${fmtMinor(o.amountMinor.abs(), 'CNY')}',
                    style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('全部计划'),
              ),
              for (final e in events)
                ListTile(
                  leading: Icon(e.direction == EventDirection.outflow
                      ? Icons.arrow_outward
                      : Icons.arrow_downward),
                  title: Text(e.name),
                  subtitle: Text(
                      '${e.cadence.labelZh} · ${fmtMinor(e.resolvedAmountMinor(), e.currencyCode)}'
                      '${e.isEstimate ? '（估）' : ''} · ${e.status.name}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final s = sessionOf(ref.read(vaultProvider));
                      if (s == null) return;
                      await s.planning.deleteScheduledEvent(e.id);
                      ref.invalidate(_plansProvider);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

final _plansProvider =
    FutureProvider.autoDispose<(List<ScheduledEvent>, List<Occurrence>)>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) return const (<ScheduledEvent>[], <Occurrence>[]);
  final events = await s.planning.scheduledEvents();
  final now = DateTime.now();
  final through = now.add(const Duration(days: 30));
  final occ = <Occurrence>[];
  for (final e in events) {
    occ.addAll(e.expand(DateTime(now.year, now.month, now.day), through));
  }
  occ.sort((a, b) => a.date.compareTo(b.date));
  return (events, occ);
});

/// 计划编辑对话框（initial 非空时为编辑/预填模式）。
class PlanEditDialog extends ConsumerStatefulWidget {
  const PlanEditDialog({super.key, this.initial});

  final ScheduledEvent? initial;

  @override
  ConsumerState<PlanEditDialog> createState() => _PlanEditDialogState();
}

class _PlanEditDialogState extends ConsumerState<PlanEditDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _amount = TextEditingController(
      text: widget.initial?.amountMinor == null
          ? ''
          : Money.fromMinor(widget.initial!.amountMinor!, CurrencyInfo.cny)
              .format());
  late final TextEditingController _anchor = TextEditingController(
      text: widget.initial == null
          ? dateToday()
          : dateKey(widget.initial!.anchorDate));
  late EventDirection _direction =
      widget.initial?.direction ?? EventDirection.outflow;
  late Cadence _cadence = widget.initial?.cadence ?? Cadence.monthly;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _anchor.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _name.text.isEmpty || _amount.text.isEmpty) return;
    await s.planning.saveScheduledEvent(ScheduledEvent(
      id: widget.initial?.id ??
          'evt:${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      name: _name.text.trim(),
      direction: _direction,
      currencyCode: 'CNY',
      cadence: _cadence,
      intervalValue: widget.initial?.intervalValue ?? 1,
      anchorDate: DateTime.tryParse(_anchor.text) ?? DateTime.now(),
      amountMinor: Money.parse(_amount.text, CurrencyInfo.cny).amountMinor,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建计划'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '名称（如 房租 / 工资）')),
          const SizedBox(height: 8),
          SegmentedButton<EventDirection>(
            segments: const [
              ButtonSegment(value: EventDirection.outflow, label: Text('支出')),
              ButtonSegment(value: EventDirection.inflow, label: Text('收入')),
            ],
            selected: {_direction},
            onSelectionChanged: (v) => setState(() => _direction = v.first),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Cadence>(
            initialValue: _cadence,
            decoration: const InputDecoration(labelText: '周期'),
            items: [
              for (final c in Cadence.values)
                DropdownMenuItem(value: c, child: Text(c.labelZh)),
            ],
            onChanged: (v) => setState(() => _cadence = v!),
          ),
          const SizedBox(height: 8),
          TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '金额（元）')),
          const SizedBox(height: 8),
          TextField(
              controller: _anchor,
              decoration: const InputDecoration(labelText: '起始日（每月此日发生）')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}
