import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../globe/glass_card.dart';
import '../widgets/common.dart';

/// 设置页组件套件：深空控制舱形态的共享件——玻璃面板、核心操作卡、
/// 状态章、呼吸光环、点阵地球弧面、阶梯入场。全部复用设计令牌与
/// GlassCard / ParticleEdge 体系（docs/12 §9），页面不自造同类控件。

/// 循环动画测试冻结（惯例同 particle_edge / space_backdrop）：
/// FLUTTER_TEST 下不起常驻 Ticker，画静态帧——walkthrough 的
/// pumpAndSettle 才能收场。
final bool kSettingsTestEnv = Platform.environment['FLUTTER_TEST'] == 'true';

/// 玻璃设置面板：图标 + 标题 + info 提示 + 可选尾件 + 主体。
/// 说明文字一律挂 [hint]（提示语规范），不铺静态副标题。
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.hint,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
  });

  final String title;
  final IconData? icon;
  final String? hint;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(width: 6),
                  InfoHint(message: hint!),
                ],
                const Spacer(),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// 核心操作卡：左上渐变图标位 + 标题（说明挂 info）+ 右下圆形箭头钮。
/// 整卡可点；hover 上浮 + 边框提亮 + 箭头滑移 + 底缘光尘，按压轻缩。
class SettingsActionCard extends StatefulWidget {
  const SettingsActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  /// 危险操作：图标位与箭头钮转语义红。
  final bool destructive;

  @override
  State<SettingsActionCard> createState() => _SettingsActionCardState();
}

class _SettingsActionCardState extends State<SettingsActionCard> {
  bool _hover = false;
  bool _press = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = widget.destructive
        ? AppColors.negativeOf(theme.brightness)
        : theme.colorScheme.primary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _press = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _press = true),
        onTapCancel: () => setState(() => _press = false),
        onTap: () {
          setState(() => _press = false);
          widget.onTap();
        },
        child: ParticleEdge.active(
          active: _hover,
          band: 18,
          child: AnimatedScale(
            scale: _press ? 0.982 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
              child: AnimatedScale(
                scale: _hover ? 1.008 : 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: GlassCard(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(
                        color: tint.withValues(alpha: _hover ? 0.35 : 0),
                      ),
                      boxShadow: _hover
                          ? [
                              BoxShadow(
                                color: tint.withValues(alpha: 0.14),
                                blurRadius: 26,
                                offset: const Offset(0, 12),
                              ),
                            ]
                          : const [],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 渐变图标位：主色 18%→6% 斜向，细边同色。
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    tint.withValues(alpha: 0.20),
                                    tint.withValues(alpha: 0.06),
                                  ],
                                ),
                                border: Border.all(
                                  color: tint.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Icon(widget.icon, size: 21, color: tint),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InfoHint(message: widget.hint),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // 右下圆形箭头钮：hover 时填充提亮 + 箭头右移。
                            Align(
                              alignment: Alignment.centerRight,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tint.withValues(
                                    alpha: _hover ? 0.16 : 0.07,
                                  ),
                                  border: Border.all(
                                    color: tint.withValues(
                                      alpha: _hover ? 0.42 : 0.2,
                                    ),
                                  ),
                                ),
                                child: AnimatedSlide(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  offset: _hover
                                      ? const Offset(0.12, 0)
                                      : Offset.zero,
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 状态章：小标签 + 状态值 + 对勾/警示图标，颜色随 [ok] 平滑过渡
/// （状态翻转时章体色彩渐变，不瞬跳）。说明挂 [tooltip]。
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.value,
    required this.ok,
    this.tooltip,
  });

  final String label;
  final String value;
  final bool ok;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ok
        ? AppColors.positiveOf(theme.brightness)
        : AppColors.warnOf(theme.brightness);
    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.chip),
        color: color.withValues(alpha: 0.09),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Icon(
              ok ? Icons.check_circle : Icons.warning_amber,
              key: ValueKey(ok),
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (tooltip == null) return body;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: body,
    );
  }
}

/// 统计瓦片：标签 + 数值（时间等宽），概览横排用；说明挂 [tooltip]。
class SettingsStatTile extends StatelessWidget {
  const SettingsStatTile({
    super.key,
    required this.label,
    required this.value,
    this.tooltip,
    this.color,
  });

  final String label;
  final String value;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (tooltip != null) ...[
          const SizedBox(width: 4),
          InfoHint(message: tooltip!, size: 13),
        ],
        const SizedBox(width: 10),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// 呼吸光环图标：双环以整周期余弦包络呼吸（0.5-0.5·cos(2πt)，周期
/// 边界无缝），核心渐变圆 + 图标 + 同步柔光。循环动画测试冻结静态帧。
class BreathingHalo extends StatefulWidget {
  const BreathingHalo({
    super.key,
    required this.icon,
    this.size = 84,
    this.color,
  });

  final IconData icon;
  final double size;
  final Color? color;

  @override
  State<BreathingHalo> createState() => _BreathingHaloState();
}

class _BreathingHaloState extends State<BreathingHalo>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    // initState 即刻构造（惰性构造 dispose 崩坑，同 space_backdrop）。
    _ticker = createTicker((elapsed) {
      setState(() => _t = elapsed.inMicroseconds / 1e6);
    });
    if (!kSettingsTestEnv) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ?? Theme.of(context).colorScheme.primary;
    final size = widget.size;
    // 两环相位错开半周期，各自整周期归零——叠加仍无缝。
    final k1 = 0.5 - 0.5 * math.cos(2 * math.pi * _t / 3.2);
    final k2 = 0.5 - 0.5 * math.cos(2 * math.pi * _t / 3.2 + math.pi);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.scale(
            scale: 1 + 0.18 * k1,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.10 + 0.28 * k1),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: 1 + 0.30 * k2,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.05 + 0.16 * k2),
                  width: 1,
                ),
              ),
            ),
          ),
          // 核心渐变圆 + 呼吸柔光。
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.22 + 0.08 * k1),
                  color.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: color.withValues(alpha: 0.34)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.12 + 0.20 * k1),
                  blurRadius: 22 + 10 * k1,
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: size * 0.28,
              color: color.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

/// 点阵地球弧面：概览大卡右缘的极淡数字地球（经纬网点阵 + 慢速自转 +
/// 球缘弧线）。临边透明度按 √(1-x²) 衰减——点在轮廓处隐没，自转回绕
/// 无跳变（循环无缝规范 ①/②）。整体透明度极低，不与文字争抢。
class EarthArc extends StatefulWidget {
  const EarthArc({super.key, this.color});

  final Color? color;

  @override
  State<EarthArc> createState() => _EarthArcState();
}

class _EarthArcState extends State<EarthArc>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _t = elapsed.inMicroseconds / 1e6);
    });
    if (!kSettingsTestEnv) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkPrimary
            : AppColors.navy);
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _EarthArcPainter(t: kSettingsTestEnv ? 0.8 : _t, color: color),
      ),
    );
  }
}

class _EarthArcPainter extends CustomPainter {
  _EarthArcPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 40 || size.height < 40) return;
    // 球心在画布右缘之外：只露出朝左的一瓣弧面。
    final r = size.height * 0.92;
    final c = Offset(size.width + r * 0.30, size.height * 0.52);
    final phase = t * 0.10; // 慢速自转（rad/s，单调无回绕）

    // 球缘弧线：一道极淡的轮廓。
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.10),
    );

    // 经纬网点阵：纬度 15° 步进、经度 10° 步进；经度随 phase 自转。
    final dot = Paint();
    for (var lat = -75; lat <= 75; lat += 15) {
      final la = lat * math.pi / 180;
      for (var lon = 0; lon < 360; lon += 10) {
        final lo = lon * math.pi / 180 + phase;
        final x3 = math.cos(la) * math.sin(lo);
        final y3 = math.sin(la);
        // 屏幕坐标：正对观察者的经度朝左（露出的瓣）。
        final px = c.dx - x3 * r;
        final py = c.dy - y3 * r * 0.97;
        if (px < -4 || px > size.width + 4) continue;
        if (py < -4 || py > size.height + 4) continue;
        // 临边衰减：x3→±1（轮廓）时归零，点隐没后回绕到另一侧无跳变。
        final limb = math.sqrt(math.max(0, 1 - x3 * x3));
        if (limb < 0.14) continue;
        final a = 0.085 * math.pow(limb, 1.6);
        dot.color = color.withValues(alpha: a);
        canvas.drawCircle(Offset(px, py), 1.15, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_EarthArcPainter old) => old.t != t || old.color != color;
}

/// 阶梯入场：卡片按 [index] 依次 45ms 延迟淡入上浮（360ms easeOut）。
/// 分类切换与首屏共用；「减少动画」直接定格终态。
class StaggerIn extends StatefulWidget {
  const StaggerIn({
    super.key,
    required this.index,
    required this.child,
    this.rise = 14,
  });

  final int index;
  final Widget child;

  /// 上浮距离（px）。
  final double rise;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 45 * widget.index.clamp(0, 8)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final e = Curves.easeOut.transform(_c.value);
        return Opacity(
          opacity: _c.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.rise * (1 - e)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// 相对时间（安全事件行右缘）：刚刚 / N 分钟前 / N 小时前 / N 天前，
/// 超过 7 天退回绝对时间（yyyy-MM-dd HH:mm）。
String relTime(DateTime at, AppLocalizations t) {
  final d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return t.settingsRelNow;
  if (d.inMinutes < 60) return t.settingsRelMin(d.inMinutes);
  if (d.inHours < 24) return t.settingsRelHour(d.inHours);
  if (d.inDays < 7) return t.settingsRelDay(d.inDays);
  return DateFormat('yyyy-MM-dd HH:mm').format(at);
}

/// 操作卡自适应网格：≥[wide3At] 三列 → ≥[wide2At] 两列 → 单列；每张卡
/// 自带阶梯入场（[startIndex] 起算序号，避免与上方卡片争同一个节拍）。
class SettingsCardGrid extends StatelessWidget {
  const SettingsCardGrid({
    super.key,
    required this.children,
    this.startIndex = 0,
    this.wide3At = 780,
    this.wide2At = 500,
  });

  final List<Widget> children;
  final int startIndex;
  final double wide3At;
  final double wide2At;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= wide3At
            ? 3
            : (c.maxWidth >= wide2At ? 2 : 1);
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == children.length - 1 ? 0 : 16,
                  ),
                  child: StaggerIn(
                    index: startIndex + i,
                    child: children[i],
                  ),
                ),
            ],
          );
        }
        const gap = 16.0;
        final tile = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                width: tile,
                child: StaggerIn(index: startIndex + i, child: children[i]),
              ),
          ],
        );
      },
    );
  }
}
