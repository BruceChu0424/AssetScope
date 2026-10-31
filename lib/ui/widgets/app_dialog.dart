import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'page_frame.dart' show PageMeasure;
import 'particle_dialog.dart';
import 'particle_edge.dart';

/// 统一弹窗体系（v0.25）：
///
/// - [AppDialog] + [showAppDialog]：居中悬浮表单/确认弹窗。桌面观感的
///   玻璃卡家族（发丝线 + 18 圆角），标题行带关闭钮，动作区右对齐、
///   按钮与输入框同高（主题层 48）。**进出场全部粒子化**
///   （showParticleDialog）：入场四散汇聚成弹窗形态（0.82s），退场
///   截图粒子化——取消温和外散、确认先收束再迸散闪光环。
/// - [showAppSheet]：详情/工作流面板。**大屏（≥900）= 右缘侧滑面板**
///   （粒子汇聚 + 自右落位，退场粒子化）；小屏 = 常规底部弹层。
///   一处 API，两种形态。
///
/// 「减少动画」/测试环境一律退回淡入切换。所有弹窗尊重这套体系，
/// 禁止页面再裸调 showDialog/showModalBottomSheet 自造容器。

/// 居中悬浮弹窗容器：统一宽度（[width]，默认 [AppMeasure.dialogW]）、
/// 标题行（图标可选 + 关闭钮）、内容、底部动作区。标题旁可挂
/// [titleTooltip]（info 图标悬停弹说明——提示语规范）。
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.icon,
    this.titleTooltip,
    this.width = AppMeasure.dialogW,
    this.scroll = false,
  });

  final String title;

  /// 标题行左侧的图标（语义强化，如删除类用警示色）。
  final IconData? icon;

  /// 标题旁 info 图标的悬停提示（如「为什么需要位置」）。
  final String? titleTooltip;
  final Widget content;
  final List<Widget> actions;

  /// 内容超高时内部滚动（长表单传 true）。
  final bool scroll;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (titleTooltip != null) ...[
              Tooltip(
                message: titleTooltip,
                waitDuration: const Duration(milliseconds: 400),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const _DialogCloseButton(),
          ],
        ),
        const SizedBox(height: 18),
        scroll
            ? Flexible(child: SingleChildScrollView(child: content))
            : content,
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 22),
          // OverflowBar（与 AlertDialog 同款）：动作拿到**有界**宽度——
          // 内含 Expanded 的整行动作（如新建资产的一行双钮）可铺满，
          // 普通按钮按固有宽度右对齐、超宽自动换行。
          OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 10,
            children: actions,
          ),
        ],
      ],
    );
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ParticleEdge(
        band: 18,
        extendBelow: 8,
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.light
                    ? const Color(0x1F000000)
                    : Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          // 透明 Material 垫层：ListTile/InkWell 的墨迹画在最近的 Material
          // 上——不垫的话壳底色（DecoratedBox）会盖住水波/选中态并触发
          // 框架断言（AlertDialog 原生就是 Material 表面）。
          child: Material(
            color: Colors.transparent,
            child: body,
          ),
        ),
      ),
    );
  }
}

/// 弹窗右上角幽灵关闭钮（与页面 ActionIcon 同手感，36 命中区）。
class _DialogCloseButton extends StatefulWidget {
  const _DialogCloseButton();

  @override
  State<_DialogCloseButton> createState() => _DialogCloseButtonState();
}

class _DialogCloseButtonState extends State<_DialogCloseButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: AppLocalizations.of(context).wdgCloseEsc,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hover
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            child: Icon(
              Icons.close,
              size: 18,
              color: theme.hintColor.withValues(alpha: _hover ? 1 : 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

/// 打开居中悬浮弹窗：粒子化进退场（见文件头；showParticleDialog）。
/// [barrierDismissible] 点遮罩关闭；返回值类型与 showDialog 一致。
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  return showParticleDialog<T>(
    context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
  );
}

/// 详情/工作流面板：大屏右缘侧滑（贴右全高、左缘 20 圆角），小屏底部
/// 弹层。退场原路返回，动画完整。
///
/// [builder] 只需给内容（自带内边距，如 24/0/24/24）；面板壳（宽度、
/// 圆角、滑动）由这里承担。小屏时透传 [bottomSheetBuilder] 定制参数
/// （默认带拖拽把）。
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
  Color? backgroundColor,
  bool scrollControlled = false,
}) {
  final wide = MediaQuery.sizeOf(context).width >= PageMeasure.wide;
  if (!wide) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: scrollControlled,
      showDragHandle: true,
      backgroundColor: backgroundColor,
      builder: builder,
    );
  }
  final theme = Theme.of(context);
  final bg = backgroundColor ?? theme.colorScheme.surface;
  // 大屏 = 粒子化右缘面板：粒子自四周汇入面板轮廓，表面自右侧落位，
  // 退场粒子化消散（showParticleDialog 统一编排）。
  return showParticleDialog<T>(
    context,
    barrierDismissible: dismissible,
    barrierColor: theme.brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.20)
        : Colors.black.withValues(alpha: 0.42),
    alignment: Alignment.centerRight,
    entryFrom: const Offset(1, 0),
    builder: (context) => Material(
      color: bg,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: AppMeasure.sideSheetW,
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.dividerColor, width: 1),
          ),
        ),
        child: Builder(builder: builder),
      ),
    ),
  );
}
