import 'package:flutter/material.dart';

import '../../domain/money/currency.dart';
import '../../domain/money/money.dart';
import '../theme/app_theme.dart';
import 'money_text.dart' show fmtMinor;
import '../widgets/particle_interactive.dart';

/// 涨跌徽章：胶囊、箭头、语义色、等宽数字。
class DeltaBadge extends StatelessWidget {
  const DeltaBadge({
    super.key,
    required this.minor,
    required this.currencyCode,
    this.percent,
  });

  final BigInt minor;
  final String currencyCode;

  /// 同时展示百分比（如净资产月环比）。
  final double? percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final up = !minor.isNegative;
    final c = signColor(minor, theme.brightness);
    final amount = fmtMinor(minor, currencyCode, sign: up);
    final label = percent == null
        ? amount
        : '$amount（${up ? '↑' : '↓'} ${(percent!.abs() * 100).toStringAsFixed(1)}%）';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// 空状态：图标 + 标题 + 引导文案 + 可选动作按钮。
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                  height: 1.5,
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// 错误占位。
class ErrorPlaceholder extends StatelessWidget {
  const ErrorPlaceholder(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

/// 今日日期字符串（表单默认值）。
String dateToday() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

/// 金额输入域：解析校验 + 币种感知。
class AppAmountField extends StatelessWidget {
  const AppAmountField({
    super.key,
    required this.controller,
    required this.currencyCode,
    this.label = '金额',
    this.allowNegative = false,
  });

  final TextEditingController controller;
  final String currencyCode;
  final String label;
  final bool allowNegative;

  @override
  Widget build(BuildContext context) {
    final ccy = CurrencyInfo.parse(currencyCode);
    return ParticleTextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: allowNegative,
      ),
      decoration: InputDecoration(labelText: label, suffixText: ccy.code),
    );
  }

  /// 解析为最小单位；空或非法返回 null。
  BigInt? parseMinor() {
    final t = controller.text.trim();
    if (t.isEmpty) return null;
    try {
      return Money.parse(t, CurrencyInfo.parse(currencyCode)).amountMinor;
    } on FormatException {
      return null;
    }
  }
}

/// 日期输入域：文本 + 点击弹日历选择器。
class AppDateField extends StatelessWidget {
  const AppDateField({super.key, required this.controller, this.label = '日期'});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ParticleTextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          controller.text =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }
}

/// 确认对话框（危险操作的统一入口）。
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '确认',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        ParticleFilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}
