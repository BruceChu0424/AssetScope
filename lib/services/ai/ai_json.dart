/// AI 应答 JSON 提取（共享工具）。
///
/// 各 AI 服务的结构化输出解析共用：优先 ```json 围栏，否则取首个 '{'
/// 到与之平衡的 '}'（字符串内的括号不计入深度）。
library;

import 'dart:convert';

String? extractAiJson(String content) {
  final fence = RegExp(
    r'```(?:json)?\s*(\{.*?\})\s*```',
    dotAll: true,
  ).firstMatch(content);
  if (fence != null) return fence.group(1);
  final start = content.indexOf('{');
  if (start < 0) return null;
  var depth = 0;
  var inString = false;
  for (var i = start; i < content.length; i++) {
    final ch = content[i];
    if (inString) {
      if (ch == r'\' && i + 1 < content.length) {
        i++;
      } else if (ch == '"') {
        inString = false;
      }
      continue;
    }
    if (ch == '"') {
      inString = true;
    } else if (ch == '{') {
      depth++;
    } else if (ch == '}') {
      depth--;
      if (depth == 0) return content.substring(start, i + 1);
    }
  }
  return null;
}

/// 解析 AI 应答为 JSON 对象；失败抛 [FormatException]（消息面向用户）。
Map<String, Object?> decodeAiJsonObject(String content) {
  final jsonText = extractAiJson(content);
  if (jsonText == null) {
    throw const FormatException('AI 应答中未找到 JSON 数据');
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(jsonText);
  } on FormatException {
    throw const FormatException('AI 应答 JSON 无法解析');
  }
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('AI 应答 JSON 不是对象');
  }
  return decoded;
}
