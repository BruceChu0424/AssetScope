import 'package:flutter/material.dart';

import '../../services/stats_service.dart';
import '../widgets/common.dart' show fmtMinor;
import 'globe_state.dart';

/// 标记详情底部弹层：地球上对已选中标记再次点击时打开。
void showMarkerDetailSheet(
  BuildContext context, {
  required GlobeMarker marker,
  required AccountValuationItem? item,
  required String base,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: const Color(0xFF0A1420),
    builder: (_) => _MarkerDetailSheet(marker: marker, item: item, base: base),
  );
}

class _MarkerDetailSheet extends StatelessWidget {
  const _MarkerDetailSheet({
    required this.marker,
    required this.item,
    required this.base,
  });

  final GlobeMarker marker;
  final AccountValuationItem? item;
  final String base;

  @override
  Widget build(BuildContext context) {
    final hasValue = item != null && !item!.valuationMissing;
    final color = marker.kind == MarkerKind.fixed
        ? const Color(0xFF7FD4C1)
        : const Color(0xFFE5C078);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    marker.locationName ?? marker.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${marker.name} · ${marker.lat.toStringAsFixed(2)}°, ${marker.lon.toStringAsFixed(2)}°',
              style: TextStyle(
                color: Colors.tealAccent.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            _row('资产类别', '${marker.subtypeLabel} · ${marker.kindLabel}'),
            if (marker.institution != null) _row('机构', marker.institution!),
            _row(
              '当前价值',
              hasValue ? fmtMinor(item!.valueBaseMinor, base) : '缺估值（不计净资产）',
            ),
            if (item != null && item!.valuationStale)
              _row('估值状态', '已过期（>30 天未更新）'),
            _row('计价币种', marker.currencyCode),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.tealAccent.withValues(alpha: 0.6)),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}
