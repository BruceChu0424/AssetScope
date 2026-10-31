import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/planning/fire.dart';
import '../../l10n/app_localizations.dart';
import '../../services/scenario_service.dart';
import '../widgets/common.dart';
import 'fire_sheet.dart';

/// FIRE 默认参数（可投资净资产 + 近 12 个月储蓄/支出实绩）。
final fireDefaultsProvider = FutureProvider.autoDispose<FireDefaults>((
  ref,
) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) throw StateError('locked');
  return s.scenarios.fireDefaults();
});

/// FIRE 卡：财务独立门槛与进度（默认假设，点开弹层可调全部参数）。
/// 参数弹层（含蒙特卡洛/敏感性）见 fire_sheet.dart。
class FireCard extends ConsumerWidget {
  const FireCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return ref
        .watch(fireDefaultsProvider)
        .when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => ErrorPlaceholder(t.loadFailedReports(e.toString())),
          data: (d) => _card(context, ref, d),
        );
  }

  Widget _card(BuildContext context, WidgetRef ref, FireDefaults d) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final s = sessionOf(ref.read(vaultProvider))!;
    final plan = FirePlanner.plan(
      FireInput(
        portfolioMinor: d.investableMinor,
        annualSavingsMinor: d.ttmSavingsMinor,
        annualSpendMinor: d.ttmSpendMinor,
        nominalReturnAnnual: Rational.percent('5'),
        inflationAnnual: Rational.percent('2.5'),
        withdrawalRate: Rational.parseDecimal('0.04'),
      ),
    );
    final base = s.statsService.baseCurrency();
    return SectionCard(
      title: t.fireTitle,
      trailing: IconButton(
        tooltip: t.fireTuneTooltip,
        icon: const Icon(Icons.tune, size: 18),
        onPressed: () {
          ref.invalidate(fireDefaultsProvider);
          showFireSheet(context, ref);
        },
      ),
      child: d.ttmSpendMinor == BigInt.zero
              ? Text(
                  t.fireEmptyHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                height: 1.6,
              ),
            )
          : Column(
              children: [
                FutureBuilder<String>(
                  future: base,
                  builder: (_, snap) => StatRow(
                    label: t.fiNumberToday,
                    value: fmtMinor(plan.fiNumberMinor, snap.data ?? 'CNY'),
                    emphasized: true,
                  ),
                ),
                StatRow(
                  label: t.investableCoverage,
                  value:
                      '${(plan.coverage * 100).toStringAsFixed(0)}%'
                      '${d.monthsOfHistory < 12 ? t.coverageHistoryMonths(d.monthsOfHistory) : ''}',
                ),
                StatRow(
                  label: t.fiTimeToReach,
                  value: plan.yearsToFi == null
                      ? t.fiUnreachable
                      : plan.alreadyFi
                      ? t.fiReached
                      : t.fiYearsAway(plan.yearsToFi!),
                ),
                const SizedBox(height: 6),
                Text(
                  t.fireDefaultsNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
    );
  }
}
