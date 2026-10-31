import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/debt/debt_contract.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/money.dart';
import '../../l10n/app_localizations.dart';
import '../../services/insight_service.dart' show DebtStrategyCompare;
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 雪崩 vs 雪球还款策略对比弹层。
///
/// 雪崩=高利率优先（总利息最少）；雪球=小额优先（心理激励快）。
/// 用户输入"每月额外还款额"，展示两套计划的期数/总利息/还清顺序。
Future<void> showDebtStrategySheet(BuildContext context, WidgetRef ref) async {
  final s = sessionOf(ref.read(vaultProvider));
  if (s == null) return;
  final ctrl = TextEditingController(text: '1000');

  await showAppSheet<void>(
    context,
    scrollControlled: true,
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
      ),
      child: StatefulBuilder(
        builder: (ctx, setState) {
          final t = AppLocalizations.of(ctx);
          Future<DebtStrategyCompare?> simulate() async {
            final amount = ctrl.text.trim().isEmpty
                ? BigInt.zero
                : Money.parse(ctrl.text.trim(), CurrencyInfo.cny).amountMinor;
            try {
              return await s.insightService.debtStrategies(
                extraMonthlyMinor: amount,
              );
            } catch (_) {
              return null;
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.strategyCompareTitle,
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                t.strategySubtitle,
                style: Theme.of(
                  ctx,
                ).textTheme.bodySmall?.copyWith(color: Theme.of(ctx).hintColor),
              ),
              const SizedBox(height: 14),
              AppAmountField(
                controller: ctrl,
                currencyCode: 'CNY',
                label: t.strategyExtraMonthly,
              ),
              const SizedBox(height: 12),
              ParticleFilledButton(
                onPressed: () => setState(() {}),
                child: Text(t.strategyResimulate),
              ),
              const SizedBox(height: 8),
              FutureBuilder<DebtStrategyCompare?>(
                future: simulate(),
                builder: (bctx, snap) {
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final r = snap.data!;
                  if (r.positions.isEmpty) {
                        return Text(t.strategyNoDebt);
                  }
                  final theme = Theme.of(bctx);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _planCard(
                        bctx,
                        title: t.strategyAvalancheTitle,
                        highlight: r.avalancheSaving > BigInt.zero,
                        plan: r.avalanche,
                        positions: r.positions,
                      ),
                      const SizedBox(height: 8),
                      _planCard(
                        bctx,
                        title: t.strategySnowballTitle,
                        highlight: r.avalancheSaving <= BigInt.zero,
                        plan: r.snowball,
                        positions: r.positions,
                      ),
                      if (r.avalancheSaving > BigInt.zero)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            t.strategyAvalancheSaves(
                              fmtMinor(r.avalancheSaving, 'CNY'),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.positiveOf(theme.brightness),
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    ),
  );
}

Widget _planCard(
  BuildContext context, {
  required String title,
  required bool highlight,
  required PayoffPlan plan,
  required List<DebtPosition> positions,
}) {
  final theme = Theme.of(context);
  final t = AppLocalizations.of(context);
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: highlight
          ? theme.colorScheme.primary.withValues(alpha: 0.06)
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: highlight
            ? theme.colorScheme.primary.withValues(alpha: 0.4)
            : theme.dividerColor,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (highlight)
              Icon(Icons.verified, size: 16, color: theme.colorScheme.primary),
          ],
        ),
        const SizedBox(height: 6),
        StatRow(
          label: t.strategyPayoffTime,
          value: t.strategyDuration(plan.months ~/ 12, plan.months % 12),
        ),
        StatRow(
          label: t.strategyTotalInterest,
          value: fmtMinor(plan.totalInterestMinor, 'CNY'),
          emphasized: true,
        ),
        StatRow(
          label: t.strategyPayoffOrder,
          value: [
            for (final i in plan.order.take(4)) positions[i].name,
            if (plan.order.length > 4) '…',
          ].join(' → '),
        ),
      ],
    ),
  );
}
