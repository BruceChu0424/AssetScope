/// 归属份额（家庭账本）：解析/格式化 + 编辑对话框。
///
/// 口径（docs/05 §16）：份额是账户存量的归属比例（1 = 全额本人），
/// 只影响净资产/FIRE 等存量口径，不影响流水与月报收支（全家庭）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ledger/account.dart';
import '../../domain/money/fx_rate.dart';
import '../widgets/particle_interactive.dart';

/// "50"、"33.3" → 有理数份额（1/2、333/1000）；非法或不在 (0,1] 返回 null。
Rational? parseOwnership(String percentText) {
  final t = percentText.trim();
  if (t.isEmpty) return null;
  final Rational pct;
  try {
    pct = Rational.parseDecimal(t);
  } catch (_) {
    return null;
  }
  final share = pct / Rational.fromInt(BigInt.from(100));
  if (share.isZero || share.isNegative || share > Rational.one) return null;
  return share;
}

/// 份额 → 百分比显示（"50"、"33.3"）。展示层允许有限小数。
String fmtOwnership(Rational share) {
  final pct = share * Rational.fromInt(BigInt.from(100));
  if (pct.isZero) return '0';
  final d = (pct.n / pct.d).toDouble();
  var s = d.toStringAsFixed(2);
  if (s.endsWith('.00')) {
    s = s.substring(0, s.length - 3);
  } else if (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

/// 编辑账户归属份额；返回 true 表示已保存。
Future<bool> showOwnershipDialog(
  BuildContext context,
  WidgetRef ref,
  VaultUnlocked s,
  Account account,
) async {
  final ctrl = TextEditingController(
    text: fmtOwnership(account.effectiveOwnership),
  );
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('归属份额'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ParticleTextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: '本人份额（%）',
              suffixText: '%',
              helperText:
                  '100 = 全额本人；夫妻共同账户各填 50。'
                  '只影响净资产/我的份额统计，不改流水。',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: const Text('取消'),
        ),
        ParticleFilledButton(
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: const Text('保存'),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  final share = parseOwnership(ctrl.text);
  ctrl.dispose();
  if (share == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('份额需在 0–100 之间（例如 50 或 33.3）')),
      );
    }
    return false;
  }
  await s.accounts.upsert(
    account.copyWith(ownership: share == Rational.one ? null : share),
  );
  return true;
}
