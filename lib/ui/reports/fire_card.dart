import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/planning/fire.dart';
import '../../services/scenario_service.dart';
import '../widgets/common.dart';
import 'fire_sheet.dart';

/// FIRE 默认参数（可投资净资产 + 近 12 个月储蓄/支出实绩）。
final fireDefaultsProvider =
    FutureProvider.autoDispose<FireDefaults>((ref) async {
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
    return ref.watch(fireDefaultsProvider).when(
          loading: () => const SizedBox(
              height: 60, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => ErrorPlaceholder('加载失败：$e'),
          data: (d) => _card(context, ref, d),
        );
  }

  Widget _card(BuildContext context, WidgetRef ref, FireDefaults d) {
    final theme = Theme.of(context);
    final s = sessionOf(ref.read(vaultProvider))!;
    final plan = FirePlanner.plan(FireInput(
      portfolioMinor: d.investableMinor,
      annualSavingsMinor: d.ttmSavingsMinor,
      annualSpendMinor: d.ttmSpendMinor,
      nominalReturnAnnual: Rational.percent('5'),
      inflationAnnual: Rational.percent('2.5'),
      withdrawalRate: Rational.parseDecimal('0.04'),
    ));
    final base = s.statsService.baseCurrency();
    return SectionCard(
      title: '财务独立（FIRE）',
      trailing: IconButton(
        tooltip: '调整参数与模拟',
        icon: const Icon(Icons.tune, size: 18),
        onPressed: () {
          ref.invalidate(fireDefaultsProvider);
          showFireSheet(context, ref);
        },
      ),
      child: d.ttmSpendMinor == BigInt.zero
          ? Text(
              '记录一段时间的收支后，这里会给出"多少钱可以财务自由"的测算。\n'
              '口径：FI 门槛 = 年支出 ÷ 提取率（4% 法则），可投资净资产 = 净资产 − 固定资产 − 长期权益。',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor, height: 1.6),
            )
          : Column(
              children: [
                FutureBuilder<String>(
                  future: base,
                  builder: (_, snap) => StatRow(
                    label: 'FI 门槛（今天的钱）',
                    value: fmtMinor(plan.fiNumberMinor, snap.data ?? 'CNY'),
                    emphasized: true,
                  ),
                ),
                StatRow(
                    label: '可投资净资产覆盖',
                    value: '${(plan.coverage * 100).toStringAsFixed(0)}%'
                        '${d.monthsOfHistory < 12 ? '（历史 ${d.monthsOfHistory} 个月）' : ''}'),
                StatRow(
                    label: '默认假设下达标',
                    value: plan.yearsToFi == null
                        ? '不可达（提高储蓄或收益假设）'
                        : plan.alreadyFi
                            ? '已达标 🎉'
                            : '≈ ${plan.yearsToFi} 年'),
                const SizedBox(height: 6),
                Text(
                  '默认：名义收益 5% · 通胀 2.5% · 提取率 4% · 储蓄取近 12 个月实绩。点右上角调整并跑蒙特卡洛。',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor, fontSize: 11),
                ),
              ],
            ),
    );
  }
}
