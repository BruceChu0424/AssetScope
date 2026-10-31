import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/gestures.dart'
    show
        PointerHoverEvent,
        PointerPanZoomEndEvent,
        PointerPanZoomStartEvent,
        PointerPanZoomUpdateEvent,
        PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/runtime_l10n.dart';
import '../../services/stats_service.dart';
import '../widgets/common.dart';
import 'globe_painter.dart';
import 'globe_state.dart';
import 'marker_detail_sheet.dart';
import 'marker_popup.dart';
import 'space_backdrop.dart';

/// 交互式资产地球（点阵线框 + 呼吸标记），可嵌入任意容器。
///
/// - 拖拽旋转（带惯性）、双指捏合/鼠标滚轮/触控板缩放、双击复位；
/// - 悬停（桌面）或点选（触屏）光点：光点旁锚点弹窗展示该处资产，
///   移开/点空白即隐去；对已选中的光点再次点击打开详情弹层；
/// - 空闲 [idleDelay] 后缓慢自转；点击标记：粒子爆发 + 飞行动画转正；
/// - 深空氛围：星野闪烁 + 星云漂移 + 偶发流星（[space_backdrop.dart]），
///   大陆点阵入场按索引波式浮现，球缘大气辉光缓慢呼吸；
///   标记持续升起星尘微粒（粒子池上限防失控）；
/// - [onImmersionChanged]：交互进行中上报 true、空闲自转恢复时上报
///   false——首页据此让整页让位，地球扩张为沉浸全屏（[ImmersiveGlobeHost]）；
/// - 自带右上角悬浮操作（复位 / 全屏入口，[showActions] 可关——首页把
///   这组操作统一挪到窗口右上角）与左下角 HUD（资产计数）；
///   背景透明，由外层提供深空底色。
class AssetGlobe extends ConsumerStatefulWidget {
  const AssetGlobe({
    super.key,
    this.onOpenFullscreen,
    this.idleDelay,
    this.backdrop = true,
    this.onImmersionChanged,
    this.showActions = true,
  });

  /// 交互停止后多少毫秒恢复自转（默认 2.5s）。
  final Duration? idleDelay;

  /// 全屏入口回调（首页取景框里提供，全屏页自身不显示）。
  final VoidCallback? onOpenFullscreen;

  /// 是否自带深空底幕（星野/星云/流星）。首页整页铺深空时传 false，
  /// 由页面提供，避免双重绘制。
  final bool backdrop;

  /// 沉浸状态上报（见类注释）。null 时（独立全屏页）不生效。
  final void Function(bool immersed)? onImmersionChanged;

  /// 是否绘制组件内右上角的复位/全屏按钮。首页（GlobeHomePage）把这组
  /// 操作统一放到窗口右上角，传 false；独立全屏页保持 true。
  final bool showActions;

  @override
  ConsumerState<AssetGlobe> createState() => AssetGlobeState();
}

/// 公开 State：首页持有 `GlobalKey<AssetGlobeState>`，通过 [resetView]
/// 从窗口右上角「定位」按钮驱动视角复位（同一实例，视角状态连续）。
class AssetGlobeState extends ConsumerState<AssetGlobe>
    with SingleTickerProviderStateMixin {
  List<double> _landDots = const [];
  List<GlobeMarker> _markers = const [];
  Map<String, AccountValuationItem> _values = const {};
  String _baseCurrency = 'CNY';
  BigInt _maxMarkerValue = BigInt.zero;

  // ── 新标记绽放（reload 差分）──
  Set<String>? _prevMarkerIds; // null = 首载（入场波已覆盖，不再绽放）
  Set<String> _spawnIds = const {};
  double _spawnAt = 0; // 绽放起始（_elapsed 基准）

  // 注意：必须在 initState 显式初始化，不能用 late final 字段惰性初始化——
  // 若页面在首次访问 _pulse 前就被销毁（数据未加载即退出），dispose 里的
  // _pulse.dispose() 会触发惰性构造 AnimationController，在已失活的
  // element 上查询 TickerMode 而崩溃。
  late final AnimationController _pulse;

  GlobeView _view = GlobeView();

  // ── 时间基准氛围（球缘呼吸/入场波/星尘粒子）──
  double _elapsed = 0; // 经过秒数
  double _appear = 0; // 入场波进度（大陆波式浮现）
  double _ambientBudget = 0; // 标记星尘生成预算（粒/秒累积）
  Size _size = Size.zero; // 画布尺寸（build 时更新）
  final math.Random _rnd = math.Random();
  final ParticleField _particles = ParticleField();

  // ── 手势物理（时间基准，120Hz 屏与 60Hz 屏手感一致）──
  // 手势只用 scale 识别器（pan 的超集）：单指=拖拽（scale 恒 1），双指=捏合。
  // 框架断言禁止 pan/scale 回调并存，曾因此红屏。
  double _velocity = 0; // 经度角速度（度/秒）：惯性向空闲自转速收敛后并入
  bool _dragging = false; // 手势中不叠惯性（旧 bug：事件率≠帧率时双重位移）
  bool _idleSpin = false; // 角速度已并入空闲自转（稳定慢转中）
  double _idleOmega = -3.2; // 空闲自转角速度（度/秒）——方向跟随最近拖拽
  double _dragDx = 0; // 本次手势累计水平位移（无惯性释放时据此定自转向）
  double _pinchZoomStart = 1; // 缩放手势起点的 zoom（防逐事件复合漂移）
  int _lastPointers = 1; // 捏合中途增减手指时重锚缩放基准
  double _baseRadius = 300; // min(w,h)/2·0.86，build 时更新
  Duration? _lastTick;

  // ── 滚轮缩放补间：目标值指数逼近（每格滚轮也平滑放大，不逐格跳变）──
  double _zoomTarget = 1;
  bool _zoomAnimating = false;

  // ── 沉浸上报（拖过阈值/捏合/滚轮即沉浸，空闲自转恢复即退出）──
  bool _immersing = false;
  double _dragTravel = 0; // 本次手势累计位移（px），超过阈值才沉浸

  // ── 触控板捏合（PointerPanZoom 流，独立于滚轮信号）──
  double _panZoomBase = 1;

  // ── 锚点弹窗（悬停或点选的光点组）──
  GlobePopupGroup? _popup;
  bool _popupFromHover = false; // 悬停来源的弹窗随鼠标移开消失；点选的保留
  Rect? _popupCardRect; // 弹窗卡矩形（悬停命中区扩到卡上，防移入卡内闪灭）

  static const _idleRate = 3.2; // 空闲自转速（正量，度/秒；方向跟手）
  static const _frictionTau = 0.32; // 惯性摩擦时间常数（秒）
  static const _flickMin = 40.0; // 释放速度低于此值（度/秒）不给惯性
  static const _flickMax = 540.0; // 惯性封顶（度/秒，≈每秒 1.5 圈）
  static const _zoomTau = 0.10; // 滚轮缩放补间时间常数（秒）
  static const _immerseDragPx = 18.0; // 拖动多少像素后进入沉浸（点一下不算）

  Timer? _idleTimer;
  String? _selectedId;
  bool _flying = false;

  /// 每逻辑像素对应的旋转角（度）。弧长映射：球心点跟手 1:1，
  /// 随屏幕尺寸与缩放自适应（半径已含 zoom，不再额外除）。
  double get _degPerPx => 180 / (math.pi * _baseRadius * _view.zoom);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadLand();
    _loadMarkers();
    _startIdle();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _loadLand() async {
    final text = await rootBundle.loadString('assets/globe/land_dots.json');
    final decoded = jsonDecode(text) as List<dynamic>;
    final list = <double>[];
    for (final pair in decoded) {
      final p = pair as List<dynamic>;
      list.add((p[0] as num).toDouble());
      list.add((p[1] as num).toDouble());
    }
    if (mounted) setState(() => _landDots = list);
  }

  Future<void> _loadMarkers() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final nw = await s.statsService.netWorthAt(DateTime.now());
    final markers = <GlobeMarker>[];
    final values = <String, AccountValuationItem>{};
    var maxValue = BigInt.zero;
    for (final item in nw.items) {
      final a = item.account;
      values[a.id] = item;
      if (!a.hasLocation) continue;
      if (item.valueBaseMinor > maxValue) maxValue = item.valueBaseMinor;
      markers.add(
        GlobeMarker(
          accountId: a.id,
          name: a.name,
          lat: a.locationLat!,
          lon: a.locationLon!,
          valueBaseMinor: item.valueBaseMinor,
          currencyCode: a.currencyCode,
          locationName: a.locationName,
          valuationMissing: item.valuationMissing,
          kind: GlobeMarker.kindOf(a.assetSubtype),
          institution: a.institution,
          subtypeLabel: a.assetSubtype?.labelZh ?? rt('资产'),
        ),
      );
    }
    markers.sort((x, y) => y.valueBaseMinor.compareTo(x.valueBaseMinor));
    if (!mounted) return;
    // 新标记绽放：与上一批求差——光束到达 reloadMarkers 时只有**新增**
    // 的光点自 0 绽放（0.45s，恰被到达闪耀罩住），存量标记纹丝不动
    // （2026-10 用户指令：阶段衔接要流畅，标记不得瞬间弹出）。
    final newIds = markers.map((m) => m.accountId).toSet();
    final bloom = _prevMarkerIds == null
        ? <String>{}
        : newIds.difference(_prevMarkerIds!);
    _prevMarkerIds = newIds;
    setState(() {
      _markers = markers;
      _values = values;
      _maxMarkerValue = maxValue;
      _baseCurrency = nw.baseCurrencyCode;
      if (bloom.isNotEmpty) {
        _spawnIds = bloom;
        _spawnAt = _elapsed;
      }
    });
  }

  void _startIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(
      widget.idleDelay ?? const Duration(milliseconds: 2500),
      () {
        if (!mounted || _dragging || _flying) return;
        // 惯性未收敛完先等（收敛路径自己会并入）；已并入/静止则（重）
        // 确立空闲自转——滚轮/拖拽后整页也由此退出沉浸。
        if (_velocity != 0 && _velocity != _idleOmega) return;
        _idleSpin = true;
        _velocity = _idleOmega;
        _notifyImmersive(false); // 空闲自转恢复：整页从沉浸中让回
      },
    );
  }

  void _stopIdle() {
    _idleTimer?.cancel();
    _idleSpin = false;
    _velocity = 0;
    // 直接操控介入：缩放补间重锚到当前值，滚轮目标不再悬空。
    _zoomTarget = _view.zoom;
    _zoomAnimating = false;
  }

  void _notifyImmersive(bool active) {
    if (_immersing == active) return;
    _immersing = active;
    widget.onImmersionChanged?.call(active);
  }

  /// 外部视角复位入口（首页窗口右上角「定位」按钮）：平滑旋转回默认
  /// 视角（不瞬移）。
  void resetView() => _reset();

  /// 外部标记重载入口（首页「添加资产」保存后调用——同一地球实例，
  /// 视角/缩放保持连续，仅刷新光点与估值）。
  void reloadMarkers() => _loadMarkers();

  /// 经纬度的当前屏幕位置（全局坐标；转到背面或未布局时为 null）。
  /// 供弹窗溶解光束逐帧追踪落点——地球飞行/沉浸扩张中都持续跟随。
  Offset? locationScreenPos(double lat, double lon) {
    if (_size == Size.zero) return null;
    final p = _view.project(lat, lon, _baseRadius * _view.zoom);
    if (p == null) return null;
    final ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return null;
    return ro.localToGlobal(
      Offset(_size.width / 2 + p.dx, _size.height / 2 + p.dy),
    );
  }

  /// 外部飞行入口（新建资产粒子光束联动）：飞往指定经纬度上空——
  /// 最短经度路径 + 轻微推近（+0.12 zoom），期间整页进入沉浸（卡片
  /// 让位、地球扩张全屏）；到达交还空闲自转（约 2.5s 后退出沉浸）。
  /// 「减少动画」直接落位。与 [DissolveStage] 的光束时间轴配套：
  /// 出鞘即飞（1250ms easeInOutCubic），彗头 1.15s 抵达时地球近停。
  Future<void> flyToLocation(
    double lat,
    double lon, {
    Duration? duration,
  }) async {
    if (_size == Size.zero) return;
    var targetLambda = lon;
    var diff = targetLambda - _view.lambda;
    while (diff > 180) {
      diff -= 360;
    }
    while (diff < -180) {
      diff += 360;
    }
    targetLambda = _view.lambda + diff;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _view = _view.copyWith(lambda: targetLambda, phi: lat));
      return;
    }
    _stopIdle();
    _notifyImmersive(true);
    final from = (lambda: _view.lambda, phi: _view.phi, zoom: _view.zoom);
    final zoomTo = (from.zoom + 0.12).clamp(0.75, 2.2);
    final controller = AnimationController(
      vsync: this,
      duration: duration ?? const Duration(milliseconds: 1250),
    );
    _flying = true;
    final curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );
    void listener() {
      if (!_flying) {
        controller.dispose();
        return;
      }
      setState(() {
        final t = curve.value;
        _view = GlobeView(
          lambda: from.lambda + (targetLambda - from.lambda) * t,
          phi: from.phi + (lat - from.phi) * t,
          zoom: from.zoom + (zoomTo - from.zoom) * t,
        );
      });
    }

    curve.addListener(listener);
    unawaited(
      controller.forward().orCancel.whenComplete(() {
        curve.removeListener(listener);
        controller.dispose();
        curve.dispose();
        _flying = false;
        _startIdle();
      }),
    );
  }

  /// 复位：视角**平滑旋转**回默认（最短经度路径，900ms easeInOutCubic；
  /// 「减少动画」直接落位）——不瞬移。选中与弹窗立即清除，飞行结束后
  /// 回到空闲自转。掐掉进行中的飞行（点第二次复位 = 从当前位重飞）。
  void _reset() {
    setState(() {
      _selectedId = null;
      _popup = null;
    });
    _flying = false;
    final target = GlobeView(); // 默认视角（中国上空）
    var diff = target.lambda - _view.lambda;
    while (diff > 180) {
      diff -= 360;
    }
    while (diff < -180) {
      diff += 360;
    }
    final targetLambda = _view.lambda + diff;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _view = GlobeView());
      return;
    }
    _stopIdle();
    final from = (lambda: _view.lambda, phi: _view.phi, zoom: _view.zoom);
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _flying = true;
    final curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );
    void listener() {
      if (!_flying) {
        controller.dispose();
        return;
      }
      setState(() {
        final t = curve.value;
        _view = GlobeView(
          lambda: from.lambda + (targetLambda - from.lambda) * t,
          phi: from.phi + (target.phi - from.phi) * t,
          zoom: from.zoom + (target.zoom - from.zoom) * t,
        );
      });
    }

    curve.addListener(listener);
    unawaited(
      controller.forward().orCancel.whenComplete(() {
        curve.removeListener(listener);
        controller.dispose();
        curve.dispose();
        _flying = false;
        _startIdle();
      }),
    );
  }

  void _onScaleStart(ScaleStartDetails s) {
    // 新手势打断一切：飞行动画、自转、残余惯性（抓住即停，手感可控）。
    _stopIdle();
    _flying = false;
    _dragging = true;
    _pinchZoomStart = _view.zoom;
    _lastPointers = s.pointerCount;
    _dragTravel = 0;
    _dragDx = 0;
  }

  void _onScaleUpdate(ScaleUpdateDetails s) {
    if (s.pointerCount != _lastPointers) {
      // 捏合中途抬起/落下一指：scale 以新手数重算基准会跳变，
      // 重锚缩放起点并吞掉这一帧的焦点位移。
      _lastPointers = s.pointerCount;
      _pinchZoomStart = _view.zoom;
      return;
    }
    _dragDx += s.focalPointDelta.dx;
    // 拖过阈值/双指捏合才上报沉浸——单纯轻点光点不应惊动整页。
    _dragTravel += s.focalPointDelta.distance;
    if (!_immersing &&
        (s.pointerCount >= 2 ||
            (s.scale - 1).abs() > 0.012 ||
            _dragTravel > _immerseDragPx)) {
      _notifyImmersive(true);
    }
    // 单指：scale 恒为 1（纯拖拽旋转）；双指：捏合缩放 + 焦点位移旋转。
    setState(() {
      _view = _view.copyWith(
        zoom: _pinchZoomStart * s.scale,
        lambda: _view.lambda - s.focalPointDelta.dx * _degPerPx,
        phi: _view.phi + s.focalPointDelta.dy * _degPerPx,
      );
    });
    _zoomTarget = _view.zoom; // 直接缩放与滚轮补间互不残留
  }

  void _onScaleEnd(ScaleEndDetails s) {
    _dragging = false;
    // 惯性速度取系统跟踪的释放速度（像素/秒），而非最后一个事件增量
    // （后者随事件节抖动，是"忽快忽慢"的根源之一）。
    final v = -s.velocity.pixelsPerSecond.dx * _degPerPx;
    _velocity = v.abs() >= _flickMin ? v.clamp(-_flickMax, _flickMax) : 0;
    // 自转方向跟手：甩动取释放速度方向，慢放取累计位移方向。
    final dir = _velocity != 0
        ? _velocity.sign
        : _dragDx.abs() > 8
        ? (-_dragDx).sign
        : _idleOmega.sign;
    _idleOmega = dir * _idleRate;
    _idleSpin = false;
    _startIdle();
  }

  // ── 滚轮 / 触控板缩放（桌面）──

  /// 滚轮族缩放入队：指数映射到目标值（_tick 里平滑逼近，逐格滚轮也
  /// 是连续缓放），并上报沉浸（整页卡片让位）。
  void _queueWheelZoom(double dy) {
    _idleTimer?.cancel();
    // 滚轮不打断自转、也不走惯性收敛路径：曾只把 _idleSpin 置 false
    // 而 _velocity 仍等于 _idleOmega——稳态空闲自转中滚一下，下一帧
    // _tick 的「惯性收敛并入自转」分支会立即 _notifyImmersive(false)，
    // 把刚上报的沉浸一帧内撤销（滚轮缩放卡片不消失的根因；拖拽后
    // 真惯性距 _idleOmega 远、要 ~1.7s 才收敛，所以拖拽路径不犯病）。
    // 改为直接并入稳态自转：退出沉浸只由 _startIdle 的空闲计时器负责。
    _velocity = _idleOmega;
    _idleSpin = true;
    _zoomTarget = (_zoomTarget * math.exp(-dy / 480)).clamp(0.75, 2.2);
    _zoomAnimating = true;
    _notifyImmersive(true);
    _startIdle();
  }

  void _onScroll(PointerScrollEvent e) => _queueWheelZoom(e.scrollDelta.dy);

  void _onPanZoomStart(PointerPanZoomStartEvent e) {
    _stopIdle();
    _panZoomBase = _view.zoom;
  }

  void _onPanZoomUpdate(PointerPanZoomUpdateEvent e) {
    if ((e.scale - 1).abs() >= 0.005) {
      setState(() {
        _view = _view.copyWith(zoom: _panZoomBase * e.scale);
      });
      _zoomTarget = _view.zoom; // 直接缩放与滚轮补间互不残留
      _notifyImmersive(true);
      return;
    }
    // 触控板双指滚动（scale≈1 的 pan 位移）：地球区域没有可滚动内容，
    // 按 Google Earth 惯例映射为缩放——部分设备的滚动手势不发
    // PointerScrollEvent 而走 pan-zoom 流，两条路都通向缩放+沉浸。
    if (e.panDelta.distanceSquared < 0.01) return;
    _queueWheelZoom(e.panDelta.dy);
  }

  void _onPanZoomEnd(PointerPanZoomEndEvent e) => _startIdle();

  void _tick() {
    // 由 CustomPaint 的 repaint 监听驱动每帧推进（时间基准）。
    final now = SchedulerBinding.instance.currentFrameTimeStamp;
    final dt = _lastTick == null
        ? 0.0
        : (now - _lastTick!).inMicroseconds / 1e6;
    _lastTick = now;
    if (dt <= 0 || dt > 0.25) return; // 首帧/后台恢复的长间隔不推进
    _elapsed += dt;
    if (_landDots.isNotEmpty) _appear = math.min(1.0, _appear + dt / 1.5);
    _advanceAmbient(dt);
    _particles.update(dt);
    // 滚轮缩放补间：向目标指数逼近（即便单格滚轮也是连续缓放）。
    if (_zoomAnimating) {
      final next =
          _view.zoom +
          (_zoomTarget - _view.zoom) * (1 - math.exp(-dt / _zoomTau));
      if ((_zoomTarget - next).abs() < 0.0006) {
        _view.zoom = _zoomTarget;
        _zoomAnimating = false;
      } else {
        _view.zoom = next.clamp(0.75, 2.2);
      }
    }
    if (_dragging || _flying) return;
    if (_idleSpin) {
      _view = _view.copyWith(lambda: _view.lambda + _idleOmega * dt);
      return;
    }
    if (_velocity != 0) {
      _view = _view.copyWith(lambda: _view.lambda + _velocity * dt);
      // 惯性不衰减到停：向空闲自转角速度收敛，到达后并入自转继续转
      // （方向 = 本次甩动/拖动方向），除非再次按住抓住。
      _velocity =
          _idleOmega + (_velocity - _idleOmega) * math.exp(-dt / _frictionTau);
      if ((_velocity - _idleOmega).abs() < 0.8) {
        _velocity = _idleOmega;
        _idleSpin = true;
        _notifyImmersive(false); // 已稳入空闲自转：整页让回
      }
    }
  }

  /// 标记星尘：每个可见标记低频升起微粒（生成率随标记数封顶 6 粒/秒）。
  void _advanceAmbient(double dt) {
    if (_markers.isEmpty || _size == Size.zero) return;
    _ambientBudget += dt * math.min(6.0, _markers.length * 0.6);
    final center = _size.center(Offset.zero);
    while (_ambientBudget >= 1) {
      _ambientBudget -= 1;
      final m = _markers[_rnd.nextInt(_markers.length)];
      final p = _view.project(m.lat, m.lon, _baseRadius * _view.zoom);
      if (p == null) continue; // 背面标记这颗作废
      _particles.sparkle(
        center + Offset(p.dx, p.dy),
        color: m.accountId == _selectedId
            ? const Color(0xFFC4DCF8)
            : const Color(0xFFE5C078),
      );
    }
  }

  // ── 光点命中（悬停/点击共用）：最近者为主锚，附近 34px 内聚为一组 ──

  GlobePopupGroup? _hitGroup(Offset point) {
    GlobeMarker? anchor;
    Offset? anchorScreen;
    var best = double.infinity;
    final positions = <GlobeMarker, Offset>{};
    for (final m in _markers) {
      final p = _view.project(m.lat, m.lon, _baseRadius * _view.zoom);
      if (p == null) continue;
      final screen = Offset(p.dx, p.dy);
      positions[m] = screen;
      final r = markerRadiusFor(
        m.valueBaseMinor,
        _maxMarkerValue,
        zoom: _view.zoom,
      );
      final d = (screen - point).distance;
      if (d <= r + 14 && d < best) {
        best = d;
        anchor = m;
        anchorScreen = screen;
      }
    }
    if (anchor == null || anchorScreen == null) return null;
    final near = [
      for (final e in positions.entries)
        if ((e.value - anchorScreen).distance <= 34) e.key,
    ];
    return GlobePopupGroup(anchor: anchor, markers: near);
  }

  void _onHover(PointerHoverEvent e) {
    // 悬停命中区扩到弹窗卡本身：鼠标移入卡内不视为"移开"。
    if (_popupFromHover && _popupCardRect?.contains(e.localPosition) == true) {
      return;
    }
    final g = _hitGroup(e.localPosition);
    if (g != null) {
      if (g.key == _popup?.key) return;
      setState(() {
        _popup = g;
        _popupFromHover = true;
      });
    } else if (_popupFromHover && _popup != null) {
      setState(() => _popup = null);
    }
  }

  void _onHoverExit() {
    if (_popupFromHover && _popup != null) {
      setState(() => _popup = null);
    }
  }

  void _onTap(TapUpDetails d) {
    final g = _hitGroup(d.localPosition);
    if (g == null) {
      // 空白处点击：收起弹窗/选中，并退出沉浸。
      _notifyImmersive(false);
      if (_selectedId != null || _popup != null) {
        setState(() {
          _selectedId = null;
          _popup = null;
        });
      }
      return;
    }
    final p = _view.project(
      g.anchor.lat,
      g.anchor.lon,
      _baseRadius * _view.zoom,
    );
    if (p != null) {
      _particles.burst(Offset(_size.width / 2 + p.dx, _size.height / 2 + p.dy));
    }
    if (_selectedId == g.anchor.accountId && _popup?.key == g.key) {
      _openDetail(g.anchor); // 已选中：再点一次开详情
    } else {
      _flyTo(g.anchor, group: g);
    }
  }

  /// 飞行动画：经度取最短路径，纬度直接过渡。
  Future<void> _flyTo(GlobeMarker m, {GlobePopupGroup? group}) async {
    _stopIdle();
    setState(() {
      _selectedId = m.accountId;
      _popup = group;
      _popupFromHover = false;
    });
    var targetLambda = m.lon.toDouble();
    // 最短经度路径（跨 ±180 处理）。
    var diff = targetLambda - _view.lambda;
    while (diff > 180) {
      diff -= 360;
    }
    while (diff < -180) {
      diff += 360;
    }
    targetLambda = _view.lambda + diff;
    final from = (lambda: _view.lambda, phi: _view.phi);
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _flying = true;
    final curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    void listener() {
      if (!_flying) {
        controller.dispose();
        return;
      }
      setState(() {
        final t = curve.value;
        _view = GlobeView(
          lambda: from.lambda + (targetLambda - from.lambda) * t,
          phi: from.phi + (m.lat - from.phi) * t,
          zoom: _view.zoom,
        );
      });
    }

    curve.addListener(listener);
    unawaited(
      controller.forward().orCancel.whenComplete(() {
        curve.removeListener(listener);
        controller.dispose();
        curve.dispose();
        // 复位飞行标志：否则 _tick 永久早退、空闲自转停摆（存量 bug）。
        _flying = false;
        _startIdle();
      }),
    );
  }

  void _openDetail(GlobeMarker m) {
    showMarkerDetailSheet(
      context,
      marker: m,
      item: _values[m.accountId],
      base: _baseCurrency,
    );
  }

  // ── 弹窗定位：每帧跟随锚点（旋转/缩放时贴住光点），贴上缘时翻到下方 ──

  Widget? _buildPopupLayer() {
    final g = _popup;
    if (g == null || _size == Size.zero) {
      _popupCardRect = null;
      return null;
    }
    final p = _view.project(
      g.anchor.lat,
      g.anchor.lon,
      _baseRadius * _view.zoom,
    );
    // 锚点转到背面/地平线附近：本帧不显示（转回来自动复现）。
    if (p == null || p.z <= 0.12) {
      _popupCardRect = null;
      return null;
    }
    final pos = Offset(_size.width / 2 + p.dx, _size.height / 2 + p.dy);
    final r = markerRadiusFor(
      g.anchor.valueBaseMinor,
      _maxMarkerValue,
      zoom: _view.zoom,
    );
    final estHeight = 46 + math.min(3, g.markers.length) * 34.0;
    var below = false;
    var top = pos.dy - r - 10 - estHeight;
    if (top < 8) {
      below = true;
      top = pos.dy + r + 12;
    }
    top = top
        .clamp(8.0, math.max(8.0, _size.height - estHeight - 8))
        .toDouble();
    final left = (pos.dx - MarkerPopupCard.width / 2)
        .clamp(8.0, math.max(8.0, _size.width - MarkerPopupCard.width - 8))
        .toDouble();
    _popupCardRect = Rect.fromLTWH(left, top, MarkerPopupCard.width, estHeight);
    return SizedBox.expand(
      child: Transform.translate(
        offset: Offset(left, top),
        child: MarkerPopupCard(
          key: ValueKey('globe-popup-${g.key}'),
          group: g,
          values: _values,
          base: _baseCurrency,
          below: below,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_landDots.isEmpty) {
      return const Center(
        child: OrbitSpinner(size: 44, color: Color(0xFF7EA6D9)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        _baseRadius =
            math.min(constraints.maxWidth, constraints.maxHeight) / 2 * 0.86;
        _size = constraints.biggest;
        return AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            _tick();
            return Stack(
              children: [
                // 深空底幕：星野/星云/流星（在地球之下，自带 Ticker）。
                if (widget.backdrop)
                  const Positioned.fill(child: SpaceBackdrop()),
                Positioned.fill(
                  child: Listener(
                    onPointerSignal: (e) {
                      if (e is PointerScrollEvent) _onScroll(e);
                    },
                    onPointerPanZoomStart: _onPanZoomStart,
                    onPointerPanZoomUpdate: _onPanZoomUpdate,
                    onPointerPanZoomEnd: _onPanZoomEnd,
                    child: MouseRegion(
                      onHover: _onHover,
                      onExit: (_) => _onHoverExit(),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        // 手势只用 scale 识别器（pan 的超集）：单指拖拽 /
                        // 双指捏合，与 onPan* 并存会触发框架断言
                        // 「Incorrect GestureDetector arguments」红屏。
                        // 双击复位已移除（瞬移观感差且误触）；暂停自转
                        // 的唯一手势是长按（按住停住，松手 2.5s 后回转）。
                        onScaleStart: _onScaleStart,
                        onScaleUpdate: _onScaleUpdate,
                        onScaleEnd: _onScaleEnd,
                        onTapUp: _onTap,
                        onLongPressStart: (_) => _stopIdle(),
                        onLongPressEnd: (_) => _startIdle(),
                        child: CustomPaint(
                          painter: GlobePainter(
                            landDots: _landDots,
                            markers: _markers,
                            view: _view,
                            pulse: _pulse.value,
                            selectedId: _selectedId,
                            appear: _appear,
                            t: _elapsed,
                            spawnIds: _spawnIds,
                            spawnAge: _elapsed - _spawnAt,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                ),
                // 粒子层：标记星尘与点击爆发（地球之上，hitTest 恒 false）。
                Positioned.fill(
                  child: CustomPaint(painter: ParticlesPainter(_particles)),
                ),
                // 锚点弹窗：跟随光点，IgnorePointer 让点击穿透到背后的
                // 光点（再点一次开详情）。入场由卡片自绘（放大+上浮），
                // 离场在此 160ms 淡出；duration 1ms = 入场瞬时交给卡片。
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1),
                      reverseDuration: const Duration(milliseconds: 160),
                      switchInCurve: Curves.linear,
                      switchOutCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: _buildPopupLayer() ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
                // 右上角悬浮操作：复位 + 全屏（浅色主题下也保持深空配色）。
                // 首页把这组操作统一挪到窗口右上角，此处不画。
                if (widget.showActions)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _overlayIcon(
                          tooltip: t.globeResetView,
                          icon: Icons.my_location,
                          onTap: _reset,
                        ),
                        if (widget.onOpenFullscreen != null) ...[
                          const SizedBox(width: 8),
                          _overlayIcon(
                            tooltip: t.globeFullscreen,
                            icon: Icons.open_in_full,
                            onTap: widget.onOpenFullscreen!,
                          ),
                        ],
                      ],
                    ),
                  ),
                // 左下角 HUD 已按用户要求移除（图例/探索提示属于
                // 「需要时才看」的信息；资产数在卡片区可见）。
              ],
            );
          },
        );
      },
    );
  }

  Widget _overlayIcon({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.07),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 18, // 与首页右上角刷新按钮同尺寸
              color: const Color(0xFF7EA6D9).withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}
