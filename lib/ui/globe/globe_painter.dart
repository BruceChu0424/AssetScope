import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'globe_state.dart';

/// 点阵线框地球绘制器。
///
/// 视觉：深空背景上的青绿点阵大陆 + 细经纬网 + 呼吸光圈资产标记。
/// 标记按类别配色：资金金色、固定资产薄荷青，选中变浅蓝。
/// [landDots] 为 [lat, lon, lat, lon, ...] 扁平数组（assets/globe/land_dots.json）。
/// [pulse] 为 0~1 循环相位，驱动标记呼吸；[selectedId] 高亮当前选中。
/// [appear] 0~1 入场进度：大陆点阵按索引波式浮现、球缘渐显；
/// [t] 为经过秒数，驱动球缘呼吸微光。
/// [spawnIds]+[spawnAge]：新标记绽放（reload 差分出的新光点自 0 绽放
/// 0.45s——光束到达点亮时不瞬跳）。
class GlobePainter extends CustomPainter {
  GlobePainter({
    required this.landDots,
    required this.markers,
    required this.view,
    required this.pulse,
    this.selectedId,
    this.appear = 1,
    this.t = 0,
    this.spawnIds = const {},
    this.spawnAge = 99,
  });

  final List<double> landDots;
  final List<GlobeMarker> markers;
  final GlobeView view;
  final double pulse;
  final String? selectedId;
  final double appear;
  final double t;

  /// 本次 reload 新增的标记（accountId）；[spawnAge] 为距绽放开始的秒数。
  final Set<String> spawnIds;
  final double spawnAge;

  static const _dotColor = Color(0xFF6FA8DC);
  static const _gridColor = Color(0x146FA8DC);
  static const _markerColor = Color(0xFFE5C078); // 资金：金色
  static const _fixedColor = Color(0xFF7FD4C1); // 固定资产：薄荷青
  static const _markerCore = Color(0xFFFFF3D6);
  static const _fixedCore = Color(0xFFE9FFF9);
  static const _selectedColor = Color(0xFFC4DCF8);

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
        colors: const [Color(0x0E6FA8DC), Color(0x00000000)],
        stops: const [0.72, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius * 1.35, glow);
  }

  void _paintSphereBase(Canvas canvas, Offset center, double radius) {
    final base = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        colors: const [Color(0xFF0C1B2C), Color(0xFF050D18)],
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
      _strokeArc(
        canvas,
        center,
        radius,
        paint,
        (lon) => (lat.toDouble(), lon),
        -180,
        180,
      );
    }
    // 经线：本经线 + 对蹠经线构成完整大圆。
    for (var lon = -180; lon < 0; lon += 30) {
      for (final l in [lon.toDouble(), lon + 180.0]) {
        _strokeArc(canvas, center, radius, paint, (lat) => (lat, l), -88, 88);
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
    final total = landDots.length ~/ 2;
    var i = 0;
    for (var k = 0; k + 1 < landDots.length; k += 2, i++) {
      final p = view.project(landDots[k], landDots[k + 1], radius);
      if (p == null) continue;
      // 深度淡出：边缘的陆地更暗，形成球体立体感。
      final alpha = 0.25 + 0.65 * p.z.clamp(0.0, 1.0);
      // 入场：按索引错峰的波式浮现（appear*1.6 - 索引占比*0.6）。
      final sweep = (appear * 1.6 - (i / total) * 0.6).clamp(0.0, 1.0);
      final pop = Curves.easeOutCubic.transform(sweep);
      if (pop <= 0) continue;
      canvas.drawCircle(
        center + Offset(p.dx, p.dy),
        base * (0.7 + 0.5 * p.z) * (0.6 + 0.4 * pop),
        Paint()..color = _dotColor.withValues(alpha: alpha * pop),
      );
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
      // 新标记绽放：0.45s 自 0 长成（easeOutBack 轻过冲——像光点被
      // 「点亮」；恰与光束到达闪耀同时发生，覆盖浮现过程）。
      var bloom = 1.0;
      if (spawnIds.contains(m.accountId) && spawnAge < 0.45) {
        bloom = Curves.easeOutBack.transform(
          (spawnAge / 0.45).clamp(0.0, 1.0),
        );
      }
      if (bloom <= 0) {
        idx++;
        continue;
      }
      final r = markerRadiusFor(m.valueBaseMinor, maxValue, zoom: view.zoom) *
          bloom;
      final phase = (pulse + idx * 0.18) % 1.0;
      final selected = m.accountId == selectedId;
      final color = selected
          ? _selectedColor
          : (m.kind == MarkerKind.fixed ? _fixedColor : _markerColor);
      final core = m.valuationMissing
          ? color
          : (m.kind == MarkerKind.fixed ? _fixedCore : _markerCore);

      // 呼吸外环：半径与透明度随相位扩散。包络 sin(phase·π) 两端归零
      // ——环从核边淡入扩散、扩散中淡出、相位回绕时无可见跳变
      // （旧版 (1-phase) 包络在回绕处 0→0.55 瞬间弹现，每圈"咔"一下）。
      final spread = phase * r * 2.6;
      final ringAlpha = math.sin(phase * math.pi) * 0.55;
      canvas.drawCircle(
        pos,
        r + spread,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 + math.sin(phase * math.pi) * 1.4
          ..color = color.withValues(alpha: ringAlpha),
      );
      // 光晕 + 实心核。
      canvas.drawCircle(
        pos,
        r * 0.85,
        Paint()..color = color.withValues(alpha: 0.22),
      );
      canvas.drawCircle(pos, r * 0.55, Paint()..color = core);
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

  /// 球缘细描：一圈若有似无的青色 + 缓慢呼吸的外层辉光，聚拢视觉。
  void _paintRim(Canvas canvas, Offset center, double radius) {
    final breath = 0.5 + 0.5 * math.sin(t * 1.3);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _dotColor.withValues(alpha: (0.22 + 0.08 * breath) * appear),
    );
    // 大气辉光：球缘外侧一圈渐隐的青色环，随呼吸涨落。
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _dotColor.withValues(alpha: 0),
          _dotColor.withValues(alpha: 0.07 + 0.05 * breath),
          _dotColor.withValues(alpha: 0),
        ],
        stops: const [0.86, 0.97, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.12));
    canvas.drawCircle(center, radius * 1.12, glow);
  }

  @override
  bool shouldRepaint(GlobePainter oldDelegate) =>
      oldDelegate.pulse != pulse ||
      oldDelegate.view.lambda != view.lambda ||
      oldDelegate.view.phi != view.phi ||
      oldDelegate.view.zoom != view.zoom ||
      oldDelegate.selectedId != selectedId ||
      oldDelegate.appear != appear ||
      oldDelegate.t != t ||
      oldDelegate.spawnAge != spawnAge ||
      !identical(oldDelegate.markers, markers);
}
