import 'csv_table.dart';
import 'dedup.dart';
import '../money/currency.dart';
import '../money/money.dart';

/// 原生账单格式。
enum BillFormat {
  wechat('微信支付账单'),
  alipay('支付宝账单'),
  generic('通用 CSV');

  const BillFormat(this.label);
  final String label;
}

/// 单条跳过原因与条数。
class SkipReason {
  const SkipReason(this.reason, this.count);
  final String reason;
  final int count;
}

/// 原生账单解析结果。
class BillParseOutcome {
  const BillParseOutcome({
    required this.format,
    required this.rows,
    required this.skipped,
  });

  final BillFormat format;
  final List<NormalizedRow> rows;

  /// 按原因聚合的跳过明细。
  final List<SkipReason> skipped;

  int get skippedCount => skipped.fold(0, (a, s) => a + s.count);

  /// 跳过摘要（每原因一行，供预览界面展示）。
  List<String> get skippedSummary =>
      [for (final s in skipped) '${s.reason} ×${s.count}'];
}

/// 微信支付 / 支付宝原生导出账单解析器。
///
/// - 只取“成功”状态的收支流水；退款、未完成、不计收支（中性转账）按原因跳过。
/// - 交易单号 / 交易号作为稳定来源 ID → 同一笔账单跨文件重复导入幂等。
/// - 表头按列名定位（列序无关），前导元数据行自动忽略。
/// - 金额剥除 ¥/￥/千分位后走 [Money.parse]（halfEven，全程整数最小单位）。
class BillParsers {
  const BillParsers._();

  /// 依据文本特征探测格式；无法识别返回 null（调用方回退通用 CSV）。
  static BillFormat? detect(String text) {
    final head = text.length > 4096 ? text.substring(0, 4096) : text;
    if (head.contains('微信支付账单')) return BillFormat.wechat;
    if (head.contains('支付宝交易明细')) return BillFormat.alipay;
    final table = CsvTable.parse(text);
    if (table.headerRowIndex(const {'交易时间', '收/支', '交易单号'}) >= 0) {
      return BillFormat.wechat;
    }
    if (table.headerRowIndex(const {'交易创建时间', '收/支', '交易号'}) >= 0) {
      return BillFormat.alipay;
    }
    return null;
  }

  static BillParseOutcome? parseWeChat(String text,
      {String currencyCode = 'CNY'}) {
    final table = CsvTable.parse(text);
    final header = table.headerRowIndex(const {'交易时间', '收/支', '金额(元)', '交易单号'});
    if (header < 0) return null;
    final dateI = table.columnIndex(header, '交易时间');
    final typeI = table.columnIndex(header, '交易类型');
    final cpartyI = table.columnIndex(header, '交易对方');
    final goodsI = table.columnIndex(header, '商品');
    final dirI = table.columnIndex(header, '收/支');
    final amountI = table.columnIndex(header, '金额(元)');
    final statusI = table.columnIndex(header, '当前状态');
    final txIdI = table.columnIndex(header, '交易单号');
    final noteI = table.columnIndex(header, '备注');

    final ccy = CurrencyInfo.parse(currencyCode);
    final rows = <NormalizedRow>[];
    final skipped = <String, int>{};
    void skip(String reason) => skipped[reason] = (skipped[reason] ?? 0) + 1;

    String cell(List<String> r, int i) =>
        i >= 0 && i < r.length ? r[i].trim() : '';

    for (var i = header + 1; i < table.rows.length; i++) {
      final r = table.rows[i];
      if (r.isEmpty || r.first.startsWith('---')) continue;
      final status = cell(r, statusI);
      if (_badStatus(status)) {
        skip('状态不纳入（$status）');
        continue;
      }
      final dirText = cell(r, dirI);
      final bool? direction = switch (dirText) {
        '收入' => true,
        '支出' => false,
        _ => null,
      };
      if (direction == null) {
        skip('不计收支（中性转账/资金转移）');
        continue;
      }
      final amountRaw = cell(r, amountI);
      if (amountRaw.isEmpty) {
        skip('金额为空');
        continue;
      }
      final BigInt amountMinor;
      try {
        amountMinor = Money.parse(cleanAmount(amountRaw), ccy).amountMinor;
      } on FormatException {
        skip('金额无法解析（$amountRaw）');
        continue;
      }
      if (amountMinor <= BigInt.zero) {
        skip('金额非正（$amountRaw）');
        continue;
      }
      DateTime date;
      try {
        date = parseDateTime(cell(r, dateI));
      } on FormatException {
        skip('日期无法解析（${cell(r, dateI)}）');
        continue;
      }
      final counterparty =
          cell(r, cpartyI).isNotEmpty ? cell(r, cpartyI) : cell(r, goodsI);
      final noteParts = [
        if (cell(r, goodsI).isNotEmpty && cell(r, goodsI) != '/') cell(r, goodsI),
        if (cell(r, noteI).isNotEmpty) cell(r, noteI),
      ];
      final txId = cell(r, txIdI);
      rows.add(NormalizedRow(
        date: date,
        direction: direction,
        amountMinor: amountMinor,
        currencyCode: currencyCode,
        counterparty: counterparty,
        note: noteParts.isEmpty ? (cell(r, typeI).isNotEmpty ? cell(r, typeI) : null) : noteParts.join(' · '),
        rawRowJson: _rowJson(r),
        rowKey: txId.isNotEmpty ? txId : null,
        sourceTxId: txId.isNotEmpty ? txId : null,
      ));
    }
    return BillParseOutcome(
      format: BillFormat.wechat,
      rows: rows,
      skipped: [for (final e in skipped.entries) SkipReason(e.key, e.value)],
    );
  }

  static BillParseOutcome? parseAlipay(String text,
      {String currencyCode = 'CNY'}) {
    final table = CsvTable.parse(text);
    final header = table.headerRowIndex(const {'交易创建时间', '收/支', '金额(元)', '交易号'});
    if (header < 0) return null;
    final txIdI = table.columnIndex(header, '交易号');
    final createdI = table.columnIndex(header, '交易创建时间');
    final paidI = table.columnIndex(header, '付款时间');
    final typeI = table.columnIndex(header, '类型');
    final cpartyI = table.columnIndex(header, '交易对方');
    final goodsI = table.columnIndex(header, '商品名称');
    final dirI = table.columnIndex(header, '收/支');
    final amountI = table.columnIndex(header, '金额(元)');
    final statusI = table.columnIndex(header, '交易状态');
    final noteI = table.columnIndex(header, '备注');

    final ccy = CurrencyInfo.parse(currencyCode);
    final rows = <NormalizedRow>[];
    final skipped = <String, int>{};
    void skip(String reason) => skipped[reason] = (skipped[reason] ?? 0) + 1;

    String cell(List<String> r, int i) =>
        i >= 0 && i < r.length ? r[i].trim() : '';

    for (var i = header + 1; i < table.rows.length; i++) {
      final r = table.rows[i];
      if (r.isEmpty || r.first.startsWith('---')) continue;
      final status = cell(r, statusI);
      if (_badStatus(status)) {
        skip('状态不纳入（$status）');
        continue;
      }
      final dirText = cell(r, dirI);
      final bool? direction = switch (dirText) {
        '收入' => true,
        '支出' => false,
        _ => null,
      };
      if (direction == null) {
        skip('不计收支（中性转账/资金转移）');
        continue;
      }
      final amountRaw = cell(r, amountI);
      if (amountRaw.isEmpty) {
        skip('金额为空');
        continue;
      }
      final BigInt amountMinor;
      try {
        amountMinor = Money.parse(cleanAmount(amountRaw), ccy).amountMinor;
      } on FormatException {
        skip('金额无法解析（$amountRaw）');
        continue;
      }
      if (amountMinor <= BigInt.zero) {
        skip('金额非正（$amountRaw）');
        continue;
      }
      DateTime date;
      try {
        final raw = cell(r, createdI).isNotEmpty
            ? cell(r, createdI)
            : cell(r, paidI);
        date = parseDateTime(raw);
      } on FormatException {
        skip('日期无法解析（${cell(r, createdI)}）');
        continue;
      }
      final counterparty =
          cell(r, cpartyI).isNotEmpty ? cell(r, cpartyI) : cell(r, goodsI);
      final noteParts = [
        if (cell(r, goodsI).isNotEmpty && cell(r, goodsI) != '/') cell(r, goodsI),
        if (cell(r, noteI).isNotEmpty) cell(r, noteI),
      ];
      final txId = cell(r, txIdI);
      rows.add(NormalizedRow(
        date: date,
        direction: direction,
        amountMinor: amountMinor,
        currencyCode: currencyCode,
        counterparty: counterparty,
        note: noteParts.isEmpty ? (cell(r, typeI).isNotEmpty ? cell(r, typeI) : null) : noteParts.join(' · '),
        rawRowJson: _rowJson(r),
        rowKey: txId.isNotEmpty ? txId : null,
        sourceTxId: txId.isNotEmpty ? txId : null,
      ));
    }
    return BillParseOutcome(
      format: BillFormat.alipay,
      rows: rows,
      skipped: [for (final e in skipped.entries) SkipReason(e.key, e.value)],
    );
  }

  /// 不纳入导入的状态：退款（原始消费行已单独存在）、未完成、失败、关闭。
  static bool _badStatus(String status) {
    if (status.isEmpty) return false;
    const bad = ['退款', '关闭', '失败', '待付款', '待收钱', '处理中', '还款中'];
    return bad.any(status.contains);
  }

  /// 剥除货币符号（¥/￥）与千分位、空白。
  static String cleanAmount(String raw) =>
      raw.replaceAll(RegExp(r'[¥￥\s]'), '').replaceAll(',', '');

  /// "yyyy-MM-dd HH:mm[:ss]" 或 "yyyy/M/d HH:mm[:ss]"。
  static DateTime parseDateTime(String s) {
    final t = s.trim();
    final m = RegExp(
            r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:[ T](\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?$')
        .firstMatch(t);
    if (m == null) throw FormatException('bad datetime: $s');
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      m.group(4) != null ? int.parse(m.group(4)!) : 0,
      m.group(5) != null ? int.parse(m.group(5)!) : 0,
      m.group(6) != null ? int.parse(m.group(6)!) : 0,
    );
  }

  static String _rowJson(List<String> r) {
    // 简单 JSON 数组序列化（保留原始行快照）。
    final sb = StringBuffer('[');
    for (var i = 0; i < r.length; i++) {
      if (i > 0) sb.write(',');
      sb.write('"${r[i].replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"');
    }
    sb.write(']');
    return sb.toString();
  }
}
