# 贡献指南

感谢你考虑为资观 AssetScope 贡献！这是一个用爱发电的开源个人财务项目。

## 快速上手

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 生成 drift 代码
flutter analyze                                            # 必须零 issue
flutter test                                               # 全部通过
flutter run -d windows                                     # 或 android/ios
```

环境要求：Flutter 3.44+（stable）、Dart 3.12+。国内网络可配置
`FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn` 与
`PUB_HOSTED_URL=https://pub.flutter-io.cn` 镜像。

## 项目结构

```
lib/
├── app/       # Riverpod 提供者、路由、金库会话与自动锁定
├── domain/    # 纯 Dart 领域层（金额、账本、债务、预测、分析算法）——不得 import flutter/第三方
├── data/      # Drift 表、加密打开、仓储
├── security/  # CryptoSuite(sodium/纯Dart)、KeyManager、备份容器
├── services/  # 账务/统计/预测/导入/备份/智慧分析服务
└── ui/        # 页面与共享组件（见 docs/12）
```

依赖方向：domain ← data ← services ← app ← ui。PR 检查的第一条就是 domain 层纯净性。

## 开发铁律

1. **金额**：一律 `BigInt`（分）+ `Money`/`Rational`；出现 double 处理金额即 bug（展示层除外）。
2. **过账**：只经 `TxBuilders`；新增交易类型 = 新构造器 + docs/05 口径表更新 + 测试。
3. **测试先行**：新口径必须先有测试（红）再有实现（绿）；账务规则改动必须同步更新 docs/05。
4. **迁移**：改表 → `schemaVersion+1` + `MigrationStrategy` 升级路径 + 迁移测试。
5. **安全改动**：更新 docs/06 威胁模型与 MASVS 证据；密钥/口令永不写日志、示例与仓库。
6. **分析**：`flutter analyze` 零 issue 是合并门槛（CI 强制）。
7. **模块化**：单文件控制在 ~400 行内；可复用组件进 `lib/ui/widgets/`（见 docs/12 共享组件索引）。

## 提交流程

1. Fork → 分支（`feat/xxx` 或 `fix/xxx`）→ 开发 → 本地全绿。
2. 提交信息格式：`模块: 摘要`（例：`ledger: 卖出按平均成本结转`、`insight: 周期识别容忍月末差`）。
3. 开 PR 描述动机与测试证据；CI（analyze + test）通过后进入 review。

## 行为准则

保持友善与专业；对事不对人。财务数据处理涉及他人隐私，示例数据请使用虚构账目，
**绝不提交真实账单/流水截图**。
