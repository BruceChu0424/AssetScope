# 资观字体方案（2026-10-30 调研选定）

墨蓝香槟金「私人财富终端」的字体系统：中文、英文、数字各司其职。
全部 **SIL OFL 1.1** 开源许可，个人与非商业、乃至商业用途均完全免费，可自由分发。

| 角色 | 字体 | 文件 | 说明 |
|---|---|---|---|
| 中文 | 思源黑体 Noto Sans SC | `NotoSansSC-VF.ttf` | 可变字重 100–900 单文件；30,890 字形；界面与正文 |
| 中文备选 | 思源宋体 Noto Serif SC | `NotoSerifSC-VF.ttf` | 可变字重 200–900；只建议用于里程碑/年度盘点类大标题 |
| 英文 | Space Grotesk | `SpaceGrotesk-VF.ttf` | 可变字重 300–700；品牌字标与英文导览；自带 tnum 等宽数字 |
| 数字 | IBM Plex Mono | `IBMPlexMono-{Regular,Medium,SemiBold,Bold}.ttf` | 等宽=金额天然对齐；¥、↑↓、−、% 等财务字符全覆盖 |

来源：google/fonts 仓库（raw.githubusercontent.com/google/fonts/main/...），下载于 2026-10-30。

## 选型理由（对齐 app_theme.dart 的「私人银行质感 · 数字优先」）

- **思源黑体**：Adobe×Google 十年打磨的中文标杆。字重最全，Black 900 配香槟金做标题极有力量，
  Regular 在蓝碳暗底小字号下笔画均匀清晰；骨架中性偏现代，与几何感的 Space Grotesk 灰度协调。
  可变字重一个文件替代九个静态文件，Flutter 中 `FontWeight` 直接映射 wght 轴。
- **Space Grotesk**：太空时代几何骨架 + 微怪细节，名字与气质都贴「地球指挥舱」；fintech 常用面孔，
  辨识度远高于 Inter/Roboto 一类默认选择。
- **IBM Plex Mono**：「财富终端」的仪表盘数字。等宽让资产列表、变动的金额天然对齐；
  IBM 金融计算的血统，字形在等宽体里最具工艺感，冷峻中带人文温度，与香槟金相衬。
- 备选说明：MiSans / HarmonyOS Sans 更「消费电子」，阿里普惠体偏「商务亲和」，都不如思源系配私人银行调性；
  霞鹜文楷美在书卷气，与终端感相悖。思源宋体保留为大标题备选。

## 接入方法（已于 2026-10-30 接入）

pubspec 已声明四个字体家族；主题层已设置 `fontFamily: SpaceGrotesk` +
`fontFamilyFallback: [NotoSansSC, IBMPlexMono]`（逐字符回落：拉丁/数字走
Grotesk、中文走思源黑体）；`MoneyText`（全应用金额唯一入口）已挂 IBM Plex Mono。

```yaml
flutter:
  fonts:
    - family: NotoSansSC        # 思源黑体（可变字重）
      fonts:
        - asset: assets/fonts/NotoSansSC-VF.ttf
    - family: SpaceGrotesk
      fonts:
        - asset: assets/fonts/SpaceGrotesk-VF.ttf
    - family: IBMPlexMono
      fonts:
        - asset: assets/fonts/IBMPlexMono-Regular.ttf
          weight: 400
        - asset: assets/fonts/IBMPlexMono-Medium.ttf
          weight: 500
        - asset: assets/fonts/IBMPlexMono-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/IBMPlexMono-Bold.ttf
          weight: 700
```

主题层（buildAppTheme）建议：

```dart
fontFamily: 'SpaceGrotesk',
fontFamilyFallback: ['NotoSansSC', 'IBMPlexMono'], // 英文优先，汉字回落思源黑体
```

- 金额/百分比数字：`TextStyle(fontFamily: 'IBMPlexMono')`（可封装 AppTypography.num）。
- 货币符号用半角 `¥`（U+00A5，Plex/Grotesk 均内含）；全角 `￥` 会回落到中文字体，宽度突兀。
- 可变字重文件在 Flutter 中直接用 `FontWeight.w300~w900` 取值，无需逐字重声明；
  思源宋体如启用，建议只挂在大标题组件上，不进全局 fontFamilyFallback。
