import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'globe_state.dart';

/// 点阵线框地球绘制器。
///
/// 视觉：深空背景上的青绿点阵大陆 + 细经纬网 + 呼吸光圈资产标记。
/// [landDots] 为 [lat, lon, lat, lon, ...] 扁平数组（assets/globe/land_dots.json）。
/// [pulse] 为 0~1 循环相位，驱动标记呼吸；[selectedId] 高亮当前选中。
class GlobePainter extends CustomPainter {
  GlobePainter({
    required this.landDots,
    required this.markers,
    required this.view,
    required this.pulse,
    this.selectedId,
  });

  final List<double> landDots;
  final List<GlobeMarker> markers;
  final GlobeView view;
  final double pulse;
  final String? selectedId;

  static const _dotColor = Color(0xFF2DD4BF);
  static const _gridColor = Color(0x1432D4B8);
  static const _markerColor = Color(0xFFF5B841);
  static const _markerCore = Color(0xFFFFE9C4);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.86 * view.zoom;

    _paintSpaceGlow(canvas, center, radius);
    _paintSphereBase(canvas, center, radius);
    _paintGraticule(canvas, center, radius);
    _paintLandDots(canvas, center, radius);
    _paintMarkers(canvas, center, radius);
    _paintRim(canvas, center, radius);
  }

  /// 深空氛围：径向渐变 + 外圈微光（黑客感来自克制的青色辉光）。
  void _paintSpaceGlow(Canvas canvas, Offset center, double radius) {
    final rect = Rect.fromCircle(center: center, radius: radius * 1.35);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0x0E2DD4BF),
          Color(0x00000000),
        ],
        stops: const [0.72, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius * 1.35, glow);
  }

  void _paintSphereBase(Canvas canvas, Offset center, double radius) {
    final base = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        colors: const [Color(0xFF0D1E30), Color(0xFF060D18)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, base);
  }

  /// 经纬网：每 30°，仅正面段。
  void _paintGraticule(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = _gridColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    // 纬线：经度扫整圈。
    for (var lat = -60; lat <= 60; lat += 30) {
      _strokeArc(canvas, center, radius, paint,
          (lon) => (lat.toDouble(), lon), -180, 180);
    }
    // 经线：本经线 + 对蹠经线构成完整大圆。
    for (var lon = -180; lon < 0; lon += 30) {
      for (final l in [lon.toDouble(), lon + 180.0]) {
        _strokeArc(canvas, center, radius, paint,
            (lat) => (lat, l), -88, 88);
      }
    }
  }

  void _strokeArc(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    (double, double) Function(double) point,
    double from,
    double to,
  ) {
    var started = false;
    final path = Path();
    for (var t = from; t <= to; t += 4) {
      final (lat, lon) = point(t);
      final p = view.project(lat, lon, radius);
      if (p == null) {
        started = false;
        continue;
      }
      final pos = center + Offset(p.dx, p.dy);
      if (!started) {
        path.moveTo(pos.dx, pos.dy);
        started = true;
      } else {
        path.lineTo(pos.dx, pos.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _paintLandDots(Canvas canvas, Offset center, double radius) {
    // 点大小随缩放与深度：正面稍大更通透。
    final base = 1.05 * (view.zoom * 0.8 + 0.4);
    for (var i = 0; i + 1 < landDots.length; i += 2) {
      final p = view.project(landDots[i], landDots[i + 1], radius);
      if (p == null) continue;
      // 深度淡出：边缘的陆地更暗，形成球体立体感。
      final alpha = 0.25 + 0.65 * p.z.clamp(0.0, 1.0);
      final paint = Paint()..color = _dotColor.withValues(alpha: alpha);
      canvas.drawCircle(center + Offset(p.dx, p.dy), base * (0.7 + 0.5 * p.z), paint);
    }
  }

  void _paintMarkers(Canvas canvas, Offset center, double radius) {
    var maxValue = BigInt.zero;
    for (final m in markers) {
      if (m.valueBaseMinor > maxValue) maxValue = m.valueBaseMinor;
    }
    // 背面标记不画；呼吸相位对每个标记错开一点，避免同步闪烁。
    var idx = 0;
    for (final m in markers) {
      final p = view.project(m.lat, m.lon, radius);
      if (p == null) continue;
      final pos = center + Offset(p.dx, p.dy);
      final r = markerRadiusFor(m.valueBaseMinor, maxValue);
      final phase = (pulse + idx * 0.18) % 1.0;
      final selected = m.accountId == selectedId;
      final color = selected ? const Color(0xFF7FF0DC) : _markerColor;

      // 呼吸外环：半径与透明度随相位扩散。
      final spread = phase * r * 2.6;
      final ringAlpha = (1 - phase) * 0.55;
      canvas.drawCircle(
        pos,
        r + spread,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 + (1 - phase) * 1.4
          ..color = color.withValues(alpha: ringAlpha),
      );
      // 光晕 + 实心核。
      canvas.drawCircle(
        pos,
        r * 0.85,
        Paint()..color = color.withValues(alpha: 0.22),
      );
      canvas.drawCircle(
        pos,
        r * 0.55,
        Paint()..color = m.valuationMissing ? _markerColor : _markerCore,
      );
      // 名称标签：仅选中或悬停大小达标时显示，避免过密。
      if (selected || r >= 14) {
        final tp = TextPainter(
          text: TextSpan(
            text: m.locationName ?? m.name,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, pos + Offset(-tp.width / 2, r + 8));
      }
      idx++;
    }
  }

  /// 球缘细描：一圈若有似无的青色，聚拢视觉。
  void _paintRim(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _dotColor.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(GlobePainter oldDelegate) =>
      oldDelegate.pulse != pulse ||
      oldDelegate.view.lambda != view.lambda ||
      oldDelegate.view.phi != view.phi ||
      oldDelegate.view.zoom != view.zoom ||
      oldDelegate.selectedId != selectedId ||
      !identical(oldDelegate.markers, markers);
}
