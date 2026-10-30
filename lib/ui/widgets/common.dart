/// 资观共享 UI 库（桶文件）。
///
/// 各组件的职责与用法详见 docs/12-共享组件与工具库.md。
/// 页面只应从这里 import，不要深入子文件。
library;

export 'brand_logo.dart' show BrandMark, BrandLockup;
export 'busy_overlay.dart' show runBusy, OrbitSpinner, BusyHost, BusyReveal;
export 'dialog_dissolve.dart' show DissolveController, DissolveCapture;
export 'fields_and_badges.dart'
    show
        DeltaBadge,
        EmptyState,
        ErrorPlaceholder,
        dateToday,
        AppAmountField,
        AppDateField,
        confirmDialog;
export 'hero_grow.dart' show HeroLaunch, HeroGrow;
export 'money_text.dart' show MoneyText, MoneySize, fmtMinor;
export 'odometer.dart' show Odometer;
export 'page_frame.dart'
    show PageFrame, PageMeasure, StatBand, StatBandItem, CardWrap, InfoHint;
export 'page_kit.dart'
    show ActionIcon, ListRow, ProgressMeter, RingProgress, DayHeader;
export 'particle_edge.dart' show ParticleEdge;
export 'particle_interactive.dart' show ParticleFilledButton, ParticleTextField;
export 'particle_logo.dart' show ParticleBrandMark;
export 'rational_display.dart' show RationalDisplayX;
export 'section_card.dart' show SectionCard, StatRow, AmountTile;
export 'top_notice.dart' show showTopNotice, TopNoticeTone;
