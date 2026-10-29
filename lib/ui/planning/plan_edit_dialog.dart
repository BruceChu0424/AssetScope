import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/money.dart';
import '../../domain/planning/recurrence.dart';
import '../../domain/utils/dates.dart';
import '../transactions/transactions_page.dart' show txAccountsProvider;
import '../widgets/common.dart';
import 'plan_fields.dart';

/// 计划编辑对话框（initial 非空时为编辑模式，保留跳过/覆盖等原有配置）。
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
  late final TextEditingController _end = TextEditingController(
      text: widget.initial?.endDate == null
          ? ''
          : dateKey(widget.initial!.endDate!));
  late EventDirection _direction =
      widget.initial?.direction ?? EventDirection.outflow;
  late Cadence _cadence = widget.initial?.cadence ?? Cadence.monthly;
  String? _payAccountId;
  String? _categoryId;
  late bool _autoPost = widget.initial?.autoPost ?? false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _anchor.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _name.text.isEmpty || _amount.text.isEmpty) return;
    final anchor = DateTime.tryParse(_anchor.text) ?? DateTime.now();
    final end = _end.text.isEmpty ? null : DateTime.tryParse(_end.text);
    final amountMinor =
        Money.parse(_amount.text, CurrencyInfo.cny).amountMinor;
    final editing = widget.initial;
    final saved = editing == null
        ? ScheduledEvent(
            id: 'evt:${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
            name: _name.text.trim(),
            direction: _direction,
            currencyCode: 'CNY',
            cadence: _cadence,
            anchorDate: anchor,
            amountMinor: amountMinor,
            paymentAccountId: _payAccountId,
            categoryId: _categoryId,
            autoPost: _autoPost,
            endDate: end,
          )
        : editing.copyWith(
            name: _name.text.trim(),
            direction: _direction,
            cadence: _cadence,
            anchorDate: anchor,
            amountMinor: amountMinor,
            paymentAccountId: _payAccountId,
            categoryId: _categoryId,
            autoPost: _autoPost,
            endDate: end,
            clearEndDate: end == null,
          );
    await s.planning.saveScheduledEvent(saved);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initial;
    final accountsAsync = ref.watch(txAccountsProvider);
    return AlertDialog(
      title: Text(initial == null ? '新建计划' : '编辑计划'),
      content: accountsAsync.when(
        loading: () => const SizedBox(
            height: 320, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => SizedBox(height: 120, child: Text('$e')),
        data: (accounts) {
          // 与下拉显示一致的默认值：不改选择直接保存也带上账户/分类。
          final payOptions = payableFor(accounts, _direction, 'CNY');
          if (_payAccountId == null ||
              !payOptions.any((a) => a.id == _payAccountId)) {
            _payAccountId = payOptions.isEmpty ? null : payOptions.first.id;
          }
          final catOptions = categoriesFor(accounts, _direction);
          if (_categoryId == null ||
              !catOptions.any((a) => a.id == _categoryId)) {
            _categoryId = catOptions.isEmpty ? null : catOptions.first.id;
          }
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                        labelText: '名称（如 房租 / 工资）')),
                const SizedBox(height: 8),
                SegmentedButton<EventDirection>(
                  segments: const [
                    ButtonSegment(
                        value: EventDirection.outflow, label: Text('支出')),
                    ButtonSegment(
                        value: EventDirection.inflow, label: Text('收入')),
                  ],
                  selected: {_direction},
                  onSelectionChanged: (v) => setState(() {
                    _direction = v.first;
                    _payAccountId = null;
                    _categoryId = null;
                  }),
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
                PlanAccountDropdown(
                  accounts: accounts,
                  direction: _direction,
                  currency: 'CNY',
                  value: _payAccountId,
                  onChanged: (v) => setState(() => _payAccountId = v),
                ),
                const SizedBox(height: 8),
                PlanCategoryDropdown(
                  accounts: accounts,
                  direction: _direction,
                  value: _categoryId,
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 8),
                AppAmountField(
                    controller: _amount, currencyCode: 'CNY'),
                const SizedBox(height: 8),
                AppDateField(
                    controller: _anchor,
                    label: _cadence == Cadence.monthly ? '起始日（每月此日发生）' : '起始日'),
                const SizedBox(height: 8),
                AppDateField(controller: _end, label: '结束日（可选）'),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('到期自动记入账本'),
                  subtitle: const Text('解锁应用时自动落账；已入账/作废不会重复记'),
                  value: _autoPost,
                  onChanged: (v) => setState(() => _autoPost = v),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}
