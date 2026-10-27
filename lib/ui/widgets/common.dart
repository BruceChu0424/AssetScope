/// 资观共享 UI 库（桶文件）。
///
/// 各组件的职责与用法详见 docs/12-共享组件与工具库.md。
/// 页面只应从这里 import，不要深入子文件。
library;

export 'fields_and_badges.dart'
    show
        DeltaBadge,
        EmptyState,
        ErrorPlaceholder,
        dateToday,
        AppAmountField,
        AppDateField,
        confirmDialog;
export 'money_text.dart' show MoneyText, MoneySize, fmtMinor;
export 'rational_display.dart' show RationalDisplayX;
export 'section_card.dart' show SectionCard, StatRow, AmountTile;
