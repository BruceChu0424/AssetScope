import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../security/key_manager.dart';
import '../dashboard/dashboard_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/particle_orbit.dart';

/// 锁屏：首次创建金库（设定主口令 → 展示恢复码 → 确认后进入）/ 日常解锁。
///
/// 表单形态：胶囊输入框 + 框右圆形图标按钮（回车等效按钮）。错误不再
/// 内联展示——输入框红框加粗 + 顶部通知条（[showTopNotice]）+ 横摇，
/// 圆钮同步转朱砂并自摇（迟 70ms 起摇，与整表单横摇成复合晃动）。
///
/// 加载编排（两段式）：口令核验（慢哈希）期间**只有钮内粒子轨道在转**，
/// 不上全屏舞台；核验通过才立即上粒子舞台。解锁/创建确认的舞台任务里
/// 顺带**预热首页**（等仪表盘数据就绪再短暂安定），舞台盖着首页加载；
/// 散场用 900ms 渐隐 + [BusyReveal] 揭幕钟同步首页入场——烟雾散尽时
/// 地球与卡片恰好浮现，不再出现「进了首页还要再转一次圈」的二次加载。
class LockPage extends ConsumerStatefulWidget {
  const LockPage({super.key});

  @override
  ConsumerState<LockPage> createState() => _LockPageState();
}

class _LockPageState extends ConsumerState<LockPage> {
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  final _pass2Focus = FocusNode();
  final _actionKey = GlobalKey();
  final _confirmKey = GlobalKey(); // 恢复码「我已保存」钮：舞台喷发原点
  bool _busy = false;
  String? _error; // 仅驱动红框/辉光错误态；文字走顶部通知
  int _shake = 0; // 递增触发表单横摇

  /// 解锁/创建进场散场参数（最短可行序列，2026-10 用户指令：总时长压到
  /// 下限，但粒子 logo 必须完整成形——成形保底由 busy 舞台承担：迸散
  /// 不早于汇聚完成 1.79s）：迸散后短驻 120ms，整层 640ms 渐隐——幕布
  /// 渐薄的同时首页入场（揭幕钟同步），烟雾散尽恰好浮现到位。
  static const _revealFade = Duration(milliseconds: 640);
  static const _revealHold = Duration(milliseconds: 120);

  /// 预热首页：会话发布后 router 已换树、首页在粒子幕布下开始加载——
  /// 等仪表盘数据就绪再短暂安定（大陆点/标记首批上屏），舞台才开始
  /// 成功散场。失败不阻塞解锁：首页自会展示错误态。
  Future<void> _primeHome() async {
    try {
      // listenManual 为 autoDispose 的仪表盘保活，桥接「发布会话」到
      // 「首页挂上监听」之间的空窗（首页挂上后由其接管保活）。
      final sub = ref.listenManual(dashboardProvider, (_, _) {});
      try {
        await ref.read(dashboardProvider.future);
      } finally {
        sub.close();
      }
    } catch (_) {
      /* 首页自会展示错误 */
    }
    // 短驻一拍即放行散场（首帧已上屏即可；拉长只会白等）。
    await Future<void>.delayed(const Duration(milliseconds: 140));
  }

  @override
  void initState() {
    super.initState();
    _pass.addListener(_clearError);
    _pass2.addListener(_clearError);
  }

  @override
  void dispose() {
    _pass.dispose();
    _pass2.dispose();
    _pass2Focus.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _fail(String message) {
    setState(() {
      _error = message;
      _shake++;
    });
    showTopNotice(context, message);
  }

  /// 圆形按钮中心的全局坐标：粒子舞台的喷发原点。
  Offset? _actionCenter() {
    final box = _actionKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  /// 恢复码「我已保存」按钮中心：确认进场的喷发原点。
  Offset? _confirmCenter() {
    final box = _confirmKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  Future<void> _create() async {
    if (_busy) return;
    final t = AppLocalizations.of(context);
    final err = _validateNewPass();
    if (err != null) return _fail(err);
    setState(() => _busy = true);
    try {
      // 只建密钥不发布会话——恢复码先示人（金库此刻仍是未初始化态，
      // 本页不换树），确认保存后再 finishCreate 进首页。慢哈希（两次：
      // 口令 + 恢复码）期间只有钮内粒子在转，不上全屏舞台；成功直接
      // 呈现恢复码页（[_EnterFade] 做桥）。
      final code = await ref.read(vaultProvider.notifier).createVault(
        _pass.text,
      );
      if (!mounted) return;
      setState(() {
        _recoveryCode = code;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _fail(t.lockCreateFailed(e.toString()));
    }
  }

  /// 恢复码确认：打开账本进入首页。与解锁同一进场编排——粒子幕布盖住
  /// 首页预热，900ms 渐隐揭幕。
  Future<void> _finishCreate() async {
    if (_busy) return;
    final t = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await runBusy(
        context,
        message: t.lockOpeningLedger,
        successMessage: t.lockWelcome,
        showError: false,
        hold: _revealHold,
        exitFade: _revealFade,
        syncReveal: true,
        origin: _confirmCenter(),
        task: () async {
          await ref.read(vaultProvider.notifier).finishCreate();
          await _primeHome();
        },
      );
      // 成功后路由自动进入首页
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _fail(t.lockOpenFailed(e.toString()));
    }
  }

  String? _validateNewPass() {
    final t = AppLocalizations.of(context);
    final p = _pass.text;
    if (p.length < 8) return t.lockPassphraseRule;
    if (p != _pass2.text) return t.lockPassMismatch;
    final classes = [
      RegExp(r'[a-z]').hasMatch(p),
      RegExp(r'[A-Z]').hasMatch(p) || RegExp(r'[^\w]').hasMatch(p),
      RegExp(r'\d').hasMatch(p),
    ].where((v) => v).length;
    if (p.length < 12 && classes < 2) return t.lockWeakPassphrase;
    return null;
  }

  Future<void> _unlock() async {
    if (_busy) return;
    final t = AppLocalizations.of(context);
    if (_pass.text.isEmpty) return _fail(t.lockEnterPrompt);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // 第一步·核验（慢哈希）：不上全屏舞台，只有钮内粒子在转——
      // 错口令即时交还红框 + 顶部通知 + 横摇（钮也转朱砂并自摇）。
      await ref.read(vaultProvider.notifier).unlockCheck(_pass.text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      return _fail(
        e is WrongPassphraseException
            ? t.lockWrongCredential
            : t.lockUnlockFailed(e.toString()),
      );
    }
    try {
      // 第二步·验证通过，立即上全屏粒子舞台：盖住开库与首页预热，
      // 散场用 900ms 渐隐 + [BusyReveal] 揭幕钟同步首页入场。
      if (!mounted) return;
      await runBusy(
        context,
        message: t.lockUnlocking,
        successMessage: t.lockUnlocked,
        showError: false,
        hold: _revealHold,
        exitFade: _revealFade,
        syncReveal: true,
        origin: _actionCenter(),
        task: () async {
          await ref.read(vaultProvider.notifier).finalizeUnlock();
          await _primeHome();
        },
      );
      // 成功后路由自动跳转
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _fail(t.lockUnlockFailed(e.toString()));
    }
  }

  String? _recoveryCode;

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(vaultProvider);
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    if (_recoveryCode != null) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _EnterFade(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.key, size: 40, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(t.lockSaveRecoveryTitle, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      t.lockRecoveryIntro,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        _recoveryCode!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          letterSpacing: 1.2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ParticleFilledButton(
                      key: _confirmKey,
                      onPressed: _busy ? null : _finishCreate,
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : Text(t.lockRecoverySaved),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final setup = vault is VaultUninitialized;
    final bad = _error != null;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _FormShake(
              trigger: _shake,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: ParticleBrandMark(size: 176)),
                  if (!setup) ...[
                    const SizedBox(height: 24),
                    Text(
                      t.appTitle,
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (setup) ...[
                    ParticleTextField(
                      controller: _pass,
                      obscureText: true,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _pass2Focus.requestFocus(),
                      decoration: _capsuleDecoration(
                        theme,
                        t.lockCreateHint,
                        tooltip: t.lockPassphraseTooltip,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ErrorHalo(
                      bad: bad,
                      child: ParticleTextField(
                        controller: _pass2,
                        focusNode: _pass2Focus,
                        obscureText: true,
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => _create(),
                        decoration: _capsuleDecoration(
                          theme,
                          t.lockRepeatPassphrase,
                          action: _RoundAction(
                            buttonKey: _actionKey,
                            icon: Icons.check_rounded,
                            busy: _busy,
                            error: bad,
                            shakeTrigger: _shake,
                            size: 46,
                            onTap: _create,
                          ),
                        ),
                      ),
                    ),
                  ] else
                    _ErrorHalo(
                      bad: bad,
                      child: ParticleTextField(
                        controller: _pass,
                        obscureText: true,
                        autofocus: true,
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => _unlock(),
                        decoration: _capsuleDecoration(
                          theme,
                          t.lockUnlockHint,
                          action: _RoundAction(
                        buttonKey: _actionKey,
                        icon: Icons.arrow_forward_rounded,
                        busy: _busy,
                        error: bad,
                        shakeTrigger: _shake,
                        size: 46,
                        onTap: _unlock,
                      ),
                        ),
                      ),
                    ),
                  if (!setup)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ParticleEdge(
                        band: 7,
                        extendBelow: 2,
                        child: TextButton(
                          onPressed: () => showTopNotice(
                            context,
                            t.lockRecoveryNotice,
                            tone: TopNoticeTone.info,
                          ),
                          child: Text(t.lockForgotPassphrase),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 胶囊输入框装饰：错误态红框加粗（2.2/2.6px）+ 淡红底。
  /// [tooltip] 提供时在框尾放 info 圆标（悬停/长按弹提示）；
  /// [action] 提供时圆动作钮**嵌在框内右端**（下一步/解锁，靠右留 6px）。
  InputDecoration _capsuleDecoration(
    ThemeData theme,
    String hint, {
    String? tooltip,
    Widget? action,
  }) {
    final cs = theme.colorScheme;
    final bad = _error != null;
    final negative = AppColors.negativeOf(theme.brightness);
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: bad
          ? negative.withValues(alpha: 0.06)
          : cs.surfaceContainerLow,
      // 上下 19 + 行高 ≈20 ⇒ 内高 ≈58；46px 圆钮上下各 ≈6px，与框右
      // 留白 6px 三边等距（用户要求：上=下=右）。
      contentPadding: const EdgeInsets.only(left: 22, top: 19, bottom: 19),
      suffixIcon: action != null
          ? Padding(
              // 右对齐 + 垂直居中：钮保持正圆、贴右端，上下离边恒等。
              padding: const EdgeInsets.only(right: 6),
              child: Align(alignment: Alignment.centerRight, child: action),
            )
          : (tooltip == null
                ? null
                : Tooltip(
                    message: tooltip,
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.hintColor,
                    ),
                  )),
      suffixIconConstraints: action != null
          // Align(centerRight) 贪宽：不给 maxWidth 会占满一切可用宽度，
          // 把可编辑区挤成 0 宽（圆点/光标/悬停 I-beam 光标全部消失，
          // 点击框内也命中不到字段——v0.21 存量 bug）。钮 46 + 右留白 6。
          ? const BoxConstraints(minWidth: 52, maxWidth: 52)
          : const BoxConstraints(minWidth: 36, minHeight: 36),
      enabledBorder: _capsuleSide(
        bad ? negative : cs.outline.withValues(alpha: 0.45),
        bad ? 2.2 : 1.1,
      ),
      focusedBorder: _capsuleSide(bad ? negative : cs.primary, bad ? 2.6 : 1.8),
    );
  }

  static OutlineInputBorder _capsuleSide(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// 错误辉光：红框时框外加朱砂柔光，随错误态即时开关（动效由横摇承担）。
class _ErrorHalo extends StatelessWidget {
  const _ErrorHalo({required this.bad, required this.child});

  final bool bad;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!bad) return child;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.negativeOf(
              Theme.of(context).brightness,
            ).withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 圆形动作按钮：嵌在输入胶囊框内右端（默认 46px；尺寸随 [size]），
/// 按压缩放（120ms easeOutCubic）。三态：
/// - 平常：主色圆 + 图标；
/// - [busy]：钮内粒子轨道（[ParticleOrbit]）替代转圈——口令核验的
///   慢哈希期间只有这圈粒子在转，全屏舞台留到核验成功之后；
/// - [error]：整钮转朱砂（错误消除随输入自动回蓝）。
/// [shakeTrigger] 递增时钮自身横摇一次（迟 70ms 起摇，叠在整表单
/// 横摇之上形成复合晃动）。
/// [buttonKey] 供粒子舞台取喷发原点。
class _RoundAction extends StatefulWidget {
  const _RoundAction({
    required this.buttonKey,
    required this.icon,
    required this.onTap,
    this.busy = false,
    this.error = false,
    this.shakeTrigger = 0,
    this.size = 46,
  });

  final GlobalKey buttonKey;
  final IconData icon;
  final VoidCallback onTap;
  final bool busy;
  final bool error;
  final int shakeTrigger;
  final double size;

  @override
  State<_RoundAction> createState() => _RoundActionState();
}

class _RoundActionState extends State<_RoundAction>
    with SingleTickerProviderStateMixin {
  bool _down = false;
  bool _reduce = false;
  Timer? _shakeArm;
  int _lastShake = 0;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void didUpdateWidget(_RoundAction old) {
    super.didUpdateWidget(old);
    if (widget.shakeTrigger != _lastShake) {
      _lastShake = widget.shakeTrigger;
      _shakeArm?.cancel();
      if (widget.shakeTrigger > 0 && !_reduce) {
        // 迟 70ms 起摇：整表单横摇先动，钮自身再补一记——层次而非同频。
        _shakeArm = Timer(const Duration(milliseconds: 70), () {
          if (mounted) _shake.forward(from: 0);
        });
      }
    }
  }

  @override
  void dispose() {
    _shakeArm?.cancel();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final negative = AppColors.negativeOf(theme.brightness);
    final s = widget.size;
    final bad = widget.error && !widget.busy;
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedBuilder(
          animation: _shake,
          builder: (context, child) => Transform.translate(
            offset: Offset(_shakeTween.evaluate(_shake), 0),
            child: child,
          ),
          child: ParticleEdge(
            band: 10,
            extendBelow: 2,
            baseColor: bad ? negative : null,
            child: Material(
              key: widget.buttonKey,
              color: widget.busy
                  ? cs.primary.withValues(alpha: 0.55)
                  : bad
                  ? negative
                  : cs.primary,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              elevation: widget.busy ? 0 : 2,
              child: InkWell(
                onTap: widget.busy ? null : widget.onTap,
                child: SizedBox(
                  width: s,
                  height: s,
                  child: widget.busy
                      ? Center(child: ParticleOrbit(size: s * 0.6))
                      : Icon(widget.icon, size: s * 0.52, color: cs.onPrimary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 0 → -3.2 → 3.2 → -2.2 → 2.2 → -1.2 → 1.2 → 0（像素，幅度递减收束）。
  static final _shakeTween = TweenSequence<double>([
    for (final (from, to) in [
      (0.0, -3.2),
      (-3.2, 3.2),
      (3.2, -2.2),
      (-2.2, 2.2),
      (2.2, -1.2),
      (-1.2, 1.2),
      (1.2, 0.0),
    ])
      TweenSequenceItem(tween: Tween(begin: from, end: to), weight: 1),
  ]);
}

/// 表单错误横摇：trigger 每递增一次播放 ±6px 三次往复（320ms）。
/// 「减少动画」时跳过（红框 + 顶部通知已足够表达）。
class _FormShake extends StatefulWidget {
  const _FormShake({required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<_FormShake> createState() => _FormShakeState();
}

class _FormShakeState extends State<_FormShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  int _last = 0;
  bool _reduce = false;

  // 「减少动画」开关缓存自 didChangeDependencies（didUpdateWidget 里
  // 直接读 inherited 依赖不规范）。
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void didUpdateWidget(_FormShake old) {
    super.didUpdateWidget(old);
    if (widget.trigger != _last) {
      _last = widget.trigger;
      if (widget.trigger > 0 && !_reduce) {
        _shake.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 像素级横摇（SlideTransition 的偏移是子元素尺寸百分比，量级不可控）。
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeTween.evaluate(_shake), 0),
        child: child,
      ),
      child: widget.child,
    );
  }

  /// 0 → -6 → 6 → -4 → 4 → 0（像素）。
  static final _shakeTween = TweenSequence<double>([
    for (final (from, to) in [
      (0.0, -6.0),
      (-6.0, 6.0),
      (6.0, -4.0),
      (-4.0, 4.0),
      (4.0, 0.0),
    ])
      TweenSequenceItem(
        tween: Tween(begin: from, end: to),
        weight: 1,
      ),
  ]);
}

/// 恢复码页入场桥：创建慢哈希在钮内粒子转完后表单直接换页，给
/// 240ms 淡入 + 8px 上浮（easeOutCubic）避免硬切。「减少动画」直入。
class _EnterFade extends StatefulWidget {
  const _EnterFade({required this.child});

  final Widget child;

  @override
  State<_EnterFade> createState() => _EnterFadeState();
}

class _EnterFadeState extends State<_EnterFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _in.value = 1;
    } else if (!_in.isAnimating && _in.value == 0) {
      _in.forward();
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _in,
      builder: (context, child) => Opacity(
        opacity: Curves.easeOutCubic.transform(_in.value),
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - Curves.easeOutCubic.transform(_in.value))),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
