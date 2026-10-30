import 'package:assetscope/ui/globe/globe_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// 投影方向回归：v0.16 之前绕 x 轴旋转符号写反，屏幕中心实际显示
/// -phi 纬度（南北镜像）——垂直拖拽方向颠倒、点击标记飞完贴顶边。
/// 此处以固定断言锁住方向，防止再翻回去。
void main() {
  test('视野中心经纬投影到屏幕正中', () {
    final v = GlobeView(lambda: 116.4, phi: 30);
    final p = v.project(30, 116.4, 100)!;
    expect(p.dx, closeTo(0, 1e-9));
    expect(p.dy, closeTo(0, 1e-9));
    expect(p.z, closeTo(1, 1e-9));
  });

  test('北极在屏幕上方且可见（北上，不镜像）', () {
    final v = GlobeView(lambda: 0, phi: 20);
    final p = v.project(90, 0, 100)!;
    expect(p.dy, lessThan(0));
    expect(p.z, greaterThan(0));
  });

  test('phi 增大（下滑手势）→ 原中心内容移到屏幕下方（垂直跟手）', () {
    final v = GlobeView(lambda: 0, phi: 30);
    final after = v.copyWith(phi: 40).project(30, 0, 100)!;
    expect(after.dy, greaterThan(0));
    expect(after.z, greaterThan(0));
  });

  test('lambda 减小（右滑手势）→ 原中心内容移到屏幕右方（水平跟手）', () {
    final v = GlobeView(lambda: 0, phi: 30);
    final after = v.copyWith(lambda: -10).project(30, 0, 100)!;
    expect(after.dx, greaterThan(0));
  });

  test('飞行动画落点视角（phi=lat, lambda=lon）将标记置于正中', () {
    final v = GlobeView(lambda: 151.2, phi: -33.9); // 悉尼
    final p = v.project(-33.9, 151.2, 100)!;
    expect(p.dx, closeTo(0, 1e-9));
    expect(p.dy, closeTo(0, 1e-9));
    expect(p.z, closeTo(1, 1e-9));
  });
}
