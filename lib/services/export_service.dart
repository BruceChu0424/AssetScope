import '../data/repositories/accounts_repo.dart';
import '../data/repositories/ledger_repo.dart';
import '../domain/ledger/transaction.dart';
import '../domain/money/currency.dart';
import '../domain/utils/dates.dart';

/// 数据导出服务：把账本导出为通用 CSV。
///
/// 与加密备份（.asbk）互补的"数据自由"通道：明文 CSV 由用户
/// 显式选择存放位置；写出带 UTF-8 BOM，Excel 可直接打开中文。
/// 金额为主要单位十进制（无千分位），保持可再导入/可审计。
class ExportService {
  ExportService(this._accounts, this._ledger);

  final AccountsRepo _accounts;
  final LedgerRepo _ledger;

  /// 全部流水（含作废，附状态列）导出为 CSV 文本。
  Future<String> transactionsCsv() async {
    final accounts = await _accounts.all();
    final byId = {for (final a in accounts) a.id: a};
    final txs = await _ledger.list(
        from: DateTime(2000), to: DateTime(2999, 12, 31),
        includeVoided: true);
    txs.sort((a, b) => a.date.compareTo(b.date));

    final sb = StringBuffer('\uFEFF'); // UTF-8 BOM
    sb.writeln('日期,时间,类型,方向,金额,币种,账户,对方,分类,备注,状态');
    for (final tx in txs) {
      final userAccounts = <String>[];
      String? category;
      BigInt? amountMinor;
      String? ccy;
      for (final p in tx.postings) {
        final acc = byId[p.accountId];
        if (acc == null) continue;
        if (p.accountId.startsWith('cat:')) {
          category ??= acc.name;
          if (amountMinor == null && p.amountMinor != null) {
            amountMinor = p.amountMinor!.abs();
            ccy = p.currencyCode;
          }
          continue;
        }
        if (p.accountId.startsWith('sys:')) {
          if (amountMinor == null && p.amountMinor != null) {
            amountMinor = p.amountMinor!.abs();
            ccy = p.currencyCode;
          }
          continue;
        }
        userAccounts.add(acc.name);
        if (amountMinor == null && p.amountMinor != null) {
          amountMinor = p.amountMinor!.abs();
          ccy = p.currencyCode;
        }
      }
      final d = tx.date;
      sb.writeln([
        dateKey(d),
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
        tx.kind.labelZh,
        _directionLabel(tx.kind),
        if (amountMinor != null && ccy != null)
          _plainAmount(amountMinor, ccy)
        else
          '',
        ccy ?? '',
        userAccounts.join('+'),
        tx.counterparty ?? '',
        category ?? '',
        tx.note ?? '',
        tx.status == TxStatus.voided ? '已作废' : '有效',
      ].map(_esc).join(','));
    }
    return sb.toString();
  }

  static String _directionLabel(TxKind kind) => switch (kind) {
        TxKind.income ||
        TxKind.refund ||
        TxKind.dividend ||
        TxKind.receiveBack ||
        TxKind.borrow =>
          '收入',
        TxKind.expense ||
        TxKind.loanRepay ||
        TxKind.creditCardRepay ||
        TxKind.lend =>
          '支出',
        _ => '中性',
      };

  /// 主要单位十进制（按币种精度，无千分位）。
  static String _plainAmount(BigInt minor, String ccy) {
    final info = CurrencyInfo.parse(ccy);
    final neg = minor.isNegative;
    final abs = minor.abs();
    final major = abs ~/ info.minorFactor;
    final frac = (abs % info.minorFactor)
        .toString()
        .padLeft(info.minorUnitDigits, '0');
    final body = info.minorUnitDigits == 0
        ? major.toString()
        : '$major.$frac';
    return neg ? '-$body' : body;
  }

  /// CSV 字段转义：含逗号/引号/换行时引号包裹并双写引号。
  static String _esc(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
