import 'dart:convert';

import '../../l10n/runtime_l10n.dart';
import '../ledger/transaction.dart';
import '../utils/hashing.dart';

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
    final basis =
        rowKey ??
        (sourceTxId ?? '') +
            date.millisecondsSinceEpoch.toString() +
            amountMinor.toString() +
            counterparty;
    final bytes = utf8.encode('$parserId|$accountId|$basis');
    return sha256Hex(bytes);
  }

  /// 规范化指纹：用于“疑似重复”提示（不是自动删除依据）。
  String fingerprint() {
    final normalizedCounterparty = counterparty
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase()
        .replaceAll(RegExp(r'[(（].*[)）]'), '');
    final day =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final basis =
        '$day|$amountMinor|$currencyCode|${direction ? 'in' : 'out'}|$normalizedCounterparty';
    return sha256Hex(utf8.encode(basis));
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
        reason: rt('外部 ID 已存在：${row.rowKey}'),
      );
    }
    final fp = row.fingerprint();
    final hit = fingerprintToTxId[fp];
    if (hit != null) {
      return DedupMatch(
        decision: DedupDecision.fingerprintDuplicate,
        existingTxId: hit,
        reason: rt('同日同金额同对手方（指纹一致）'),
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

/// 供 importers 层复用：稳定 id 生成。
String stableExternalId({
  required String parserId,
  required String accountId,
  required TxSource source,
  required String basis,
}) => sha256Hex(utf8.encode('$parserId|$accountId|${source.name}|$basis'));
