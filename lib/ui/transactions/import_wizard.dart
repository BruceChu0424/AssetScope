import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/import/bill_parsers.dart';
import '../../domain/ledger/account.dart';
import '../../l10n/app_localizations.dart';
import '../../services/import_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'transactions_page.dart' show txAccountsProvider;

/// 账单导入向导：选文件 → 自动识别格式 → 选账户 → 预览（去重+分类建议）→ 入账。
///
/// 微信/支付宝原生账单自动识别（含 GBK 编码）；其他 CSV 需表头含
/// date、type(或 direction)、amount 三列。
Future<void> showImportWizard(BuildContext context, WidgetRef ref) async {
  await showAppDialog<void>(
    context,
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
    rows: [],
    skipped: [],
    suggestions: [],
  );
  String? _accountId;
  String? _expenseCatId;
  String? _incomeCatId;
  int _suggestCount = 0;
  bool _importing = false;
  int? _imported;

  Future<void> _pickFile() async {
    final t = AppLocalizations.of(context);
    final picked = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(label: t.importFileTypeBills, extensions: const ['csv', 'txt']),
      ],
    );
    if (picked == null) return;
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    try {
      final bytes = await File(picked.path).readAsBytes();
      _fileName = picked.name;
      _lastPath = picked.path;
      // 解码（GBK/UTF-8）+ 解析在独立 isolate 执行，大账单不卡 UI。
      _auto = await s.importService.decodeAndParseAutoIsolated(
        bytes,
        genericParserId: picked.name,
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
    final t = AppLocalizations.of(context);
    final accountsAsync = ref.watch(txAccountsProvider);
    return AppDialog(
      title: t.importTitle,
      scroll: true,
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.importStepHeader(_step + 1, _stepTitles()[_step]),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
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
          child: Text(_step == 3 ? t.importStepDone : t.commonCancel),
        ),
        if (_step == 1)
          ParticleFilledButton(
            onPressed: (_accountId != null && _lastPath != null)
                ? _analyze
                : null,
            child: Text(t.importParsePreview),
          ),
        if (_step == 2)
          ParticleFilledButton(
            onPressed:
                (_expenseCatId != null && _incomeCatId != null && !_importing)
                ? _import
                : null,
            child: _importing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.importConfirm),
          ),
      ],
    );
  }

  List<String> _stepTitles() {
    final t = AppLocalizations.of(context);
    return [
      t.importStepPickFile,
      t.importStepChooseAccount,
      t.importStepPreview,
      t.importStepDone,
    ];
  }

  List<Widget> _stepPickFile(ThemeData theme) => [
    Text(
      AppLocalizations.of(context).importPickFileHint,
      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
    ),
    const SizedBox(height: 12),
    OutlinedButton.icon(
      onPressed: _pickFile,
      icon: const Icon(Icons.upload_file),
      label: Text(_fileName ?? AppLocalizations.of(context).importChooseCsvFile),
    ),
    if (_parseError.isNotEmpty) ...[
      const SizedBox(height: 8),
      Text(
        AppLocalizations.of(context).importParseFailed(_parseError),
        style: TextStyle(color: AppColors.negativeOf(theme.brightness)),
      ),
    ],
  ];

  List<Widget> _stepChooseAccount(
    ThemeData theme,
    AsyncValue<List<Account>> accountsAsync,
  ) {
    final t = AppLocalizations.of(context);
    return [
      accountsAsync.maybeWhen(
        data: (accounts) {
          final money = accounts
              .where(
                (a) =>
                    a.type == AccountType.asset && !a.isSystem && !a.isHolding,
              )
              .toList();
          return ParticleDropdownField<String>(
            initialValue: _accountId,
            decoration: InputDecoration(labelText: t.importTargetAccount),
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
          Text(
            t.importFileName('$_fileName'),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text(_auto?.format.label ?? '—'),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          Text(
            t.importRowsDetected(_auto?.rows.length ?? 0),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    ];
  }

  List<Widget> _stepPreview(
    ThemeData theme,
    AsyncValue<List<Account>> accountsAsync,
  ) {
    final t = AppLocalizations.of(context);
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
              ParticleDropdownField<String>(
                initialValue: _expenseCatId,
                decoration: InputDecoration(
                  labelText: t.importDefaultExpenseCategory,
                ),
                items: [
                  for (final a in expenses)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setState(() => _expenseCatId = v),
              ),
              const SizedBox(height: 10),
              ParticleDropdownField<String>(
                initialValue: _incomeCatId,
                decoration: InputDecoration(
                  labelText: t.importDefaultIncomeCategory,
                ),
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
      _previewLine(
        theme,
        t.importReadyToPost,
        t.importLineCount(_preview.rows.length),
        emphasized: true,
      ),
      _previewLine(
        theme,
        t.importExactDuplicates,
        t.importLineCount(_preview.skipped.length),
      ),
      _previewLine(
        theme,
        t.importCategoryHits,
        t.importCategoryHitsDetail(_suggestCount),
      ),
      for (final line in _auto?.skippedLines ?? const <String>[])
        _previewLine(theme, t.importParserSkipped, line),
      if (_preview.suggestions.isNotEmpty)
        _previewLine(
          theme,
          t.importTransferSuggestions,
          t.importTransferSuggestionDetail(_preview.suggestions.length),
        ),
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
              title: Text(
                r.counterparty.isEmpty
                    ? t.importNoCounterparty
                    : r.counterparty,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${r.date.month}/${r.date.day} · ${r.direction ? t.dirIncome : t.dirExpense}',
              ),
              trailing: Text(
                fmtMinor(r.amountMinor, r.currencyCode),
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _previewLine(
    ThemeData theme,
    String label,
    String value, {
    bool emphasized = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _stepDone(ThemeData theme) => [
    Icon(
      Icons.check_circle,
      size: 44,
      color: AppColors.positiveOf(theme.brightness),
    ),
    const SizedBox(height: 10),
    Text(
      AppLocalizations.of(context).importPostedCount(_imported ?? 0),
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 6),
    Text(
      AppLocalizations.of(context).importDoneHint,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.hintColor,
        height: 1.5,
      ),
    ),
  ];
}
