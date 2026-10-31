import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/money/currency.dart';
import '../../security/dart_crypto_suite.dart';
import '../../services/backup_service.dart';
import '../../services/merge_service.dart';
import '../widgets/common.dart';

/// 设置页的全部对话框流程（安全/备份/本位币），与页面骨架分离。
///
/// 约定：返回 `Future<void>`，完成各自弹提示；跨 async 使用 context
/// 前必须 mounted 检查。

Future<void> showChangePassphraseDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final t = AppLocalizations.of(context);
  final old = TextEditingController();
  final neu = TextEditingController();
  final ok = await showAppDialog<bool>(
    context,
    builder: (_) => AppDialog(
      title: t.settingsChangePassphrase,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ParticleTextField(
            controller: old,
            obscureText: true,
            decoration: InputDecoration(labelText: t.settingsCurrentPassphrase),
          ),
          const SizedBox(height: 10),
          ParticleTextField(
            controller: neu,
            obscureText: true,
            decoration: InputDecoration(labelText: t.settingsNewPassphraseLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.settingsCancel),
        ),
        ParticleFilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(t.settingsConfirm),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref.read(vaultProvider.notifier).changePassphrase(old.text, neu.text);
    if (!context.mounted) return;
    _snack(context, t.settingsPassphraseUpdated);
  } catch (e) {
    if (!context.mounted) return;
    _snack(context, t.settingsFailed(e));
  }
}

Future<void> showNewRecoveryCodeDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final t = AppLocalizations.of(context);
  try {
    final code = await ref
        .read(vaultProvider.notifier)
        .regenerateRecoveryCode();
    if (!context.mounted) return;
    await showAppDialog<void>(
      context,
      builder: (_) => AppDialog(
        title: t.settingsNewRecoveryCode,
        content: SelectableText(code),
        actions: [
          ParticleFilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.settingsGotIt),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    _snack(context, t.settingsFailed(e));
  }
}

/// 导出加密备份：口令 ≥8 位（与主口令规则一致，建议 12 位以上）。
Future<void> showBackupExportDialog(
  BuildContext context,
  WidgetRef ref,
  VaultUnlocked s,
) async {
  final t = AppLocalizations.of(context);
  final pass = TextEditingController();
  final ok = await showAppDialog<bool>(
    context,
    builder: (_) => AppDialog(
      title: t.settingsBackupPassphrase,
      content: ParticleTextField(
        controller: pass,
        obscureText: true,
        decoration: InputDecoration(labelText: t.settingsBackupPassphraseLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.settingsCancel),
        ),
        ParticleFilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(t.settingsExport),
        ),
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
      vaultFingerprint: MergeService.vaultFingerprint(
        s.keyManager.databaseKeyHex(),
      ),
    );
    // 记录备份时间（仪表盘备份提醒的依据）。
    await s.meta.setSetting(
      'lastBackupAtMs',
      DateTime.now().millisecondsSinceEpoch,
    );
    if (!context.mounted) return;
    _snack(context, t.settingsExportedTo(file.path));
  } catch (e) {
    if (!context.mounted) return;
    _snack(context, t.settingsExportFailed(e));
  }
}

Future<void> showBackupRestoreDialog(
  BuildContext context,
  WidgetRef ref,
  VaultUnlocked s,
) async {
  final t = AppLocalizations.of(context);
  final picked = await openFile(
    acceptedTypeGroups: [
      XTypeGroup(label: t.settingsBackupFileType, extensions: ['asbk']),
    ],
  );
  if (picked == null || !context.mounted) return;
  final pass = TextEditingController();
  final ok = await showAppDialog<bool>(
    context,
    builder: (_) => AppDialog(
      title: t.settingsBackupPassphraseTitle,
      content: ParticleTextField(controller: pass, obscureText: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.settingsCancel),
        ),
        ParticleFilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(t.settingsVerifyAndRestore),
        ),
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
      _snack(context, t.settingsRestoreDone);
    }
  } catch (e) {
    if (!context.mounted) return;
    _snack(context, t.settingsRestoreFailed(e));
  }
}

Future<void> showBaseCurrencyDialog(
  BuildContext context,
  WidgetRef ref,
  VaultUnlocked s,
) async {
  final t = AppLocalizations.of(context);
  final options = CurrencyInfo.builtin.map((c) => c.code).toList();
  final picked = await showAppDialog<String>(
    context,
    builder: (_) => AppDialog(
      title: t.settingsBaseCurrency,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in options)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.pop(context, c),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Text(c),
              ),
            ),
        ],
      ),
    ),
  );
  if (picked == null || !context.mounted) return;
  await s.meta.setSetting('baseCurrency', picked);
  if (!context.mounted) return;
  _snack(context, t.settingsBaseCurrencySet(picked));
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
