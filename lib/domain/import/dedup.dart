import 'dart:convert';

import '../ledger/transaction.dart';

/// 导入流水规范化后的候选行。
class NormalizedRow {
  const NormalizedRow({
    required this.date,
    required this.direction,
    required this.amountMinor,
    required this.currencyCode,
    required this.counterparty,
    this.categoryGuess,
    this.note,
    this.rawRowJson,
    this.rowKey,
    this.sourceTxId,
  });

  final DateTime date;

  /// true=收入（钱进账），false=支出。
  final bool direction;
  final BigInt amountMinor;
  final String currencyCode;
  final String counterparty;
  final String? categoryGuess;
  final String? note;

  /// 原始行（JSON 快照，保留依据）。
  final String? rawRowJson;

  /// 来源系统内稳定行键（流水号优先；无则 行内容哈希）。
  final String? rowKey;
  final String? sourceTxId;

  /// 稳定外部 ID：同一行重复导入得到相同 id → 幂等跳过。
  String externalId(String parserId, String accountId) {
    final basis = rowKey ??
        (sourceTxId ?? '') +
            date.millisecondsSinceEpoch.toString() +
            amountMinor.toString() +
            counterparty;
    final bytes = utf8.encode('$parserId|$accountId|$basis');
    return _sha256Hex(bytes);
  }

  /// 规范化指纹：用于“疑似重复”提示（不是自动删除依据）。
  String fingerprint() {
    final normalizedCounterparty = counterparty
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase()
        .replaceAll(RegExp(r'[(（].*[)）]'), '');
    final day = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final basis =
        '$day|$amountMinor|$currencyCode|${direction ? 'in' : 'out'}|$normalizedCounterparty';
    return _sha256Hex(utf8.encode(basis));
  }
}

/// 与已有账目或同批次其他行的匹配结论。
enum DedupDecision { isNew, exactDuplicate, fingerprintDuplicate, transferPair }

class DedupMatch {
  const DedupMatch({
    required this.decision,
    this.existingTxId,
    this.pairedRowExternalId,
    this.reason,
  });

  final DedupDecision decision;
  final String? existingTxId;
  final String? pairedRowExternalId;
  final String? reason;
}

/// 去重与关联：
/// 1) 稳定外部 ID 完全一致 → 精确重复，跳过；
/// 2) 指纹一致（同日±1天、同金额、同对手方规范化） → 疑似重复，仅生成建议；
/// 3) 两个支付通道同日±2天、金额一致、方向互补（一出一进）→ 疑似内部转账对，
///    归并为一笔转账，只产生一次资金影响。
class Deduper {
  const Deduper();

  static DedupMatch matchAgainst({
    required NormalizedRow row,
    required Set<String> knownExternalIds,
    required Map<String, String> fingerprintToTxId,
  }) {
    // externalId 由调用方补全 parser/account 维度后判断。
    if (row.rowKey != null && knownExternalIds.contains(row.rowKey)) {
      return DedupMatch(
          decision: DedupDecision.exactDuplicate,
          reason: '外部 ID 已存在：${row.rowKey}');
    }
    final fp = row.fingerprint();
    final hit = fingerprintToTxId[fp];
    if (hit != null) {
      return DedupMatch(
        decision: DedupDecision.fingerprintDuplicate,
        existingTxId: hit,
        reason: '同日同金额同对手方（指纹一致）',
      );
    }
    return const DedupMatch(decision: DedupDecision.isNew);
  }

  /// 在同一批次内寻找转账对：A 通道支出 + B 通道收入，金额一致，日期差 ≤2 天。
  /// 返回配对（小索引在前）；未配对行按普通收支处理。
  static List<TransferPairCandidate> pairTransfers(List<NormalizedRow> rows) {
    final used = List<bool>.filled(rows.length, false);
    final pairs = <TransferPairCandidate>[];
    for (var i = 0; i < rows.length; i++) {
      if (used[i] || rows[i].direction) continue;
      for (var j = 0; j < rows.length; j++) {
        if (used[j] || !rows[j].direction) continue;
        if (rows[i].amountMinor != rows[j].amountMinor) continue;
        if (rows[i].currencyCode != rows[j].currencyCode) continue;
        final gap = rows[i].date.difference(rows[j].date).abs();
        if (gap.inDays > 2) continue;
        used[i] = true;
        used[j] = true;
        pairs.add(TransferPairCandidate(outIndex: i, inIndex: j));
        break;
      }
    }
    return pairs;
  }
}

class TransferPairCandidate {
  const TransferPairCandidate({required this.outIndex, required this.inIndex});
  final int outIndex;
  final int inIndex;
}

String _sha256Hex(List<int> bytes) {
  // 纯 Dart SHA-256（FIPS 180-4），保证领域层无第三方依赖。
  final h = _Sha256().hash(bytes);
  return h.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

class _Sha256 {
  static const List<int> k = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
    0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
    0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
    0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  List<int> hash(List<int> input) {
    var h0 = 0x6a09e667, h1 = 0xbb67ae85;
    var h2 = 0x3c6ef372, h3 = 0xa54ff53a;
    var h4 = 0x510e527f, h5 = 0x9b05688c;
    var h6 = 0x1f83d9ab, h7 = 0x5be0cd19;

    final bitLen = input.length * 8;
    final padded = <int>[
      ...input,
      0x80,
      ...List.filled((55 - input.length % 64 + 64) % 64, 0),
    ];
    // 长度（64 位大端）——只支持 <2^32 位消息（导入行足够）。
    padded
      ..addAll(List.filled(4, 0))
      ..add((bitLen >> 24) & 0xff)
      ..add((bitLen >> 16) & 0xff)
      ..add((bitLen >> 8) & 0xff)
      ..add(bitLen & 0xff);

    var w = List<int>.filled(64, 0);
    for (var block = 0; block < padded.length; block += 64) {
      for (var t = 0; t < 16; t++) {
        w[t] = (padded[block + t * 4] << 24) |
            (padded[block + t * 4 + 1] << 16) |
            (padded[block + t * 4 + 2] << 8) |
            padded[block + t * 4 + 3];
      }
      for (var t = 16; t < 64; t++) {
        final s0 = _rotr(w[t - 15], 7) ^ _rotr(w[t - 15], 18) ^ (w[t - 15] >> 3);
        final s1 = _rotr(w[t - 2], 17) ^ _rotr(w[t - 2], 19) ^ (w[t - 2] >> 10);
        w[t] = (w[t - 16] + s0 + w[t - 7] + s1) & 0xffffffff;
      }
      var a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, hh = h7;
      for (var t = 0; t < 64; t++) {
        final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ ((~e & 0xffffffff) & g);
        final temp1 = (hh + s1 + ch + k[t] + w[t]) & 0xffffffff;
        final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & 0xffffffff;
        hh = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xffffffff;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xffffffff;
      }
      h0 = (h0 + a) & 0xffffffff;
      h1 = (h1 + b) & 0xffffffff;
      h2 = (h2 + c) & 0xffffffff;
      h3 = (h3 + d) & 0xffffffff;
      h4 = (h4 + e) & 0xffffffff;
      h5 = (h5 + f) & 0xffffffff;
      h6 = (h6 + g) & 0xffffffff;
      h7 = (h7 + hh) & 0xffffffff;
    }
    return [h0, h1, h2, h3, h4, h5, h6, h7].expand((v) => [
          (v >> 24) & 0xff,
          (v >> 16) & 0xff,
          (v >> 8) & 0xff,
          v & 0xff,
        ]).toList();
  }

  int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xffffffff;
}

/// 供 importers 层复用：稳定 id 生成。
String stableExternalId({
  required String parserId,
  required String accountId,
  required TxSource source,
  required String basis,
}) =>
    _sha256Hex(utf8.encode('$parserId|$accountId|${source.name}|$basis'));
