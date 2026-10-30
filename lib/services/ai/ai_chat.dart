import '../net/guarded_http.dart';

/// 请求协议形态。
enum AiProtocol { openai, anthropic }

/// AI 服务商预设。
class AiProviderPreset {
  const AiProviderPreset({
    required this.id,
    required this.label,
    required this.protocol,
    required this.defaultBaseUrl,
    required this.defaultModel,
    required this.supportsWebSearch,
    this.note,
  });

  final String id;
  final String label;
  final AiProtocol protocol;
  final String defaultBaseUrl;

  /// 联网搜索默认模型（可改）。
  final String defaultModel;

  /// API 是否支持服务端联网搜索（行情抓取的前提）。
  final bool supportsWebSearch;
  final String? note;
}

class AiProviderPresets {
  AiProviderPresets._();

  static const glm = AiProviderPreset(
    id: 'glm',
    label: '智谱 GLM（glm-4.7-flash 免费）',
    protocol: AiProtocol.openai,
    defaultBaseUrl: 'https://open.bigmodel.cn/api/paas/v4',
    defaultModel: 'glm-4.7-flash',
    supportsWebSearch: true,
    note: '国内直连，web_search 工具联网',
  );

  static const moonshot = AiProviderPreset(
    id: 'moonshot',
    label: '月之暗面 Kimi',
    protocol: AiProtocol.openai,
    defaultBaseUrl: 'https://api.moonshot.cn/v1',
    defaultModel: 'kimi-latest',
    supportsWebSearch: true,
    note: '内置 \$web_search 联网搜索',
  );

  static const qwen = AiProviderPreset(
    id: 'qwen',
    label: '通义千问（阿里云百炼）',
    protocol: AiProtocol.openai,
    defaultBaseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    defaultModel: 'qwen-plus',
    supportsWebSearch: true,
    note: 'enable_search 联网搜索',
  );

  static const deepseek = AiProviderPreset(
    id: 'deepseek',
    label: 'DeepSeek（不支持联网）',
    protocol: AiProtocol.openai,
    defaultBaseUrl: 'https://api.deepseek.com/v1',
    defaultModel: 'deepseek-chat',
    supportsWebSearch: false,
    note: 'API 无联网搜索，行情抓取结果可能不是实时数据',
  );

  static const openai = AiProviderPreset(
    id: 'openai',
    label: 'OpenAI',
    protocol: AiProtocol.openai,
    defaultBaseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-4o',
    supportsWebSearch: true,
    note: 'web_search 工具联网',
  );

  static const anthropic = AiProviderPreset(
    id: 'anthropic',
    label: 'Anthropic Claude',
    protocol: AiProtocol.anthropic,
    defaultBaseUrl: 'https://api.anthropic.com',
    defaultModel: 'claude-sonnet-4-5',
    supportsWebSearch: true,
    note: 'web_search 服务端工具联网',
  );

  static const custom = AiProviderPreset(
    id: 'custom',
    label: '自定义（OpenAI 兼容）',
    protocol: AiProtocol.openai,
    defaultBaseUrl: '',
    defaultModel: '',
    supportsWebSearch: false,
    note: '任意 OpenAI 兼容端点；请自行确认联网能力',
  );

  static const List<AiProviderPreset> all = [
    glm,
    moonshot,
    qwen,
    deepseek,
    openai,
    anthropic,
    custom,
  ];

  static AiProviderPreset? byCode(String? id) {
    if (id == null) return null;
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// AI 服务配置（持久化在加密库 settings 表，key: aiProvider）。
class AiConfig {
  const AiConfig({
    required this.presetId,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.enableWebSearch,
  });

  final String presetId;
  final String baseUrl;
  final String apiKey;
  final String model;
  final bool enableWebSearch;

  AiProviderPreset? get preset => AiProviderPresets.byCode(presetId);

  AiProtocol get protocol => preset?.protocol ?? AiProtocol.openai;

  Map<String, Object?> toJson() => {
    'presetId': presetId,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'model': model,
    'enableWebSearch': enableWebSearch,
  };

  static AiConfig? fromJson(Map<String, Object?>? j) {
    if (j == null) return null;
    final presetId = j['presetId'];
    final baseUrl = j['baseUrl'];
    final apiKey = j['apiKey'];
    final model = j['model'];
    if (presetId is! String ||
        baseUrl is! String ||
        apiKey is! String ||
        model is! String) {
      return null;
    }
    return AiConfig(
      presetId: presetId,
      baseUrl: baseUrl,
      apiKey: apiKey,
      model: model,
      enableWebSearch: j['enableWebSearch'] == true,
    );
  }
}

/// 一条对话消息（user / assistant）。
class AiMessage {
  const AiMessage.user(this.content) : role = 'user';
  const AiMessage.assistant(this.content) : role = 'assistant';

  AiMessage.fromMap(Map<String, Object?> m)
    : role = m['role'] as String? ?? 'user',
      content = m['content'] as String? ?? '';

  final String role;
  final String content;

  Map<String, Object?> toMap() => {'role': role, 'content': content};
}

/// 聊天补全客户端：OpenAI 兼容与 Anthropic 两种协议。
/// 请求构造与响应提取拆为纯静态方法便于测试；网络走 [GuardedHttp]。
class AiChat {
  const AiChat();

  /// 单轮补全，返回模型文本。异常信息不含 API Key。
  Future<String> complete(AiConfig cfg, String system, String user) =>
      converse(cfg, system, [AiMessage.user(user)]);

  /// 多轮对话：[messages] 为按时间序的 user/assistant 交替历史。
  Future<String> converse(
    AiConfig cfg,
    String system,
    List<AiMessage> messages,
  ) async {
    final Map<String, String> headers;
    final Object body;
    final String url;
    if (cfg.protocol == AiProtocol.anthropic) {
      final (u, h, b) = buildAnthropicMessagesRequest(cfg, system, messages);
      headers = h;
      body = b;
      url = u.toString();
    } else {
      final (u, h, b) = buildOpenAiMessagesRequest(cfg, system, messages);
      headers = h;
      body = b;
      url = u.toString();
    }
    final resp = await GuardedHttp.postJson(url, headers: headers, body: body);
    final text = cfg.protocol == AiProtocol.anthropic
        ? extractAnthropicText(resp)
        : extractOpenAiText(resp);
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('AI 响应中没有文本内容');
    }
    return text;
  }

  /// OpenAI 兼容请求：{baseUrl}/chat/completions。
  /// 联网搜索按预设注入：GLM web_search 工具 / Kimi builtin_function /
  /// 千问 enable_search / OpenAI web_search 工具。
  static (Uri, Map<String, String>, Map<String, Object?>) buildOpenAiRequest(
    AiConfig cfg,
    String system,
    String user,
  ) => buildOpenAiMessagesRequest(cfg, system, [AiMessage.user(user)]);

  /// 多轮版请求构造（消息体见 [AiMessage]）。
  static (Uri, Map<String, String>, Map<String, Object?>)
  buildOpenAiMessagesRequest(
    AiConfig cfg,
    String system,
    List<AiMessage> messages,
  ) {
    final tools = <Object?>[];
    final extra = <String, Object?>{};
    if (cfg.enableWebSearch) {
      switch (cfg.preset?.id) {
        case 'glm':
          tools.add({
            'type': 'web_search',
            'web_search': {'enable': true, 'search_result': true},
          });
        case 'moonshot':
          tools.add({
            'type': 'builtin_function',
            'function': {'name': r'$web_search'},
          });
        case 'qwen':
          extra['enable_search'] = true;
        case 'custom':
        case 'deepseek':
          break; // 不支持服务端联网搜索
        default: // openai 及其余兼容端点
          tools.add({'type': 'web_search'});
      }
    }
    final body = <String, Object?>{
      'model': cfg.model,
      'messages': [
        {'role': 'system', 'content': system},
        for (final m in messages) m.toMap(),
      ],
      'stream': false,
      ...extra,
      if (tools.isNotEmpty) 'tools': tools,
    };
    final headers = {
      'Authorization': 'Bearer ${cfg.apiKey}',
      'Accept': 'application/json',
    };
    final base = cfg.baseUrl.endsWith('/')
        ? cfg.baseUrl.substring(0, cfg.baseUrl.length - 1)
        : cfg.baseUrl;
    return (GuardedHttp.validate('$base/chat/completions'), headers, body);
  }

  /// Anthropic Messages API：system 独立字段、x-api-key 鉴权。
  static (Uri, Map<String, String>, Map<String, Object?>) buildAnthropicRequest(
    AiConfig cfg,
    String system,
    String user,
  ) => buildAnthropicMessagesRequest(cfg, system, [AiMessage.user(user)]);

  /// 多轮版 Anthropic 请求构造。
  static (Uri, Map<String, String>, Map<String, Object?>)
  buildAnthropicMessagesRequest(
    AiConfig cfg,
    String system,
    List<AiMessage> messages,
  ) {
    final body = <String, Object?>{
      'model': cfg.model,
      'max_tokens': 4096,
      'system': system,
      'messages': [for (final m in messages) m.toMap()],
      'stream': false,
      if (cfg.enableWebSearch)
        'tools': [
          {'type': 'web_search_20250305', 'name': 'web_search'},
        ],
    };
    final headers = {
      'x-api-key': cfg.apiKey,
      'anthropic-version': '2023-06-01',
      'Accept': 'application/json',
    };
    final base = cfg.baseUrl.endsWith('/')
        ? cfg.baseUrl.substring(0, cfg.baseUrl.length - 1)
        : cfg.baseUrl;
    return (GuardedHttp.validate('$base/v1/messages'), headers, body);
  }

  /// OpenAI 兼容响应 → 文本（content 为字符串或分段块列表）。
  static String? extractOpenAiText(Map<String, Object?> resp) {
    final choices = resp['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final message = (choices.first as Map)['message'];
    if (message is! Map) return null;
    final content = message['content'];
    if (content is String) return content;
    if (content is List) {
      final sb = StringBuffer();
      for (final block in content) {
        if (block is Map &&
            block['type'] == 'text' &&
            block['text'] is String) {
          sb.write(block['text'] as String);
        }
      }
      final s = sb.toString();
      return s.isEmpty ? null : s;
    }
    return null;
  }

  /// Anthropic 响应 → 文本块拼接。
  static String? extractAnthropicText(Map<String, Object?> resp) {
    final content = resp['content'];
    if (content is! List) return null;
    final sb = StringBuffer();
    for (final block in content) {
      if (block is Map && block['type'] == 'text' && block['text'] is String) {
        sb.write(block['text'] as String);
      }
    }
    final s = sb.toString();
    return s.isEmpty ? null : s;
  }
}
