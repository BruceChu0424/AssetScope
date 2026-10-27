import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/ai/ai_chat.dart';
import '../theme/app_theme.dart';

/// AI 服务配置弹层：预设（智谱/Kimi/千问/DeepSeek/OpenAI/Claude/自定义）
/// + Base URL + 模型 + API Key + 联网搜索开关 + 测试连接。
Future<void> showAiConfigSheet(BuildContext context, VaultUnlocked s) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _AiConfigDialog(),
  );
}

class _AiConfigDialog extends ConsumerStatefulWidget {
  const _AiConfigDialog();

  @override
  ConsumerState<_AiConfigDialog> createState() => _AiConfigDialogState();
}

class _AiConfigDialogState extends ConsumerState<_AiConfigDialog> {
  String _presetId = 'glm';
  late final TextEditingController _baseUrl;
  late final TextEditingController _model;
  late final TextEditingController _apiKey;
  bool _webSearch = true;
  bool _obscure = true;
  bool _testing = false;
  String? _testResult;
  bool _loaded = false;

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final cfg = await s.quoteFetch.config();
    if (cfg != null) {
      _presetId = cfg.presetId;
      _baseUrl.text = cfg.baseUrl;
      _model.text = cfg.model;
      _apiKey.text = cfg.apiKey;
      _webSearch = cfg.enableWebSearch;
    } else {
      _applyPreset('glm');
    }
  }

  void _applyPreset(String id) {
    final preset = AiProviderPresets.byCode(id)!;
    _baseUrl.text = preset.defaultBaseUrl;
    _model.text = preset.defaultModel;
    _webSearch = preset.supportsWebSearch;
  }

  AiConfig _build() => AiConfig(
        presetId: _presetId,
        baseUrl: _baseUrl.text.trim(),
        apiKey: _apiKey.text.trim(),
        model: _model.text.trim(),
        enableWebSearch: _webSearch,
      );

  Future<void> _test() async {
    final cfg = _build();
    if (cfg.apiKey.isEmpty || cfg.baseUrl.isEmpty) {
      setState(() => _testResult = '请先填写 Base URL 与 API Key');
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final reply = await const AiChat()
          .complete(cfg, '你是连通性测试助手。', '只回复两个字母：OK');
      setState(() => _testResult = '连接成功：${reply.trim().substring(0, reply.trim().length.clamp(0, 40))}');
    } catch (e) {
      setState(() => _testResult = '失败：$e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    await s.quoteFetch.saveConfig(_build());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _load();
    final preset = AiProviderPresets.byCode(_presetId)!;
    return AlertDialog(
      title: const Text('AI 服务配置'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'API Key 加密存储在本地账本库中，仅用于行情/汇率联网抓取；'
                '抓取时只发送查询名称与币种对，绝不发送余额与金额。',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor, height: 1.5),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _presetId,
                decoration: const InputDecoration(labelText: '服务商'),
                items: [
                  for (final p in AiProviderPresets.all)
                    DropdownMenuItem(value: p.id, child: Text(p.label)),
                ],
                onChanged: (v) => setState(() {
                  _presetId = v!;
                  _applyPreset(v);
                }),
              ),
              if (preset.note != null) ...[
                const SizedBox(height: 6),
                Text(preset.note!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: preset.supportsWebSearch
                            ? theme.hintColor
                            : AppColors.brass)),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _baseUrl,
                decoration: const InputDecoration(
                    labelText: 'Base URL（https://…，不含 /chat/completions）'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _model,
                decoration:
                    const InputDecoration(labelText: '模型（须支持联网搜索）'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _apiKey,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('联网搜索'),
                subtitle: Text(preset.supportsWebSearch
                    ? '行情抓取必须开启（否则价格可能来自模型记忆）'
                    : '该服务商 API 不支持联网，抓取结果可能是过时数据'),
                value: _webSearch,
                onChanged: preset.supportsWebSearch
                    ? (v) => setState(() => _webSearch = v)
                    : null,
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 4),
                Text(_testResult!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: _testResult!.startsWith('失败')
                            ? AppColors.negative
                            : AppColors.positive)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _testing ? null : _test,
          child: _testing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('测试连接'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}
