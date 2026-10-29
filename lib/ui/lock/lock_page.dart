import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../security/key_manager.dart';
import '../widgets/common.dart';

/// 锁屏：首次创建金库（设定主口令 + 展示恢复码）/ 日常解锁。
class LockPage extends ConsumerStatefulWidget {
  const LockPage({super.key});

  @override
  ConsumerState<LockPage> createState() => _LockPageState();
}

class _LockPageState extends ConsumerState<LockPage> {
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _recoveryCode;

  @override
  void dispose() {
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final err = _validateNewPass();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _busy = true);
    try {
      final code = await ref
          .read(vaultProvider.notifier)
          .createVault(_pass.text);
      setState(() {
        _recoveryCode = code;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = '创建失败：$e';
        _busy = false;
      });
    }
  }

  String? _validateNewPass() {
    final p = _pass.text;
    if (p.length < 8) return '主口令至少 8 位；建议 12 位以上 passphrase';
    if (p != _pass2.text) return '两次输入不一致';
    final classes = [
      RegExp(r'[a-z]').hasMatch(p),
      RegExp(r'[A-Z]').hasMatch(p) || RegExp(r'[^\w]').hasMatch(p),
      RegExp(r'\d').hasMatch(p),
    ].where((v) => v).length;
    if (p.length < 12 && classes < 2) return '口令强度不足：请更长或混合字符类型';
    return null;
  }

  Future<void> _unlock() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(vaultProvider.notifier).unlock(_pass.text);
      // 成功后路由自动跳转
    } catch (e) {
      setState(() {
        _error = e is WrongPassphraseException ? '主口令或恢复码不正确' : '解锁失败：$e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(vaultProvider);
    final theme = Theme.of(context);

    if (_recoveryCode != null) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Icon(Icons.key, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text('请离线保存恢复码', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  '恢复码是丢失主口令后唯一的自救方式。请抄写在安全的地方（不要拍照存云端）。',
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
                FilledButton(
                  onPressed: () => setState(() => _recoveryCode = null),
                  child: const Text('我已保存，继续'),
                ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final setup = vault is VaultUninitialized;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (setup)
                  _BrandReveal(
                    child: Center(child: BrandLockup(width: 280)),
                  )
                else
                  const Center(child: BrandMark(size: 64)),
                const SizedBox(height: 12),
                Text(
                  setup ? '创建加密账本' : '资观 AssetScope',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  setup ? '设定主口令。它派生密钥加密全部数据，无法找回，只能用恢复码自救。'
                      : '输入主口令解锁本地加密账本',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(
                      labelText: '主口令', border: OutlineInputBorder()),
                ),
                if (setup) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass2,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: '重复主口令', border: OutlineInputBorder()),
                  ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!,
                        style: TextStyle(color: theme.colorScheme.error)),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : (setup ? _create : _unlock),
                  child: Text(_busy ? '处理中…' : (setup ? '创建' : '解锁')),
                ),
                if (!setup)
                  TextButton(
                    onPressed: () => setState(() => _error = '也可输入恢复码解锁'),
                    child: const Text('忘记主口令？使用恢复码'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 首启动品牌揭示：lockup 淡入并自 96% 轻微放大（easeOutCubic，450ms）。
///
/// 动效门槛：仅首次创建金库（一次性 onboarding）播放——日常解锁是
/// 高频路径，logo 静态直达；系统"减少动画"时直接呈现终态。
class _BrandReveal extends StatefulWidget {
  const _BrandReveal({required this.child});

  final Widget child;

  @override
  State<_BrandReveal> createState() => _BrandRevealState();
}

class _BrandRevealState extends State<_BrandReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _anim =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(_anim),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(_anim),
          child: widget.child,
        ),
      );
}
