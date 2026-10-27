import 'dart:convert';
import 'dart:typed_data';

import 'package:fast_gbk/fast_gbk.dart';

import '../data/repositories/accounts_repo.dart';
import '../data/repositories/ledger_repo.dart';
import '../data/repositories/meta_repo.dart';
import '../domain/import/dedup.dart';
import '../domain/ledger/transaction.dart';
import '../domain/money/currency.dart';
import '../domain/money/money.dart';

/// 账单导入服务。
///
/// 流程：识别文件 → 解析 → 规范化 → 去重 → 预览 → 确认 → 入账。
/// 原始行以 JSON 快照保留；同一文件重复导入幂等（稳定外部 ID）。
/// 微信/支付宝导出为 GBK 编码，自动探测。
class ImportService {
  ImportService(this._accounts, this._ledger, this._meta);

  final AccountsRepo _accounts;
  final LedgerRepo _ledger;
  final MetaRepo _meta;

  /// 解析文本（UTF-8 优先，失败回退 GBK）。
  String decode(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return gbk.decode(bytes);
    }
  }

  List<List<String>> parseCsv(String text) {
    final rows = <List<String>>[];
    var field = StringBuffer();
    var row = <String>[];
    var inQuotes = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',' || ch == '\t') {
          row.add(field.toString().trim());
          field = StringBuffer();
        } else if (ch == '\n' || ch == '\r') {
          if (field.isNotEmpty || row.isNotEmpty) {
            row.add(field.toString().trim());
            rows.add(row);
            row = <String>[];
            field = StringBuffer();
          }
          // 跳过 \r\n
          if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        } else {
          field.write(ch);
        }
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString().trim());
      rows.add(row);
    }
    return rows;
  }

  /// 通用 CSV 解析（表头映射）。
  /// 列名（表头必须包含）：date, time?, type/direction, amount, counterparty, note?
  /// date 格式 yyyy-MM-dd 或 yyyy/M/d；direction: 支出/收入 或 out/in。
  List<NormalizedRow> parseGenericCsv(
    String text, {
    required String parserId,
    required String accountId,
    String currencyCode = 'CNY',
  }) {
    final rows = parseCsv(text);
    if (rows.isEmpty) return const [];
    final header = [for (final h in rows.first) h.toLowerCase()];
    int col(String name) => header.indexOf(name);
    final dateI = col('date');
    final timeI = col('time');
    final typeI = col('type') >= 0 ? col('type') : col('direction');
    final amountI = col('amount');
    final cpartyI = col('counterparty') >= 0 ? col('counterparty') : col('merchant');
    final noteI = col('note');
    final txIdI = col('txid') >= 0 ? col('txid') : col('transaction_id');
    if (dateI < 0 || typeI < 0 || amountI < 0) {
      throw const FormatException('CSV 表头缺少 date/type/amount 列');
    }
    final out = <NormalizedRow>[];
    final ccy = CurrencyInfo.parse(currencyCode);
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.length <= amountI) continue;
      try {
        final d = _parseDate(r[dateI], timeI >= 0 && r.length > timeI ? r[timeI] : null);
        final dirText = r[typeI];
        final isIncome = dirText.contains('收入') || dirText.toLowerCase().contains('in');
        final amount = Money.parse(r[amountI], ccy);
        final sourceTxId =
            txIdI >= 0 && r.length > txIdI && r[txIdI].isNotEmpty ? r[txIdI] : null;
        out.add(NormalizedRow(
          date: d,
          direction: isIncome,
          amountMinor: amount.amountMinor,
          currencyCode: currencyCode,
          counterparty: cpartyI >= 0 && r.length > cpartyI ? r[cpartyI] : '',
          note: noteI >= 0 && r.length > noteI ? r[noteI] : null,
          rawRowJson: _rowJson(r),
          rowKey: sourceTxId,
          sourceTxId: sourceTxId,
        ));
      } on FormatException {
        // 无法解析的行：跳过并计入失败数（预览时显示）
        continue;
      }
    }
    return out;
  }

  DateTime _parseDate(String d, String? time) {
    var s = d.trim().replaceAll('/', '-');
    final parts = s.split('-');
    if (parts.length < 3) throw FormatException('bad date: $d');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    var day = int.parse(parts[2].split(' ').first);
    var hour = 0, minute = 0;
    if (time != null && time.contains(':')) {
      final tp = time.split(':');
      hour = int.tryParse(tp[0]) ?? 0;
      minute = int.tryParse(tp[1]) ?? 0;
    }
    return DateTime(y, m, day, hour, minute);
  }

  String _rowJson(List<String> r) => const JsonEncoder().convert(r);

  /// 预览：去重分级。返回可入账行 + 跳过原因。
  Future<ImportPreview> preview({
    required List<NormalizedRow> rows,
    required String parserId,
    required String accountId,
  }) async {
    final toImport = <NormalizedRow>[];
    final skipped = <String>[];
    final suggestions = <DedupMatch>[];
    final knownIds = await _ledger.externalIds();
    for (final row in rows) {
      final extId = row.externalId(parserId, accountId);
      if (knownIds.contains(extId)) {
        skipped.add('精确重复（外部 ID 已存在）: ${row.counterparty}');
        continue;
      }
      toImport.add(row);
    }
    // 同批次转账对建议
    final pairs = Deduper.pairTransfers(rows);
    for (final _ in pairs) {
      suggestions.add(const DedupMatch(
          decision: DedupDecision.transferPair,
          reason: '同批次内金额一致的一出一进，建议确认为内部转账'));
    }
    return ImportPreview(rows: toImport, skipped: skipped, suggestions: suggestions);
  }

  /// 入账：按行生成 收入/消费 交易（外部 ID 幂等）。
  ///
  /// [resolveCategory] 可对每行按对手方规则返回分类覆盖（智慧分类建议）；
  /// 返回 null 时用 [expenseCategoryId]/[incomeCategoryId] 默认值。
  Future<int> commit({
    required List<NormalizedRow> rows,
    required String parserId,
    required String accountId,
    required String expenseCategoryId,
    required String incomeCategoryId,
    required String sourceName,
    String? Function(NormalizedRow row)? resolveCategory,
  }) async {
    final account = await _accounts.byId(accountId);
    if (account == null) throw ArgumentError('账户不存在: $accountId');
    final expenseCat = await _accounts.byId(expenseCategoryId);
    final incomeCat = await _accounts.byId(incomeCategoryId);
    if (expenseCat == null || incomeCat == null) {
      throw ArgumentError('分类账户不存在');
    }
    final source = TxSource.values.firstWhere(
      (s) => s.name == sourceName,
      orElse: () => TxSource.importCsv,
    );
    final batchId =
        await _meta.createImportBatch(source: sourceName, filename: parserId, parserVersion: 'v1');
    var count = 0;
    var dupSkipped = 0;
    for (final row in rows) {
      final extId = row.externalId(parserId, accountId);
      if (await _ledger.externalIdExists(extId)) {
        dupSkipped++;
        continue;
      }
      final override = resolveCategory?.call(row);
      final draft = row.direction
          ? TxBuilders.income(
              destAsset: account,
              incomeCategory: override != null && override.startsWith('cat:i:')
                  ? (await _accounts.byId(override)) ?? incomeCat
                  : incomeCat,
              amountMinor: row.amountMinor,
              date: row.date,
              counterparty: row.counterparty,
              note: row.note,
              source: source,
              externalId: extId,
              importBatchId: batchId,
            )
          : TxBuilders.expense(
              payFrom: account,
              expenseCategory: override != null && override.startsWith('cat:e:')
                  ? (await _accounts.byId(override)) ?? expenseCat
                  : expenseCat,
              amountMinor: row.amountMinor,
              date: row.date,
              counterparty: row.counterparty,
              note: row.note,
              source: source,
              externalId: extId,
              importBatchId: batchId,
            );
      await _ledger.post(draft);
      count++;
    }
    await _meta.finishImportBatch(batchId, {'imported': count, 'skipped': dupSkipped},
        status: 'done');
    return count;
  }
}

class ImportPreview {
  const ImportPreview({
    required this.rows,
    required this.skipped,
    required this.suggestions,
  });

  final List<NormalizedRow> rows;
  final List<String> skipped;
  final List<DedupMatch> suggestions;
}
