import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'dissolve_particles.dart';
import 'soft_sprite.dart';

/// 弹窗溶解舞台画笔：四幕连台（时间轴常量见 [dissolve_particles.dart]）。
/// 全部粒子每帧**纯函数求值**（无逐帧状态），软粒子经 drawAtlas 单批
/// 绘制；光束路径随 [target] 每帧重算——地球飞行/扩张中彗头实时追踪。
class DissolveStagePainter extends CustomPainter {
  DissolveStagePainter({
    required this.clock,
    required this.data,
    required this.sprite,
    required this.target,
  }) : super(repaint: clock);

  final DissolveClock clock;
  final DissolveCaptureData data;
  final ui.Image? sprite;
  final Offset? target;

  final List<ui.RSTransform> _xf = [];
  final List<Color> _cols = [];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = clock.t;
    if (t >= kDissolveTotal) return;
    final tgt = target ?? size.center(Offset.zero);

    // 第一幕 · 无缝接管：原图淡出的同时粒子云淡入（同帧同位）。
    final imgAlpha = (1 - t / kImageHold).clamp(0.0, 1.0);
    if (imgAlpha > 0) {
      canvas.drawImageRect(
        data.image,
        Rect.fromLTWH(
          0,
          0,
          data.image.width.toDouble(),
          data.image.height.toDouble(),
        ),
        data.dialogRect,
        Paint()
          ..color = Colors.white.withValues(alpha: imgAlpha)
          ..filterQuality = FilterQuality.medium,
      );
    }

    // 光束几何：起点=保存按钮，终点=落点（随地球转动移动），控制点
    // 向侧向弓起 + 轻微上扬——一道甩出去的弧形光束。
    final p0 = data.launchFrom;
    final dir = tgt - p0;
    final len = dir.distance;
    final perp = len < 1 ? const Offset(0, -1) : Offset(-dir.dy, dir.dx) / len;
    final ctrl =
        (p0 + tgt) / 2 +
        perp * (len * 0.16 * data.bend) +
        Offset(0, -len * 0.06);
    Offset bez(double s) {
      final im = 1 - s;
      return p0 * (im * im) + ctrl * (2 * im * s) + tgt * (s * s);
    }

    final headU = Curves.easeInOutCubic.transform(
      ((t - kLaunchAt) / kTravelDur).clamp(0.0, 1.0),
    );
    final joinU = Curves.easeInOutCubic.transform(
      ((t - kLaunchAt) / kBeamJoin).clamp(0.0, 1.0),
    );
    final convE = Curves.easeOutCubic.transform(
      ((t - kConvergeAt) / kConvergeDur).clamp(0.0, 1.0),
    );
    final drain =
        ((t - kConvergeAt - kConvergeDur) /
                (kFadeAt - kConvergeAt - kConvergeDur))
            .clamp(0.0, 1.0);

    _xf.clear();
    _cols.clear();
    for (final p in data.particles) {
      var pos = p.start;
      var radius = p.radius;
      var alpha = 0.45 + 0.55 * p.shade;
      if (t < kImageHold) alpha *= t / kImageHold;

      // 第二幕 · 碎裂：波前自保存按钮扫过，粒子外抛 + 涡旋 + 湍流。
      final u = ((t - kShatterAt - p.wave) / kShatterDur).clamp(0.0, 1.0);
      if (u > 0) {
        final e = Curves.easeOutCubic.transform(u);
        var d = _dirFrom(p.start, p0) * (p.scatter * e);
        final a = p.swirl * e;
        final c = math.cos(a);
        final s = math.sin(a);
        d = Offset(d.dx * c - d.dy * s, d.dx * s + d.dy * c);
        final bell = math.sin(u * math.pi);
        pos =
            p.start +
            d +
            Offset(
                  math.sin(u * 2 * math.pi * p.turbFreq + p.turbPhase),
                  math.cos(u * 2 * math.pi * p.turbFreq * 0.8 + p.turbPhase),
                ) *
                (5 * bell) +
            Offset(0, -14 * e * e);
        radius *= 1 + 0.45 * bell;
        alpha *= 0.95 - 0.3 * bell;
      }

      // 第三幕 · 光束：散落粒子汇入彗尾（头密尾疏、越近落点越收拢）。
      if (joinU > 0) {
        final s = (headU * (1 + p.tail) - p.tail).clamp(0.0, 1.0);
        final beam =
            bez(s) +
            perp * (p.lateral * (1 - 0.8 * headU)) +
            Offset(
                  math.sin(t * 6.3 + p.turbPhase),
                  math.cos(t * 5.1 + p.turbPhase),
                ) *
                1.6;
        pos = Offset.lerp(pos, beam, joinU)!;
        radius *= 1.25 - 0.5 * (p.tail / 0.55);
        alpha += ((p.tail < 0.1 ? 0.95 : 0.8) - alpha) * joinU;
      }

      // 第四幕 · 汇聚：全体收束到落点，凝成标志后随迸散消散。
      if (convE > 0) {
        pos = Offset.lerp(pos, tgt, convE)!;
        radius *= 1 - 0.55 * convE;
        alpha *= 1 - 0.2 * convE;
      }
      alpha *= 1 - drain;
      if (alpha <= 0.02) continue;
      final color = Color.lerp(p.color, p.beamColor, joinU * 0.8)!;
      _soft(canvas, pos, radius, color.withValues(alpha: alpha));
    }
    _flushAtlas(canvas, size);

    if (t >= kLaunchAt && t < kConvergeAt + 0.06) {
      _paintHead(canvas, bez(headU), t, headU);
    }
    if (t >= kConvergeAt) _paintArrival(canvas, tgt, t - kConvergeAt);
  }

  /// 软粒子入批（贴图就绪走 drawAtlas，否则退化硬圆点）。
  void _soft(Canvas canvas, Offset pos, double radius, Color color) {
    if (sprite == null) {
      canvas.drawCircle(pos, radius * 0.6, Paint()..color = color);
      return;
    }
    _xf.add(ui.RSTransform(radius * 2 / kSoftSpriteSize, 0, pos.dx, pos.dy));
    _cols.add(color);
  }

  void _flushAtlas(Canvas canvas, Size size) {
    if (sprite == null || _xf.isEmpty) return;
    canvas.drawAtlas(
      sprite!,
      _xf,
      List.filled(
        _xf.length,
        const Rect.fromLTWH(0, 0, kSoftSpriteSize, kSoftSpriteSize),
      ),
      _cols,
      BlendMode.modulate, // 白贴图 × 粒子色 = 逐粒着色并保留径向柔边
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium,
    );
  }

  /// 彗头发光头：三层渐变（钢蓝外晕→香槟中晕→白核）+ 环绕微芒。
  void _paintHead(Canvas canvas, Offset pos, double t, double headU) {
    final fade = (headU / 0.06).clamp(0.0, 1.0); // 出鞘瞬间点亮
    canvas.drawCircle(
      pos,
      26,
      _radial(pos, 26, kDissolveSteelLight.withValues(alpha: 0.20 * fade)),
    );
    canvas.drawCircle(
      pos,
      13,
      _radial(pos, 13, kDissolveChampagne.withValues(alpha: 0.42 * fade)),
    );
    canvas.drawCircle(
      pos,
      4.5,
      Paint()..color = kDissolveChampagneCore.withValues(alpha: 0.95 * fade),
    );
    for (var k = 0; k < 12; k++) {
      final ang = k * 2.399963 + t * 5.0;
      final dist = 7 + (k * 37 % 100) / 100 * 9;
      canvas.drawCircle(
        pos + Offset(math.cos(ang), math.sin(ang)) * dist,
        1.1,
        Paint()
          ..color = (k % 3 == 0 ? kDissolveFog : kDissolveChampagne).withValues(
            alpha: 0.75 * fade,
          ),
      );
    }
  }

  /// 落点闪耀：双扩散环 + 中心绽放 + 向上光柱 + 径向迸散火花
  /// （[u] 为到达后经过的秒数）。标记本身由地球侧在同一时刻重载点亮，
  /// 闪耀的光效恰好覆盖其浮现。
  void _paintArrival(Canvas canvas, Offset tgt, double u) {
    if (u < 0.5) {
      final e = Curves.easeOutCubic.transform(u / 0.5);
      canvas.drawCircle(
        tgt,
        8 + 46 * e,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 - 1.6 * e
          ..color = kDissolveChampagne.withValues(alpha: 0.85 * (1 - e)),
      );
    }
    if (u >= 0.11 && u < 0.61) {
      final e = Curves.easeOutCubic.transform((u - 0.11) / 0.5);
      canvas.drawCircle(
        tgt,
        6 + 30 * e,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 - 1.1 * e
          ..color = kDissolveSteelLight.withValues(alpha: 0.6 * (1 - e)),
      );
    }
    if (u < 0.4) {
      final e = 1 - u / 0.4;
      canvas.drawCircle(
        tgt,
        30 * (1.15 - 0.15 * e),
        _radial(tgt, 30, kDissolveChampagneCore.withValues(alpha: 0.5 * e * e)),
      );
    }
    if (u < kArriveFx) {
      final grow = Curves.easeOutCubic.transform((u / 0.3).clamp(0.0, 1.0));
      final fade = 1 - u / kArriveFx;
      final top = tgt - Offset(0, 60 * grow);
      for (final (w, a) in const [(2.4, 0.9), (7.0, 0.20)]) {
        canvas.drawLine(
          tgt,
          top,
          Paint()
            ..strokeWidth = w
            ..strokeCap = StrokeCap.round
            ..shader = ui.Gradient.linear(
              tgt,
              top,
              [
                kDissolveChampagneCore.withValues(alpha: a * fade),
                kDissolveChampagne.withValues(alpha: a * 0.5 * fade),
                kDissolveChampagne.withValues(alpha: 0),
              ],
              const [0.0, 0.45, 1.0],
            ),
        );
      }
    }
    if (u < 0.46) {
      final e = Curves.easeOutCubic.transform(u / 0.46);
      for (var k = 0; k < 26; k++) {
        final ang = _hash(k, 1) * math.pi * 2;
        final dist = (12 + _hash(k, 2) * 52) * e;
        final size = 1.6 * (1 - e * 0.8);
        canvas.drawCircle(
          tgt + Offset(math.cos(ang), math.sin(ang)) * dist,
          size,
          Paint()
            ..color =
                (_hash(k, 3) < 0.3
                        ? kDissolveChampagneCore
                        : kDissolveChampagne)
                    .withValues(alpha: 0.9 * (1 - e)),
        );
      }
    }
  }

  /// 径向渐变圆（中心 [inner] → 边缘透明）。
  static Paint _radial(Offset c, double r, Color inner) => Paint()
    ..shader = ui.Gradient.radial(c, r, [inner, inner.withValues(alpha: 0)]);

  /// 稳定伪随机 0~1（无状态迸散火花，跨帧不闪跳）。
  static double _hash(int k, int salt) {
    final v = math.sin(k * 12.9898 + salt * 78.233) * 43758.5453;
    return v - v.floor();
  }

  /// 碎裂方向：自保存按钮指向粒子；恰在按钮上的给固定斜向上初速。
  static Offset _dirFrom(Offset from, Offset origin) {
    final d = from - origin;
    final l = d.distance;
    return l < 0.001 ? const Offset(0.2, -0.98) : d / l;
  }

  @override
  bool shouldRepaint(DissolveStagePainter old) =>
      old.target != target || old.sprite != sprite;
}
