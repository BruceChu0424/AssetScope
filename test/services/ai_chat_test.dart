import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/services/ai/ai_chat.dart';

/// AI 客户端：各厂商请求体/请求头构造与响应文本提取（纯函数，无网络）。
void main() {
  group('预设', () {
    test('国内主流预设齐全且带联网搜索能力标注', () {
      final ids = AiProviderPresets.all.map((p) => p.id).toSet();
      expect(ids, containsAll(
          ['glm', 'glmCoding', 'moonshot', 'qwen', 'openai', 'anthropic']));
      expect(
          AiProviderPresets.byCode('glm')!.supportsWebSearch, isTrue);
      // 智谱默认模型须为现行模型（4.x flash 系列已下线）。
      expect(AiProviderPresets.byCode('glm')!.defaultModel, 'glm-5.3-flash');
      // DeepSeek API 无服务端联网搜索：明确标注不可用于行情
      final ds = AiProviderPresets.all.firstWhere((p) => p.id.contains('deepseek'));
      expect(ds.supportsWebSearch, isFalse);
    });

    test('按 id 查找，未知道返回 null', () {
      expect(AiProviderPresets.byCode('nope'), isNull);
    });
  });

  group('OpenAI 兼容请求体', () {
    test('GLM：web_search 工具开启', () {
      final cfg = AiConfig(
          presetId: 'glm',
          baseUrl: AiProviderPresets.byCode('glm')!.defaultBaseUrl,
          apiKey: 'k',
          model: 'glm-4-flash',
          enableWebSearch: true);
      final (uri, headers, body) = AiChat.buildOpenAiRequest(cfg, 'S', 'U');
      expect(uri.toString(),
          'https://open.bigmodel.cn/api/paas/v4/chat/completions');
      expect(headers['Authorization'], 'Bearer k');
      final b = body;
      expect(b['model'], 'glm-4-flash');
      expect((b['tools'] as List).first,
          containsPair('type', 'web_search'));
      expect((b['messages'] as List).length, 2);
    });

    test('GLM Coding Plan：套餐专用端点 + 不注入联网工具', () {
      final preset = AiProviderPresets.byCode('glmCoding')!;
      expect(preset.defaultBaseUrl,
          'https://open.bigmodel.cn/api/coding/paas/v4');
      // 存量配置可能残留 enableWebSearch=true：套餐端点也绝不注入工具。
      final cfg = AiConfig(
          presetId: 'glmCoding',
          baseUrl: preset.defaultBaseUrl,
          apiKey: 'k',
          model: 'glm-5.3-flash',
          enableWebSearch: true);
      final (uri, _, body) = AiChat.buildOpenAiRequest(cfg, 'S', 'U');
      expect(uri.toString(),
          'https://open.bigmodel.cn/api/coding/paas/v4/chat/completions');
      expect(body['tools'], isNull);
    });

    test('Kimi：builtin_function \$web_search', () {
      final cfg = AiConfig(
          presetId: 'moonshot',
          baseUrl: AiProviderPresets.byCode('moonshot')!.defaultBaseUrl,
          apiKey: 'k',
          model: 'kimi-latest',
          enableWebSearch: true);
      final (_, _, body) = AiChat.buildOpenAiRequest(cfg, 'S', 'U');
      final tool = body['tools'] as List;
      expect((tool.first as Map)['type'], 'builtin_function');
      expect(
          ((tool.first as Map)['function'] as Map)['name'], r'$web_search');
    });

    test('通义千问：enable_search 参数', () {
      final cfg = AiConfig(
          presetId: 'qwen',
          baseUrl: AiProviderPresets.byCode('qwen')!.defaultBaseUrl,
          apiKey: 'k',
          model: 'qwen-plus',
          enableWebSearch: true);
      final (_, _, body) = AiChat.buildOpenAiRequest(cfg, 'S', 'U');
      final b = body;
      expect(b['enable_search'], isTrue);
      expect(b['tools'], isNull); // qwen 走 enable_search 而非 tools
    });

    test('关闭联网时不带搜索工具', () {
      final cfg = AiConfig(
          presetId: 'glm',
          baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
          apiKey: 'k',
          model: 'glm-4-flash',
          enableWebSearch: false);
      final (_, _, body) = AiChat.buildOpenAiRequest(cfg, 'S', 'U');
      expect(body['tools'], isNull);
    });
  });

  group('Anthropic 请求', () {
    test('system 独立、web_search 工具、鉴权头', () {
      final cfg = AiConfig(
          presetId: 'anthropic',
          baseUrl: 'https://api.anthropic.com',
          apiKey: 'k',
          model: 'claude-sonnet-4-5',
          enableWebSearch: true);
      final (uri, headers, body) = AiChat.buildAnthropicRequest(cfg, 'SYS', 'U');
      expect(uri.toString(), 'https://api.anthropic.com/v1/messages');
      expect(headers['x-api-key'], 'k');
      expect(headers['anthropic-version'], isNotNull);
      final b = body;
      expect(b['system'], 'SYS');
      expect((b['messages'] as List).length, 1);
      final tool = (b['tools'] as List).first as Map;
      expect(tool['type'], 'web_search_20250305');
    });
  });

  group('响应文本提取', () {
    test('OpenAI 兼容：字符串 content', () {
      final resp = jsonDecode(
          '{"choices":[{"message":{"role":"assistant","content":"OK"}}]}')
          as Map<String, Object?>;
      expect(AiChat.extractOpenAiText(resp), 'OK');
    });

    test('OpenAI 兼容：分段 content 取文本块', () {
      final resp = jsonDecode(
          '{"choices":[{"message":{"content":[{"type":"text","text":"A"},{"type":"other"}]}}]}')
          as Map<String, Object?>;
      expect(AiChat.extractOpenAiText(resp), 'A');
    });

    test('Anthropic：content 块拼接', () {
      final resp = jsonDecode(
          '{"content":[{"type":"text","text":"A"},{"type":"text","text":"B"},{"type":"citation","citation":{}}]}')
          as Map<String, Object?>;
      expect(AiChat.extractAnthropicText(resp), 'AB');
    });

    test('缺失结构返回 null', () {
      expect(AiChat.extractOpenAiText(<String, Object?>{}), isNull);
      expect(AiChat.extractAnthropicText(<String, Object?>{}), isNull);
    });
  });

  group('配置序列化', () {
    test('AiConfig JSON 往返', () {
      final cfg = AiConfig(
          presetId: 'glm',
          baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
          apiKey: 'secret',
          model: 'glm-4-flash',
          enableWebSearch: true);
      final back = AiConfig.fromJson(jsonDecode(jsonEncode(cfg.toJson()))
          as Map<String, Object?>)!;
      expect(back.presetId, 'glm');
      expect(back.apiKey, 'secret');
      expect(back.enableWebSearch, isTrue);
    });
  });

  group('多轮对话', () {
    final cfg = AiConfig(
        presetId: 'glm',
        baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
        apiKey: 'k',
        model: 'glm-4.7-flash',
        enableWebSearch: true);

    test('OpenAI 兼容：消息按序展开并带联网工具', () {
      final (uri, headers, body) = AiChat.buildOpenAiMessagesRequest(
        cfg,
        '你是账房先生',
        [
          AiMessage.user('我的钱花哪儿了'),
          AiMessage.assistant('上月餐饮占 40%'),
          AiMessage.user('那怎么省'),
        ],
      );
      expect(uri.toString(),
          'https://open.bigmodel.cn/api/paas/v4/chat/completions');
      final msgs = (body['messages'] as List).cast<Map<String, Object?>>();
      expect(msgs.length, 4);
      expect(msgs[0]['role'], 'system');
      expect(msgs[1]['content'], '我的钱花哪儿了');
      expect(msgs[2]['role'], 'assistant');
      expect(msgs[3]['content'], '那怎么省');
      final tools = (body['tools'] as List).cast<Map<String, Object?>>();
      expect(tools.single['type'], 'web_search');
      expect(headers['Authorization'], 'Bearer k');
    });

    test('Anthropic：system 独立字段、多轮消息体', () {
      final (uri, _, body) = AiChat.buildAnthropicMessagesRequest(
        cfg,
        'SYS',
        [AiMessage.user('u1'), AiMessage.assistant('a1'), AiMessage.user('u2')],
      );
      expect(uri.toString(), 'https://open.bigmodel.cn/api/paas/v4/v1/messages');
      expect(body['system'], 'SYS');
      final msgs = (body['messages'] as List).cast<Map<String, Object?>>();
      expect(msgs.map((m) => m['role']).toList(), ['user', 'assistant', 'user']);
    });

    test('AiMessage 构造器与映射', () {
      expect(AiMessage.user('x').role, 'user');
      expect(AiMessage.assistant('y').toMap(), {'role': 'assistant', 'content': 'y'});
    });
  });
}
