import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../globe/space_backdrop.dart';
import '../widgets/common.dart';

/// 沉浸式详情页统一外壳（v0.26 Orbital Finance）。
///
/// 全出血深空页：SpaceBackdrop（降透明度让数据可读）铺满窗口，页头
/// 与首页同一节奏线，标题旁挂 InfoHint（提示语规范：说明不写成静态
/// 副标题）。内容区由页面自管滚动；本壳只给背景、页头与响应式留白。
///
/// - 大屏（≥900）：页头自窗口左缘 24px 起排：返回键（2026-10-30 导航
///   体系删除后的回上层入口，恒用深空玻璃配色）+ 大标题 + 动作行，
///   内容左右各 24px 安全边距，可收束 [maxWidth]；
/// - 小屏：常规 AppBar 形态（返回 + 标题），内容单列。
class OverviewScaffold extends StatelessWidget {
  const OverviewScaffold({
    super.key,
    required this.title,
    required this.titleHint,
    required this.child,
    this.actions = const [],
    this.maxWidth = double.infinity,
    this.updatedLabel,
    this.appBarBottom,
    this.fab,
  });

  final String title;

  /// 页标题悬停说明（提示语规范）。
  final String titleHint;

  final List<Widget> actions;

  /// 内容最大宽度；默认整窗（工作台式多栏），收束页可传具体值。
  final double maxWidth;

  /// 数据更新时间标签（如「截至 10-30」），右侧胶囊。
  final String? updatedLabel;

  /// 页头下的附加控件（月份切换条等）。
  final Widget? appBarBottom;

  final Widget? fab;

  /// 页面主体（内容区，自管滚动）。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final body = wide ? _wideBody(context) : _narrowBody(context);
    return Scaffold(
      backgroundColor: const Color(0xFF050A12),
      floatingActionButton: fab,
      body: Stack(
        children: [
          // 深空底幕降一档亮度：星野仍在呼吸，数据区永远第一优先。
          const Positioned.fill(
            child: Opacity(opacity: 0.5, child: SpaceBackdrop()),
          ),
          Positioned.fill(child: body),
        ],
      ),
    );
  }

  Widget _wideBody(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          // 页头自窗口左缘起排（原 A 导航入口让位已随导航体系删除）；
          // 右侧给窗口栏留白。
          padding: EdgeInsets.fromLTRB(24, topInset + 14, 24, 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const PageBackButton(onDark: true),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: const Color(0xFFF0F5FB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InfoHint(message: titleHint),
                    const Spacer(),
                    if (updatedLabel != null) _UpdatedChip(label: updatedLabel!),
                    const SizedBox(width: 10),
                    ...actions,
                  ],
                ),
                if (appBarBottom != null) ...[
                  const SizedBox(height: 12),
                  appBarBottom!,
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _narrowBody(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: const PageBackButton(onDark: true),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            const SizedBox(width: 6),
            InfoHint(message: titleHint),
          ],
        ),
        actions: [
          if (updatedLabel != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(child: _UpdatedChip(label: updatedLabel!)),
            ),
          ...actions,
        ],
        bottom: appBarBottom == null
            ? null
            : PreferredSize(
                preferredSize: appBarBottom is PreferredSizeWidget
                    ? (appBarBottom! as PreferredSizeWidget).preferredSize
                    : const Size.fromHeight(48),
                child: appBarBottom!,
              ),
        foregroundColor: const Color(0xFFF0F5FB),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: const Color(0xFFF0F5FB),
          fontWeight: FontWeight.w700,
        ),
      ),
      body: child,
    );
  }
}

/// 更新时间胶囊：细描边玻璃小片，等宽数字。
class _UpdatedChip extends StatelessWidget {
  const _UpdatedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: const Color(0x2EE7ECF2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: const Color(0xFFA5B5C7),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// 沉浸式详情页玻璃面板：与首页 GlassCard 同一家族（发丝边 + 顶部斜
/// 高光 + 悬浮阴影 + 底缘光尘），但不做逐卡 BackdropFilter（一页十余
/// 面板全挂模糊会互相叠加）——用更深的实底渐变读作「磨砂后的玻璃」。
/// hover 上浮 -3px + 投影加深 + 0.5% 放大（180ms easeOut，与全站
/// _LiftTile 同参数；触屏自然不触发）。
class OvPanel extends StatefulWidget {
  const OvPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 16),
    this.hoverLift = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool hoverLift;

  @override
  State<OvPanel> createState() => _OvPanelState();
}

class _OvPanelState extends State<OvPanel> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
        ),
        child: AnimatedScale(
          scale: _hover ? 1.005 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: ParticleEdge(
            band: 22,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // 磨砂玻璃底：细腻上下渐变（主卡 #0C1929 → 次底 #081321）。
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xCC0C1929), Color(0xE6081321)],
                        ),
                      ),
                    ),
                  ),
                  // 发丝边。
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x33E7ECF2)),
                      ),
                    ),
                  ),
                  // 顶部斜高光（GlassCard 签名工艺）。
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment(0.4, 1),
                            colors: [Colors.white, Colors.transparent],
                            stops: [0, 0.22],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(padding: widget.padding, child: widget.child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// KPI 瓦片：图标 + 标签（悬停提示）+ 大数（Odometer 滚动）+ 可选
/// 变化徽章。沉浸页的统一指标形态。
class OvKpiTile extends StatelessWidget {
  const OvKpiTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.delta,
    this.deltaCurrency,
    this.accent,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String? hint;

  /// 完整格式化后的金额/比率文本。
  final String value;

  /// 与上期差值（正负着色 + 箭头）。
  final BigInt? delta;
  final String? deltaCurrency;

  /// 图标容器强调色（语义色）。
  final Color? accent;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = accent ?? theme.colorScheme.primary;
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tint.withValues(alpha: 0.30),
                      tint.withValues(alpha: 0.10),
                    ],
                  ),
                  border: Border.all(color: tint.withValues(alpha: 0.35)),
                ),
                child: Icon(icon, size: 16, color: tint),
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFA5B5C7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (hint != null) ...[
                const SizedBox(width: 5),
                InfoHint(message: hint!, size: 13),
              ],
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Odometer(
              text: value,
              style: theme.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFFF0F5FB),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (delta != null) ...[
            const SizedBox(height: 6),
            DeltaBadge(minor: delta!, currencyCode: deltaCurrency ?? ''),
          ],
        ],
      ),
    );
  }
}

/// 区块标题行：小标题 + InfoHint + 右侧尾件。详情页面板的统一抬头。
class OvSectionHead extends StatelessWidget {
  const OvSectionHead({
    super.key,
    required this.title,
    this.hint,
    this.trailing,
  });

  final String title;
  final String? hint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: const Color(0xFFE7F0FA),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(width: 6),
          InfoHint(message: hint!),
        ],
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

/// KPI 瓦片自适应行：宽屏 [widePerRow] 连排；中屏折半；窄屏（<640）
/// 两枚一行（图标+提示的固定开销决定了每枚最小宽度，硬塞会溢出）。
/// 行内 IntrinsicHeight 等高。
class OvKpiRow extends StatelessWidget {
  const OvKpiRow({super.key, required this.children, this.widePerRow = 4});

  final List<Widget> children;
  final int widePerRow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth >= 1000
            ? widePerRow
            : (c.maxWidth >= 640 ? (widePerRow ~/ 2).clamp(2, widePerRow) : 2);
        return Column(
          children: [
            for (var r = 0; r < children.length; r += perRow)
              Padding(
                padding: EdgeInsets.only(
                  bottom: r + perRow < children.length ? 12 : 0,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = r;
                          i < math.min(r + perRow, children.length);
                          i++) ...[
                        if (i > r) const SizedBox(width: 12),
                        Expanded(child: children[i]),
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
}
