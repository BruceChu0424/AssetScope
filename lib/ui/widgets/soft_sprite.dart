import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 白色径向软贴图（中心实、边缘零透明）——粒子系统的公共工艺：
/// `drawAtlas + BlendMode.modulate` 一批绘制逐粒着色并保留径向柔边
/// （白贴图 × 粒子色）。贴图按尺寸全局缓存，重复烘焙直接复用；
/// 共享缓存归公共所有，使用方**不得 dispose**。
const double kSoftSpriteSize = 64;

final Map<double, Future<ui.Image>> _spriteCache = {};

/// 烘焙 [size] 见方的软贴图（异步，同尺寸只烘一次）。
Future<ui.Image> bakeSoftSprite([double size = kSoftSpriteSize]) {
  return _spriteCache[size] ??= () {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size, size),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size / 2, size / 2),
          size / 2,
          [
            Colors.white,
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0),
          ],
          const [0.0, 0.35, 1.0],
        ),
    );
    return rec.endRecording().toImage(size.toInt(), size.toInt());
  }();
}
