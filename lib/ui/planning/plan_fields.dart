import 'package:flutter/material.dart';

import '../../domain/ledger/account.dart';
import '../../domain/planning/recurrence.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/runtime_l10n.dart';
import '../widgets/common.dart' show ParticleDropdownField;

/// 计划表单公共件：支付账户与分类的口径过滤 + 下拉。
///
/// 口径与 PlanExecutionService._autoPostCheck 一致：
/// 收入 → 普通资产（非持仓/应收）；支出 → 普通资产或信用卡/负债。
/// 币种必须与计划一致（跨币种计划不支持自动落地）。

List<Account> payableFor(
  List<Account> all,
  EventDirection dir,
  String currency,
) {
  bool plain(Account a) =>
      a.currencyCode == currency &&
      !a.isSystem &&
      !a.isHolding &&
      a.assetSubtype != AssetSubtype.receivable;
  return all.where((a) {
    if (!plain(a)) return false;
    if (dir == EventDirection.inflow) return a.type == AccountType.asset;
    return a.type == AccountType.asset || a.type == AccountType.liability;
  }).toList();
}

List<Account> categoriesFor(List<Account> all, EventDirection dir) => all
    .where(
      (a) =>
          !a.isSystem &&
          a.type ==
              (dir == EventDirection.inflow
                  ? AccountType.income
                  : AccountType.expense),
    )
    .toList();

/// 支付/入账账户下拉。
class PlanAccountDropdown extends StatelessWidget {
  const PlanAccountDropdown({
    super.key,
    required this.accounts,
    required this.direction,
    required this.currency,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final List<Account> accounts;
  final EventDirection direction;
  final String currency;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final options = payableFor(accounts, direction, currency);
    final valid = value != null && options.any((a) => a.id == value);
    return ParticleDropdownField<String>(
      initialValue: valid ? value : (options.isEmpty ? null : options.first.id),
      decoration: InputDecoration(
        labelText: label ?? t.planPayAccount,
        helperText: options.isEmpty ? t.planNoAccountForCurrency(currency) : null,
      ),
      items: [
        for (final a in options)
          DropdownMenuItem(value: a.id, child: Text(a.name)),
      ],
      onChanged: options.isEmpty ? null : onChanged,
    );
  }
}

/// 收入/支出分类下拉。
class PlanCategoryDropdown extends StatelessWidget {
  const PlanCategoryDropdown({
    super.key,
    required this.accounts,
    required this.direction,
    required this.value,
    required this.onChanged,
  });

  final List<Account> accounts;
  final EventDirection direction;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final options = categoriesFor(accounts, direction);
    final valid = value != null && options.any((a) => a.id == value);
    return ParticleDropdownField<String>(
      initialValue: valid ? value : (options.isEmpty ? null : options.first.id),
      decoration: InputDecoration(labelText: t.planCategory),
      items: [
        for (final a in options)
          DropdownMenuItem(value: a.id, child: Text(a.name)),
      ],
      onChanged: options.isEmpty ? null : onChanged,
    );
  }
}

/// 计划状态 → 中文标签。
String planStatusLabel(PlanStatus s) => switch (s) {
  PlanStatus.active => rt('进行中'),
  PlanStatus.paused => rt('已暂停'),
  PlanStatus.finished => rt('已结束'),
  PlanStatus.cancelled => rt('已取消'),
};
