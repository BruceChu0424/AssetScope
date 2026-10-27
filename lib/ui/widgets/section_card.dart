import 'package:flutter/material.dart';

/// 统一区块卡片：发丝线描边、圆角、可带标题与右侧动作。
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  });

  final String title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      )),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
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
            child: Text(label,
                style: emphasized
                    ? theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)
                    : theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.hintColor)),
          ),
          Text(
            value,
            style: (emphasized
                    ? theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: valueColor ?? theme.colorScheme.onSurface)
                    : theme.textTheme.bodyMedium
                        ?.copyWith(color: valueColor))
                ?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

/// 标签 + 金额 + 可选说明的统计瓦片（多列排布用）。
class AmountTile extends StatelessWidget {
  const AmountTile({
    super.key,
    required this.label,
    required this.amount,
    this.hint,
    this.color,
  });

  final String label;
  final String amount;
  final String? hint;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 3),
        Text(
          amount,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(hint!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor)),
          ),
      ],
    );
  }
}
