import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/analytics/health.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_providers.dart';
import '../widgets/common.dart';
import 'health_parts.dart';
import 'overview_anim.dart';
import 'overview_scaffold.dart';

/// 财务体检页：健康评分仪表 + 四维轨道节点 + 目标雷达 + 六项核心指标
/// + 诊断与行动建议。评分由四项真实指标的归一化带通平均而来（口径见
/// InfoHint），数据不足时如实「暂无法评分」并列缺失项——不造分数。
class HealthPage extends ConsumerWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(dashboardProvider);
    return OverviewScaffold(
      title: t.ovHlTitle,
      titleHint: t.ovHlHint,
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 44)),
        error: (e, _) => Center(child: ErrorPlaceholder(t.homeLoadFailed(e))),
        data: (d) => _HealthBody(h: d.insights.health, d: d),
      ),
    );
  }
}

/// 各维度归一化得分（0..1）与目标带（口径唯一实现点，指标卡/雷达/
/// 评分共用）。
class HlDim {
  const HlDim({
    required this.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.valueText,
    required this.targetText,
    required this.score,
  });

  final String key;
  final IconData icon;
  final String label;
  final String hint;
  final String valueText;
  final String targetText;

  /// null = 数据不足。
  final double? score;
}

List<HlDim> hlDims(BuildContext context, FinancialHealth h) {
  final t = AppLocalizations.of(context);
  String pct(double? v) => v == null ? '—' : '${(v * 100).toStringAsFixed(0)}%';
  return [
    HlDim(
      key: 'save',
      icon: Icons.savings_outlined,
      label: t.dashSavingsRate,
      hint: t.dashSavingsRateHint,
      valueText: pct(h.savingsRate),
      targetText: t.ovHlTargetSave,
      score: h.savingsRate == null
          ? null
          : (h.savingsRate! / 0.30).clamp(0.0, 1.0),
    ),
    HlDim(
      key: 'emergency',
      icon: Icons.health_and_safety_outlined,
      label: t.dashEmergencyMonths,
      hint: t.dashEmergencyMonthsHint,
      valueText: h.emergencyMonths == null
          ? '—'
          : h.emergencyMonths!.toStringAsFixed(1),
      targetText: t.ovHlTargetEmergency,
      score: h.emergencyMonths == null
          ? null
          : (h.emergencyMonths! / 6).clamp(0.0, 1.0),
    ),
    HlDim(
      key: 'leverage',
      icon: Icons.scale_outlined,
      label: t.dashDebtToAsset,
      hint: t.dashDebtToAssetHint,
      valueText: pct(h.debtToAsset),
      targetText: t.ovHlTargetLeverage,
      score: h.debtToAsset == null
          ? null
          : (1 - h.debtToAsset! / 0.5).clamp(0.0, 1.0),
    ),
    HlDim(
      key: 'cushion',
      icon: Icons.waves_outlined,
      label: t.ovHlCushion,
      hint: t.ovHlCushionHint,
      valueText: h.passiveCushion == null
          ? '—'
          : '${(h.passiveCushion! * 100).toStringAsFixed(0)}%',
      targetText: t.ovHlTargetCushion,
      score: h.passiveCushion?.clamp(0.0, 1.0),
    ),
  ];
}

double? hlScore(List<HlDim> dims) {
  final scores = [
    for (final d in dims)
      if (d.score != null) d.score!,
  ];
  if (scores.isEmpty) return null;
  return scores.average;
}

extension on List<double> {
  double get average => isEmpty ? 0 : fold(0.0, (a, b) => a + b) / length;
}

class _HealthBody extends StatelessWidget {
  const _HealthBody({required this.h, required this.d});

  final FinancialHealth h;
  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final dims = hlDims(context, h);
    final score = hlScore(dims);
    final width = MediaQuery.sizeOf(context).width;

    Widget row1 = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 2, child: ScorePanel(score: score, dims: dims)),
        const SizedBox(width: 14),
        Expanded(flex: 3, child: OrbitPanel(dims: dims, score: score)),
        const SizedBox(width: 14),
        Expanded(flex: 2, child: RadarPanel(dims: dims)),
      ],
    );
    Widget row2 = MetricRow(dims: dims, d: d);
    Widget row3 = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: DiagnosisPanel(dims: dims, d: d)),
        const SizedBox(width: 14),
        Expanded(child: ActionPanel(dims: dims, d: d)),
      ],
    );

    if (width < 1120) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: SingleChildScrollView(
          child: OvStaggerColumn(
            gap: 12,
            children: [
              SizedBox(height: 300, child: ScorePanel(score: score, dims: dims)),
              SizedBox(height: 330, child: OrbitPanel(dims: dims, score: score)),
              SizedBox(height: 300, child: RadarPanel(dims: dims)),
              MetricRow(dims: dims, d: d),
              DiagnosisPanel(dims: dims, d: d),
              SizedBox(height: 320, child: ActionPanel(dims: dims, d: d)),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: SingleChildScrollView(
        child: OvStaggerColumn(
          gap: 14,
          children: [
            SizedBox(height: 360, child: row1),
            row2,
            SizedBox(height: 320, child: row3),
          ],
        ),
      ),
    );
  }
}

/// 评分状态语。
(String, Color) hlStatusOf(BuildContext context, double? score) {
  final t = AppLocalizations.of(context);
  if (score == null) return (t.ovHlNoScore, const Color(0xFF71859D));
  if (score >= 0.8) return (t.ovHlExcellent, const Color(0xFF8FBCE8));
  if (score >= 0.6) return (t.ovHlGood, const Color(0xFF7EA6D9));
  if (score >= 0.4) return (t.ovHlAttention, const Color(0xFFD8BE85));
  return (t.ovHlRisk, const Color(0xFFF0907C));
}

/// 找出最弱的维度（行动建议排序用）。
List<HlDim> hlWeakest(List<HlDim> dims) {
  final scored = [
    for (final d in dims)
      if (d.score != null) d,
  ]..sort((a, b) => a.score!.compareTo(b.score!));
  return scored;
}

/// 供轨道/雷达复用的「建议目标」标签换行规避（短词直接展示）。
String hlTargetShort(HlDim d) => d.targetText;

double hlOrbitAngle(int i, int n) => -math.pi / 2 + 2 * math.pi * i / n;
