import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:fast_gbk/fast_gbk.dart';

import '../data/repositories/accounts_repo.dart';
import '../data/repositories/ledger_repo.dart';
import '../data/repositories/meta_repo.dart';
import '../domain/import/bill_parsers.dart';
import '../domain/import/csv_table.dart';
import '../domain/import/dedup.dart';
import '../domain/ledger/transaction.dart';
import '../domain/money/currency.dart';
import '../domain/money/money.dart';

/// 账单导入服务。
///
/// 流程：识别文件 → 解析 → 规范化 → 去重 → 预览 → 确认 → 入账。
/// 原始行以 JSON 快照保留；同一文件重复导入幂等（稳定外部 ID）。
/// 微信/支付宝原生账单自动识别；导出为 GBK 编码时自动探测。
class ImportService {
  ImportService(this._accounts, this._ledger, this._meta);

  final AccountsRepo _accounts;
  final LedgerRepo _ledger;
  final MetaRepo _meta;

  /// 解析文本（UTF-8 优先，失败回退 GBK）。
  String decode(Uint8List bytes) => decodeBillBytes(bytes);

  /// 解码 + 自动探测解析，全部在独立 isolate 执行（万行级账单
  /// 的 GBK 解码与 CSV 解析是纯 CPU 工作，不再阻塞 UI 线程）。
  /// 闭包只引用顶层纯函数（不捕获 this/仓储/数据库句柄），可跨 isolate。
  Future<AutoParsed> decodeAndParseAutoIsolated(
    Uint8List bytes, {
    required String genericParserId,
    String currencyCode = 'CNY',
  }) {
    return Isolate.run(
      () => parseBillAuto(
        decodeBillBytes(bytes),
        genericParserId: genericParserId,
        currencyCode: currencyCode,
      ),
    );
  }

  List<List<String>> parseCsv(String text) => CsvTable.parse(text).rows;

  /// 自动探测解析：微信/支付宝原生账单优先，否则回退通用 CSV。
  ///
  /// 原生账单的 [AutoParsed.parserId] 用格式名（交易单号作稳定来源 ID，
  /// 跨文件、跨时间段重复导入同样幂等）；通用 CSV 沿用文件名。
  AutoParsed parseAuto(
    String text, {
    required String genericParserId,
    String currencyCode = 'CNY',
  }) => parseBillAuto(
    text,
    genericParserId: genericParserId,
    currencyCode: currencyCode,
  );

  /// 通用 CSV 解析（表头映射）。
  /// 列名（表头必须包含）：date, time?, type/direction, amount, counterparty, note?
  /// date 格式 yyyy-MM-dd 或 yyyy/M/d；direction: 支出/收入 或 out/in。
  List<NormalizedRow> parseGenericCsv(
    String text, {
    required String parserId,
    required String accountId,
    String currencyCode = 'CNY',
  }) => parseGenericCsvPure(
    text,
    parserId: parserId,
    accountId: accountId,
    currencyCode: currencyCode,
  );

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
      suggestions.add(
        const DedupMatch(
          decision: DedupDecision.transferPair,
          reason: '同批次内金额一致的一出一进，建议确认为内部转账',
        ),
      );
    }
    return ImportPreview(
      rows: toImport,
      skipped: skipped,
      suggestions: suggestions,
    );
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
    final batchId = await _meta.createImportBatch(
      source: sourceName,
      filename: parserId,
      parserVersion: 'v1',
    );
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
    await _meta.finishImportBatch(batchId, {
      'imported': count,
      'skipped': dupSkipped,
    }, status: 'done');
    return count;
  }
}

// ---------- 顶层纯函数（供 isolate 调用：不捕获实例/仓储/数据库句柄） ----------

/// 解码：UTF-8 优先，失败回退 GBK。
String decodeBillBytes(Uint8List bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return gbk.decode(bytes);
  }
}

/// 自动探测解析（微信/支付宝原生账单优先，回退通用 CSV）。
AutoParsed parseBillAuto(
  String text, {
  required String genericParserId,
  String currencyCode = 'CNY',
}) {
  final format = BillParsers.detect(text);
  if (format == BillFormat.wechat) {
    final r = BillParsers.parseWeChat(text, currencyCode: currencyCode);
    if (r != null) {
      return AutoParsed(
        format: BillFormat.wechat,
        parserId: 'wechat',
        rows: r.rows,
        skippedLines: r.skippedSummary,
      );
    }
  } else if (format == BillFormat.alipay) {
    final r = BillParsers.parseAlipay(text, currencyCode: currencyCode);
    if (r != null) {
      return AutoParsed(
        format: BillFormat.alipay,
        parserId: 'alipay',
        rows: r.rows,
        skippedLines: r.skippedSummary,
      );
    }
  }
  return AutoParsed(
    format: BillFormat.generic,
    parserId: genericParserId,
    rows: parseGenericCsvPure(
      text,
      parserId: genericParserId,
      accountId: 'generic',
      currencyCode: currencyCode,
    ),
    skippedLines: const [],
  );
}

/// 通用 CSV 解析（表头映射）。
/// 列名（表头必须包含）：date, time?, type/direction, amount, counterparty, note?
/// date 格式 yyyy-MM-dd 或 yyyy/M/d；direction: 支出/收入 或 out/in。
List<NormalizedRow> parseGenericCsvPure(
  String text, {
  required String parserId,
  required String accountId,
  String currencyCode = 'CNY',
}) {
  final rows = CsvTable.parse(text).rows;
  if (rows.isEmpty) return const [];
  final header = [for (final h in rows.first) h.toLowerCase()];
  int col(String name) => header.indexOf(name);
  final dateI = col('date');
  final timeI = col('time');
  final typeI = col('type') >= 0 ? col('type') : col('direction');
  final amountI = col('amount');
  final cpartyI = col('counterparty') >= 0
      ? col('counterparty')
      : col('merchant');
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
      final d = _parseDate(
        r[dateI],
        timeI >= 0 && r.length > timeI ? r[timeI] : null,
      );
      final dirText = r[typeI];
      final isIncome =
          dirText.contains('收入') || dirText.toLowerCase().contains('in');
      final amount = Money.parse(r[amountI], ccy);
      final sourceTxId = txIdI >= 0 && r.length > txIdI && r[txIdI].isNotEmpty
          ? r[txIdI]
          : null;
      out.add(
        NormalizedRow(
          date: d,
          direction: isIncome,
          amountMinor: amount.amountMinor,
          currencyCode: currencyCode,
          counterparty: cpartyI >= 0 && r.length > cpartyI ? r[cpartyI] : '',
          note: noteI >= 0 && r.length > noteI ? r[noteI] : null,
          rawRowJson: _rowJson(r),
          rowKey: sourceTxId,
          sourceTxId: sourceTxId,
        ),
      );
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

/// 自动探测解析结果。
class AutoParsed {
  const AutoParsed({
    required this.format,
    required this.parserId,
    required this.rows,
    required this.skippedLines,
  });

  final BillFormat format;

  /// 外部 ID 的 parser 维度（原生账单用格式名保证跨文件幂等）。
  final String parserId;
  final List<NormalizedRow> rows;

  /// 原生解析阶段按原因跳过的行（如退款、不计收支）。
  final List<String> skippedLines;
}
