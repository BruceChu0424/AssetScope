import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/stats_service.dart';
import '../widgets/common.dart';
import 'globe_painter.dart';
import 'globe_state.dart';

/// 资产地球页：点阵线框 3D 地球 + 固定资产呼吸标记。
///
/// - 拖拽旋转（带惯性）、双指/滚轮缩放、双击复位；
/// - 空闲 4 秒后缓慢自转；
/// - 点击标记：飞行动画转到正对该资产并弹出详情。
class GlobePage extends ConsumerStatefulWidget {
  const GlobePage({super.key});

  @override
  ConsumerState<GlobePage> createState() => _GlobePageState();
}

class _GlobePageState extends ConsumerState<GlobePage>
    with SingleTickerProviderStateMixin {
  List<double> _landDots = const [];
  List<GlobeMarker> _markers = const [];
  Map<String, AccountValuationItem> _values = const {};
  String _baseCurrency = 'CNY';

  // 注意：必须在 initState 显式初始化，不能用 late final 字段惰性初始化——
  // 若页面在首次访问 _pulse 前就被销毁（数据未加载即退出），dispose 里的
  // _pulse.dispose() 会触发惰性构造 AnimationController，在已失活的
  // element 上查询 TickerMode 而崩溃。
  late final AnimationController _pulse;

  GlobeView _view = GlobeView();
  double _velocity = 0; // 经度方向惯性速度（度/帧）
  Timer? _idleTimer;
  String? _selectedId;
  bool _flying = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
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
    for (final item in nw.items) {
      final a = item.account;
      values[a.id] = item;
      if (!a.hasLocation) continue;
      markers.add(GlobeMarker(
        accountId: a.id,
        name: a.name,
        lat: a.locationLat!,
        lon: a.locationLon!,
        valueBaseMinor: item.valueBaseMinor,
        currencyCode: a.currencyCode,
        locationName: a.locationName,
        valuationMissing: item.valuationMissing,
      ));
    }
    markers.sort((x, y) => y.valueBaseMinor.compareTo(x.valueBaseMinor));
    if (!mounted) return;
    setState(() {
      _markers = markers;
      _values = values;
      _baseCurrency = nw.baseCurrencyCode;
    });
  }

  void _startIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _velocity = -0.055); // 缓慢自转
    });
  }

  void _stopIdle() {
    _idleTimer?.cancel();
    _velocity = 0;
  }

  void _onPan(DragUpdateDetails d) {
    _stopIdle();
    _flying = false;
    const sensitivity = 0.28;
    setState(() {
      _view = _view.copyWith(
        lambda: _view.lambda - d.delta.dx * sensitivity / _view.zoom,
        phi: _view.phi + d.delta.dy * sensitivity / _view.zoom,
      );
      _velocity = -d.delta.dx * sensitivity / _view.zoom;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    _startIdle();
  }

  void _tick() {
    // 由 CustomPaint 的 repaint 监听驱动每帧惯性衰减。
    if (_velocity.abs() < 0.004) {
      if (_velocity != 0) _velocity = 0;
      return;
    }
    _view = _view.copyWith(lambda: _view.lambda + _velocity);
    _velocity *= 0.94;
  }

  void _onTap(TapUpDetails d, BoxConstraints size) {
    final radius =
        math.min(size.maxWidth, size.maxHeight) / 2 * 0.86 * _view.zoom;
    var maxValue = BigInt.zero;
    for (final m in _markers) {
      if (m.valueBaseMinor > maxValue) maxValue = m.valueBaseMinor;
    }
    for (final m in _markers) {
      final p = _view.project(m.lat, m.lon, radius);
      if (p == null) continue;
      if (GlobeMarker.hit(
          Offset3D(p.dx, p.dy, p.z), d.localPosition, markerRadiusFor(m.valueBaseMinor, maxValue))) {
        _flyTo(m);
        return;
      }
    }
    // 空白处点击：取消选中。
    if (_selectedId != null) setState(() => _selectedId = null);
  }

  /// 飞行动画：经度取最短路径，纬度直接过渡。
  Future<void> _flyTo(GlobeMarker m) async {
    _stopIdle();
    setState(() => _selectedId = m.accountId);
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
        vsync: this, duration: const Duration(milliseconds: 650));
    _flying = true;
    final curve = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
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
    unawaited(controller.forward().orCancel.whenComplete(() {
      curve.removeListener(listener);
      controller.dispose();
      _startIdle();
      _openDetail(m);
    }));
  }

  void _openDetail(GlobeMarker m) {
    final item = _values[m.accountId];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF0B1626),
      builder: (_) => _MarkerDetailSheet(marker: m, item: item, base: _baseCurrency),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      appBar: AppBar(
        title: const Text('资产地球'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.tealAccent,
        actions: [
          IconButton(
            tooltip: '复位视角',
            icon: const Icon(Icons.my_location, color: Colors.tealAccent),
            onPressed: () => setState(() {
              _view = GlobeView();
              _selectedId = null;
              _flying = false;
              _startIdle();
            }),
          ),
        ],
      ),
      body: _landDots.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent))
          : LayoutBuilder(builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: _onPan,
                onPanEnd: _onPanEnd,
                onTapUp: (d) => _onTap(d, constraints),
                onScaleUpdate: (s) {
                  if (s.pointerCount == 2) {
                    setState(() => _view = _view.copyWith(
                        zoom: _view.zoom * (1 + (s.scale - 1) * 0.05)));
                  }
                },
                onDoubleTap: () => setState(() {
                  _view = GlobeView();
                  _flying = false;
                }),
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    _tick();
                    return CustomPaint(
                      painter: GlobePainter(
                        landDots: _landDots,
                        markers: _markers,
                        view: _view,
                        pulse: _pulse.value,
                        selectedId: _selectedId,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              );
            }),
      bottomNavigationBar: _markers.isEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '还没有资产带位置。到「账户」页打开资产详情，点「设置位置」即可出现在地球上。',
                  style: TextStyle(color: Colors.tealAccent.withValues(alpha: 0.7)),
                ),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Icon(Icons.public,
                        size: 16, color: Colors.tealAccent.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Text(
                      '${_markers.length} 处固定资产 · 拖动旋转 · 点击标记查看',
                      style: TextStyle(
                          color: Colors.tealAccent.withValues(alpha: 0.7),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFFF5B841)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    marker.locationName ?? marker.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${marker.name} · ${marker.lat.toStringAsFixed(2)}°, ${marker.lon.toStringAsFixed(2)}°',
              style: TextStyle(
                  color: Colors.tealAccent.withValues(alpha: 0.6), fontSize: 12),
            ),
            const SizedBox(height: 16),
            _row('当前价值',
                hasValue ? fmtMinor(item!.valueBaseMinor, base) : '缺估值（不计净资产）'),
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
            Text(label, style: TextStyle(color: Colors.tealAccent.withValues(alpha: 0.6))),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontFeatures: [FontFeature.tabularFigures()])),
          ],
        ),
      );
}
