import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/analytics/personal_cpi.dart';
import '../../domain/utils/dates.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 我的通胀：近 12 个月分类支出 → 固定篮子个人消费指数（docs/11 §8）。
final personalCpiProvider =
    FutureProvider.autoDispose<PersonalCpiResult?>((ref) async {
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
    return ref.watch(personalCpiProvider).when(
          loading: () => const SizedBox(
              height: 60, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => ErrorPlaceholder('加载失败：$e'),
          data: (r) => SectionCard(
            title: '我的通胀 · 近 12 个月',
            child: r == null
                ? Text(
                    '记账满 6 个月后，这里会用你自己的消费篮子计算"你的生活成本通胀"'
                    '（固定篮子口径：维持基期消费结构不变，现在要多花多少）。',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor, height: 1.6),
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
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: r.annualRate > _kAssumedInflation
                                  ? AppColors.negativeOf(theme.brightness)
                                  : AppColors.positiveOf(theme.brightness),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.annualRate > _kAssumedInflation
                                  ? '高于假设通胀 ${(_kAssumedInflation * 100).toStringAsFixed(1)}%'
                                  : '不高于假设通胀 ${(_kAssumedInflation * 100).toStringAsFixed(1)}%',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor),
                            ),
                          ),
                        ],
                      ),
                      if (!r.reliable)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '⚠ 篮子覆盖率 ${(r.basketCoverage * 100).toStringAsFixed(0)}%'
                            '（消费结构变化较大，解读需谨慎）',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.brassOf(theme.brightness)),
                          ),
                        ),
                      const Divider(height: 20),
                      for (final c in r.contributions.take(3))
                        _contributionTile(theme, c),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '基期 ${r.baseMonths} 个月 vs 近期 ${r.recentMonths} 个月的月均支出；'
                          '口径：维持基期消费结构不变的价格指数近似（固定篮子 Laspeyres）。',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              fontSize: 11,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
          ),
        );
  }

  Widget _contributionTile(
      ThemeData theme, ({String categoryId, double share, double ratio}) c) {
    final name = c.categoryId.replaceAll('cat:e:', '');
    final delta = c.share * (c.ratio - 1) * 100;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      subtitle: Text('占篮子 ${(c.share * 100).toStringAsFixed(0)}% · 近期/基期 ×${c.ratio.toStringAsFixed(2)}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.hintColor, fontSize: 11)),
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
