import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'ui/widgets/window_chrome.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 双语日期符号（zh/en）：DateFormat 按 locale 取月份名/上下午等需先加载。
  await initializeDateFormatting('zh');
  await initializeDateFormatting('en');
  // 桌面端：去原生标题条（内容全出血到窗口顶缘），窗口控件自绘
  // （macOS 红绿灯，见 WindowChrome）。失败则退回原生标题条。
  if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    _installErrorLog();
    try {
      await windowManager.ensureInitialized();
      await windowManager.waitUntilReadyToShow(
        const WindowOptions(
          titleBarStyle: TitleBarStyle.hidden,
          minimumSize: Size(480, 600),
        ),
        () async {
          WindowChrome.enabled = true;
          await windowManager.show();
        },
      );
    } catch (_) {
      // 保持 WindowChrome.enabled=false，界面照常运行。
    }
  }
  runApp(ProviderScope(child: AssetScopeApp()));
}

/// Release 诊断日志：未捕获的框架/平台异常追加写到数据目录
/// errors.log（超 512KB 截断重开）。Release 构建出错时界面只余灰屏/
/// 空白，无控制台可看——留下证据才能定位（如「弹窗没出现」类问题）。
void _installErrorLog() {
  Future<void> append(String text) async {
    try {
      final dir = Platform.environment['APPDATA'];
      if (dir == null) return;
      final home = Directory(
        '$dir${Platform.pathSeparator}dev.assetscope'
        '${Platform.pathSeparator}assetscope',
      );
      await home.create(recursive: true);
      final file = File('${home.path}${Platform.pathSeparator}errors.log');
      if (await file.exists() && await file.length() > 512 * 1024) {
        await file.delete();
      }
      await file.writeAsString(
        '---- ${DateTime.now()} ----\n$text\n\n',
        mode: FileMode.append,
      );
    } catch (_) {
      /* 日志失败静默 */
    }
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(append(details.toString()));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(append('$error\n$stack'));
    return true;
  };
}
