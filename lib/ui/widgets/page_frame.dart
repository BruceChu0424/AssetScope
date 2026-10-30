import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'odometer.dart';
import 'particle_edge.dart';

/// 响应式页面骨架令牌：大屏断点与 HomeShell 一致（900）；大屏内容
/// 收束居中（不再让卡片从头横到尾），栏间距 16。
abstract final class PageMeasure {
  static const wide = 900.0;
  static const contentMax = 1120.0;
  static const gutter = 16.0;
  static const screenH = AppSpace.screenH;
}

/// 页面统一外框：大小屏两种形态。
///
/// - 小屏（<900）：常规 AppBar（标题 + 动作），内容单列。
/// - 大屏（≥900）：无 AppBar——顶部标题带（大标题 + 动作行 + 底缘发丝
///   线），内容列收束居中（[maxWidth]，默认 1120），与首页深空卡片的
///   「悬浮于窗口」气质同源。
///
/// 子内容自带滚动；[child] 被放进居中约束列中。
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.maxWidth = PageMeasure.contentMax,
    this.appBarBottom,
    this.fab,
  });

  final String title;
  final List<Widget> actions;

  /// 大屏内容列最大宽度（流水等清单页可收得更窄）。
  final double maxWidth;

  /// 大屏标题带与内容之间附加的控件（如报表的月/年切换），小屏时
  /// 渲染在 AppBar 下方。
  final PreferredSizeWidget? appBarBottom;

  /// 悬浮动作（记一笔/新建…），两种形态共用。
  final Widget? fab;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= PageMeasure.wide;
    if (!wide) {
      return Scaffold(
        appBar: AppBar(title: Text(title), actions: actions, bottom: appBarBottom),
        floatingActionButton: fab,
        body: child,
      );
    }
    final topInset = MediaQuery.paddingOf(context).top;
    final hairline = theme.brightness == Brightness.light
        ? const Color(0x141E2A38)
        : const Color(0x26E7ECF2);
    return Scaffold(
      floatingActionButton: fab,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(32, topInset + 16, 32, 0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  ...actions,
                ],
              ),
            ),
          ),
          if (appBarBottom != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: appBarBottom!,
              ),
            ),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: hairline),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 页首统计带：一排「标签 + 数值」瓦片，发丝线分隔，等宽数字。
/// 大屏一行铺开；小屏自动两两折行。替代「每张卡从头横到尾」的旧摘要。
class StatBand extends StatelessWidget {
  const StatBand({super.key, required this.items});

  final List<StatBandItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 底缘光尘（docs/12 §9 卡片规范）：统计带与区块卡同一家族。
    return ParticleEdge(
      band: 22,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.dividerColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        child: Wrap(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                // 折行时分隔线跟着换行，视觉仍成立。
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: theme.dividerColor,
                ),
              _BandTile(item: items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _BandTile extends StatelessWidget {
  const _BandTile({required this.item});

  final StatBandItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (item.tooltip != null) ...[
              const SizedBox(width: 4),
              InfoHint(message: item.tooltip!),
            ],
          ],
        ),
        const SizedBox(height: 3),
        // 数值走老虎机式逐位滚动（Odometer）：刷新时滚动到位。
        Odometer(
          text: item.value,
          style: theme.textTheme.titleMedium!.copyWith(
            color: item.color,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class StatBandItem {
  const StatBandItem(this.label, this.value, {this.color, this.tooltip});
  final String label;
  final String value;
  final Color? color;
  final String? tooltip;
}

/// 大屏卡片网格：[tileWidth] 定宽的 Wrap（窄于 tileWidth 的容器自动
/// 退化为单列）。卡片保持各自内在高度，行距统一 [PageMeasure.gutter]；
/// 每张卡自动获得 hover 上浮 + 投影加深（180ms easeOut，与首页玻璃卡
/// 同一手感；触屏设备 MouseRegion 不触发，天然无影响）。
class CardWrap extends StatelessWidget {
  const CardWrap({super.key, required this.tileWidth, required this.children});

  final double tileWidth;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = tileWidth.clamp(0.0, constraints.maxWidth).toDouble();
        return Wrap(
          spacing: PageMeasure.gutter,
          runSpacing: PageMeasure.gutter,
          children: [
            for (final c in children) SizedBox(width: w, child: _LiftTile(child: c)),
          ],
        );
      },
    );
  }
}

/// 网格卡 hover 抬升：-3px 上浮 + 投影 + 0.5% 放大（与首页 _HoverLift
/// 同参数；此处为公共组件，供全站网格卡复用）。
class _LiftTile extends StatefulWidget {
  const _LiftTile({required this.child});

  final Widget child;

  @override
  State<_LiftTile> createState() => _LiftTileState();
}

class _LiftTileState extends State<_LiftTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: theme.brightness == Brightness.light
                        ? const Color(0x14000000)
                        : Colors.black.withValues(alpha: 0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: AnimatedScale(
          scale: _hover ? 1.005 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 提示语规范的最小单元：标题旁的小问号，悬停弹说明。
/// 禁止静态副标题/提示文字，一切「为什么是这个数」都挂在这里。
class InfoHint extends StatelessWidget {
  const InfoHint({super.key, required this.message, this.size = 14});

  final String message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 300),
      child: Icon(
        Icons.info_outline,
        size: size,
        color: Theme.of(context).hintColor.withValues(alpha: 0.7),
      ),
    );
  }
}
