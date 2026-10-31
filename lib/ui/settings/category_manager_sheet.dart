import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/import/category_rules.dart';
import '../../domain/ledger/account.dart';
import '../widgets/common.dart';

/// 分类与规则管理：收支分类增删改 + 商户关键词规则。
Future<void> showCategoryManagerSheet(
  BuildContext context,
  WidgetRef ref,
  VaultUnlocked s,
) async {
  await showAppSheet<void>(
    context,
    scrollControlled: true,
    builder: (sheetCtx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (_, controller) => FutureBuilder(
        future: Future.wait([
          s.accounts.all(),
          s.insightService.categoryRules(),
        ]),
        builder: (bctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounts = snap.data![0] as List<Account>;
          var rules = [...snap.data![1] as List<CategoryRule>];
          final theme = Theme.of(bctx);
          final t = AppLocalizations.of(bctx);
          return StatefulBuilder(
            builder: (ctx, setState) {
              final expenses = accounts
                  .where((a) => a.type == AccountType.expense && !a.isSystem)
                  .toList();
              final incomes = accounts
                  .where((a) => a.type == AccountType.income && !a.isSystem)
                  .toList();
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Text(
                    t.categoryManagerTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.categoryRulePriorityHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _groupHeader(
                    ctx,
                    t.categoryExpenseGroup,
                    () => _addCategory(
                      ctx,
                      s,
                      AccountType.expense,
                      () => setState(() {}),
                    ),
                  ),
                  for (final c in expenses)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () =>
                            _renameCategory(ctx, s, c, () => setState(() {})),
                      ),
                    ),
                  _groupHeader(
                    ctx,
                    t.categoryIncomeGroup,
                    () => _addCategory(
                      ctx,
                      s,
                      AccountType.income,
                      () => setState(() {}),
                    ),
                  ),
                  for (final c in incomes)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () =>
                            _renameCategory(ctx, s, c, () => setState(() {})),
                      ),
                    ),
                  const Divider(height: 28),
                  _groupHeader(
                    ctx,
                    t.categoryKeywordRules,
                    () => _addRule(
                      ctx,
                      s,
                      accounts,
                      rules,
                      onSave: (r) => setState(() => rules = r),
                    ),
                  ),
                  if (rules.isEmpty)
                    Text(
                      t.categoryNoRulesHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  for (final r in rules)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        t.categoryRuleKeyword(r.keyword),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      title: Text(
                        accounts
                            .firstWhere(
                              (a) => a.id == r.categoryId,
                              orElse: () => accounts.first,
                            )
                            .name,
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () async {
                          final next = [...rules]..remove(r);
                          await s.insightService.saveCategoryRules(next);
                          setState(() => rules = next);
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    ),
  );
}

Widget _groupHeader(BuildContext ctx, String title, VoidCallback onAdd) {
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              ctx,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(icon: const Icon(Icons.add, size: 20), onPressed: onAdd),
      ],
    ),
  );
}

Future<void> _addCategory(
  BuildContext ctx,
  VaultUnlocked s,
  AccountType type,
  VoidCallback refresh,
) async {
  final t = AppLocalizations.of(ctx);
  final ctrl = TextEditingController();
  final ok = await showAppDialog<bool>(
    ctx,
    builder: (dctx) => AppDialog(
      title: type == AccountType.expense
          ? t.categoryAddExpense
          : t.categoryAddIncome,
      content: ParticleTextField(controller: ctrl, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dctx, false),
          child: Text(t.settingsCancel),
        ),
        ParticleFilledButton(
          onPressed: () => Navigator.pop(dctx, true),
          child: Text(t.settingsSave),
        ),
      ],
    ),
  );
  if (ok != true || ctrl.text.trim().isEmpty) return;
  final prefix = type == AccountType.expense ? 'cat:e' : 'cat:i';
  final id =
      '$prefix:${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
  await s.accounts.upsert(
    Account(id: id, name: ctrl.text.trim(), type: type, currencyCode: 'CNY'),
  );
  refresh();
}

Future<void> _renameCategory(
  BuildContext ctx,
  VaultUnlocked s,
  Account account,
  VoidCallback refresh,
) async {
  final t = AppLocalizations.of(ctx);
  final ctrl = TextEditingController(text: account.name);
  final ok = await showAppDialog<bool>(
    ctx,
    builder: (dctx) => AppDialog(
      title: t.categoryRename,
      content: ParticleTextField(controller: ctrl, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dctx, false),
          child: Text(t.settingsCancel),
        ),
        ParticleFilledButton(
          onPressed: () => Navigator.pop(dctx, true),
          child: Text(t.settingsSave),
        ),
      ],
    ),
  );
  if (ok != true || ctrl.text.trim().isEmpty) return;
  await s.accounts.upsert(
    Account(
      id: account.id,
      name: ctrl.text.trim(),
      type: account.type,
      currencyCode: account.currencyCode,
      isSystem: account.isSystem,
    ),
  );
  refresh();
}

Future<void> _addRule(
  BuildContext ctx,
  VaultUnlocked s,
  List<Account> accounts,
  List<CategoryRule> rules, {
  required void Function(List<CategoryRule>) onSave,
}) async {
  final t = AppLocalizations.of(ctx);
  final kw = TextEditingController();
  String? catId;
  final cats = accounts
      .where(
        (a) =>
            (a.type == AccountType.expense || a.type == AccountType.income) &&
            !a.isSystem,
      )
      .toList();
  final ok = await showAppDialog<bool>(
    ctx,
    builder: (dctx) => StatefulBuilder(
      builder: (d2, setState) => AppDialog(
        title: t.categoryAddRule,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ParticleTextField(
              controller: kw,
              autofocus: true,
              decoration: InputDecoration(labelText: t.categoryRuleKeywordLabel),
            ),
            const SizedBox(height: 12),
            ParticleDropdownField<String>(
              initialValue: catId,
              decoration: InputDecoration(labelText: t.categoryRuleTargetLabel),
              items: [
                for (final c in cats)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => catId = v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(t.settingsCancel),
          ),
          ParticleFilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(t.settingsSave),
          ),
        ],
      ),
    ),
  );
  if (ok != true || kw.text.trim().isEmpty || catId == null) return;
  final next = [
    ...rules,
    CategoryRule(keyword: kw.text.trim(), categoryId: catId!),
  ];
  await s.insightService.saveCategoryRules(next);
  onSave(next);
}
