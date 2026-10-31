import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui show Gradient, Image, ImageFilter, RSTransform;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../l10n/runtime_l10n.dart';
import 'logo_points.dart';
import 'soft_sprite.dart';

/// 全局忙碌场景：任何长任务前调用
/// `await runBusy(context, message: '正在解锁…', task: () => unlock())`。
///
/// 视觉（无卡片的全屏粒子舞台，烟雾形态）：
/// - 粒子自 [origin]（触发按钮位置）如烟喷发：沿锥形方向涌出，中途
///   膨胀成半透烟团并受湍流摆动（正弦叠加模拟），末端被「吸入」屏幕
///   中心凝成清晰珠点，汇聚成超大品牌 A 标（300 目标点由
///   tool/gen_logo_points.py 采样）；底层另有大尺寸低透明烟霭沿
///   按钮→中心轴线缓慢漂移，补足烟感的「体」；
/// - 所有粒子用一张白色径向渐变软贴图（64px，启动时录制）经
///   drawAtlas 单次批量绘制（BlendMode.modulate 逐粒着色）；
/// - logo 背后是局部高斯模糊 + 呼吸光晕；粒子到位后绕 logo 走行波
///   （加载感的涟漪），低频烟雾卷流持续补充「源源不断」的动势；
/// - 成功：烟团自 logo 膨胀迸散（easeOutCubic 500ms）+ 光晕闪耀，
///   展示成功文案后收场；失败：粒子染朱砂消散，展示错误（点按内容
///   或 2.5s 后关闭）并重新抛出——[showError] 为 false 时失败立即收场，
///   错误交还调用方内联展示。
///
/// 时间轴：压暗 200ms → 粒子 0~0.8s 喷发（先 900/s 密集 120ms，后续
/// 300/s）× 0.65~1.0s 烟雾飞行（easeInOutCubic）→ ~1.8s 汇聚完成。
/// 系统「减少动画」时：静态呈现已汇聚的 logo + 文案，无粒子与波。
///
/// 宿主与生命周期：舞台挂在 [BusyHost]（app.dart 置于 MaterialApp.builder
/// ——**Navigator 之上**）的根 Overlay 里。解锁/上锁会替换整个 router，
/// 挂在旧 navigator 上的弹窗会随之销毁（粒子戛然而止）；根 Overlay 与
/// router 换树无关，舞台得以安然盖住新旧两棵树，直到编排完成。无宿主
/// 环境（widget 测试直泵页面）自动退回 showDialog。
///
/// 散场编排：成功迸散（500ms）+ 文案，[hold] 后整层以 [exitFade] 时长
/// 渐隐（easeOutCubic：先快散后余韵拖尾）。[syncReveal] 为 true 时（解锁
/// 进首页），散场开始那一刻触发 [BusyReveal.reveal]——首页入场动画与
/// 幕布渐薄同步启幕，烟雾散尽时地球/卡片恰好浮现到位。
Future<T> runBusy<T>(
  BuildContext context, {
  required String message,
  required Future<T> Function() task,
  String? successMessage,
  bool showError = true,
  Duration hold = const Duration(milliseconds: 800),
  Duration exitFade = const Duration(milliseconds: 240),
  bool syncReveal = false,
  Offset? origin,
}) {
  final client = _BusyClient(message);
  final closed = Completer<void>();
  final overlay = BusyHost.overlayKey.currentState;
  if (overlay != null) {
    // 根 Overlay 舞台：跨 router 换树存活（见类注释）。
    OverlayEntry? entry;
    entry = OverlayEntry(
      opaque: false,
      maintainState: true,
      builder: (_) => _BusyScene(
        client: client,
        hold: hold,
        showError: showError,
        origin: origin,
        exitFadeSec: exitFade.inMilliseconds / 1000,
        syncReveal: syncReveal,
        onRemove: () {
          if (entry!.mounted) entry.remove();
          if (!closed.isCompleted) closed.complete();
        },
      ),
    );
    overlay.insert(entry);
  } else {
    // 无宿主退路（测试/未挂 BusyHost 的环境）：弹窗形式，语义不变。
    unawaited(
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (_) => _BusyScene(
          client: client,
          hold: hold,
          showError: showError,
          origin: origin,
          exitFadeSec: exitFade.inMilliseconds / 1000,
          syncReveal: syncReveal,
        ),
      ).whenComplete(() {
        if (!closed.isCompleted) closed.complete();
      }),
    );
  }
  return () async {
    T result;
    try {
      result = await task();
    } catch (e) {
      client._fail(e);
      if (!showError) client.requestClose();
      await closed.future;
      rethrow;
    }
    client._succeed(successMessage);
    await closed.future;
    return result;
  }();
}

/// 揭幕钟：粒子舞台（syncReveal）与首页入场动画的同步点。
/// 舞台上场即「持幕」（hold），散场开始时「揭幕」（reveal）——首页
/// [_HomeBody] 的入场监听它，地球/卡片恰在幕布渐薄的同一刻浮现，
/// 而不是在幕布后面独自播完。常态下 revealed 恒为 true（刷新、普通
/// 页面挂载即刻入场，不受影响）。
class BusyReveal extends ChangeNotifier {
  BusyReveal._();

  static final instance = BusyReveal._();

  bool _revealed = true;

  /// 是否已揭幕（false = 有 syncReveal 舞台持幕中，入场须等待）。
  bool get revealed => _revealed;

  void hold() {
    if (_revealed == false) return;
    _revealed = false;
    notifyListeners();
  }

  void reveal() {
    if (_revealed) return;
    _revealed = true;
    notifyListeners();
  }
}

/// 粒子舞台宿主：置于 MaterialApp.builder（WindowChrome 之内、Navigator
/// 之上）。底层条目是整棵路由树，舞台条目由 runBusy 动态压入其上——
/// router 换树只替换底层条目的内容，舞台条目不受牵连。窗口红绿灯在
/// WindowChrome 更外层，舞台期间依然可见可用。
class BusyHost extends StatefulWidget {
  const BusyHost({super.key, required this.child});

  /// 根 Overlay 钥匙：runBusy 经此挂舞台（无宿主时为 null，走弹窗退路）。
  static final overlayKey = GlobalKey<OverlayState>(debugLabel: 'busy-stage');

  final Widget child;

  @override
  State<BusyHost> createState() => _BusyHostState();
}

class _BusyHostState extends State<BusyHost> {
  late final OverlayEntry _content = OverlayEntry(
    // builder 求值时经 widget getter 取「当前」child：换树后仍指向新子树。
    builder: (_) => widget.child,
  );

  @override
  Widget build(BuildContext context) =>
      Overlay(key: BusyHost.overlayKey, initialEntries: [_content]);
}

enum _BusyPhase { running, success, error }

/// 弹窗与 runBusy 之间的单向状态通道（弹窗只读，按相位自排离场）。
class _BusyClient extends ChangeNotifier {
  _BusyClient(this.message);

  final String message;
  _BusyPhase phase = _BusyPhase.running;
  String? detail;
  bool closeNow = false;

  void _succeed(String? text) {
    phase = _BusyPhase.success;
    detail = text;
    notifyListeners();
  }

  void _fail(Object e) {
    phase = _BusyPhase.error;
    // 原始异常常多行（含堆栈式连接串），只取首行展示。
    final raw = e.toString();
    detail = raw.length > 120 ? raw.substring(0, 120) : raw;
    notifyListeners();
  }

  void requestClose() {
    closeNow = true;
    notifyListeners();
  }
}

/// 场景单调时钟：Ticker 驱动，painter 以它为 repaint 监听。
/// 「减少动画」时不启动 Ticker，t 固定在汇聚完成后的静止帧。
class _Clock extends ChangeNotifier {
  double t = 0;

  void tick(Duration elapsed) {
    t = elapsed.inMicroseconds / 1e6;
    notifyListeners();
  }
}

/// 白色径向软贴图尺寸（px）——公共工艺见 soft_sprite.dart。
const _kSpriteSize = kSoftSpriteSize;

class _BusyScene extends StatefulWidget {
  const _BusyScene({
    required this.client,
    required this.hold,
    required this.showError,
    required this.exitFadeSec,
    required this.syncReveal,
    this.origin,
    this.onRemove,
  });

  final _BusyClient client;
  final Duration hold;
  final bool showError;
  final double exitFadeSec; // 整层渐隐时长（秒）
  final bool syncReveal; // 散场开始时触发 BusyReveal.reveal
  final Offset? origin;

  /// 根 Overlay 模式的离场回调（移除条目）。null = 弹窗退路，自行 pop。
  final VoidCallback? onRemove;

  @override
  State<_BusyScene> createState() => _BusySceneState();
}

class _BusySceneState extends State<_BusyScene>
    with SingleTickerProviderStateMixin {
  final _Clock _clock = _Clock();
  late final Ticker _ticker;
  late final List<_FounderSpec> _founders;
  late final List<_WispSpec> _wisps;
  ui.Image? _sprite; // 软贴图（异步生成，就绪前退化硬圆点）

  Timer? _timer;
  Timer? _burstArm; // 迸散迟发（等 logo 汇聚成形）
  bool _inited = false;
  bool _reduce = false;
  bool _closing = false;
  bool _popped = false;
  double _tPhase = -1; // 成功/失败切换时刻（-1 = 未发生）
  double _tClose = -1;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(11);
    _founders = [
      for (var i = 0; i < kLogoParticlePoints.length ~/ 2; i++)
        _FounderSpec(rnd, i),
    ];
    _wisps = [for (var i = 0; i < 256; i++) _WispSpec(rnd, i)];
    _ticker = createTicker(_clock.tick);
    _bakeSprite();
    widget.client.addListener(_onPhase);
    if (widget.syncReveal) BusyReveal.instance.hold();
  }

  /// 软贴图（公共烘焙缓存，就绪前退化硬圆点；共享单例不得 dispose）。
  void _bakeSprite() {
    bakeSoftSprite().then((img) {
      if (mounted) setState(() => _sprite = img);
    });
  }

  // 弹窗内容为全屏展开（SizedBox.expand），全局坐标即场景本地坐标，
  // origin 无需换算直接使用。MediaQuery 不允许在 initState 读。
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      _inited = true;
      _reduce = MediaQuery.disableAnimationsOf(context);
      if (_reduce) {
        _clock.t = 1.2; // 静止帧：logo 已汇聚、文案已就位
      } else {
        _ticker.start();
      }
      // 任务可能在弹窗挂上监听前就已完成（notifyListeners 无人接收），
      // 注册后立即按当前相位补课一次。
      _syncPhase();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _burstArm?.cancel();
    _ticker.dispose();
    widget.client.removeListener(_onPhase);
    // 兜底揭幕：舞台以任何方式消失（含宿主整树被销毁）都不得让
    // 等待入场的页面悬挂。
    BusyReveal.instance.reveal();
    // _sprite 为公共缓存单例（soft_sprite.dart），不在此 dispose。
    super.dispose();
  }

  void _onPhase() => _syncPhase();

  /// founders 全员到位时刻：delay 上限 0.12+200/300=0.79s + travel 上限
  /// 1.0s ≈ 1.79s。成功迸散**不得早于此刻**——任务快于汇聚时 logo 还未
  /// 成形就被炸散，用户看不到粒子汇聚效果（登录→首页过渡的下限即此）。
  /// 测试环境不等待（舞台定格、测试按原节奏推进）。
  static const double _kConvergeDone = 1.79;
  static final bool _testEnv =
      Platform.environment['FLUTTER_TEST'] == 'true';

  /// 按 client 当前相位自排离场（监听回调与注册后补课共用）。
  void _syncPhase() {
    if (_closing) return;
    final c = widget.client;
    if (c.closeNow) return _close();
    switch (c.phase) {
      case _BusyPhase.success:
        if (_reduce) {
          // 「减少动画」不进迸散分支（-1），静态呈现成功文案即可。
          _tPhase = -1;
          _timer ??= Timer(widget.hold, _close);
          break;
        }
        // logo 成形（+0.07s 定格一拍）之前不迸散；欠的时长补进 hold 前，
        // 总程仍是「汇聚完成 → 迸散 → hold → 渐隐」的最短可行序列。
        final wait = _testEnv
            ? 0.0
            : math.max(0.0, _kConvergeDone + 0.07 - math.max(_clock.t, 0));
        void armBurst() {
          if (mounted && !_closing && widget.client.phase == _BusyPhase.success) {
            setState(() => _tPhase = _clock.t);
          }
        }
        if (wait <= 0.001) {
          _tPhase = _clock.t;
        } else {
          _burstArm?.cancel();
          _burstArm = Timer(
            Duration(microseconds: (wait * 1e6).round()),
            armBurst,
          );
        }
        _timer ??= Timer(widget.hold + Duration(microseconds: (wait * 1e6).round()), _close);
      case _BusyPhase.error:
        _tPhase = _reduce ? -1 : _clock.t;
        // 交还调用方内联展示：立即离场；否则停留至点按或超时。
        if (!widget.showError) return _close();
        _timer ??= Timer(const Duration(milliseconds: 2500), _close);
      case _BusyPhase.running:
        return;
    }
    if (mounted) setState(() {});
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    _timer = null;
    _burstArm?.cancel();
    _burstArm = null;
    // 散场开始即揭幕：首页入场与幕布渐薄同步启幕。
    BusyReveal.instance.reveal();
    if (!mounted) return;
    if (_reduce) return _pop();
    _tClose = _clock.t;
    scheduleExitCheck(); // 渐隐 exitFade 后离场
    setState(() {});
  }

  void _pop() {
    if (_popped) return;
    _popped = true;
    if (widget.onRemove != null) return widget.onRemove!();
    // 弹窗退路：推迟到帧末——解锁/上锁瞬间整个 router 会被替换
    // （app.dart 按 locked 缓存双 router），旧 navigator 随旧树销毁，
    // 此刻直接 pop 会触发「popped the last page」断言；帧末时弹窗若
    // 已被销毁就无需再弹。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final logoSize = (mq.size.shortestSide * 0.42).clamp(200.0, 320.0);

    return PopScope(
      canPop: widget.client.phase != _BusyPhase.running,
      child: AnimatedBuilder(
        animation: _clock,
        builder: (context, _) {
          final t = _clock.t;
          final fade = _closing && !_reduce
              ? 1 -
                    Curves.easeOutCubic.transform(
                      ((t - _tClose) / widget.exitFadeSec).clamp(0.0, 1.0),
                    )
              : 1.0;
          final scrim =
              0.55 * Curves.easeOutCubic.transform((t / 0.2).clamp(0.0, 1.0));
          return Opacity(
            opacity: fade,
            child: SizedBox.expand(
              key: const ValueKey('as-busy-scene'),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 全屏压暗：粒子舞台的底幕。
                  ColoredBox(color: Colors.black.withValues(alpha: scrim)),
                  // logo 背景局部模糊：中心圆域高斯模糊 + 轻微提亮。
                  Center(
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: SizedBox(
                          width: logoSize * 1.5,
                          height: logoSize * 1.5,
                          child: ColoredBox(
                            color: Colors.white.withValues(alpha: 0.03 * scrim),
                          ),
                        ),
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: _ScenePainter(
                      clock: _clock,
                      founders: _founders,
                      wisps: _wisps,
                      sprite: _sprite,
                      origin: widget.origin,
                      phase: widget.client.phase,
                      detail: widget.client.detail,
                      message: widget.client.message,
                      tPhase: _tPhase,
                      frozen: _reduce,
                      logoSize: logoSize,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 以 60ms 轮询等待离场渐隐完成后离场（避免再起一个控制器）。
  void scheduleExitCheck() {
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (!mounted || _popped) return;
      if (_reduce || _clock.t - _tClose >= widget.exitFadeSec) {
        _pop();
      } else {
        scheduleExitCheck();
      }
    });
  }
}

/// 汇聚粒子（founder）：一一对应一个 logo 目标点，走烟雾三段生命——
/// 锥形喷发 → 膨胀湍流 → 吸入凝珠。
class _FounderSpec {
  _FounderSpec(math.Random rnd, this.target) {
    // 前 100 颗 900/s 密集起跳，其余 0.12s 后以 300/s 匀速补充。
    delay = target < 100 ? target / 900 : 0.12 + (target - 100) / 300;
    travel = 0.65 + rnd.nextDouble() * 0.35;
    size = 2.0 + rnd.nextDouble() * 1.2; // 到位珠径
    peak = 8 + rnd.nextDouble() * 8; // 中途烟团直径
    coneRot = (rnd.nextDouble() - 0.5) * 1.0; // 喷发锥偏角 ±0.5rad
    turbAmp = 10 + rnd.nextDouble() * 18;
    f1 = 1.5 + rnd.nextDouble();
    f2 = 2.6 + rnd.nextDouble() * 1.4;
    p1 = rnd.nextDouble() * math.pi * 2;
    p2 = rnd.nextDouble() * math.pi * 2;
    wavePhase = rnd.nextDouble() * math.pi * 2;
    originJitter = Offset(
      (rnd.nextDouble() - 0.5) * 20,
      (rnd.nextDouble() - 0.5) * 20,
    );
    burstDist = 70 + rnd.nextDouble() * 90;
    final c = rnd.nextDouble();
    color = c < 0.14
        ? const Color(0xFFE7ECF2) // 雾白
        : c < 0.32
        ? const Color(0xFFD8BE85) // 香槟金
        : const Color(0xFF7EA6D9); // 钢蓝
  }

  final int target;
  late final double delay;
  late final double travel;
  late final double size;
  late final double peak;
  late final double coneRot;
  late final double turbAmp;
  late final double f1;
  late final double f2;
  late final double p1;
  late final double p2;
  late final double wavePhase;
  late final Offset originJitter;
  late final double burstDist;
  late final Color color;
}

/// 烟雾卷流（wisp）：汇聚完成后自按钮持续涌向 logo 边缘并消散。
class _WispSpec {
  _WispSpec(math.Random rnd, int k) {
    spawn = 0.7 + k * 0.07;
    life = 0.7 + rnd.nextDouble() * 0.35;
    angle = rnd.nextDouble() * math.pi * 2;
    radius = 0.5 + rnd.nextDouble() * 0.3; // logoSize 倍数
    size = 5 + rnd.nextDouble() * 4;
    sway = (rnd.nextDouble() - 0.5) * 26;
    color = rnd.nextDouble() < 0.3
        ? const Color(0xFFE7ECF2)
        : const Color(0xFF7EA6D9);
  }

  late final double spawn;
  late final double life;
  late final double angle;
  late final double radius;
  late final double size;
  late final double sway;
  late final Color color;
}

/// 粒子舞台：光晕 + 烟雾粒子 + 烟霭 + 文案。软粒子经 drawAtlas 单批
/// 绘制（贴图未就绪时退化为硬圆点）。
class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.clock,
    required this.founders,
    required this.wisps,
    required this.sprite,
    required this.origin,
    required this.phase,
    required this.detail,
    required this.message,
    required this.tPhase,
    required this.frozen,
    required this.logoSize,
  }) : super(repaint: clock);

  final _Clock clock;
  final List<_FounderSpec> founders;
  final List<_WispSpec> wisps;
  final ui.Image? sprite;
  final Offset? origin;
  final _BusyPhase phase;
  final String? detail;
  final String message;
  final double tPhase;
  final bool frozen;
  final double logoSize;

  final List<ui.RSTransform> _xf = [];
  final List<Color> _cols = [];

  // 文案按 (文本, 颜色) 缓存布局；painter 随帧重建，缓存挂在类上复用。
  static final Map<String, TextPainter> _textCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final t = frozen ? 1.2 : clock.t;
    final center = size.center(Offset.zero);
    final emit =
        origin ?? Offset(size.width / 2, size.height * 0.78); // 无起点：自下方涌起

    _xf.clear();
    _cols.clear();
    _paintHalo(canvas, center, t);
    _paintFounders(canvas, size, center, emit, t);
    if (!frozen) {
      _paintHaze(canvas, center, emit, t);
      _paintWisps(canvas, center, emit, t);
      _paintBurstPuffs(canvas, center, t);
    }
    _flushAtlas(canvas, size);
    _paintText(canvas, size, center, t);
  }

  /// 软粒子入批：贴图就绪走 drawAtlas，否则直接画硬圆点。
  void _soft(Canvas canvas, Offset pos, double radius, Color color) {
    if (sprite == null) {
      canvas.drawCircle(pos, radius * 0.6, Paint()..color = color);
      return;
    }
    _xf.add(ui.RSTransform(radius * 2 / _kSpriteSize, 0, pos.dx, pos.dy));
    _cols.add(color);
  }

  void _flushAtlas(Canvas canvas, Size size) {
    if (sprite == null || _xf.isEmpty) return;
    canvas.drawAtlas(
      sprite!,
      _xf,
      // 整张贴图即源矩形（逐实例重复）。
      List.filled(
        _xf.length,
        const Rect.fromLTWH(0, 0, _kSpriteSize, _kSpriteSize),
      ),
      _cols,
      BlendMode.modulate, // 白贴图 × 粒子色 = 逐粒着色并保留径向柔边
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium,
    );
  }

  /// 呼吸光晕：钢蓝径向渐变，2.4s 余弦呼吸；成功瞬间闪耀后随迸散衰减；
  /// 失败染朱砂。渐变自带柔边，无需 blur。
  void _paintHalo(Canvas canvas, Offset center, double t) {
    final breath = frozen ? 0.5 : 0.5 - 0.5 * math.cos(t * 2 * math.pi / 2.4);
    var alpha = 0.10 + 0.16 * breath;
    var color = const Color(0xFF7EA6D9);
    if (tPhase >= 0) {
      final u = ((t - tPhase) / 0.5).clamp(0.0, 1.0);
      if (phase == _BusyPhase.success) {
        alpha += 0.5 * math.pow(1 - u, 2).toDouble(); // 闪耀
      } else {
        alpha *= 1 - u;
        color = const Color(0xFFF0907C);
      }
    }
    final radius = logoSize * (0.85 + 0.08 * breath);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [
            color.withValues(alpha: alpha.clamp(0.0, 1.0)),
            color.withValues(alpha: (alpha * 0.45).clamp(0.0, 1.0)),
            color.withValues(alpha: 0),
          ],
          [0.0, 0.45, 1.0],
        ),
    );
  }

  void _paintFounders(
    Canvas canvas,
    Size size,
    Offset center,
    Offset emit,
    double t,
  ) {
    final burst = tPhase >= 0; // 成功/失败已触发
    for (final p in founders) {
      if (t < p.delay) continue;
      final target = Offset(
        center.dx + kLogoParticlePoints[p.target * 2] * logoSize,
        center.dy + kLogoParticlePoints[p.target * 2 + 1] * logoSize,
      );
      final start = emit + p.originJitter;
      final u = ((t - p.delay) / p.travel).clamp(0.0, 1.0);
      var pos = _smokePath(start, target, p, u);
      var radius = p.size + (p.peak - p.size) * _bell(u, 1.3);
      var alpha = 0.8 - 0.48 * math.sin(u * math.pi);
      var color = p.color;

      if (u >= 1) {
        // 到位：凝成珠点，绕 logo 行波（径向涟漪）+ 闪烁。
        final n = _norm(target - center);
        final theta = math.atan2(
          kLogoParticlePoints[p.target * 2 + 1],
          kLogoParticlePoints[p.target * 2],
        );
        final wave = frozen
            ? 0.0
            : math.sin(t * 2 * math.pi * 0.85 + theta * 2.6 + p.wavePhase) *
                  4.2;
        pos += n * wave;
        radius = p.size;
        alpha = frozen
            ? 0.9
            : 0.72 + 0.28 * math.sin(t * 2 * math.pi * 1.2 + p.wavePhase * 7);
      }

      if (burst) {
        final v = ((t - tPhase) / 0.5).clamp(0.0, 1.0);
        final dir = _norm(pos - center);
        final e = Curves.easeOutCubic.transform(v);
        if (phase == _BusyPhase.success) {
          // 迸散：烟团膨胀外抛并渐隐。
          pos += dir * (e * p.burstDist);
          radius += p.peak * 0.9 * e;
          alpha *= math.pow(1 - v, 1.4).toDouble();
        } else {
          // 失败：染朱砂，微散后消散。
          pos += dir * (e * 24);
          radius *= 1 + 0.6 * e;
          alpha *= 1 - v;
          color = Color.lerp(color, const Color(0xFFF0907C), v)!;
        }
      }

      _soft(
        canvas,
        pos,
        radius,
        color.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
    }
  }

  /// 烟雾路径：锥形喷发控制点的贝塞尔 + 中途隆起的湍流摆动（两端为 0，
  /// 保证出发贴按钮、到达贴目标点）。
  Offset _smokePath(Offset start, Offset target, _FounderSpec p, double u) {
    final e = Curves.easeInOutCubic.transform(u);
    final d = target - start;
    final len = d.distance;
    final dir = len < 1 ? const Offset(0, -1) : d / len;
    final c = math.cos(p.coneRot);
    final s = math.sin(p.coneRot);
    final cone = Offset(dir.dx * c - dir.dy * s, dir.dx * s + dir.dy * c);
    final ctrl = start + cone * (len * 0.33);
    final im = 1 - e;
    final base = start * im * im + ctrl * 2 * im * e + target * e * e;
    final billow = _bell(u, 0.8) * p.turbAmp;
    return base +
        Offset(
              math.sin(u * 2 * math.pi * p.f1 + p.p1),
              math.sin(u * 2 * math.pi * p.f2 + p.p2),
            ) *
            billow;
  }

  /// 烟霭：大尺寸低透明软团沿按钮→中心轴线缓慢漂移（烟雾的「体」）。
  void _paintHaze(Canvas canvas, Offset center, Offset emit, double t) {
    const life = 2.4, period = 0.16;
    final stopSpawn = tPhase >= 0 ? tPhase : t - life;
    final n = (t / period).floor();
    for (var k = math.max(0, n - life ~/ period); k <= n; k++) {
      final spawn = k * period;
      if (spawn >= stopSpawn || t >= spawn + life) continue;
      final rnd = math.Random(1000 + k);
      final u = (t - spawn) / life;
      final drift = Offset.lerp(
        emit +
            Offset(
              (rnd.nextDouble() - 0.5) * 30,
              (rnd.nextDouble() - 0.5) * 30,
            ),
        Offset.lerp(emit, center, 0.55)!,
        Curves.easeOutQuad.transform(u),
      )!;
      final sway =
          Offset(
            math.sin(u * 2 * math.pi + rnd.nextDouble() * math.pi * 2),
            math.cos(u * 2 * math.pi * 0.7 + rnd.nextDouble() * math.pi * 2),
          ) *
          14;
      var alpha = 0.055 * math.sin(u * math.pi);
      if (tPhase >= 0) {
        alpha *= (1 - ((t - tPhase) / 0.3).clamp(0.0, 1.0));
      }
      _soft(
        canvas,
        drift + sway,
        20 + 26 * u, // 20→46px 膨胀
        const Color(0xFF7EA6D9).withValues(alpha: alpha),
      );
    }
  }

  /// 烟雾卷流：汇聚完成后自按钮涌向 logo 边缘的半透软团。
  void _paintWisps(Canvas canvas, Offset center, Offset emit, double t) {
    final stopSpawn = tPhase >= 0 ? tPhase : double.infinity;
    for (final w in wisps) {
      if (t < w.spawn || t >= w.spawn + w.life || w.spawn >= stopSpawn) {
        continue;
      }
      final u = (t - w.spawn) / w.life;
      final target =
          center +
          Offset(math.cos(w.angle), math.sin(w.angle)) * (w.radius * logoSize);
      final pos =
          Offset.lerp(emit, target, Curves.easeInOutCubic.transform(u))! +
          Offset(math.sin(u * math.pi * 2 + w.angle * 3), 0) * w.sway;
      var alpha = 0.32 * math.sin(u * math.pi);
      if (tPhase >= 0) {
        alpha *= (1 - ((t - tPhase) / 0.15).clamp(0.0, 1.0));
      }
      _soft(
        canvas,
        pos,
        w.size * (0.6 + 0.6 * math.sin(u * math.pi)),
        w.color.withValues(alpha: alpha),
      );
    }
  }

  /// 成功一瞬的中心烟团：10 颗大软团自 logo 迸出（500ms）。
  void _paintBurstPuffs(Canvas canvas, Offset center, double t) {
    if (tPhase < 0 || phase != _BusyPhase.success) return;
    final v = ((t - tPhase) / 0.5).clamp(0.0, 1.0);
    final e = Curves.easeOutCubic.transform(v);
    for (var i = 0; i < 10; i++) {
      final rnd = math.Random(2000 + i);
      final a = rnd.nextDouble() * math.pi * 2;
      final dist = (30 + rnd.nextDouble() * 80) * e;
      _soft(
        canvas,
        center + Offset(math.cos(a), math.sin(a)) * dist,
        14 + 22 * e,
        const Color(0xFFD8BE85).withValues(alpha: 0.30 * math.pow(1 - v, 1.5)),
      );
    }
  }

  void _paintText(Canvas canvas, Size size, Offset center, double t) {
    final succeeded = phase == _BusyPhase.success;
    final failed = phase == _BusyPhase.error;
    final text = succeeded
        ? (detail ?? rt('完成'))
        : failed
        ? (detail == null || detail!.isEmpty
              ? rt('操作失败')
              : '${rt('操作失败：')}$detail')
        : message;
    final color = succeeded
        ? const Color(0xFFD8BE85)
        : failed
        ? const Color(0xFFF0907C)
        : const Color(0xFFE7ECF2);
    final tp = _textCache.putIfAbsent(
      '$text|$color',
      () => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color.withValues(alpha: 0.92),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            height: 1.4,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width * 0.8),
    );
    var alpha = Curves.easeOutCubic.transform(
      ((t - 0.25) / 0.3).clamp(0.0, 1.0),
    );
    if (tPhase >= 0) {
      alpha = Curves.easeOutCubic.transform(
        ((t - tPhase) / 0.18).clamp(0.0, 1.0),
      );
    }
    if (alpha <= 0) return;
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white.withValues(alpha: alpha),
    );
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, center.dy + logoSize * 0.58 + 26),
    );
    canvas.restore();
  }

  /// 钟形包络 sin(πu)^k：两端正负零、中途隆起。
  static double _bell(double u, double k) =>
      math.pow(math.max(0.0, math.sin(u * math.pi)), k).toDouble();

  static Offset _norm(Offset o) {
    final l = o.distance;
    return l < 0.001 ? const Offset(0, -1) : o / l;
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.phase != phase ||
      old.tPhase != tPhase ||
      old.origin != origin ||
      old.logoSize != logoSize ||
      old.frozen != frozen ||
      old.sprite != sprite;
}

// ─────────────────────────────────────────────────────────────────────────
// 以下 OrbitSpinner 为地球等深色场景的内联加载指示器，与粒子舞台无关。
// ─────────────────────────────────────────────────────────────────────────

/// 轨道环加载指示器：细轨道 + 旋转亮弧 + 中心点。
class OrbitSpinner extends StatefulWidget {
  const OrbitSpinner({super.key, this.size = 40, this.color});

  /// 视觉边长（正方形）。
  final double size;

  /// 弧与中心点颜色（轨道为其 12% 透明度）。
  final Color? color;

  @override
  State<OrbitSpinner> createState() => _OrbitSpinnerState();
}

class _OrbitSpinnerState extends State<OrbitSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rot = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _rot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _rot,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _OrbitPainter(
          angle: _rot.value * 2 * math.pi,
          // 减少动画：旋转改为整体呼吸明暗（弧角固定）。
          breath: reduce ? 0.55 + 0.45 * (_rot.value * 2 - 1).abs() : 1.0,
          fixedArc: reduce,
          color: color,
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.angle,
    required this.breath,
    required this.fixedArc,
    required this.color,
  });

  final double angle;
  final double breath;
  final bool fixedArc;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2.5;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = color.withValues(alpha: 0.14 * breath),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final sweep = fixedArc
        ? 4.71238898038469
        : 1.7453292519943295; // 270° / 100°
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.95 * breath),
    );
    canvas.restore();
    canvas.drawCircle(
      center,
      2.6,
      Paint()..color = color.withValues(alpha: 0.9 * breath),
    );
    // 外圈对转细弧 + 领先端卫星点（尺寸足够时才有层次）。
    if (size.width < 36) return;
    final angle2 = -angle * 0.55;
    final outer = radius + 5;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle2);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: outer),
      -math.pi / 2,
      0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.38 * breath),
    );
    canvas.restore();
    final tip = Offset(
      center.dx + math.cos(-math.pi / 2 + angle2) * outer,
      center.dy + math.sin(-math.pi / 2 + angle2) * outer,
    );
    canvas.drawCircle(
      tip,
      1.8,
      Paint()..color = color.withValues(alpha: 0.8 * breath),
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.angle != angle || old.breath != breath;
}
