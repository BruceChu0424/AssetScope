import 'dart:convert';

import '../data/repositories/accounts_repo.dart';
import '../data/repositories/ledger_repo.dart';
import '../data/repositories/meta_repo.dart';
import '../data/repositories/planning_repo.dart';
import '../domain/ledger/transaction.dart';
import '../domain/money/currency.dart';
import '../domain/utils/dates.dart';

/// 数据导出服务：把账本导出为通用 CSV / 全量 JSON。
///
/// 与加密备份（.asbk）互补的"数据自由"通道：明文导出由用户
/// 显式选择存放位置；CSV 带 UTF-8 BOM，Excel 可直接打开中文。
/// 金额为主要单位十进制（无千分位），保持可再导入/可审计；
/// JSON 导出为最小单位字符串（BigInt 无损）。
class ExportService {
  ExportService(this._accounts, this._ledger, this._meta, this._planning);

  final AccountsRepo _accounts;
  final LedgerRepo _ledger;
  final MetaRepo _meta;
  final PlanningRepo _planning;

  /// 全部流水（含作废，附状态列）导出为 CSV 文本。
  Future<String> transactionsCsv() async {
    final accounts = await _accounts.all();
    final byId = {for (final a in accounts) a.id: a};
    final txs = await _ledger.list(
      from: DateTime(2000),
      to: DateTime(2999, 12, 31),
      includeVoided: true,
    );
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
      sb.writeln(
        [
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
        ].map(_esc).join(','),
      );
    }
    return sb.toString();
  }

  /// 全量账本导出（JSON，明文）：账户/估值/汇率/交易全量/计划/预算/
  /// 白名单设置。金额一律最小单位字符串（BigInt 无损），数量为
  /// "n/d" 有理数字符串。**设置白名单**导出——含密钥的键
  /// （aiProvider 等）绝不进入明文导出。
  Future<String> fullLedgerJson({String appVersion = ''}) async {
    final accounts = await _accounts.all();
    final valuations = await _meta.valuations();
    final fxRates = await _meta.latestFxRates();
    final txs = await _ledger.list(
      from: DateTime(2000),
      to: DateTime(2999, 12, 31),
      includeVoided: true,
    );
    txs.sort((a, b) => a.date.compareTo(b.date));
    final events = await _planning.scheduledEvents();
    final budgets = await _planning.budgets();
    const settingWhitelist = {
      'baseCurrency',
      'themeMode',
      'lockTimeoutMinutes',
      'projectionHorizonDays',
      'baselineMinCashMinor',
      'riskFreeRatePercent',
      'allocationTargets',
      'categoryRules',
    };
    final settings = <String, Object?>{};
    (await _meta.allSettings()).forEach((k, v) {
      if (settingWhitelist.contains(k)) settings[k] = v;
    });

    const enc = JsonEncoder.withIndent('  ');
    return enc.convert({
      'format': 'assetscope-full-export',
      'formatVersion': 1,
      'appVersion': appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': [
        for (final a in accounts)
          {
            'id': a.id,
            'name': a.name,
            'type': a.type.name,
            'assetSubtype': a.assetSubtype?.name,
            'liabilitySubtype': a.liabilitySubtype?.name,
            'institution': a.institution,
            'currencyCode': a.currencyCode,
            'ownership': a.ownership == null
                ? null
                : '${a.ownership!.n}/${a.ownership!.d}',
            'includeInNetWorth': a.includeInNetWorth,
            'creditLimitMinor': a.creditLimitMinor?.toString(),
            'statementDay': a.statementDay,
            'dueDay': a.dueDay,
            'isSystem': a.isSystem,
            'archived': a.archived,
            'sortOrder': a.sortOrder,
            'notes': a.notes,
            'costBasisAccountId': a.costBasisAccountId,
            'securityId': a.securityId,
            'locationLat': a.locationLat,
            'locationLon': a.locationLon,
          },
      ],
      'valuations': [
        for (final v in valuations)
          {
            'accountId': v.accountId,
            'date': dateKey(v.date),
            'kind': v.kind.name,
            'unitPrice': v.unitPrice == null
                ? null
                : '${v.unitPrice!.n}/${v.unitPrice!.d}',
            'totalValueMinor': v.totalValueMinor?.toString(),
            'source': v.source,
            'note': v.note,
          },
      ],
      'fxRates': [
        for (final f in fxRates)
          {
            'from': f.from.code,
            'to': f.to.code,
            'rate': '${f.rate.n}/${f.rate.d}',
            'date': dateKey(f.asOf),
            'source': f.source,
          },
      ],
      'transactions': [
        for (final t in txs)
          {
            'id': t.id,
            'date': dateKey(t.date),
            'kind': t.kind.name,
            'status': t.status.name,
            'note': t.note,
            'counterparty': t.counterparty,
            'categoryId': t.categoryId,
            'tags': t.tags,
            'externalId': t.externalId,
            'source': t.source.name,
            'postings': [
              for (final p in t.postings)
                {
                  'accountId': p.accountId,
                  'amountMinor': p.amountMinor?.toString(),
                  'currencyCode': p.currencyCode,
                  'securityId': p.securityId,
                  'quantity': p.quantity == null
                      ? null
                      : '${p.quantity!.n}/${p.quantity!.d}',
                  'memo': p.memo,
                },
            ],
          },
      ],
      'scheduledEvents': [
        for (final e in events)
          {
            'id': e.id,
            'name': e.name,
            'direction': e.direction.name,
            'currencyCode': e.currencyCode,
            'cadence': e.cadence.name,
            'anchorDate': dateKey(e.anchorDate),
            'amountMinor': e.amountMinor?.toString(),
            'amountLowMinor': e.amountLowMinor?.toString(),
            'amountHighMinor': e.amountHighMinor?.toString(),
            'intervalValue': e.intervalValue,
            'monthEndPolicy': e.monthEndPolicy.name,
            'endDate': e.endDate == null ? null : dateKey(e.endDate!),
            'paymentAccountId': e.paymentAccountId,
            'categoryId': e.categoryId,
            'autoPost': e.autoPost,
            'notes': e.notes,
            'status': e.status.name,
            'skippedMonthKeys': e.skippedMonthKeys.toList(),
            'skippedDateKeys': e.skippedDateKeys.toList(),
            'amountOverrides': {
              for (final kv in e.amountOverrides.entries)
                kv.key: kv.value.toString(),
            },
          },
      ],
      'budgets': [
        for (final b in budgets)
          {
            'id': b.id,
            'name': b.name,
            'scope': b.scope.name,
            'limitMinor': b.limitMinor.toString(),
            'currencyCode': b.currencyCode,
            'startMonthKey': b.startMonthKey,
            'endMonthKey': b.endMonthKey,
            'categoryId': b.categoryId,
            'rollover': b.rollover.name,
            'rolloverCapMinor': b.rolloverCapMinor?.toString(),
            'active': b.active,
          },
      ],
      'settings': settings,
    });
  }

  static String _directionLabel(TxKind kind) => switch (kind) {
    TxKind.income ||
    TxKind.refund ||
    TxKind.dividend ||
    TxKind.receiveBack ||
    TxKind.borrow => '收入',
    TxKind.expense ||
    TxKind.loanRepay ||
    TxKind.creditCardRepay ||
    TxKind.lend => '支出',
    _ => '中性',
  };

  /// 主要单位十进制（按币种精度，无千分位）。
  static String _plainAmount(BigInt minor, String ccy) {
    final info = CurrencyInfo.parse(ccy);
    final neg = minor.isNegative;
    final abs = minor.abs();
    final major = abs ~/ info.minorFactor;
    final frac = (abs % info.minorFactor).toString().padLeft(
      info.minorUnitDigits,
      '0',
    );
    final body = info.minorUnitDigits == 0 ? major.toString() : '$major.$frac';
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
