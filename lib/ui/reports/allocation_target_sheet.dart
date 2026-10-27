import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/invest/allocation.dart';
import 'allocation_card.dart';

/// 目标配置编辑：逐类整数百分比（0–100），合计 ≤ 100%，
/// 未设目标的类不参与再平衡建议。
Future<void> showAllocationTargetSheet(
    BuildContext context, WidgetRef ref, TargetAllocation current) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TargetSheet(current: current),
  ).then((_) => ref.invalidate(allocationProvider));
}

class _TargetSheet extends ConsumerStatefulWidget {
  const _TargetSheet({required this.current});

  final TargetAllocation current;

  @override
  ConsumerState<_TargetSheet> createState() => _TargetSheetState();
}

class _TargetSheetState extends ConsumerState<_TargetSheet> {
  late final Map<AllocationClass, TextEditingController> _ctrls = {
    for (final c in AllocationClass.values)
      c: TextEditingController(text: widget.current[c]?.toString() ?? ''),
  };

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _sum => _parsed.values.fold(0, (a, b) => a + b);

  /// 解析后的目标（空输入视为不设目标）。
  Map<AllocationClass, int> get _parsed {
    final m = <AllocationClass, int>{};
    for (final e in _ctrls.entries) {
      final t = e.value.text.trim();
      if (t.isEmpty) continue;
      final v = int.tryParse(t);
      if (v != null && v >= 0 && v <= 100) m[e.key] = v;
    }
    return m;
  }

  bool get _valid =>
      _parsed.length == _ctrls.entries.where((e) => e.value.text.trim().isNotEmpty).length &&
      _sum <= 100;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('目标配置', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '各类占全部资产的百分比，合计 ≤ 100%。留空 = 不设目标（不参与再平衡提醒）。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final c in AllocationClass.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(c.labelZh)),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: _ctrls[c],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            decoration: const InputDecoration(
                              suffixText: '%',
                              isDense: true,
                              counterText: '',
                            ),
                            maxLength: 3,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _sum > 100 ? '合计 $_sum%（超过 100%）' : '合计 $_sum% · 未设目标/未分配 ${100 - _sum}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _sum > 100 ? theme.colorScheme.error : theme.hintColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: _valid
                    ? () async {
                        final s = sessionOf(ref.read(vaultProvider));
                        if (s == null) return;
                        await s.portfolioAnalytics
                            .setTargetAllocation(TargetAllocation(_parsed));
                        if (context.mounted) Navigator.pop(context);
                      }
                    : null,
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
