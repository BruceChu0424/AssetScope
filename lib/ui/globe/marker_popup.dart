import 'package:flutter/material.dart';

import '../../services/stats_service.dart';
import '../widgets/common.dart' show fmtMinor;
import 'globe_state.dart';

/// 同一位置附近的标记聚合（屏幕 34px 内视为一处），锚点弹窗一次展示。
class GlobePopupGroup {
  const GlobePopupGroup({required this.anchor, required this.markers});

  /// 主锚标记（离指针最近/被点中的那个）。
  final GlobeMarker anchor;

  /// 该处全部标记（含锚点）。
  final List<GlobeMarker> markers;

  String get key => anchor.accountId;
}

/// 锚点弹窗卡片：悬停/点选光点时出现在光点旁的迷你资产卡。
///
/// 动效：入场自 96% 轻微放大 + 6px 上浮 + 淡入（240ms easeOutCubic，
/// 放大原点在锚点一侧）；离场由外层 AnimatedSwitcher 160ms 淡出。
/// IgnorePointer 由外层负责——弹窗不抢手势，点击穿透到背后的光点
/// （再点一次即开详情页）。
class MarkerPopupCard extends StatelessWidget {
  const MarkerPopupCard({
    super.key,
    required this.group,
    required this.values,
    required this.base,
    this.below = false,
  });

  final GlobePopupGroup group;
  final Map<String, AccountValuationItem> values;

  /// 本位币代码（估值格式化用）。
  final String base;

  /// 弹窗出现在光点下方时，入场上浮方向反转（从下方长出来）。
  final bool below;

  static const double width = 252;

  @override
  Widget build(BuildContext context) {
    final shown = group.markers.take(3).toList();
    final overflow = group.markers.length - shown.length;
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xF0071320),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x307EA6D9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (below ? -6 : 6) * (1 - t)),
            child: Transform.scale(
              scale: 0.96 + 0.04 * t,
              alignment: below ? Alignment.topCenter : Alignment.bottomCenter,
              child: _content(shown, overflow),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(List<GlobeMarker> shown, int overflow) {
    final anchorColor = group.anchor.kind == MarkerKind.fixed
        ? const Color(0xFF7FD4C1)
        : const Color(0xFFE5C078);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, size: 13, color: anchorColor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                group.anchor.locationName ?? group.anchor.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _kindPill(group.anchor.kindLabel, anchorColor),
          ],
        ),
        for (final m in shown) ...[
          const SizedBox(height: 7),
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  color: m.kind == MarkerKind.fixed
                      ? const Color(0xFF7FD4C1)
                      : const Color(0xFFE5C078),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    if (m.institution != null)
                      Text(
                        m.institution!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF7EA6D9).withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _valueText(m),
            ],
          ),
        ],
        if (overflow > 0) ...[
          const SizedBox(height: 6),
          Text(
            '同址还有 $overflow 处资产',
            style: TextStyle(
              color: const Color(0xFF7EA6D9).withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _valueText(GlobeMarker m) {
    final item = values[m.accountId];
    final hasValue = item != null && !item.valuationMissing;
    return Text(
      hasValue ? fmtMinor(m.valueBaseMinor, base) : '缺估值',
      style: TextStyle(
        color: hasValue
            ? Colors.white
            : const Color(0xFFF0907C).withValues(alpha: 0.8),
        fontSize: 12,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _kindPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, height: 1.4),
      ),
    );
  }
}
