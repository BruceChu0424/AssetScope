import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/analytics/personal_cpi.dart';
import '../../domain/utils/dates.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 我的通胀：近 12 个月分类支出 → 固定篮子个人消费指数（docs/11 §8）。
final personalCpiProvider = FutureProvider.autoDispose<PersonalCpiResult?>((
  ref,
) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) return null;
  final now = DateTime.now();
  final monthly = <(String, Map<String, BigInt>)>[];
  for (var k = 1; k <= 12; k++) {
    final d = DateTime(now.year, now.month - k);
    final r = await s.statsService.monthReport(d.year, d.month);
    monthly.add((monthKey(d), r.expenseByCategory));
  }
  return PersonalCpi.compute(monthly);
});

/// 假设通胀基线（与 FIRE 默认一致），用于对比解读。
const _kAssumedInflation = 0.025;

class PersonalCpiCard extends ConsumerWidget {
  const PersonalCpiCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return ref
        .watch(personalCpiProvider)
        .when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => ErrorPlaceholder(t.loadFailedReports(e.toString())),
          data: (r) => SectionCard(
            title: t.myCpiTitle,
            child: r == null
                ? Text(
                    t.myCpiEmptyHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      height: 1.6,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${(r.annualRate * 100).toStringAsFixed(1)}%',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: r.annualRate > _kAssumedInflation
                                  ? AppColors.negativeOf(theme.brightness)
                                  : AppColors.positiveOf(theme.brightness),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.annualRate > _kAssumedInflation
                                  ? t.aboveAssumedInflation(
                                      (_kAssumedInflation * 100).toStringAsFixed(1),
                                    )
                                  : t.notAboveAssumedInflation(
                                      (_kAssumedInflation * 100).toStringAsFixed(1),
                                    ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!r.reliable)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            t.basketCoverageWarning(
                              (r.basketCoverage * 100).toStringAsFixed(0),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.brassOf(theme.brightness),
                            ),
                          ),
                        ),
                      const Divider(height: 20),
                      for (final c in r.contributions.take(3))
                        _contributionTile(context, theme, c),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          t.cpiMethodNote(r.baseMonths, r.recentMonths),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
  }

  Widget _contributionTile(
    BuildContext context,
    ThemeData theme,
    ({String categoryId, double share, double ratio}) c,
  ) {
    final t = AppLocalizations.of(context);
    final name = c.categoryId.replaceAll('cat:e:', '');
    final delta = c.share * (c.ratio - 1) * 100;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      subtitle: Text(
        t.basketShareHint(
          (c.share * 100).toStringAsFixed(0),
          c.ratio.toStringAsFixed(2),
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.hintColor,
          fontSize: 11,
        ),
      ),
      trailing: Text(
        '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}pp',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: delta >= 0
              ? AppColors.negativeOf(theme.brightness)
              : AppColors.positiveOf(theme.brightness),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
