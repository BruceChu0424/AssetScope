import 'package:flutter/material.dart';

import 'particle_edge.dart';

/// 统一区块卡片：发丝线描边、圆角、可带标题与右侧动作。
/// [titleWidget] 非空时替代 [title]（动态标题/带动画的标题用它）。
/// 外层自动带 hover 底缘光尘（docs/12 §9 默认动效）。
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.titleWidget,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  });

  final String title;
  final Widget? titleWidget;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ParticleEdge(
      band: 22,
      child: Card(
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child:
                        titleWidget ??
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// 列表行内的「标签 — 数值」行（无内边距，等宽数字）。
class StatRow extends StatelessWidget {
  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasized
                  ? theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    )
                  : theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
            ),
          ),
          Text(
            value,
            style:
                (emphasized
                        ? theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: valueColor ?? theme.colorScheme.onSurface,
                          )
                        : theme.textTheme.bodyMedium?.copyWith(
                            color: valueColor,
                          ))
                    ?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
          ),
        ],
      ),
    );
  }
}

/// 标签 + 金额 + 可选说明的统计瓦片（多列排布用）。
/// [tooltip] 非空时标签旁出现 info 小图标，悬停显示提示——静态说明
/// 文字不得直接展示（提示语规范，docs/12 §9）。
class AmountTile extends StatelessWidget {
  const AmountTile({
    super.key,
    required this.label,
    required this.amount,
    this.tooltip,
    this.color,
  });

  final String label;
  final String amount;

  /// 悬停提示（替代旧版静态 hint 文字）。
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (tooltip != null) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: tooltip,
                child: Icon(
                  Icons.info_outline,
                  size: 13,
                  color: theme.hintColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          amount,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
