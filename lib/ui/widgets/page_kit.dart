import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/runtime_l10n.dart';
import '../theme/app_theme.dart';
import 'odometer.dart';
import 'page_frame.dart';
import 'particle_edge.dart';

/// 页面组件库（第二件）：列表行、进度计量、标题、图标动作钮、工作台
/// 侧栏汇总件。与 page_frame.dart 的 PageFrame/StatBand/CardWrap/InfoHint
/// 配套，页面重写时从这里取件，禁止各页自造同类控件。

/// 页头/工具行的幽灵图标钮：透明底 + hover 提亮底，统一 36px 命中区。
/// 页面头部动作一律用它（AppBar.actions 里同样成立）。
class ActionIcon extends StatefulWidget {
  const ActionIcon({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap; // null = 禁用
  final Color? color;

  @override
  State<ActionIcon> createState() => _ActionIconState();
}

class _ActionIconState extends State<ActionIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final color =
        widget.color ??
        (disabled
            ? Theme.of(context).disabledColor
            : Theme.of(context).colorScheme.onSurface);
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: disabled ? null : widget.onTap,
          // 底缘光尘（docs/12 §9 交互粒子规范）：页头动作钮低密度
          // 场景接入，复用 .active 模式（本组件已有 hover 态）。
          child: ParticleEdge.active(
            active: _hover,
            band: 12,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hover
                    ? Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.07,
                      )
                    : Colors.transparent,
              ),
              child: Icon(widget.icon, size: 19, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// 统一列表行（设置页 / 计划清单 / 目标行共用）：
/// 左侧主题色圆角图标位 + 标题 +（可选）右侧值/箭头 + info 悬停提示。
/// 提示语规范：说明不写成静态副标题，挂 [hint]。
class ListRow extends StatefulWidget {
  const ListRow({
    super.key,
    required this.icon,
    required this.title,
    this.trailingValue,
    this.hint,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? trailingValue;
  final String? hint;
  final VoidCallback? onTap;

  /// 完全自定义右侧（菜单钮等）；有它时忽略 [trailingValue]。
  final Widget? trailing;

  /// 强调红（删除类行）。
  final bool destructive;

  @override
  State<ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<ListRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = widget.destructive
        ? AppColors.negativeOf(theme.brightness)
        : theme.colorScheme.primary;
    final clickable = widget.onTap != null;
    return MouseRegion(
      cursor: clickable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _hover && clickable
                ? theme.colorScheme.onSurface.withValues(alpha: 0.04)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: tint.withValues(alpha: 0.12),
                ),
                child: Icon(widget.icon, size: 18, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: widget.destructive
                              ? AppColors.negativeOf(theme.brightness)
                              : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.hint != null) ...[
                      const SizedBox(width: 6),
                      InfoHint(message: widget.hint!),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null)
                widget.trailing!
              else if (widget.trailingValue != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    widget.trailingValue!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                )
              else if (clickable)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.hintColor.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 进度计量条：预算/目标共用。特点——90% 处一道警戒刻痕；超支时整条
/// 变语义红并在末端溢出小段；数值变化 320ms easeOut 平滑过渡（数据
/// 刷新时进度条不跳变）。
class ProgressMeter extends StatelessWidget {
  const ProgressMeter({
    super.key,
    required this.ratio,
    this.height = 8,
    this.over = false,
  });

  /// 0..1（可略超，超出段截断显示为满格红）。
  final double ratio;
  final double height;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = over
        ? AppColors.negativeOf(theme.brightness)
        : theme.colorScheme.primary;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: ratio.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      builder: (context, v, _) => LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return SizedBox(
            height: height + 6,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 2),
                    color: color.withValues(alpha: 0.12),
                  ),
                ),
                Container(
                  width: (w * v).clamp(0.0, w),
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 2),
                    color: color,
                  ),
                ),
                // 90% 警戒刻痕
                Positioned(
                  left: w * 0.9 - 0.5,
                  child: Container(
                    width: 1.5,
                    height: height + 4,
                    color: theme.hintColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 环形进度（目标页）：细环 + 中心百分比。直径 56，静环发丝灰，
/// 前景主色或语义红（超支）。无动画（读数型数据不晃动）。
class RingProgress extends StatelessWidget {
  const RingProgress({super.key, required this.ratio, this.over = false});

  final double ratio;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = over
        ? AppColors.negativeOf(theme.brightness)
        : theme.colorScheme.primary;
    return SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(
        painter: _RingPainter(ratio: ratio.clamp(0.0, 1.0), color: color),
        child: Center(
          child: Text(
            '${(ratio.clamp(0.0, 9.99) * 100).round()}%',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 4;
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * ratio;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.14);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(c, radius, track);
    if (ratio > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: radius),
        start,
        sweep,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ratio != ratio || old.color != color;
}

/// 流水台账的日头：日期 + 星期 + 当日净额（右缘，支出红收入蓝）。
class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.date,
    required this.netLabel,
    required this.netColor,
  });

  final DateTime date;
  final String netLabel;
  final Color netColor;

  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  static const _weekdaysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Text(
            RuntimeL10n.english
                ? DateFormat('MMM d', 'en').format(date)
                : '${date.month} 月 ${date.day} 日',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            RuntimeL10n.english
                ? _weekdaysEn[date.weekday - 1]
                : '周${_weekdays[date.weekday - 1]}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
            ),
          ),
          const Spacer(),
          Text(
            netLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: netColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 工作台侧栏件（大屏 ≥900）：大屏页面 = 主区 + 固定宽侧栏（汇总/导航/
// 详情），小屏退化为单列时由页面自行收起侧栏。侧栏内容与卡片同一家族
// （发丝线卡 + 底缘光尘），但以「纵读清单」形态出现——大屏不铺满宽卡。
// ─────────────────────────────────────────────────────────────────────────

/// 侧栏汇总面板：标题行（可带 info 提示）→ 可选主数（大字 + 语义色，
/// 数值变化走 Odometer）→ 明细行列表 → 可选底部附加区。
///
/// 大屏侧栏的统一形态，预算/目标/负债/计划/流水共用；替代这些页面
/// 大屏上的 StatBand 横带（StatBand 保留给小屏）。
class SummaryPanel extends StatelessWidget {
  const SummaryPanel({
    super.key,
    required this.title,
    this.rows = const [],
    this.hint,
    this.heroValue,
    this.heroLabel,
    this.heroColor,
    this.heroHint,
    this.footer,
    this.child,
  });

  final String title;

  /// 面板标题的悬停说明（提示语规范）。
  final String? hint;

  /// 主数：大屏侧栏的视觉锚点（如「剩余可花」）。null 时不渲染。
  final String? heroValue;
  final String? heroLabel;
  final Color? heroColor;
  final String? heroHint;

  /// 明细行（label → value），发丝线分隔。
  final List<SummaryRow> rows;

  /// 底部附加区（如进度条/动作按钮），与明细行之间有 12px 间距。
  final Widget? footer;

  /// 完全自定义主体（有它时忽略 hero 与 rows）。
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ParticleEdge(
      band: 22,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.dividerColor),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(width: 6),
                  InfoHint(message: hint!),
                ],
              ],
            ),
            if (child != null) ...[
              const SizedBox(height: 12),
              child!,
            ] else ...[
              if (heroValue != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      // 长数值在窄栏自动缩小（FittedBox），不溢出。
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Odometer(
                          text: heroValue!,
                          style: theme.textTheme.headlineMedium!.copyWith(
                            color: heroColor,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    if (heroLabel != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          heroLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                    ],
                    if (heroHint != null) ...[
                      const SizedBox(width: 6),
                      InfoHint(message: heroHint!),
                    ],
                  ],
                ),
              ],
              if (rows.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.6),
                    ),
                  _SummaryRowTile(row: rows[i]),
                ],
              ],
              if (footer != null) ...[
                const SizedBox(height: 12),
                footer!,
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class SummaryRow {
  const SummaryRow(this.label, this.value, {this.color, this.tooltip});

  final String label;
  final String value;
  final Color? color;
  final String? tooltip;
}

class _SummaryRowTile extends StatelessWidget {
  const _SummaryRowTile({required this.row});

  final SummaryRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Flexible(
            child: Text(
              row.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          if (row.tooltip != null) ...[
            const SizedBox(width: 5),
            InfoHint(message: row.tooltip!, size: 13),
          ],
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Odometer(
                text: row.value,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: row.color,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 大屏工作台分栏：`rail`（固定宽侧栏，默认 300）+ 16 间距 + 主区。
/// 小屏（<900）只渲染主区（侧栏由页面以另一种形态收进页面流）。
/// [reversed] 为 true 时侧栏在右（流水概览 / 资产详情）。
class WorkbenchSplit extends StatelessWidget {
  const WorkbenchSplit({
    super.key,
    required this.rail,
    required this.main,
    this.railWidth = 300,
    this.reversed = false,
  });

  final Widget rail;
  final Widget main;
  final double railWidth;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= PageMeasure.wide;
    if (!wide) return main;
    final children = [
      SizedBox(width: railWidth, child: rail),
      const SizedBox(width: PageMeasure.gutter),
      Expanded(child: main),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: reversed ? children.reversed.toList() : children,
    );
  }
}
