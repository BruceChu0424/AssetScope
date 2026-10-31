import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import 'dissolve_particles.dart';
import 'soft_sprite.dart';

export 'dissolve_particles.dart'
    show DissolveCaptureData, DissolveParticle, sampleDissolve, kDissolveChampagne;

/// ── 弹窗粒子化 · 时间轴（秒）─────────────────────────────────────────
///
/// 入场「四散汇聚成弹窗形态」总程 0.82s：粒子自弹窗四周（环带）出发，
/// 螺旋内旋汇入弹窗轮廓网格；第 0.50s 起弹窗表面开始显形（淡入 +
/// 0.965→1 放大 + 自 [ParticleDialogHost.entryFrom] 方向落位），粒子
/// 到位即化作表面微光消隐。尘云层（烘焙贴图 ×3 层）提供数万颗的
/// 密度视效，运动由活粒子承担。
const double kConvTotal = 0.82; // 入场总程
const double kConvSurfaceAt = 0.50; // 表面开始显形
const double kConvSurfaceDur = 0.30; // 表面显形时长（与总程衔接留 0.02 尾）

/// 退场「粒子化消散/迸散」总程：取消（scatter）0.80s、确认（burst）
/// 0.94s。截图与采样粒子云无缝交接（弹窗「原地变成粒子」，与 dissolve
/// 第一幕同工艺）→ 取消类温和外散；确认类先向弹窗核心收束 0.20s，再
/// 迸散 + 闪光环——「确认 → 能量释放」。
const double kExitHandoff = 0.12; // 原图 ↔ 粒子云交叉淡入淡出
const double kExitBreakAt = 0.06; // scatter：碎裂波前起点
const double kExitScatterDur = 0.60; // 单粒碎裂时长
const double kExitImplodeAt = 0.06; // burst：向心收束起点
const double kExitImplodeDur = 0.20; // burst：收束时长
const double kExitBurstBreakAt = 0.28; // burst：迸散波前起点（收束完成）
const double kExitFadeAt = 0.46; // 全场淡出起点
const double kExitFadeDur = 0.30;
const double kExitTotal = 0.80; // scatter 总程
const double kExitTotalBurst = 0.94; // burst 总程

/// 退场形态。
enum DialogExitKind {
  /// 取消/关闭：温和外散（自弹窗中心起波）。
  scatter,

  /// 确认/保存（返回值非 null）：先向核心收束再迸散 + 闪光环。
  burst,
}

/// 单颗汇聚粒子：全部参数采样时一次性生成，painter 每帧纯函数求值。
class ConvergeParticle {
  ConvergeParticle({
    required this.start,
    required this.target,
    required this.delay,
    required this.dur,
    required this.curl,
    required this.radius,
    required this.color,
    required this.depth,
  });

  /// 出发点（全局坐标，弹窗四周环带）。
  final Offset start;

  /// 落点（弹窗轮廓内的采样网格点，全局坐标）。
  final Offset target;

  final double delay;
  final double dur;

  /// 螺旋内旋的横向摆幅（px，带符号——一半顺旋一半逆旋）。
  final double curl;

  final double radius;

  /// 渲染色（钢蓝为主、雾白与香槟点缀）。
  final Color color;

  /// 远近层 0~1：驱动亮度与到核收束的先后（近层先落位）。
  final double depth;
}

/// 弹窗轮廓 → 汇聚粒子云（数量随面积自适应，同 sampleDissolve 预算）。
///
/// 落点在圆角矩形内均匀采样（透明区不存在——入场时表面尚未绘制，以
/// 轮廓全域为目标，表面随后显形恰好覆盖）；出发自中心环带
/// （外接椭圆 1.05~2.05 倍），到站时刻聚拢在 0.58~0.82s——四周同时
/// 出发、几乎同时成形。
List<ConvergeParticle> sampleConvergence({
  required Rect rect,
  int targetCount = 5200,
  int maxCount = 6600,
  int seed = 19,
}) {
  final step = math
      .sqrt((rect.width * rect.height) / targetCount)
      .clamp(3.5, 11.0)
      .toDouble();
  final rnd = math.Random(seed);
  final center = rect.center;
  final halfDiag = Offset(rect.width / 2, rect.height / 2).distance;
  final parts = <ConvergeParticle>[];
  for (var y = step * 0.5; y < rect.height; y += step) {
    for (var x = step * 0.5; x < rect.width; x += step) {
      if (parts.length >= maxCount) break;
      final target = rect.topLeft + Offset(x, y);
      final angle = rnd.nextDouble() * math.pi * 2;
      final dist = halfDiag * (1.05 + rnd.nextDouble() * 1.0);
      final start = center + Offset(math.cos(angle), math.sin(angle)) * dist;
      final delay = rnd.nextDouble() * 0.22;
      final arrival = 0.58 + rnd.nextDouble() * 0.24;
      final c = rnd.nextDouble();
      parts.add(
        ConvergeParticle(
          start: start,
          target: target,
          delay: delay,
          dur: (arrival - delay).clamp(0.30, 0.62),
          curl: (rnd.nextDouble() - 0.5) * 2 * (14 + rnd.nextDouble() * 26),
          radius: 0.9 + rnd.nextDouble() * 1.1,
          color: c < 0.52
              ? kDissolveSteelLight
              : c < 0.84
              ? kDissolveFog
              : kDissolveChampagne,
          depth: rnd.nextDouble(),
        ),
      );
    }
  }
  return parts;
}

/// ── 尘云烘焙（「数十万粒子」的密度视效）──────────────────────────────
/// 一次性把 ~3600 颗高斯分布微尘烘进 512² 贴图并全局缓存；入场时以
/// 3 层不同旋转/缩放/相位绘制（每层一次 drawImageRect，近零帧成本），
/// 与活粒子叠出数万颗尘埃涌动的观感。共享单例，使用方不得 dispose。
const double kDustCloudSize = 512;

Future<ui.Image> _bakeDustCloud() {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final rnd = math.Random(31);
  final half = kDustCloudSize / 2;
  for (var i = 0; i < 3600; i++) {
    // 高斯径向分布：中心密、边缘疏（Box-Muller 极坐标近似）。
    final r = half *
        math.sqrt(-math.log(rnd.nextDouble() + 0.001)) *
        0.42;
    final a = rnd.nextDouble() * math.pi * 2;
    final p = Offset(half, half) + Offset(math.cos(a), math.sin(a)) * r;
    if ((p - Offset(half, half)).distance > half - 2) continue;
    final c = rnd.nextDouble();
    final color = c < 0.55
        ? kDissolveSteelLight
        : c < 0.85
        ? kDissolveFog
        : kDissolveChampagne;
    canvas.drawCircle(
      p,
      0.6 + rnd.nextDouble() * 1.3,
      Paint()..color = color.withValues(alpha: 0.05 + rnd.nextDouble() * 0.3),
    );
  }
  return rec.endRecording().toImage(kDustCloudSize.toInt(), kDustCloudSize.toInt());
}

final Future<ui.Image> _dustCloud = _bakeDustCloud();

/// 尘云贴图（可能未就绪——就绪前 painter 只画活粒子）。
Future<ui.Image>? dustCloudImage() => _dustCloud;

/// 单层尘云的烘焙参数（每场随机三份，入场期旋转收拢）。
class DustLayer {
  DustLayer(this.rot, this.spin, this.scaleFrom, this.scaleTo, this.alphaPeak);

  final double rot; // 起始旋转
  final double spin; // 全程旋转量（rad）
  final double scaleFrom; // 相对目标外接矩形的起始倍数
  final double scaleTo;
  final double alphaPeak; // 包络峰值透明度
}

List<DustLayer> bakeDustLayers(math.Random rnd) => [
  DustLayer(rnd.nextDouble() * math.pi * 2, 0.55 + rnd.nextDouble() * 0.3,
      2.7, 1.15, 0.34),
  DustLayer(rnd.nextDouble() * math.pi * 2, -0.45 - rnd.nextDouble() * 0.3,
      2.2, 1.05, 0.30),
  DustLayer(rnd.nextDouble() * math.pi * 2, 0.25, 1.8, 1.0, 0.26),
];

/// ── 入场画笔：活粒子螺旋汇聚 + 尘云层收拢 ────────────────────────────
/// [progress] 为归一化进度 0~1（内部换算秒：粒子 delay/dur 以
/// [kConvTotal] 为基）。大弹窗走满 0.82s；下拉菜单等轻量弹层用更短的
/// 控制器时长复用同一画笔（快速汇拢）。
class ConvergePainter extends CustomPainter {
  ConvergePainter({
    required this.progress,
    required this.particles,
    required this.sprite,
    required this.cloud,
    required this.layers,
    required this.rect,
  });

  final double progress;
  final List<ConvergeParticle> particles;
  final ui.Image? sprite;
  final ui.Image? cloud;
  final List<DustLayer> layers;
  final Rect rect;

  final List<ui.RSTransform> _xf = [];
  final List<Color> _cols = [];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1 || size.isEmpty) return;
    final t = progress * kConvTotal;
    _paintDust(canvas, progress);
    _xf.clear();
    _cols.clear();
    for (final p in particles) {
      final u = ((t - p.delay) / p.dur).clamp(0.0, 1.0);
      if (u <= 0) continue;
      final e = Curves.easeInOutCubic.transform(u);
      final dir = p.target - p.start;
      final len = dir.distance;
      final perp = len < 1
          ? const Offset(0, -1)
          : Offset(-dir.dy, dir.dx) / len;
      var pos = Offset.lerp(p.start, p.target, e)! +
          perp * (p.curl * math.sin(u * math.pi));
      var alpha = (0.35 + 0.55 * p.depth) *
          Curves.easeOutCubic.transform((u / 0.18).clamp(0.0, 1.0));
      // 到站化作微光消隐：末 15% 行程渐灭（表面此刻正在显形接管）。
      final landing = ((u - 0.85) / 0.15).clamp(0.0, 1.0);
      alpha *= 1 - landing;
      var radius = p.radius * (1 - 0.35 * landing);
      if (u >= 1) continue; // 已消隐
      if (alpha <= 0.02) continue;
      // 出发一瞬微涨（现身的「闪」），随后收细。
      radius *= 1 + 0.5 * math.exp(-u * 9);
      if (sprite == null) {
        canvas.drawCircle(
          pos,
          radius * 0.6,
          Paint()..color = p.color.withValues(alpha: alpha),
        );
      } else {
        _xf.add(
          ui.RSTransform(radius * 2 / kSoftSpriteSize, 0, pos.dx, pos.dy),
        );
        _cols.add(p.color.withValues(alpha: alpha));
      }
    }
    _flushAtlas(canvas, size);
  }

  void _paintDust(Canvas canvas, double progress) {
    final img = cloud;
    if (img == null) return;
    final src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    final envelope = math.sin(progress.clamp(0.0, 1.0) * math.pi); // 两端归零
    final center = rect.center;
    final base = rect.longestSide;
    for (final layer in layers) {
      final u = Curves.easeInOutCubic.transform(progress.clamp(0.0, 1.0));
      final scale = layer.scaleFrom +
          (layer.scaleTo - layer.scaleFrom) * u;
      final side = base * scale * 1.15;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(layer.rot + layer.spin * u);
      canvas.drawImageRect(
        img,
        src,
        Rect.fromCenter(
          center: Offset.zero,
          width: side,
          height: side,
        ),
        Paint()
          ..color = Colors.white.withValues(
            alpha: layer.alphaPeak * envelope,
          )
          ..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    }
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
      BlendMode.modulate,
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(ConvergePainter old) =>
      old.progress != progress ||
      old.sprite != sprite ||
      old.cloud != cloud;
}

/// ── 退场舞台：截图粒子化 →（收束→迸散 | 外散）→ 淡出 ────────────────
/// 粒子数据复用 [sampleDissolve]（弹窗截图采样，颜色即弹窗本色）。
class DialogExitStage extends StatefulWidget {
  const DialogExitStage({
    super.key,
    required this.data,
    required this.kind,
    required this.onDone,
  });

  final DissolveCaptureData data;
  final DialogExitKind kind;
  final VoidCallback onDone;

  @override
  State<DialogExitStage> createState() => _DialogExitStageState();
}

class _DialogExitStageState extends State<DialogExitStage>
    with SingleTickerProviderStateMixin {
  final DialogExitClock _clock = DialogExitClock();
  late final Ticker _ticker = createTicker(_onTick);
  ui.Image? _sprite;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    bakeSoftSprite().then((img) {
      if (mounted) setState(() => _sprite = img);
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    _clock.advance(t);
    final total =
        widget.kind == DialogExitKind.burst ? kExitTotalBurst : kExitTotal;
    if (!_done && t >= total) {
      _done = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _clock,
        builder: (context, _) => SizedBox.expand(
          key: const ValueKey('as-dialog-exit-stage'),
          child: CustomPaint(
            painter: DialogExitPainter(
              clock: _clock,
              data: widget.data,
              kind: widget.kind,
              sprite: _sprite,
            ),
          ),
        ),
      ),
    );
  }
}

/// 单调舞台时钟（同 DissolveClock 工艺；独立公开类供画笔构造签名使用）。
class DialogExitClock extends ChangeNotifier {
  double t = 0;
  void advance(double v) {
    t = v;
    notifyListeners();
  }
}

/// 退场画笔：与 dissolve 第一幕同工艺的无缝交接，随后按
/// [DialogExitKind] 走「收束→迸散+闪光环」或「温和外散」。
class DialogExitPainter extends CustomPainter {
  DialogExitPainter({
    required this.clock,
    required this.data,
    required this.kind,
    required this.sprite,
  }) : super(repaint: clock);

  final DialogExitClock clock;
  final DissolveCaptureData data;
  final DialogExitKind kind;
  final ui.Image? sprite;

  final List<ui.RSTransform> _xf = [];
  final List<Color> _cols = [];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = clock.t;
    final isBurst = kind == DialogExitKind.burst;
    final total = isBurst ? kExitTotalBurst : kExitTotal;
    if (t >= total) return;
    final center = data.dialogRect.center;

    // 第一幕 · 无缝接管：原图淡出的同时粒子云淡入（同帧同位）。
    final imgAlpha = (1 - t / kExitHandoff).clamp(0.0, 1.0);
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

    // burst：淡出窗提前（收束 0.28s + 迸散 0.6s 内收干净）。
    final fadeAt = isBurst ? kExitFadeAt + kExitBurstBreakAt - kExitBreakAt : kExitFadeAt;
    final drain = Curves.easeOutCubic.transform(
      ((t - fadeAt) / kExitFadeDur).clamp(0.0, 1.0),
    );
    final implodeU = isBurst
        ? Curves.easeInCubic.transform(
            ((t - kExitImplodeAt) / kExitImplodeDur).clamp(0.0, 1.0),
          )
        : 0.0;
    final breakAt = isBurst ? kExitBurstBreakAt : kExitBreakAt;

    _xf.clear();
    _cols.clear();
    for (final p in data.particles) {
      var pos = p.start;
      var radius = p.radius;
      var alpha = 0.45 + 0.55 * p.shade;
      alpha *= (t / kExitHandoff).clamp(0.0, 1.0);

      // burst 先声：向心收束（此刻还没碎裂——整块弹窗「捏」向核心）。
      if (implodeU > 0) {
        pos = Offset.lerp(pos, center, implodeU * 0.92)!;
        radius *= 1 - 0.3 * implodeU;
        alpha = math.min(1, alpha + 0.3 * implodeU);
      }

      // 碎裂：波前自中心扫过，粒子外抛 + 涡旋 + 湍流（burst 波距压缩、
      // 抛距放大 1.45——收束的能量释放感）。
      final u = (
        (t - breakAt - p.wave * (isBurst ? 0.5 : 1.0)) /
        kExitScatterDur
      ).clamp(0.0, 1.0);
      if (u > 0) {
        final e = Curves.easeOutCubic.transform(u);
        final origin = center;
        var d = _dirFrom(p.start, origin) *
            (p.scatter * e * (isBurst ? 1.45 : 1.0));
        final a = p.swirl * e;
        final c = math.cos(a);
        final s = math.sin(a);
        d = Offset(d.dx * c - d.dy * s, d.dx * s + d.dy * c);
        final bell = math.sin(u * math.pi);
        pos =
            pos +
            d +
            Offset(
                  math.sin(u * 2 * math.pi * p.turbFreq + p.turbPhase),
                  math.cos(u * 2 * math.pi * p.turbFreq * 0.8 + p.turbPhase),
                ) *
                (5 * bell) +
            Offset(0, -14 * e * e);
        radius *= 1 + (isBurst ? 0.75 : 0.45) * bell;
        alpha *= 0.95 - 0.3 * bell;
      }

      alpha *= 1 - drain;
      if (alpha <= 0.02) continue;
      if (sprite == null) {
        canvas.drawCircle(
          pos,
          radius * 0.6,
          Paint()..color = p.color.withValues(alpha: alpha),
        );
      } else {
        _xf.add(
          ui.RSTransform(radius * 2 / kSoftSpriteSize, 0, pos.dx, pos.dy),
        );
        _cols.add(p.color.withValues(alpha: alpha));
      }
    }
    _flushAtlas(canvas, size);

    if (isBurst && t >= kExitBurstBreakAt) {
      _paintRing(canvas, center, t - kExitBurstBreakAt);
    }
  }

  /// 迸散闪光环：双环扩散（香槟主环 + 钢蓝副环），0.36s 内消隐。
  void _paintRing(Canvas canvas, Offset c, double u) {
    if (u >= 0.36) return;
    final e = Curves.easeOutCubic.transform(u / 0.36);
    for (final (r0, w, color, a) in [
      (10.0, 2.6, kDissolveChampagne, 0.9),
      (6.0, 1.6, kDissolveSteelLight, 0.6),
    ]) {
      canvas.drawCircle(
        c,
        r0 + 64 * e,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * (1 - e * 0.7)
          ..color = color.withValues(alpha: a * (1 - e)),
      );
    }
    if (u < 0.2) {
      canvas.drawCircle(
        c,
        22 * (1 - u / 0.2),
        Paint()
          ..shader = ui.Gradient.radial(
            c,
            22,
            [kDissolveChampagneCore.withValues(alpha: 0.5), kDissolveChampagneCore.withValues(alpha: 0)],
          ),
      );
    }
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
      BlendMode.modulate,
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium,
    );
  }

  static Offset _dirFrom(Offset from, Offset origin) {
    final d = from - origin;
    final l = d.distance;
    return l < 0.001 ? const Offset(0.2, -0.98) : d / l;
  }

  @override
  bool shouldRepaint(DialogExitPainter old) =>
      old.sprite != sprite || old.kind != kind;
}
