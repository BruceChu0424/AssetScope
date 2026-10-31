import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/money.dart';
import '../../domain/planning/recurrence.dart';
import '../../domain/utils/dates.dart';
import '../../l10n/app_localizations.dart';
import '../../services/plan_execution_service.dart';
import '../transactions/transactions_page.dart' show txAccountsProvider;
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'plan_fields.dart';

/// 计划落地确认弹层：金额/账户/分类可改；落账日固定为发生日（月报归属正确）。
///
/// 返回 true 表示发生了变化（已入账或已跳过），调用方刷新清单。
Future<bool> showPlanPostSheet(
  BuildContext context,
  WidgetRef ref,
  DueOccurrence d,
) async {
  final changed = await showAppSheet<bool>(
    context,
    scrollControlled: true,
    builder: (_) => _PlanPostSheet(d: d),
  );
  return changed == true;
}

class _PlanPostSheet extends ConsumerStatefulWidget {
  const _PlanPostSheet({required this.d});

  final DueOccurrence d;

  @override
  ConsumerState<_PlanPostSheet> createState() => _PlanPostSheetState();
}

class _PlanPostSheetState extends ConsumerState<_PlanPostSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: Money.fromMinor(
      widget.d.occurrence.amountMinor.abs(),
      CurrencyInfo.cny,
    ).format(),
  );
  String? _payAccountId;
  String? _categoryId;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_saving) return;
    final t = AppLocalizations.of(context);
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _payAccountId == null) return;
    final amountText = _amount.text.trim();
    if (amountText.isEmpty) return;
    setState(() => _saving = true);
    try {
      await s.planExecution.postOne(
        widget.d,
        amountMinor: Money.parse(amountText, CurrencyInfo.cny).amountMinor,
        payAccountId: _payAccountId,
        categoryId: _categoryId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.planPostFailed(e.toString()))));
      }
    }
  }

  Future<void> _skip() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    await s.planExecution.skip(widget.d);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final e = widget.d.event;
    final isIncome = e.direction == EventDirection.inflow;
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(txAccountsProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_outward,
                    size: 18,
                    color: isIncome
                        ? AppColors.positiveOf(theme.brightness)
                        : AppColors.negativeOf(theme.brightness),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.planPostTitle(e.name),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${t.planPostDateNote(dateKey(widget.d.occurrence.date))}'
                '${widget.d.occurrence.isEstimate ? t.planPostEstimateNote : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 16),
              accountsAsync.when(
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Text(t.planAccountsLoadFailed(err.toString())),
                data: (accounts) {
                  // 下拉显示的初始值同步到状态：不改选择直接确认也能入账。
                  final payOptions = payableFor(
                    accounts,
                    e.direction,
                    e.currencyCode,
                  );
                  if (_payAccountId == null ||
                      !payOptions.any((a) => a.id == _payAccountId)) {
                    _payAccountId = payOptions.isEmpty
                        ? null
                        : (e.paymentAccountId != null &&
                                  payOptions.any(
                                    (a) => a.id == e.paymentAccountId,
                                  )
                              ? e.paymentAccountId
                              : payOptions.first.id);
                  }
                  final catOptions = categoriesFor(accounts, e.direction);
                  if (_categoryId == null ||
                      !catOptions.any((a) => a.id == _categoryId)) {
                    _categoryId = catOptions.isEmpty
                        ? null
                        : (e.categoryId != null &&
                                  catOptions.any((a) => a.id == e.categoryId)
                              ? e.categoryId
                              : catOptions.first.id);
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlanAccountDropdown(
                        accounts: accounts,
                        direction: e.direction,
                        currency: e.currencyCode,
                        value: _payAccountId,
                        label: isIncome ? t.planIncomeAccount : t.planPayAccount,
                        onChanged: (v) => setState(() => _payAccountId = v),
                      ),
                      const SizedBox(height: 12),
                      PlanCategoryDropdown(
                        accounts: accounts,
                        direction: e.direction,
                        value: _categoryId,
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              AppAmountField(controller: _amount, currencyCode: e.currencyCode),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(onPressed: _skip, child: Text(t.planSkipOnce)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(t.cancel),
                  ),
                  const SizedBox(width: 8),
                  ParticleFilledButton(
                    onPressed: _post,
                    child: Text(_saving ? t.planPosting : t.planPostNow),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
