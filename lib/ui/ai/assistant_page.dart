import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/runtime_l10n.dart';
import '../../services/ai/ai_chat.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// AI 财务助手对话页（/ai）· 大屏分屏工作台。
///
/// 大屏（≥900）：左会话栏（宽 300，**分隔栏可左右拖拽** 240–460，双击
/// 复位）+ 右对话区（气泡列收束 760 居中）。小屏：单列对话，会话从
/// 页头按钮以侧滑面板呼出。
///
/// 会话持久化：全部会话（上限 30 条、每条 200 消息）以 JSON 存本地
/// 设置表（'aiChatSessions'），重开应用不丢。
///
/// 「账本概况」开关（默认开）把净资产/本月收支等汇总数字注入 system
/// 提示——只发送汇总，不含逐笔明细。快捷指令只在空会话时出现。
class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _ChatMsg {
  _ChatMsg(this.role, this.text);
  final String role; // user / assistant
  final String text;

  Map<String, String> toJson() => {'role': role, 'text': text};
  factory _ChatMsg.fromJson(Map<String, Object?> j) =>
      _ChatMsg(j['role'] as String? ?? 'assistant', j['text'] as String? ?? '');
}

class _ChatSession {
  _ChatSession({required this.id, required this.updatedAt, List<_ChatMsg>? msgs})
      : messages = msgs ?? [];

  final String id;
  final DateTime updatedAt;
  final List<_ChatMsg> messages;

  String get title {
    for (final m in messages) {
      if (m.role == 'user' && m.text.trim().isNotEmpty) {
        return m.text.trim().replaceAll('\n', ' ');
      }
    }
    return rt('新对话');
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'updatedAt': updatedAt.toIso8601String(),
    'messages': [for (final m in messages.take(200)) m.toJson()],
  };

  factory _ChatSession.fromJson(Map<String, Object?> j) => _ChatSession(
    id: j['id'] as String? ?? '',
    updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ??
        DateTime.now(),
    msgs: [
      for (final m in (j['messages'] as List? ?? <Object?>[]))
        _ChatMsg.fromJson((m as Map).cast<String, Object?>()),
    ],
  );
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  /// 会话列表（新→旧）与当前会话 id。
  List<_ChatSession> _sessions = [];
  String _currentId = '';
  bool _loaded = false;
  bool _busy = false;
  bool _withLedger = true;
  Timer? _persistDebounce;

  // ── 分屏（大屏）：左栏宽度 + 拖拽 ──
  double _sideW = 300;
  bool _dragging = false;
  double _dragStartW = 0;

  static const _sideMin = 240.0, _sideMax = 460.0, _sideDefault = 300.0;

  _ChatSession get _current => _sessions
      .firstWhere((s) => s.id == _currentId, orElse: _newSession);

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── 持久化 ─────────────────────────────────────────────────────────

  Future<void> _loadSessions() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) {
      setState(() => _loaded = true);
      return;
    }
    try {
      final raw = await s.meta.settingString('aiChatSessions');
      final list = <_ChatSession>[];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        for (final e in decoded.take(30)) {
          list.add(_ChatSession.fromJson((e as Map).cast<String, Object?>()));
        }
      }
      if (!mounted) return;
      setState(() {
        _sessions = list;
        _currentId = list.isNotEmpty
            ? list.first.id
            : '';
        if (_currentId.isEmpty) _newConversation();
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loaded = true;
        _newConversation();
      });
    }
  }

  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 600), _persist);
  }

  Future<void> _persist() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    try {
      final raw = jsonEncode([
        for (final sess in _sessions.take(30)) sess.toJson(),
      ]);
      await s.meta.setSetting('aiChatSessions', raw);
    } catch (_) {
      // 持久化失败不影响对话（下次动作会再试）。
    }
  }

  // ── 会话管理 ───────────────────────────────────────────────────────

  _ChatSession _newSession() {
    final now = DateTime.now();
    return _ChatSession(
      id: 'chat:${now.microsecondsSinceEpoch.toRadixString(36)}',
      updatedAt: now,
    );
  }

  void _newConversation() {
    final s = _newSession();
    setState(() {
      _sessions = [s, ..._sessions];
      _currentId = s.id;
      _input.clear();
    });
    _schedulePersist();
  }

  void _switchTo(String id) {
    if (id == _currentId) return;
    setState(() {
      _currentId = id;
      _input.clear();
    });
    _scrollToEnd();
  }

  void _deleteSession(String id) {
    setState(() {
      _sessions = _sessions.where((s) => s.id != id).toList();
      if (_currentId == id) {
        if (_sessions.isNotEmpty) {
          _currentId = _sessions.first.id;
        } else {
          _newConversation();
          return;
        }
      }
    });
    _schedulePersist();
  }

  // ── 对话 ───────────────────────────────────────────────────────────

  Future<void> _send([String? preset]) async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _busy) return;
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    if (await s.assistant.config() == null) {
      if (!mounted) return;
      showTopNotice(context, AppLocalizations.of(context).aiBindKeyFirst,
          tone: TopNoticeTone.info);
      return;
    }
    final sess = _current;
    setState(() {
      _input.clear();
      sess.messages.add(_ChatMsg('user', text));
      _busy = true;
    });
    _touch(sess);
    _scrollToEnd();
    try {
      final history = [
        for (final m in sess.messages)
          m.role == 'user' ? AiMessage.user(m.text) : AiMessage.assistant(m.text),
      ];
      final reply = await s.assistant.reply(
        history: history,
        withLedger: _withLedger,
      );
      if (!mounted) return;
      setState(() => sess.messages.add(_ChatMsg('assistant', reply.trim())));
    } catch (e) {
      if (!mounted) return;
      setState(() {});
      showTopNotice(
        context,
        AppLocalizations.of(context).aiAssistantError(e.toString()),
        tone: TopNoticeTone.error,
      );
    } finally {
      _touch(sess);
      _schedulePersist();
      if (mounted) setState(() => _busy = false);
      _scrollToEnd();
    }
  }

  /// 会话活跃：置顶 + 刷新时间。
  void _touch(_ChatSession sess) {
    setState(() {
      _sessions = [
        sess,
        for (final s in _sessions.where((s) => !identical(s, sess))) s,
      ];
    });
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

  // ── 分栏拖拽 ───────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails d) {
    _dragStartW = _sideW;
    setState(() => _dragging = true);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _sideW = (_dragStartW + d.localPosition.dx).clamp(_sideMin, _sideMax);
    });
  }

  // ── 布局 ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= PageMeasure.wide;
    return PageFrame(
      title: t.aiAssistant,
      maxWidth: double.infinity,
      actions: [
        _LedgerContextToggle(
          value: _withLedger,
          onChanged: (v) => setState(() => _withLedger = v),
        ),
        if (!wide) ...[
          const SizedBox(width: 4),
          ActionIcon(
            tooltip: t.aiHistorySessions,
            icon: Icons.forum_outlined,
            onTap: () => _openSessionsSheet(context),
          ),
        ],
        const SizedBox(width: 4),
      ],
      child: !_loaded
          ? const Center(child: OrbitSpinner(size: 32))
          : wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _sideW,
                  child: _SessionsPane(
                    sessions: _sessions,
                    currentId: _currentId,
                    onSelect: _switchTo,
                    onNew: _newConversation,
                    onDelete: _deleteSession,
                  ),
                ),
                _SplitHandle(
                  dragging: _dragging,
                  onDragStart: _onDragStart,
                  onDragUpdate: _onDragUpdate,
                  onDragEnd: (_) => setState(() => _dragging = false),
                  onReset: () => setState(() => _sideW = _sideDefault),
                ),
                Expanded(child: _ChatPane(session: _current, busy: _busy, input: _input, scroll: _scroll, onSend: _send)),
              ],
            )
          : _ChatPane(session: _current, busy: _busy, input: _input, scroll: _scroll, onSend: _send),
    );
  }

  /// 小屏：会话列表走侧滑面板（大屏同样可从 Actions 呼出，仅小屏出现入口）。
  Future<void> _openSessionsSheet(BuildContext context) {
    return showAppSheet<void>(
      context,
      builder: (sheetCtx) => SafeArea(
        child: _SessionsPane(
          sessions: _sessions,
          currentId: _currentId,
          onSelect: (id) {
            _switchTo(id);
            Navigator.pop(sheetCtx);
          },
          onNew: () {
            _newConversation();
            Navigator.pop(sheetCtx);
          },
          onDelete: _deleteSession,
        ),
      ),
    );
  }
}

// ── 会话栏 ─────────────────────────────────────────────────────────

class _SessionsPane extends StatelessWidget {
  const _SessionsPane({
    required this.sessions,
    required this.currentId,
    required this.onSelect,
    required this.onNew,
    required this.onDelete,
  });

  final List<_ChatSession> sessions;
  final String currentId;
  final ValueChanged<String> onSelect;
  final VoidCallback onNew;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
          child: Row(
            children: [
              Text(
                t.aiSessions,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              ActionIcon(tooltip: t.aiNewChat, icon: Icons.add, onTap: onNew),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        Expanded(
          child: sessions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    t.aiNoSessionsHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  itemCount: sessions.length,
                  itemBuilder: (context, i) {
                    final s = sessions[i];
                    return _SessionTile(
                      session: s,
                      selected: s.id == currentId,
                      onTap: () => onSelect(s.id),
                      onDelete: () => onDelete(s.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SessionTile extends StatefulWidget {
  const _SessionTile({
    required this.session,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final _ChatSession session;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.chip),
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.09)
                : (_hover
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.04)
                    : Colors.transparent),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 3,
                height: 24,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: selected
                      ? AppColors.brassOf(brightness)
                      : Colors.transparent,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _relativeTime(widget.session.updatedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (_hover || selected)
                _DeleteButton(onTap: widget.onDelete)
              else
                const SizedBox(width: 30),
            ],
          ),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime t) {
    final now = DateTime.now();
    final d = now.difference(t);
    if (d.inMinutes < 1) return rt('刚刚');
    if (d.inHours < 1) return '${d.inMinutes} ${rt('分钟前')}';
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return '${rt('今天')} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    if (d.inDays == 1) return rt('昨天');
    return '${t.month}-${t.day.toString().padLeft(2, '0')}';
  }
}

class _DeleteButton extends StatefulWidget {
  const _DeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Tooltip(
      message: t.aiDeleteChat,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hover
                  ? AppColors.negativeOf(theme.brightness).withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            child: Icon(
              Icons.close,
              size: 15,
              color: _hover
                  ? AppColors.negativeOf(theme.brightness)
                  : theme.hintColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 分隔栏（可拖拽） ───────────────────────────────────────────────

/// 左右分屏分隔栏：拖拽即时跟手（手势交互不加缓动动画，跟手即反馈），
/// 双击复位 300。悬停/拖拽提亮香槟金。
class _SplitHandle extends StatelessWidget {
  const _SplitHandle({
    required this.dragging,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onReset,
  });

  final bool dragging;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = dragging;
    final tint = dragging
        ? AppColors.brassOf(theme.brightness)
        : theme.dividerColor;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: onDragStart,
        onHorizontalDragUpdate: onDragUpdate,
        onHorizontalDragEnd: onDragEnd,
        onDoubleTap: onReset,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 12,
          color: active ? tint.withValues(alpha: 0.08) : Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 3,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: tint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 对话区 ─────────────────────────────────────────────────────────

class _ChatPane extends StatelessWidget {
  const _ChatPane({
    required this.session,
    required this.busy,
    required this.input,
    required this.scroll,
    required this.onSend,
  });

  final _ChatSession session;
  final bool busy;
  final TextEditingController input;
  final ScrollController scroll;

  /// 发送（参数 = 快捷指令文本；空则读输入框）。
  final Future<void> Function([String? preset]) onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 150),
            child: session.messages.isEmpty
                ? _EmptyChat(
                    key: ValueKey('empty-${session.id}'),
                    onPick: (q) => onSend(q),
                  )
                : ListView.builder(
                    key: ValueKey('msgs-${session.id}'),
                    controller: scroll,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: session.messages.length + (busy ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == session.messages.length) {
                        return const _TypingBubble();
                      }
                      return _Bubble(msg: session.messages[i]);
                    },
                  ),
          ),
        ),
        _InputBar(controller: input, busy: busy, onSend: () => onSend()),
      ],
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
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brass = AppColors.brassOf(theme.brightness);
    return Tooltip(
      message: value
          ? t.aiLedgerContextOn
          : t.aiLedgerContextOff,
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

/// 空对话引导 + 快捷指令（chips 阶梯入场 40ms，仅空会话出现）。
class _EmptyChat extends StatelessWidget {
  const _EmptyChat({super.key, required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final prompts = [
      t.aiPromptSpendWhere,
      t.aiPromptNwTrend,
      t.aiPromptSaveMonth,
      t.aiPromptPrepay,
    ];
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
              t.aiAskSomething,
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
                for (var i = 0; i < prompts.length; i++)
                  reduce
                      ? ActionChip(
                          label: Text(prompts[i]),
                          onPressed: () => onPick(prompts[i]),
                        )
                      : _StaggerIn(
                          delay: Duration(milliseconds: 60 + i * 40),
                          child: ActionChip(
                            label: Text(prompts[i]),
                            onPressed: () => onPick(prompts[i]),
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

/// 输入区：输入框 + 发送钮**同高 52**（单行时严格等高，多行时发送钮
/// 贴底跟随）。忙碌时钮内小粒子轨道，不挡输入继续打字。
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
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        14 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 0.6),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ParticleTextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: t.aiInputHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ParticleFilledButton.icon(
                  onPressed: busy ? null : onSend,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(96, 52),
                    maximumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                  ),
                  icon: busy
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: Center(child: OrbitSpinner(size: 15)),
                        )
                      : const Icon(Icons.send_outlined, size: 18),
                  label: Text(t.aiSend),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
