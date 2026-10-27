import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../widgets/common.dart';
import 'quote_fetch_sheet.dart';

/// 汇率管理：查看各币种对最新汇率 + 手工新增/更新。
Future<void> showFxManagerSheet(
    BuildContext context, WidgetRef ref, VaultUnlocked s) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetCtx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (_, controller) => FutureBuilder(
        future: s.meta.latestFxRates(),
        builder: (bctx, snap) {
          final theme = Theme.of(bctx);
          final rates = snap.data ?? const <FxRate>[];
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text('汇率管理',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('净值折算取"当日或之前最近"的一条；倒序存入即可覆盖历史。',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor)),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('新增汇率'),
                onPressed: () => _editRate(bctx, s),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.travel_explore, size: 18),
                label: const Text('AI 抓取'),
                onPressed: () => showQuoteFetchSheet(bctx, ref),
              ),
              const SizedBox(height: 8),
              if (rates.isEmpty && snap.hasData)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('还没有汇率记录。多币种账户折算需要至少一条对该币种的汇率。',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                ),
              for (final r in rates)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text('${r.from.code} → ${r.to.code}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  title: Text(
                      r.rate.toDecimalString(6),
                      style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()])),
                  subtitle: Text(
                      '${r.asOf.year}-${r.asOf.month.toString().padLeft(2, '0')}-${r.asOf.day.toString().padLeft(2, '0')} · ${r.source}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _editRate(bctx, s,
                        from: r.from.code, to: r.to.code),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

Future<void> _editRate(BuildContext context, VaultUnlocked s,
    {String? from, String? to}) async {
  final fromCtrl = TextEditingController(text: from ?? 'USD');
  final toCtrl = TextEditingController(text: to ?? 'CNY');
  final rateCtrl = TextEditingController();
  final currencies = CurrencyInfo.builtin.map((c) => c.code).toList();
  final ok = await showDialog<bool>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: const Text('录入汇率'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: currencies.contains(fromCtrl.text)
                      ? fromCtrl.text
                      : currencies.first,
                  decoration: const InputDecoration(labelText: '原币种'),
                  items: [
                    for (final c in currencies)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => fromCtrl.text = v!,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 18),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: currencies.contains(toCtrl.text)
                      ? toCtrl.text
                      : currencies.first,
                  decoration: const InputDecoration(labelText: '目标币种'),
                  items: [
                    for (final c in currencies)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => toCtrl.text = v!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: rateCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: '1 原币种 = ? 目标币种（如 7.25）'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('取消')),
        FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('保存')),
      ],
    ),
  );
  if (ok != true) return;
  final t = rateCtrl.text.trim();
  if (t.isEmpty) return;
  try {
    await s.meta.saveFxRate(
      baseCcy: fromCtrl.text,
      quoteCcy: toCtrl.text,
      date: DateTime.now(),
      rate: Rational.parseDecimal(t),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('汇率已保存')));
    }
  } on FormatException {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('汇率格式不正确')));
    }
  }
}
