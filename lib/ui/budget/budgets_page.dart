import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/budget/budget_forecast.dart';
import '../../domain/budget/budget.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/money.dart';
import '../../domain/utils/dates.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../transactions/transactions_page.dart' show txAccountsProvider;
import '../widgets/common.dart';

/// 预算页 · 信封墙：页首汇总带 + 大屏信封网格（460 定宽两列），
/// 小屏单列。每只信封：剩余大字 + 90% 警戒刻度的进度条 + 额度三拆
/// + 配速预测行。
class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(_budgetEnvelopesProvider);
    final wide = MediaQuery.sizeOf(context).width >= PageMeasure.wide;
    return PageFrame(
      title: t.budgetPageTitle,
      maxWidth: wide ? AppMeasure.workbench : 980,
      fab: ParticleEdge(
        band: 12,
        extendBelow: 6,
        child: FloatingActionButton.extended(
          onPressed: () => _newBudget(context, ref),
          icon: const Icon(Icons.add),
          label: Text(t.budgetCreate),
        ),
      ),
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 36)),
        error: (e, _) => ErrorPlaceholder(t.wdgLoadFailed(e.toString())),
        data: (data) {
          final (envs, base) = data;
          if (envs.isEmpty) {
            return EmptyState(
              icon: Icons.savings_outlined,
              title: t.budgetEmptyTitle,
              message: t.budgetEmptyMessage,
            );
          }
          var limit = BigInt.zero, spent = BigInt.zero;
          var overCount = 0;
          for (final e in envs) {
            limit += e.limitMinor;
            spent += e.spentMinor;
            if (e.remainingMinor.isNegative) overCount++;
          }
          final remaining = limit - spent;
          final brightness = Theme.of(context).brightness;
          final overallRatio = limit == BigInt.zero
              ? 0.0
              : spent.toDouble() / limit.toDouble();
          if (wide) {
            // 大屏工作台：左 = 本月汇总栏（主数「剩余可花」+ 总进度），
            // 右 = 信封网格。
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 300,
                    child: SummaryPanel(
                      title: t.budgetMonthTitle,
                      heroValue: fmtMinor(remaining.abs(), base),
                      heroLabel: remaining.isNegative
                          ? t.budgetOverspentHero
                          : t.budgetRemainingHero,
                      heroColor: remaining.isNegative
                          ? AppColors.negativeOf(brightness)
                          : AppColors.positiveOf(brightness),
                      rows: [
                        SummaryRow(t.budgetTotalLimit, fmtMinor(limit, base)),
                        SummaryRow(t.budgetSpent, fmtMinor(spent, base)),
                        if (overCount > 0)
                          SummaryRow(
                            t.budgetOverEnvelopes,
                            t.budgetEnvelopeCount(overCount),
                            color: AppColors.negativeOf(brightness),
                          ),
                      ],
                      footer: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProgressMeter(
                            ratio: overallRatio,
                            over: remaining.isNegative,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.budgetTotalUsagePct(
                              (overallRatio * 100).toStringAsFixed(0),
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Theme.of(context).hintColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: PageMeasure.gutter),
                  Expanded(
                    child: CardWrap(
                      tileWidth: 460,
                      children: [
                        for (final e in envs) _EnvelopeCard(envelope: e, base: base),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              StatBand(
                items: [
                  StatBandItem(t.budgetMonthTotalLimit, fmtMinor(limit, base)),
                  StatBandItem(t.budgetSpent, fmtMinor(spent, base)),
                  StatBandItem(
                    t.budgetRemaining,
                    fmtMinor(remaining, base),
                    color: remaining.isNegative
                        ? AppColors.negativeOf(brightness)
                        : AppColors.positiveOf(brightness),
                  ),
                  if (overCount > 0)
                    StatBandItem(
                      t.budgetOverEnvelopes,
                      t.budgetEnvelopeCount(overCount),
                      color: AppColors.negativeOf(brightness),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              CardWrap(
                tileWidth: 460,
                children: [
                  for (final e in envs) _EnvelopeCard(envelope: e, base: base),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  /// 新建预算弹窗（AppDialog 体系：进场 220ms 淡入放大，退场完整对称）。
  Future<void> _newBudget(BuildContext context, WidgetRef ref) async {
    final ok = await showAppDialog<bool>(
      context,
      builder: (_) => const _BudgetEditDialog(),
    );
    if (ok == true) ref.invalidate(_budgetEnvelopesProvider);
  }
}

/// 单只预算信封：名称 + 剩余（超支为红）+ 警戒刻度进度条 + 三拆瓦片
/// + 配速预测。删除收进右上角溢出菜单（不再裸放垃圾桶图标）。
class _EnvelopeCard extends ConsumerWidget {
  const _EnvelopeCard({required this.envelope, required this.base});

  final BudgetEnvelope envelope;
  final String base;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final e = envelope;
    final over = e.remainingMinor.isNegative;
    final ratio = e.limitMinor == BigInt.zero
        ? 0.0
        : (e.spentMinor.toDouble() / e.limitMinor.toDouble());
    final brightness = theme.brightness;
    // 底缘光尘（docs/12 §9 卡片规范）：信封卡与区块卡同一家族。
    return ParticleEdge(
      band: 22,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    e.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  over
                      ? t.budgetOverAmount(fmtMinor(-e.remainingMinor, base))
                      : t.budgetRemainingAmount(fmtMinor(e.remainingMinor, base)),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: over
                        ? AppColors.negativeOf(brightness)
                        : AppColors.positiveOf(brightness),
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                ParticleMenuButton<String>(
                  tooltip: t.budgetEnvelopeActions,
                  onSelected: (a) => _delete(context, ref),
                  items: [
                    ParticleMenuEntry(
                      value: 'delete',
                      label: t.budgetDelete,
                      icon: Icons.delete_outline,
                      destructive: true,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            ProgressMeter(ratio: ratio, over: over),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AmountTile(
                    label: t.budgetLimit,
                    amount: fmtMinor(e.limitMinor, base),
                  ),
                ),
                Expanded(
                  child: AmountTile(
                    label: t.budgetSpent,
                    amount: fmtMinor(e.spentMinor, base),
                  ),
                ),
                Expanded(
                  child: AmountTile(
                    label: t.budgetPlanned,
                    amount: fmtMinor(e.plannedMinor, base),
                    tooltip: t.budgetPlannedTooltip,
                  ),
                ),
              ],
            ),
            _forecastLine(context, e),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final ok = await confirmDialog(
      context,
      title: t.budgetDeleteConfirmTitle,
      message: t.budgetDeleteConfirmMessage(envelope.name),
      confirmLabel: t.wdgDelete,
      destructive: true,
    );
    if (ok != true) return;
    await s.planning.deleteBudget(envelope.budgetId);
    ref.invalidate(_budgetEnvelopesProvider);
  }

  /// 月中配速预警：外推到月末 + 建议日均可花（月末/无数据时隐藏）。
  Widget _forecastLine(BuildContext context, BudgetEnvelope e) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final forecast = BudgetForecast.of(
      spentMinor: e.spentMinor,
      limitMinor: e.limitMinor,
      daysElapsed: now.day,
      daysInMonth: DateTime(now.year, now.month + 1, 0).day,
    );
    if (forecast == null || forecast.daysLeft <= 0) {
      return const SizedBox.shrink();
    }
    final warn = AppColors.brassOf(theme.brightness);
    final bad = AppColors.negativeOf(theme.brightness);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            forecast.willExceed ? Icons.warning_amber_rounded : Icons.speed,
            size: 16,
            color: forecast.willExceed ? bad : warn,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              forecast.willExceed
                  ? t.budgetForecastExceed(
                      fmtMinor(forecast.projectedMinor, base),
                      fmtMinor(forecast.projectedMinor - e.limitMinor, base),
                    )
                  : t.budgetForecastOk(
                      fmtMinor(forecast.projectedMinor, base),
                      fmtMinor(forecast.suggestedDailyMinor, base),
                    ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: forecast.willExceed ? bad : theme.hintColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _budgetEnvelopesProvider =
    FutureProvider.autoDispose<(List<BudgetEnvelope>, String)>((ref) async {
      final s = sessionOf(ref.watch(vaultProvider));
      if (s == null) return (const <BudgetEnvelope>[], 'CNY');
      final base = await s.statsService.baseCurrency();
      final now = DateTime.now();
      final mk = monthKey(now);
      final budgets = (await s.planning.budgets())
          .where((b) => b.coversMonth(mk))
          .toList();

      // 本月分类已花（消费发生额，含退款冲减）。
      final monthStart = DateTime(now.year, now.month, 1);
      final txs = await s.ledger.list(from: monthStart, to: now);
      final spentByCategory = <String, BigInt>{};
      var totalSpent = BigInt.zero;
      for (final tx in txs) {
        if (tx.kind != TxKind.expense && tx.kind != TxKind.refund) continue;
        if (tx.categoryId == null) continue;
        for (final p in tx.postings) {
          if (p.accountId == tx.categoryId && p.amountMinor != null) {
            spentByCategory[tx.categoryId!] =
                (spentByCategory[tx.categoryId!] ?? BigInt.zero) +
                p.amountMinor!;
            if (!tx.categoryId!.startsWith('sys:')) {
              totalSpent += p.amountMinor!;
            }
          }
        }
      }

      // 本月计划占用（同一分类的计划事件金额）。
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      final plannedByCategory = <String, BigInt>{};
      var totalPlanned = BigInt.zero;
      for (final e in await s.planning.scheduledEvents()) {
        for (final occ in e.expand(monthStart, monthEnd)) {
          if (occ.amountMinor >= BigInt.zero) continue;
          if (occ.date.isBefore(now)) continue;
          if (e.categoryId != null) {
            plannedByCategory[e.categoryId!] =
                (plannedByCategory[e.categoryId!] ?? BigInt.zero) +
                occ.amountMinor.abs();
          }
          totalPlanned += occ.amountMinor.abs();
        }
      }

      final envelopes = <BudgetEnvelope>[];
      for (final b in budgets) {
        final spent = b.scope == BudgetScope.total
            ? totalSpent
            : (spentByCategory[b.categoryId ?? ''] ?? BigInt.zero);
        final planned = b.scope == BudgetScope.total
            ? totalPlanned
            : (plannedByCategory[b.categoryId ?? ''] ?? BigInt.zero);
        envelopes.add(
          BudgetEnvelope(
            budgetId: b.id,
            name: b.name,
            monthKey: mk,
            limitMinor: b.limitMinor,
            carriedInMinor: BigInt.zero,
            spentMinor: spent,
            plannedMinor: planned,
            reservedMinor: BigInt.zero,
            overspentCarryMinor: BigInt.zero,
          ),
        );
      }
      envelopes.sort((a, b) => b.limitMinor.compareTo(a.limitMinor));
      return (envelopes, base);
    });

class _BudgetEditDialog extends ConsumerStatefulWidget {
  const _BudgetEditDialog();

  @override
  ConsumerState<_BudgetEditDialog> createState() => _BudgetEditDialogState();
}

class _BudgetEditDialogState extends ConsumerState<_BudgetEditDialog> {
  final _name = TextEditingController();
  final _limit = TextEditingController();
  BudgetScope _scope = BudgetScope.total;
  String? _categoryId;

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _limit.text.isEmpty) return;
    final now = DateTime.now();
    await s.planning.saveBudget(
      Budget(
        id: 'bud:${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
        name: _name.text.isEmpty
            ? (_scope == BudgetScope.total
                  ? t.budgetMonthlyTotalName
                  : t.budgetCategoryBudget)
            : _name.text.trim(),
        scope: _scope,
        limitMinor: Money.parse(_limit.text, CurrencyInfo.cny).amountMinor,
        currencyCode: 'CNY',
        startMonthKey: monthKey(now),
        categoryId: _scope == BudgetScope.category ? _categoryId : null,
        rollover: RolloverPolicy.none,
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final accounts = ref.watch(txAccountsProvider);
    return AppDialog(
      title: t.budgetCreate,
      scroll: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<BudgetScope>(
            segments: [
              ButtonSegment(
                value: BudgetScope.total,
                label: Text(t.budgetScopeTotal),
              ),
              ButtonSegment(
                value: BudgetScope.category,
                label: Text(t.budgetCategoryBudget),
              ),
            ],
            selected: {_scope},
            onSelectionChanged: (v) => setState(() => _scope = v.first),
          ),
          if (_scope == BudgetScope.category) ...[
            const SizedBox(height: 14),
            accounts.maybeWhen(
              data: (list) => ParticleDropdownField<String>(
                initialValue: _categoryId,
                decoration: InputDecoration(labelText: t.budgetCategoryField),
                items: [
                  for (final a in list.where(
                    (a) => a.type == AccountType.expense && !a.isSystem,
                  ))
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
          const SizedBox(height: 14),
          ParticleTextField(
            controller: _limit,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(labelText: t.budgetMonthlyLimitField),
          ),
          const SizedBox(height: 14),
          ParticleTextField(
            controller: _name,
            decoration: InputDecoration(labelText: t.budgetNameOptionalField),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.wdgCancel),
        ),
        ParticleFilledButton(onPressed: _save, child: Text(t.wdgSave)),
      ],
    );
  }
}
