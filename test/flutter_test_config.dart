import 'dart:async';
import 'dart:typed_data' show Uint8List;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter_test/flutter_test.dart';

/// 全局测试装配（对 test/ 下所有用例生效）：
/// - golden 跨平台容差比较：基线在 Windows 上生成，CI 在 Linux 上渲染，
///   字体抗锯齿与 Skia 光栅化的亚像素差异不可避免（实测 0.26%–2.79%
///   像素不等），像素级全等在跨平台上不可达；
/// - drift 多库告警静音：本仓库测试惯例是每个用例自建数据库实例，
///   该告警在此场景是噪音（drift 官方文档认可的对测试套件的静音项）。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  // 工具链引导先装好带正确 basedir（测试文件所在目录）的 LocalFileComparator
  // 再回调本函数，这里基于它替换；flutter run 下的 TrivialComparator 不动。
  final inner = goldenFileComparator;
  if (inner is LocalFileComparator) {
    goldenFileComparator = TolerantGoldenComparator(inner);
  }
  await testMain();
}

/// 在 [LocalFileComparator] 像素级全等之上放宽一档：差异像素占比
/// ≤ [precisionTolerance] 判过（[GoldenFileComparator.compareLists] 的
/// 官方容差用法，失败时仍生成 master/isolatedDiff/maskedDiff 图便于定位）。
///
/// 阈值取 0.05：高于实测跨平台噪声上限 2.79% 留 1.8 倍余量，以吸收
/// CI 侧 Flutter stable 的小版本渲染演进；真实布局回归（错位、错色、
/// 缺块）是成片像素差异，远超该阈值，仍会被拦下。
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(LocalFileComparator fallback)
    // basedir 是目录 Uri；LocalFileComparator 构造器要的是「文件」Uri，
    // 拼一个哨兵文件名再让它 dirname 回同一目录。
    : super(fallback.basedir.resolve('_test_file_.dart'));

  /// 允许的差异像素占比（0 = 全等，1 = 完全不同）。
  static const double precisionTolerance = 0.05;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    final bool passed =
        result.passed || result.diffPercent <= precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }

    final String error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
