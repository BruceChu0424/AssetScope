<div align="center">

# 资观 AssetScope

**本地优先、端到端加密的个人资产、负债与财务规划系统**

每月打开一次，就能清楚回答：我有多少、欠多少、花多少、为什么变化、接下来要付多少、还能安排多少开销。

[![CI](https://github.com/BruceChu0424/AssetScope/actions/workflows/ci.yml/badge.svg)](https://github.com/BruceChu0424/AssetScope/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-1E5C45.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-81%20passing-2E7D5B.svg)](test)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Windows-B08A2E.svg)](#)

</div>

---

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter 客户端（Android / iOS / Windows）                    │
│  ┌────────────┐  ┌────────────┐  ┌──────────────────────┐    │
│  │  UI 层      │  │  服务层     │  │  安全层               │    │
│  │  10+ 页面   │→ │ 账务/统计/  │→ │ Argon2id/PBKDF2      │    │
│  │  3D 地球    │  │ 智慧分析/   │  │ XChaCha20-Poly1305   │    │
│  │  Riverpod  │  │ 预测/导入   │  │ 密钥层级 KEK→DEK     │    │
│  └────────────┘  └─────┬──────┘  └──────────┬───────────┘    │
│                        ↓                     ↓               │
│  ┌─────────────────────────────┐  ┌──────────────────────┐   │
│  │  领域层（纯 Dart，无依赖）   │  │  自动锁定·加密备份     │   │
│  │  BigInt 金额·复式记账·守恒  │  │  恢复码自救·.asbk 容器 │   │
│  │  稳健统计·TWR/XIRR·策略模拟 │  └──────────────────────┘   │
│  └─────────────────────────────┘                              │
│                        ↓                                      │
│         加密 SQLite（SQLite3MultipleCiphers，PRAGMA key）      │
└─────────────────────────────────────────────────────────────┘
```

## 核心特性

**正确的账本**
- 复式记账 + 借贷守恒校验；转账不算消费、信用卡还款不重复记账、贷款本息拆分、浮盈卖出不重复计收益——81 个单元测试锁定这些硬规则。
- 金额全链路 `BigInt`（分）+ `Rational` 有理数，禁止 double；halfEven 舍入经有理数整体舍入。

**全资产负债视图**
- 现金/银行/支付宝/微信/券商/持仓（股票·基金·债券·加密）/房产/车辆/公积金/应收款/保险现金价值……总资产、总负债、净资产一屏可见；估值缺失不计为 0，过期估值显式提示。

**🌍 3D 资产地球**
- 点阵线框地球（Natural Earth 公有领域数据，92KB 全离线），固定资产呼吸标记、拖拽旋转/惯性/自转、点击飞行动画 + 详情弹层；账户支持城市快选定位。

**🧠 智慧分析（v0.2 新增）**
- 财务体检：储蓄率、应急月数、资产负债率、固定收支覆盖比。
- 消费配速：按当前速度外推月末总额与剩余日均可花。
- 异常检测：中位数 + MAD 稳健 z 分数，单月大额不污染基线。
- 周期识别：间隔中位数 ± 容差识别房租/订阅/工资，一键固化计划。
- 净资产里程碑：Theil–Sen 稳健回归预测下一个整数关口（抗离群月）。
- 商户→分类规则引擎：关键词规则 + 历史频率学习 + 模糊匹配，导入时逐行智慧分类。
- 投资组合 XIRR（组合边界内买卖分红视为内部事件）+ 持仓浮盈明细。
- 雪崩 vs 雪球还款策略逐月模拟对比。

**规划与预测**
- 月度总额与分类预算、月末/闰年感知的周期计划、目标预留与每月需存金额。
- 现金预测：按未来 N 天（30–180 可设）逐日推演 C(t) − R(t) − B(t)，识别"月底有钱但月中缺钱"；可支配上限 = max(0, min_t[·])，准备金在支出日自动释放（不双扣）。

**债务管理**
- 等额本息/等额本金/先息后本/固定分期/免息；还款计划、提前还款模拟（利息节省与手续费）、名义费率 vs IRR 有效年化、策略对比。

**月报与净资产归因**
- 期末净资产 = 期初 + 收支 + 投资（已实现+分红+Δ未实现）+ 汇兑 + 其他估值 + 修正 + **待核对差额**（非 0 即数据缺口，显式暴露）。

**安全**
- 数据库、备份全程加密；主口令 Argon2id/PBKDF2 派生 KEK 包裹随机 DEK，改口令不动数据；恢复码自救；自动锁定时长可设（1–60 分钟）；备份为认证加密容器 `.asbk`，错口令/损坏一律拒绝且不触碰原库。

**导入与去重**
- 通用 CSV（UTF-8/GBK 自动识别）四步向导：选文件 → 选账户 → 去重预览 → 智慧分类入账；稳定外部 ID 幂等导入，同一文件重复导入自动跳过。

## 快速开始

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 生成 drift 代码
flutter analyze                                            # 零 issue（CI 门禁）
flutter test                                               # 81 个测试
flutter run -d windows                                     # 或 android/ios
```

首次启动：设定主口令 → **离线保存恢复码** → 新建账户 → 记期初余额 → 开始记账。

> 数据库加密依赖 pubspec 中 `hooks.user_defines.sqlite3.source: sqlite3mc`
> （SQLite3MultipleCiphers）。国内网络可配置
> `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`、
> `PUB_HOSTED_URL=https://pub.flutter-io.cn` 镜像。
> 应用默认完全离线，全部功能免费，无任何付费/网络依赖。

## 项目结构

```
lib/
├── app/          # Riverpod 提供者、路由、金库会话与自动锁定
├── domain/       # 纯 Dart 领域层（金额、账本、债务、预测、analytics 稳健统计）
├── data/         # Drift 表、加密打开、仓储
├── security/     # CryptoSuite(sodium/纯Dart)、KeyManager、备份容器
├── services/     # 账务/统计/预测/导入/备份/智慧分析服务
└── ui/           # 锁屏、仪表盘、账户、流水、导入、预算、计划、目标、负债、月报、设置、3D 地球
assets/globe/     # 点阵大陆数据（Natural Earth，公有领域）
docs/             # 完整文档（见下）
test/             # 81 个验收测试
```

## 文档

| 文档 | 内容 |
|---|---|
| [01-产品需求与范围](docs/01-产品需求与范围.md) | 目标用户问题、功能范围、默认假设 |
| [02-开源调研与选型](docs/02-开源调研与选型.md) | Monekin/Firefly III/Actual 等结论、自建理由、许可证 |
| [03-系统架构](docs/03-系统架构.md) | 分层、依赖规则、关键流程 |
| [04-数据模型](docs/04-数据模型.md) | 表结构、系统账户、金额存储 |
| [05-账务口径与算法](docs/05-账务口径与算法.md) | 事件表、归因恒等式、预测公式、TWR/XIRR |
| [06-安全设计](docs/06-安全设计.md) | 威胁模型、密钥层级、MASVS 映射、已知限制 |
| [07-导入对账与去重](docs/07-导入对账与去重.md) | 流水线、指纹、幂等、转账配对 |
| [08-备份恢复与迁移](docs/08-备份恢复与迁移.md) | 容器格式、恢复流程、换机 |
| [09-测试与验收](docs/09-测试与验收.md) | 测试 ↔ 验收场景对照 |
| [10-路线图与开发指南](docs/10-路线图与开发指南.md) | 四阶段计划、开发规范 |
| [11-智慧分析算法](docs/11-智慧分析算法.md) | 配速/周期识别/MAD 异常/Theil-Sen/规则引擎/XIRR 口径 |
| [12-共享组件与工具库](docs/12-共享组件与工具库.md) | 设计令牌、组件索引、provider 复用地图、弹层速查 |

另有 [CHANGELOG](CHANGELOG.md)、[贡献指南](CONTRIBUTING.md)、[安全策略](SECURITY.md)。

## 已知限制（v0.2）

- 微信/支付宝解析器为通用模板实现，需按真实脱敏样本校准列映射（见 docs/07）。
- 多币种归因中，流量按期末汇率折算，汇兑影响与残余差额合并披露（docs/05 §4）。
- sodium 套件（Argon2id）已实现但默认未启用，待各平台原生构建验证后切换（docs/06 §6）。
- 同步/多设备为阶段 3 目标，当前单机（docs/10）；移动端生物识别解锁在路线图。

## 参与贡献

见 [CONTRIBUTING.md](CONTRIBUTING.md)（开发铁律：金额 BigInt、过账走 TxBuilders、
测试先行、analyze 零 issue 门禁）。欢迎 Issue 与 PR。

## 致谢

- [Natural Earth](https://www.naturalearthdata.com/)（公有领域）：3D 地球海岸线数据。
- 上游依赖均为宽松许可证（MIT/BSD-3/Apache-2.0），明细见 [docs/02](docs/02-开源调研与选型.md)。

## 许可证

[MIT](LICENSE) © 2026 BruceChu0424 与资观贡献者。
