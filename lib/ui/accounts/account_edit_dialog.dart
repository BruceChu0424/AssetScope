import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ledger/account.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import 'ownership.dart';

/// 新建账户对话框（资产/负债 + 子类型 + 币种 + 持仓代码）。
class AccountEditDialog extends ConsumerStatefulWidget {
  const AccountEditDialog({super.key});

  @override
  ConsumerState<AccountEditDialog> createState() => _AccountEditDialogState();
}

class _AccountEditDialogState extends ConsumerState<AccountEditDialog> {
  final _name = TextEditingController();
  final _institution = TextEditingController();
  final _code = TextEditingController();
  final _ownership = TextEditingController(text: '100');
  AccountType _type = AccountType.asset;
  AssetSubtype _assetSubtype = AssetSubtype.bank;
  LiabilitySubtype _liabilitySubtype = LiabilitySubtype.creditCard;
  String _currency = 'CNY';

  @override
  void dispose() {
    _name.dispose();
    _institution.dispose();
    _code.dispose();
    _ownership.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _name.text.trim().isEmpty) return;
    final ownership = parseOwnership(_ownership.text) ?? Rational.one;
    final isHolding = _type == AccountType.asset && _assetSubtype.isHolding;
    if (isHolding) {
      final code =
          _code.text.trim().isEmpty ? _name.text.trim() : _code.text.trim();
      await s.accounts.createHolding(
        name: _name.text.trim(),
        subtype: _assetSubtype,
        currencyCode: _currency,
        securityCode: code,
        institution:
            _institution.text.trim().isEmpty ? null : _institution.text.trim(),
      );
    } else {
      final id = 'acc:${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
      await s.accounts.upsert(Account(
        id: id,
        name: _name.text.trim(),
        type: _type,
        assetSubtype: _type == AccountType.asset ? _assetSubtype : null,
        liabilitySubtype:
            _type == AccountType.liability ? _liabilitySubtype : null,
        institution:
            _institution.text.trim().isEmpty ? null : _institution.text.trim(),
        currencyCode: _currency,
        ownership: ownership == Rational.one ? null : ownership,
      ));
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final currencies = CurrencyInfo.builtin.map((c) => c.code).toList();
    return AlertDialog(
      title: const Text('新建账户'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: '名称')),
            const SizedBox(height: 12),
            SegmentedButton<AccountType>(
              segments: const [
                ButtonSegment(value: AccountType.asset, label: Text('资产')),
                ButtonSegment(
                    value: AccountType.liability, label: Text('负债')),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() => _type = v.first),
            ),
            const SizedBox(height: 12),
            if (_type == AccountType.asset)
              DropdownButtonFormField<AssetSubtype>(
                initialValue: _assetSubtype,
                decoration: const InputDecoration(labelText: '类型'),
                items: [
                  for (final st in AssetSubtype.values)
                    DropdownMenuItem(value: st, child: Text(st.labelZh)),
                ],
                onChanged: (v) => setState(() => _assetSubtype = v!),
              )
            else
              DropdownButtonFormField<LiabilitySubtype>(
                initialValue: _liabilitySubtype,
                decoration: const InputDecoration(labelText: '类型'),
                items: [
                  for (final st in LiabilitySubtype.values)
                    DropdownMenuItem(value: st, child: Text(st.labelZh)),
                ],
                onChanged: (v) => setState(() => _liabilitySubtype = v!),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(labelText: '币种'),
              items: [
                for (final c in currencies) DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _currency = v!),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _institution,
                decoration: const InputDecoration(labelText: '机构（可选）')),
            if (_type == AccountType.asset && _assetSubtype.isHolding) ...[
              const SizedBox(height: 12),
              TextField(
                  controller: _code,
                  decoration: const InputDecoration(
                      labelText: '证券代码（如 510300）')),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _ownership,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '本人份额（%）',
                suffixText: '%',
                helperText: '共同账户可设部分份额（如 50）；100 = 全额本人',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('创建')),
      ],
    );
  }
}
