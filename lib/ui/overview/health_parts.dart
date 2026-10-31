import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_providers.dart';
import '../widgets/common.dart';
import 'health_page.dart' show HlDim, hlStatusOf, hlWeakest;
import 'overview_anim.dart';
import 'overview_charts.dart';
import 'overview_scaffold.dart';

/// 财务体检部件：评分仪表面板 / 四维轨道 / 雷达 / 指标行 / 诊断 / 行动。

/// 左：评分仪表（OvScoreGauge + 状态语 + 数据状态提示）。
class ScorePanel extends StatelessWidget {
  const ScorePanel({super.key, required this.score, required this.dims});

  final double? score;
  final List<HlDim> dims;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (status, color) = hlStatusOf(context, score);
    final missing = [for (final d in dims) if (d.score == null) d.label];
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovHlScoreTitle, hint: t.ovHlScoreHint),
          const Spacer(),
          OvScoreGauge(
            score: score ?? 0,
            size: 210,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  score == null ? '—' : ((score! * 100).round().toString()),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: const Color(0xFFF0F5FB),
                  ),
                ),
                Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (score == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                t.ovHlMissing(missing.join('、')),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFA5B5C7),
                  height: 1.5,
                ),
              ),
            )
          else
            Text(
              t.ovHlScoreNote(dims.where((d) => d.score != null).length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF71859D),
              ),
            ),
        ],
      ),
    );
  }
}

/// 中：四维轨道节点——核心（评分辉光）+ 四颗维度星沿椭圆轨道缓慢巡游，
/// 节点与核心之间微光连线；节点旁数值，悬停显示口径提示。
class OrbitPanel extends StatefulWidget {
  const OrbitPanel({super.key, required this.dims, required this.score});

  final List<HlDim> dims;
  final double? score;

  @override
  State<OrbitPanel> createState() => _OrbitPanelState();
}

class _OrbitPanelState extends State<OrbitPanel>
    with SingleTickerProviderStateMixin {
  // 46s 一圈的缓慢巡游；测试/减少动画时停在初始相位。
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 46),
  );

  @override
  void initState() {
    super.initState();
    if (!kOvTestEnv) _orbit.repeat();
    // 帧后校验「减少动画」：需要时停摆（initState 不能查 MediaQuery）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && MediaQuery.disableAnimationsOf(context)) _orbit.stop();
    });
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dims = widget.dims;
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        children: [
          OvSectionHead(
            title: t.ovHlOrbitTitle,
            hint: t.ovHlOrbitHint,
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _orbit,
              builder: (context, _) => LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth, h = c.maxHeight;
                  final cx = w / 2, cy = h / 2;
                  final rx = w * 0.34, ry = h * 0.36;
                  final phase = _orbit.value * 2 * math.pi;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 轨道环 + 连线。
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _OrbitPainter(
                            cx: cx,
                            cy: cy,
                            rx: rx,
                            ry: ry,
                            phase: phase,
                            n: dims.length,
                          ),
                        ),
                      ),
                      // 核心：评分辉光。
                      Positioned(
                        left: cx - 34,
                        top: cy - 34,
                        child: OvBreathing(
                          color: const Color(0xFF7EA6D9),
                          radius: 26,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFF22344A), Color(0xFF0C1929)],
                              ),
                              border: Border.all(
                                color: const Color(0x99BFD9F2),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                widget.score == null
                                    ? '—'
                                    : '${(widget.score! * 100).round()}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  color: const Color(0xFFF0F5FB),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 维度节点。
                      for (var i = 0; i < dims.length; i++)
                        () {
                          final a = phase +
                              -math.pi / 2 +
                              2 * math.pi * i / dims.length;
                          final x = cx + math.cos(a) * rx;
                          final y = cy + math.sin(a) * ry;
                          return Positioned(
                            left: x - 30,
                            top: y - 30,
                            child: _OrbitNode(dim: dims[i]),
                          );
                        }(),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
    required this.phase,
    required this.n,
  });

  final double cx, cy, rx, ry, phase;
  final int n;

  @override
  void paint(Canvas canvas, Size size) {
    // 椭圆轨道虚线。
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: rx * 2,
      height: ry * 2,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x26E7ECF2),
    );
    // 核心-节点连线。
    for (var i = 0; i < n; i++) {
      final a = phase + -math.pi / 2 + 2 * math.pi * i / n;
      final p = Offset(cx + math.cos(a) * rx, cy + math.sin(a) * ry);
      canvas.drawLine(
        Offset(cx, cy),
        p,
        Paint()
          ..strokeWidth = 1
          ..color = const Color(0x1EE7ECF2),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.phase != phase;
}

class _OrbitNode extends StatefulWidget {
  const _OrbitNode({required this.dim});

  final HlDim dim;

  @override
  State<_OrbitNode> createState() => _OrbitNodeState();
}

class _OrbitNodeState extends State<_OrbitNode> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.dim.score;
    final color = s == null
        ? const Color(0xFF71859D)
        : (s >= 0.6
              ? const Color(0xFF8FBCE8)
              : s >= 0.4
              ? const Color(0xFFD8BE85)
              : const Color(0xFFF0907C));
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.12 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Tooltip(
          message: widget.dim.hint,
          waitDuration: const Duration(milliseconds: 250),
          child: Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _hover
                  ? const Color(0xF5101929)
                  : const Color(0xCC0C1929),
              border: Border.all(
                color: Color.lerp(
                  const Color(0x33E7ECF2),
                  color.withValues(alpha: 0.7),
                  _hover ? 1 : 0.35,
                )!,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: _hover ? 0.35 : 0.12),
                  blurRadius: _hover ? 18 : 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.dim.icon, size: 15, color: color),
                const SizedBox(height: 3),
                Text(
                  widget.dim.valueText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: const Color(0xFFF0F5FB),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 右：目标雷达（当前值钢蓝 + 目标琥珀虚线）。
class RadarPanel extends StatelessWidget {
  const RadarPanel({super.key, required this.dims});

  final List<HlDim> dims;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovHlRadarTitle, hint: t.ovHlRadarHint),
          const SizedBox(height: 8),
          Expanded(
            child: OvRadarChart(
              dims: [
                for (final d in dims)
                  OvRadarDim(
                    label: d.label,
                    value: d.score ?? 0,
                    target: 1.0,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(const Color(0xFF8FBCE8), t.ovHlCurrent),
              const SizedBox(width: 14),
              _legend(const Color(0xFFD8BE85), t.ovHlTarget),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFFA5B5C7)),
        ),
      ],
    );
  }
}

/// 六项核心指标行（自适应折行）：四维 + 消费配速 + 估值覆盖。
class MetricRow extends StatelessWidget {
  const MetricRow({super.key, required this.dims, required this.d});

  final List<HlDim> dims;
  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pace = d.insights.pace;
    final covered = d.nw.items.where((i) => !i.valuationMissing).length;
    final total = d.nw.items.length;
    final coverage = total == 0 ? null : covered / total;
    final cards = <Widget>[
      for (final dim in dims) _card(context, dim),
      _metricCard(
        context,
        icon: Icons.speed_outlined,
        label: t.ovHlPace,
        value: t.ovHlPaceDays(pace.daysElapsed),
        sub: t.dashMonthSpendForecast,
        subValue: fmtMinor(pace.projectedMinor, d.nw.baseCurrencyCode),
        score: null,
        hint: t.dashMonthSpendForecastHint,
      ),
      _metricCard(
        context,
        icon: Icons.fact_check_outlined,
        label: t.ovHlCoverage,
        value: coverage == null
            ? '—'
            : '${(coverage * 100).toStringAsFixed(0)}%',
        sub: t.ovHlCoverageSub,
        subValue: '$covered/$total',
        score: coverage?.clamp(0.0, 1.0),
        hint: t.ovNwCoverageHint,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth >= 1500
            ? 6
            : c.maxWidth >= 1000
            ? 3
            : 2;
        return Column(
          children: [
            for (var r = 0; r < cards.length; r += perRow)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                // IntrinsicHeight 先量出行的内在高度，stretch 才能等高
                //（直接 stretch 在无界滚动里会给子级强塞无限高）。
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = r;
                          i < math.min(r + perRow, cards.length);
                          i++) ...[
                        if (i > r) const SizedBox(width: 14),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, HlDim dim) => _metricCard(
    context,
    icon: dim.icon,
    label: dim.label,
    value: dim.valueText,
    sub: dim.targetText,
    subValue: '',
    score: dim.score,
    hint: dim.hint,
  );

  Widget _metricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    required String subValue,
    required double? score,
    required String hint,
  }) {
    final theme = Theme.of(context);
    final s = score;
    final color = s == null
        ? const Color(0xFF71859D)
        : (s >= 0.6
              ? const Color(0xFF8FBCE8)
              : s >= 0.4
              ? const Color(0xFFD8BE85)
              : const Color(0xFFF0907C));
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFA5B5C7),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              InfoHint(message: hint, size: 12),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: const Color(0xFFF0F5FB),
                ),
              ),
              const Spacer(),
              if (subValue.isNotEmpty)
                Text(
                  subValue,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFA5B5C7),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (s != null)
            TweenAnimationBuilder<double>(
              tween: Tween(end: s),
              duration: const Duration(milliseconds: 640),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    children: [
                      Container(color: color.withValues(alpha: 0.13)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: v.clamp(0.0, 1.0),
                          child: Container(color: color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Text(
              sub,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF71859D),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

/// 诊断：优势亮点 / 潜在风险 / 优化空间（按真实分数分桶，规则透明）。
class DiagnosisPanel extends StatelessWidget {
  const DiagnosisPanel({super.key, required this.dims, required this.d});

  final List<HlDim> dims;
  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final good = [
      for (final dim in dims)
        if (dim.score != null && dim.score! >= 0.75) dim.label,
    ];
    final risk = [
      for (final dim in dims)
        if (dim.score != null && dim.score! < 0.4) dim.label,
    ];
    final improve = [
      for (final dim in dims)
        if (dim.score != null && dim.score! >= 0.4 && dim.score! < 0.75)
          dim.label,
    ];
    if (d.nw.missingValuations > 0) risk.add(t.ovHlDiagValuation);
    return OvPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OvSectionHead(title: t.ovHlDiagTitle, hint: t.ovHlDiagHint),
          const SizedBox(height: 8),
          _group(context, t.ovHlDiagGood, good, const Color(0xFF8FBCE8), Icons.auto_awesome),
          _group(context, t.ovHlDiagRisk, risk, const Color(0xFFF0907C), Icons.warning_amber_rounded),
          _group(context, t.ovHlDiagImprove, improve, const Color(0xFFD8BE85), Icons.trending_up),
          if (good.isEmpty && risk.isEmpty && improve.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                t.ovHlDiagEmpty,
                style: const TextStyle(color: Color(0xFF71859D)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _group(
    BuildContext context,
    String title,
    List<String> items,
    Color c,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: c),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(color: c),
              ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 4),
              child: Text(
                t.ovHlDiagNone,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF71859D),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 5),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final label in items)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: c.withValues(alpha: 0.12),
                        border: Border.all(color: c.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: c,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 行动建议：按最弱维度排序，每条给可执行入口（真实路由）。
class ActionPanel extends StatelessWidget {
  const ActionPanel({super.key, required this.dims, required this.d});

  final List<HlDim> dims;
  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final weakest = hlWeakest(dims);
    final actions = <(IconData, String, String, String)?>[
      if (d.nw.missingValuations > 0)
        (
          Icons.gavel_outlined,
          t.ovHlActValuation(d.nw.missingValuations),
          t.ovHlActValuationSub,
          '/assets',
        ),
      for (final dim in weakest.take(2))
        switch (dim.key) {
          'save' => (
            Icons.savings_outlined,
            t.ovHlActSave,
            t.ovHlActSaveSub,
            '/budgets',
          ),
          'emergency' => (
            Icons.health_and_safety_outlined,
            t.ovHlActEmergency,
            t.ovHlActEmergencySub,
            '/goals',
          ),
          'leverage' => (
            Icons.scale_outlined,
            t.ovHlActLeverage,
            t.ovHlActLeverageSub,
            '/debts',
          ),
          'cushion' => (
            Icons.waves_outlined,
            t.ovHlActCushion,
            t.ovHlActCushionSub,
            '/plans',
          ),
          _ => null,
        },
    ].whereType<(IconData, String, String, String)>().toList();
    return OvPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OvSectionHead(title: t.ovHlActTitle, hint: t.ovHlActHint),
          const SizedBox(height: 4),
          if (actions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                t.ovHlActEmpty,
                style: const TextStyle(color: Color(0xFF71859D)),
              ),
            )
          else
            for (var i = 0; i < actions.length; i++)
              _actionTile(context, theme, i, actions[i]),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context,
    ThemeData theme,
    int index,
    (IconData, String, String, String) a,
  ) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: OvRiseIn(
        delay: Duration(milliseconds: 60 * index),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => GoRouter.of(context).go(a.$4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    child: Icon(a.$1, size: 16, color: const Color(0xFFBFD9F2)),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          a.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFA5B5C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: t.ovHlActGo,
                    child: const Icon(
                      Icons.arrow_outward,
                      size: 15,
                      color: Color(0xFF71859D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
