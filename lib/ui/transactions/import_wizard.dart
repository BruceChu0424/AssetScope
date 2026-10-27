import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/import/dedup.dart';
import '../../domain/ledger/account.dart';
import '../../services/import_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'transactions_page.dart' show txAccountsProvider;

/// CSV 账单导入向导：选文件 → 选账户 → 预览（去重+分类建议）→ 入账。
///
/// 表头要求：date, type(或 direction), amount；可选 time, counterparty,
/// note, txid。中文列名可先在导出软件里改列头，或用 wechat/alipay 模板。
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
  List<NormalizedRow> _parsed = const [];
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
      _parsed = s.importService.parseGenericCsv(
        text,
        parserId: picked.name,
        accountId: _accountId ?? 'pending',
      );
      setState(() => _parseError = '');
    } on FormatException catch (e) {
      setState(() => _parseError = e.message);
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _analyze() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _accountId == null || _fileName == null) return;
    _parsed = s.importService.parseGenericCsv(
      s.importService.decode(await File(_lastPath!).readAsBytes()),
      parserId: _fileName!,
      accountId: _accountId!,
    );
    _preview = await s.importService.preview(
      rows: _parsed,
      parserId: _fileName!,
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
        _fileName == null ||
        _expenseCatId == null ||
        _incomeCatId == null) {
      return;
    }
    setState(() => _importing = true);
    final engine = await s.insightService.buildRulesEngine();
    final count = await s.importService.commit(
      rows: _preview.rows,
      parserId: _fileName!,
      accountId: _accountId!,
      expenseCategoryId: _expenseCatId!,
      incomeCategoryId: _incomeCatId!,
      sourceName: 'importCsv',
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
          '支持 UTF-8 / GBK 自动识别的通用 CSV（微信、支付宝、银行导出请先保证表头含 date、type、amount 三列，或改列名）。',
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
      Text('文件：$_fileName · 已识别 ${_parsed.length} 行',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.hintColor)),
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
