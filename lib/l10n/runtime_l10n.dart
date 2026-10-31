import 'runtime_map.dart';

/// 领域/服务层中文消息的运行时双语支持（无 BuildContext 场景）。
///
/// 领域层异常、校验消息等没有 context 可用，统一以中文原文为 key：
/// [rt] 在英文模式下查 [runtimeZhEn] 映射返回英文，未收录则原样返回。
/// 映射表由文案抽取流程生成维护（lib/l10n/runtime_map.dart）。
class RuntimeL10n {
  /// 当前 UI 语言是否为英文（app.dart 的 builder 按解析结果刷新）。
  static bool english = false;
}

/// 中文原文 → 英文译文（领域层消息专用；UI 文案请走 AppLocalizations）。
String rt(String zh) =>
    RuntimeL10n.english ? (runtimeZhEn[zh] ?? zh) : zh;
