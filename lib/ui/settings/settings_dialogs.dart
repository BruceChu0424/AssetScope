import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../domain/money/currency.dart';
import '../../security/dart_crypto_suite.dart';
import '../../services/backup_service.dart';

/// 设置页的全部对话框流程（安全/备份/本位币），与页面骨架分离。
///
/// 约定：返回 `Future<void>`，完成各自弹提示；跨 async 使用 context
/// 前必须 mounted 检查。

Future<void> showChangePassphraseDialog(
    BuildContext context, WidgetRef ref) async {
  final old = TextEditingController();
  final neu = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('修改主口令'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: old,
              obscureText: true,
              decoration: const InputDecoration(labelText: '当前主口令')),
          const SizedBox(height: 10),
          TextField(
              controller: neu,
              obscureText: true,
              decoration: const InputDecoration(labelText: '新主口令（≥12位更安全）')),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref
        .read(vaultProvider.notifier)
        .changePassphrase(old.text, neu.text);
    if (!context.mounted) return;
    _snack(context, '主口令已更新');
  } catch (e) {
    if (!context.mounted) return;
    _snack(context, '失败：$e');
  }
}

Future<void> showNewRecoveryCodeDialog(
    BuildContext context, WidgetRef ref) async {
  try {
    final code = await ref.read(vaultProvider.notifier).regenerateRecoveryCode();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('新恢复码（离线保存）'),
        content: SelectableText(code),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了')),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    _snack(context, '失败：$e');
  }
}

/// 导出加密备份：口令 ≥8 位（与主口令规则一致，建议 12 位以上）。
Future<void> showBackupExportDialog(
    BuildContext context, WidgetRef ref, VaultUnlocked s) async {
  final pass = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('备份口令'),
      content: TextField(
          controller: pass,
          obscureText: true,
          decoration:
              const InputDecoration(labelText: '备份文件口令（≥8 位，建议 12 位以上）')),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('导出')),
      ],
    ),
  );
  if (ok != true || pass.text.length < 8 || !context.mounted) return;
  final file = await getSaveLocation(
    suggestedName:
        'assetscope-${DateTime.now().toIso8601String().substring(0, 10)}.asbk',
  );
  if (file == null) return;
  try {
    final service = BackupService(s.db, DartCryptoSuite.instance);
    await service.exportTo(
      target: File(file.path),
      passphrase: pass.text,
    );
    if (!context.mounted) return;
    _snack(context, '已导出：${file.path}');
  } catch (e) {
    if (!context.mounted) return;
    _snack(context, '导出失败：$e');
  }
}

Future<void> showBackupRestoreDialog(
    BuildContext context, WidgetRef ref, VaultUnlocked s) async {
  final picked = await openFile(acceptedTypeGroups: [
    const XTypeGroup(label: '备份', extensions: ['asbk']),
  ]);
  if (picked == null || !context.mounted) return;
  final pass = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('输入备份口令'),
      content: TextField(controller: pass, obscureText: true),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('校验并恢复')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    final bytes = await File(picked.path).readAsBytes();
    final dir = await ref.read(vaultProvider.notifier).appDir();
    final target = File(p.join(dir.path, 'assetscope.db'));
    await BackupService.restoreTo(
      container: bytes,
      target: target,
      newDbKeyHex: s.keyManager.databaseKeyHex(),
      passphrase: pass.text,
    );
    await ref.read(vaultProvider.notifier).lock();
    if (context.mounted) {
      _snack(context, '恢复完成，已用新数据锁定；请用主口令解锁（原库保留为 .bak）');
    }
  } catch (e) {
    if (!context.mounted) return;
    _snack(context, '恢复失败（原账本未受影响）：$e');
  }
}

Future<void> showBaseCurrencyDialog(
    BuildContext context, WidgetRef ref, VaultUnlocked s) async {
  final options = CurrencyInfo.builtin.map((c) => c.code).toList();
  final picked = await showDialog<String>(
    context: context,
    builder: (_) => SimpleDialog(
      title: const Text('本位币'),
      children: [
        for (final c in options)
          SimpleDialogOption(
              child: Text(c), onPressed: () => Navigator.pop(context, c)),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;
  await s.meta.setSetting('baseCurrency', picked);
  if (!context.mounted) return;
  _snack(context, '本位币已设为 $picked');
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
