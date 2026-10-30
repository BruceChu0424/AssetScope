import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'dart:typed_data';

/// ── 弹窗溶解 · 时间轴（秒）───────────────────────────────────────────
/// 总程约 2.85s：接管 0.14 → 碎裂 0.10~0.88（波前延迟另计 0.16）→
/// 光束 0.55~1.70 → 汇聚 0.30 → 闪耀 0.65 → 淡出 0.30。
/// 碎裂幕与光束幕刻意交叠（0.55s 起飞时碎裂仍在收尾），衔接不断档。
const double kImageHold = 0.14; // 原图与粒子云交叉淡入
const double kShatterAt = 0.10; // 碎裂波自保存按钮扫出
const double kShatterDur = 0.62; // 单粒碎裂时长
const double kLaunchAt = 0.55; // 光束出鞘（同步触发地球飞行）
const double kTravelDur = 1.15; // 彗头全程（目标随地球飞行移动）
const double kBeamJoin = 0.38; // 散落粒子汇入光束
const double kConvergeAt = kLaunchAt + kTravelDur; // 到达落点
const double kConvergeDur = 0.30; // 粒子收束成点
const double kArriveFx = 0.65; // 落点闪耀（环/光柱/迸散）
const double kFadeAt = kConvergeAt + 0.80; // 全场淡出起点
const double kFadeDur = 0.30;
const double kDissolveTotal = kFadeAt + kFadeDur + 0.05;

/// 光束配色（墨蓝与香槟金体系，同 busy_overlay 粒子舞台）。
const Color kDissolveSteel = Color(0xFF7EA6D9);
const Color kDissolveSteelLight = Color(0xFF9DC0EA);
const Color kDissolveFog = Color(0xFFE7ECF2);
const Color kDissolveChampagne = Color(0xFFE5C078);
const Color kDissolveChampagneCore = Color(0xFFFFF3D6);

/// 舞台单调时钟（Ticker 推进 t，painter 挂 repaint 监听）。
class DissolveClock extends ChangeNotifier {
  double t = 0;

  /// 推进并通知（notifyListeners 是受保护成员，只能在类内调用）。
  void advance(double value) {
    t = value;
    notifyListeners();
  }
}

/// 单颗溶解粒子：全部参数在采样时一次性生成，painter 每帧只做纯函数
/// 求值（无逐帧状态、无 alloc），几千颗也稳定 60fps。
class DissolveParticle {
  DissolveParticle({
    required this.start,
    required this.color,
    required this.shade,
    required this.wave,
    required this.scatter,
    required this.swirl,
    required this.turbPhase,
    required this.turbFreq,
    required this.tail,
    required this.lateral,
    required this.radius,
    required this.beamColor,
  });

  /// 出发点（弹窗内采样位置，全局坐标）。
  final Offset start;

  /// 渲染色：采样色向亮色板提亮后的结果（暗底成微光、亮控件高亮）。
  final Color color;

  /// 采样亮度 0~1（驱动透明度，保持弹窗明暗层次）。
  final double shade;

  /// 碎裂波延迟（秒）：离保存按钮越远起爆越晚。
  final double wave;

  /// 碎裂飞散距离（px）。
  final double scatter;

  /// 涡旋角（弧度）：飞散方向随进度旋转出卷曲。
  final double swirl;

  final double turbPhase;
  final double turbFreq;

  /// 光束尾位 0（彗头）~ 0.55（末梢）——平方采样，头密尾疏。
  final double tail;

  /// 光束横向偏移幅度（带符号，px），越近落点越收拢。
  final double lateral;

  /// 基础半径（px，刻意小而密）。
  final double radius;

  /// 光束期颜色。
  final Color beamColor;
}

/// 弹窗捕获结果：截图 + 采样粒子云 + 光束几何锚点。
class DissolveCaptureData {
  DissolveCaptureData({
    required this.dialogRect,
    required this.image,
    required this.particles,
    required this.launchFrom,
    required this.bend,
  });

  /// 弹窗全局矩形（截图逐像素对位回屏幕）。
  final Rect dialogRect;

  /// 弹窗截图（逻辑像素 1:1）。生命周期归控制器，舞台只读。
  final ui.Image image;

  final List<DissolveParticle> particles;

  /// 光束起点（保存按钮中心，全局坐标）。
  final Offset launchFrom;

  /// 光束弧的弯向（±1，每次保存随机）。
  final double bend;
}

/// 把弹窗截图（rawRgba）采样成粒子云。
///
/// 步长按弹窗面积自适应（目标 [targetCount] 颗、上限 [maxCount]）——
/// 弹窗以后改尺寸/改内容，粒子数量与密度自动跟随，无需调参。
/// 透明像素跳过；采样色向亮色板提亮 45%——深底弹窗碎裂后在深空上
/// 依然清晰可辨，同时保留原明暗层次（shade 记录原始亮度）。
DissolveCaptureData sampleDissolve({
  required ui.Image image,
  required Uint8List rgba,
  required Rect dialogRect,
  required Offset launchFrom,
  int targetCount = 5200,
  int maxCount = 6600,
}) {
  final w = image.width;
  final h = image.height;
  final step = math.sqrt((w * h) / targetCount).clamp(3.5, 11.0).toDouble();
  final rnd = math.Random(7);
  final parts = <DissolveParticle>[];
  final longest = dialogRect.longestSide;
  for (var y = step * 0.5; y < h; y += step) {
    for (var x = step * 0.5; x < w; x += step) {
      if (parts.length >= maxCount) break;
      final px = x.toInt().clamp(0, w - 1);
      final py = y.toInt().clamp(0, h - 1);
      final i = (py * w + px) * 4;
      if (rgba[i + 3] < 0x28) continue; // 透明区（圆角/留白）不产粒子
      final r = rgba[i] / 255;
      final g = rgba[i + 1] / 255;
      final b = rgba[i + 2] / 255;
      final shade = 0.299 * r + 0.587 * g + 0.114 * b;
      // 亮色板三选一（钢蓝为主、雾白与香槟点缀），采样色向其靠拢。
      final c = rnd.nextDouble();
      final bright = c < 0.52
          ? kDissolveSteelLight
          : c < 0.84
          ? kDissolveFog
          : kDissolveChampagne;
      final origin = Color.fromARGB(255, rgba[i], rgba[i + 1], rgba[i + 2]);
      final bc = rnd.nextDouble();
      final jitter = (rnd.nextDouble() - 0.5) * step * 0.55;
      final start = Offset(
        dialogRect.left + x + jitter,
        dialogRect.top + y + (rnd.nextDouble() - 0.5) * step * 0.55,
      );
      parts.add(
        DissolveParticle(
          start: start,
          color: Color.lerp(origin, bright, 0.45)!,
          shade: shade,
          wave: (start - launchFrom).distance / longest * 0.16,
          scatter: 26 + rnd.nextDouble() * 94,
          swirl: (rnd.nextDouble() - 0.5) * 1.5,
          turbPhase: rnd.nextDouble() * math.pi * 2,
          turbFreq: 1.6 + rnd.nextDouble() * 2.2,
          tail: rnd.nextDouble() * rnd.nextDouble() * 0.55,
          lateral: (rnd.nextDouble() - 0.5) * 46,
          radius: 0.9 + rnd.nextDouble() * 1.1,
          beamColor: bc < 0.62
              ? kDissolveSteel
              : bc < 0.9
              ? kDissolveChampagne
              : kDissolveFog,
        ),
      );
    }
  }
  return DissolveCaptureData(
    dialogRect: dialogRect,
    image: image,
    particles: parts,
    launchFrom: launchFrom,
    bend: rnd.nextDouble() < 0.5 ? -1.0 : 1.0,
  );
}
