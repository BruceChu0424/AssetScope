import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/app/providers.dart';
import 'package:assetscope/domain/invest/allocation.dart';
import 'package:assetscope/ui/reports/allocation_card.dart';
import 'package:assetscope/ui/theme/app_theme.dart';

/// 图表调色板与外观模式序列化。
void main() {
  test('图表调色板：深浅各 9 色且逐档提亮（深色背景可辨识）', () {
    final light = AppChartPalette.of(Brightness.light);
    final dark = AppChartPalette.of(Brightness.dark);
    expect(light.length, 9);
    expect(dark.length, 9);
    for (var i = 0; i < 9; i++) {
      // 深色版每档亮度高于浅色版，保证在深底上的层次。
      expect(
        _luminance(dark[i]),
        greaterThan(_luminance(light[i])),
        reason: '第 $i 档在深色模式应提亮',
      );
    }
  });

  test('配置类配色：与调色板对齐且双模式不同', () {
    final equityLight = allocationColor(AllocationClass.equity, Brightness.light);
    final equityDark = allocationColor(AllocationClass.equity, Brightness.dark);
    expect(equityLight, AppChartPalette.light.first);
    expect(equityDark, AppChartPalette.dark.first);
    expect(allocationColor(AllocationClass.other, Brightness.light),
        AppChartPalette.light.last);
    expect(equityLight, isNot(equityDark));
  });

  test('外观模式序列化往返；未知值回退跟随系统', () {
    for (final m in ThemeMode.values) {
      expect(themeModeFromString(themeModeToString(m)), m);
    }
    expect(themeModeFromString('auto'), ThemeMode.system);
    expect(themeModeFromString(''), ThemeMode.system);
  });
}

double _luminance(Color c) =>
    (0.299 * (c.r * 255) + 0.587 * (c.g * 255) + 0.114 * (c.b * 255)) / 255;
