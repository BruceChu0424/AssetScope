import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/ai/ai_chat.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// AI 财务助手对话页（/ai）。
///
/// 多轮对话；「账本概况」开关（默认开）把净资产/本月收支等汇总
/// 数字注入 system 提示，让回答贴合真实财务状况——账本与 AI Key
/// 都是用户本人的，只发送汇总，不含逐笔明细。
/// 快捷指令只在空对话时出现（首次见面的一点引导，不常驻打扰）。
class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _ChatMsg {
  _ChatMsg(this.role, this.text);

  final String role; // user / assistant
  String text;
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMsg> _msgs = [];
  bool _withLedger = true;
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _busy) return;
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    if (await s.assistant.config() == null) {
      if (!mounted) return;
      showTopNotice(context, '先在 设置 → AI 服务 绑定你自己的 AI Key',
          tone: TopNoticeTone.info);
      return;
    }
    setState(() {
      _input.clear();
      _msgs.add(_ChatMsg('user', text));
      _busy = true;
    });
    _scrollToEnd();
    try {
      final history = [
        for (final m in _msgs)
          m.role == 'user' ? AiMessage.user(m.text) : AiMessage.assistant(m.text),
      ];
      final reply = await s.assistant.reply(
        history: history,
        withLedger: _withLedger,
      );
      if (!mounted) return;
      setState(() => _msgs.add(_ChatMsg('assistant', reply.trim())));
    } catch (e) {
      if (!mounted) return;
      setState(() {});
      showTopNotice(context, 'AI 助手：$e', tone: TopNoticeTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'AI 助手',
      maxWidth: 860,
      actions: [
        _LedgerContextToggle(
          value: _withLedger,
          onChanged: (v) => setState(() => _withLedger = v),
        ),
        const SizedBox(width: 4),
      ],
      child: Column(
        children: [
          Expanded(
            child: _msgs.isEmpty
                ? _EmptyChat(onPick: (q) => _send(q))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _msgs.length + (_busy ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _msgs.length) return const _TypingBubble();
                      final m = _msgs[i];
                      return _Bubble(msg: m);
                    },
                  ),
          ),
          _InputBar(
            controller: _input,
            busy: _busy,
            onSend: () => _send(),
          ),
        ],
      ),
    );
  }
}

/// 标题带上的「账本概况」开关：激活金色（AI 正带着账本上下文回答）。
class _LedgerContextToggle extends StatelessWidget {
  const _LedgerContextToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brass = AppColors.brassOf(theme.brightness);
    return Tooltip(
      message: value
          ? '已附带账本概况：净资产、本月收支等汇总数字会发给 AI（不含逐笔明细）'
          : '未附带账本数据：AI 只作通用回答',
      child: IconButton(
        isSelected: value,
        selectedIcon: Icon(Icons.auto_awesome, size: 20, color: brass),
        icon: Icon(
          Icons.auto_awesome_outlined,
          size: 20,
          color: theme.hintColor,
        ),
        onPressed: () => onChanged(!value),
      ),
    );
  }
}

/// 空对话引导 + 快捷指令（chips 阶梯入场 40ms，仅首次见面出现）。
class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 30,
              color: AppColors.brassOf(theme.brightness),
            ),
            const SizedBox(height: 10),
            Text(
              '问点什么，或从下面开始',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < _kQuickPrompts.length; i++)
                  reduce
                      ? ActionChip(
                          label: Text(_kQuickPrompts[i]),
                          onPressed: () => onPick(_kQuickPrompts[i]),
                        )
                      : _StaggerIn(
                          delay: Duration(milliseconds: 60 + i * 40),
                          child: ActionChip(
                            label: Text(_kQuickPrompts[i]),
                            onPressed: () => onPick(_kQuickPrompts[i]),
                          ),
                        ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _kQuickPrompts = [
  '我的钱都花哪儿了？',
  '净资产最近走势如何？',
  '这个月怎么省下一笔？',
  '现在适合提前还贷吗？',
];

/// 单件延迟入场（opacity 0→1 + 6px 上浮，220ms easeOut）。
class _StaggerIn extends StatefulWidget {
  const _StaggerIn({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final CurvedAnimation _anim = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 6 / 40),
          end: Offset.zero,
        ).animate(_anim),
        child: widget.child,
      ),
    );
  }
}

/// 消息气泡：用户右（主色填充白字）、AI 左（surface 容器 + 香槟金
/// 细边，带 ✦ 角标）。入场 180ms 淡入上浮（新消息出现的内容桥接）。
class _Bubble extends StatefulWidget {
  const _Bubble({required this.msg});

  final _ChatMsg msg;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  @override
  void initState() {
    super.initState();
    if (!MediaQuery.disableAnimationsOf(context)) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.msg.role == 'user';
    final anim = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, user ? 6 / 40 : -6 / 40),
          end: Offset.zero,
        ).animate(anim),
        child: Align(
          alignment: user ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: BoxDecoration(
              color: user
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.55),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(user ? 14 : 4),
                bottomRight: Radius.circular(user ? 4 : 14),
              ),
              border: user
                  ? null
                  : Border.all(
                      color: AppColors.brassOf(theme.brightness).withValues(
                        alpha: 0.45,
                      ),
                      width: 0.8,
                    ),
            ),
            child: SelectionArea(
              child: Text(
                widget.msg.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: user ? Colors.white : null,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// AI 思考中：三点呼吸脉动（1.1s，FLUTTER_TEST 下静态帧）。
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (!MediaQuery.disableAnimationsOf(context)) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brass = AppColors.brassOf(theme.brightness);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.55,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: brass.withValues(alpha: 0.45), width: 0.8),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: brass.withValues(
                        alpha: 0.3 + 0.7 * _pulse(_c.value, i),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 第 i 点在周期内的相位错开 1/3。
  double _pulse(double t, int i) {
    final phase = (t + i / 3) % 1.0;
    return phase < 0.5 ? phase * 2 : (1 - phase) * 2;
  }
}

/// 输入区：输入框 + 发送钮（忙碌时钮内小粒子轨道，不挡输入继续打字）。
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.busy,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 0.6),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ParticleTextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: '问你的账房先生…（Enter 发送）',
              ),
            ),
          ),
          const SizedBox(width: 10),
          ParticleFilledButton.icon(
            onPressed: busy ? null : onSend,
            icon: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: Center(child: OrbitSpinner(size: 14)),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: const Text('发送'),
          ),
        ],
      ),
    );
  }
}
