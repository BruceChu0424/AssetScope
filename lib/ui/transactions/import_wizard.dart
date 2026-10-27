import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/import/bill_parsers.dart';
import '../../domain/ledger/account.dart';
import '../../services/import_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'transactions_page.dart' show txAccountsProvider;

/// 账单导入向导：选文件 → 自动识别格式 → 选账户 → 预览（去重+分类建议）→ 入账。
///
/// 微信/支付宝原生账单自动识别（含 GBK 编码）；其他 CSV 需表头含
/// date、type(或 direction)、amount 三列。
Future<void> showImportWizard(BuildContext context, WidgetRef ref) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ImportWizard(),
  );
  ref.invalidate(txAccountsProvider);
}

class _ImportWizard extends ConsumerStatefulWidget {
  const _ImportWizard();

  @override
  ConsumerState<_ImportWizard> createState() => _ImportWizardState();
}

class _ImportWizardState extends ConsumerState<_ImportWizard> {
  int _step = 0;
  String? _fileName;
  String? _lastPath;
  AutoParsed? _auto;
  String _parseError = '';
  ImportPreview _preview = const ImportPreview(
      rows: [], skipped: [], suggestions: []);
  String? _accountId;
  String? _expenseCatId;
  String? _incomeCatId;
  int _suggestCount = 0;
  bool _importing = false;
  int? _imported;

  Future<void> _pickFile() async {
    final picked = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: '账单', extensions: ['csv', 'txt']),
    ]);
    if (picked == null) return;
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    try {
      final bytes = await File(picked.path).readAsBytes();
      final text = s.importService.decode(bytes);
      _fileName = picked.name;
      _lastPath = picked.path;
      _auto = s.importService.parseAuto(text, genericParserId: picked.name);
      setState(() => _parseError = '');
    } on FormatException catch (e) {
      setState(() => _parseError = e.message);
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _analyze() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _accountId == null || _auto == null) return;
    _preview = await s.importService.preview(
      rows: _auto!.rows,
      parserId: _auto!.parserId,
      accountId: _accountId!,
    );
    // 分类建议统计（规则 + 历史学习）。
    final engine = await s.insightService.buildRulesEngine();
    var hits = 0;
    for (final row in _preview.rows) {
      if (engine.match(row.counterparty) != null) hits++;
    }
    setState(() {
      _suggestCount = hits;
      _step = 2;
    });
  }

  Future<void> _import() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null ||
        _accountId == null ||
        _auto == null ||
        _expenseCatId == null ||
        _incomeCatId == null) {
      return;
    }
    setState(() => _importing = true);
    final engine = await s.insightService.buildRulesEngine();
    final sourceName = switch (_auto!.format) {
      BillFormat.wechat => 'importWechat',
      BillFormat.alipay => 'importAlipay',
      BillFormat.generic => 'importCsv',
    };
    final count = await s.importService.commit(
      rows: _preview.rows,
      parserId: _auto!.parserId,
      accountId: _accountId!,
      expenseCategoryId: _expenseCatId!,
      incomeCategoryId: _incomeCatId!,
      sourceName: sourceName,
      resolveCategory: (row) => engine.match(row.counterparty)?.categoryId,
    );
    setState(() {
      _importing = false;
      _imported = count;
      _step = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(txAccountsProvider);
    return AlertDialog(
      title: const Text('导入账单'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('第 ${_step + 1}/4 步 · ${_stepTitles[_step]}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor)),
              const SizedBox(height: 12),
              ...switch (_step) {
                0 => _stepPickFile(theme),
                1 => _stepChooseAccount(theme, accountsAsync),
                2 => _stepPreview(theme, accountsAsync),
                _ => _stepDone(theme),
              },
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_step == 3 ? '完成' : '取消'),
        ),
        if (_step == 1)
          FilledButton(
            onPressed: (_accountId != null && _lastPath != null)
                ? _analyze
                : null,
            child: const Text('解析预览'),
          ),
        if (_step == 2)
          FilledButton(
            onPressed: (_expenseCatId != null && _incomeCatId != null && !_importing)
                ? _import
                : null,
            child: _importing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('确认入账'),
          ),
      ],
    );
  }

  static const _stepTitles = [
    '选择文件',
    '选择账户',
    '预览与分类',
    '完成',
  ];

  List<Widget> _stepPickFile(ThemeData theme) => [
        Text(
          '微信 / 支付宝导出的原生账单（CSV，GBK 或 UTF-8）自动识别列名与交易单号，无需改表头；其他 CSV 需表头含 date、type、amount 三列。',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_file),
          label: Text(_fileName ?? '选择 CSV 文件'),
        ),
        if (_parseError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('解析失败：$_parseError',
              style: TextStyle(color: AppColors.negativeOf(theme.brightness))),
        ],
      ];

  List<Widget> _stepChooseAccount(
      ThemeData theme, AsyncValue<List<Account>> accountsAsync) {
    return [
      accountsAsync.maybeWhen(
        data: (accounts) {
          final money = accounts
              .where((a) =>
                  a.type == AccountType.asset &&
                  !a.isSystem &&
                  !a.isHolding)
              .toList();
          return DropdownButtonFormField<String>(
            initialValue: _accountId,
            decoration: const InputDecoration(labelText: '入到哪个账户'),
            items: [
              for (final a in money)
                DropdownMenuItem(value: a.id, child: Text(a.name)),
            ],
            onChanged: (v) => setState(() => _accountId = v),
          );
        },
        orElse: () => const CircularProgressIndicator(),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Text('文件：$_fileName',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor)),
          const SizedBox(width: 8),
          Chip(
            label: Text(_auto?.format.label ?? '—'),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          Text('已识别 ${_auto?.rows.length ?? 0} 行',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor)),
        ],
      ),
    ];
  }

  List<Widget> _stepPreview(
      ThemeData theme, AsyncValue<List<Account>> accountsAsync) {
    return [
      accountsAsync.maybeWhen(
        data: (accounts) {
          final expenses = accounts
              .where((a) => a.type == AccountType.expense && !a.isSystem)
              .toList();
          final incomes = accounts
              .where((a) => a.type == AccountType.income && !a.isSystem)
              .toList();
          _expenseCatId ??= expenses.firstOrNull?.id;
          _incomeCatId ??= incomes.firstOrNull?.id;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _expenseCatId,
                decoration:
                    const InputDecoration(labelText: '支出默认分类'),
                items: [
                  for (final a in expenses)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setState(() => _expenseCatId = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _incomeCatId,
                decoration: const InputDecoration(labelText: '收入默认分类'),
                items: [
                  for (final a in incomes)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setState(() => _incomeCatId = v),
              ),
            ],
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
      const SizedBox(height: 12),
      _previewLine(theme, '可入账', '${_preview.rows.length} 行',
          emphasized: true),
      _previewLine(theme, '精确重复跳过', '${_preview.skipped.length} 行'),
      _previewLine(theme, '智慧分类命中', '$_suggestCount 行（规则+历史学习）'),
      for (final line in _auto?.skippedLines ?? const <String>[])
        _previewLine(theme, '原生解析跳过', line),
      if (_preview.suggestions.isNotEmpty)
        _previewLine(theme, '转账配对建议', '${_preview.suggestions.length} 条（导入后可在流水页人工合并）'),
      const SizedBox(height: 8),
      SizedBox(
        height: 180,
        child: ListView.builder(
          itemCount: _preview.rows.length,
          itemBuilder: (_, i) {
            final r = _preview.rows[i];
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(r.counterparty.isEmpty ? '(无对方)' : r.counterparty,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  '${r.date.month}/${r.date.day} · ${r.direction ? '收入' : '支出'}'),
              trailing: Text(
                fmtMinor(r.amountMinor, r.currencyCode),
                style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()]),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _previewLine(ThemeData theme, String label, String value,
      {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
        ],
      ),
    );
  }

  List<Widget> _stepDone(ThemeData theme) => [
        Icon(Icons.check_circle,
            size: 44, color: AppColors.positiveOf(theme.brightness)),
        const SizedBox(height: 10),
        Text('已入账 $_imported 笔',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          '重复导入同一文件会自动跳过（外部 ID 幂等）。对手方分类已被学习，下次导入会自动建议。',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.hintColor, height: 1.5),
        ),
      ];
}
