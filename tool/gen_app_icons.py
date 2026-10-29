#!/usr/bin/env python3
"""从品牌标生成 Android / iOS / Windows 启动图标。

源资产（换 logo 后重跑本脚本即可）：
  assets/logo/mark_light.png  绿色 A 标（透明底）
  assets/logo/mark_dark.png   白色 A 标（透明底）

产出：
  Android  legacy 圆形图标（mipmap-*/ic_launcher.png）
           自适应图标前景（mipmap-*/ic_launcher_foreground.png）
           + mipmap-anydpi-v26/ic_launcher.xml + values/ic_launcher_background.xml
  iOS      AppIcon 全套（品牌绿底 + 白标，去 alpha）
  Windows  runner/resources/app_icon.ico（多尺寸）

用法：python tool/gen_app_icons.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
LOGO = ROOT / 'assets' / 'logo'
ANDROID_RES = ROOT / 'android' / 'app' / 'src' / 'main' / 'res'
IOS_APPICON = ROOT / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset'
WIN_ICO = ROOT / 'windows' / 'runner' / 'resources' / 'app_icon.ico'

BRAND_GREEN = (8, 127, 107, 255)  # #087F6B


def composite_on_green(mark: Image.Image, size: int, inner: float = 1.0) -> Image.Image:
    """不透明品牌绿底图标：mark 等比缩到 size*inner 后居中贴合。"""
    img = Image.new('RGBA', (size, size), BRAND_GREEN)
    s = max(1, round(size * inner))
    m = mark.resize((s, s), Image.LANCZOS)
    img.alpha_composite(m, ((size - s) // 2, (size - s) // 2))
    return img


def main() -> None:
    mark_green = Image.open(LOGO / 'mark_light.png').convert('RGBA')
    mark_white = Image.open(LOGO / 'mark_dark.png').convert('RGBA')

    # Android legacy：圆形品牌绿底 + 白标（旧系统直接展示此形状）。
    for dpi, s in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                   ('xxhdpi', 144), ('xxxhdpi', 192)]:
        img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ImageDraw.Draw(img).ellipse((0, 0, s - 1, s - 1), fill=BRAND_GREEN)
        img.alpha_composite(mark_white.resize((s, s), Image.LANCZOS))
        img.save(ANDROID_RES / f'mipmap-{dpi}' / 'ic_launcher.png')

    # Android 自适应：前景白标缩至 78%（可见区约为中心 66%，图形留足安全边）。
    for dpi, s in [('mdpi', 108), ('hdpi', 162), ('xhdpi', 216),
                   ('xxhdpi', 324), ('xxxhdpi', 432)]:
        fg = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        inner = max(1, round(s * 0.78))
        m = mark_white.resize((inner, inner), Image.LANCZOS)
        fg.alpha_composite(m, ((s - inner) // 2, (s - inner) // 2))
        fg.save(ANDROID_RES / f'mipmap-{dpi}' / 'ic_launcher_foreground.png')

    anydpi = ANDROID_RES / 'mipmap-anydpi-v26'
    anydpi.mkdir(exist_ok=True)
    (anydpi / 'ic_launcher.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n', encoding='utf-8')
    (ANDROID_RES / 'values' / 'ic_launcher_background.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        '    <color name="ic_launcher_background">#087F6B</color>\n'
        '</resources>\n', encoding='utf-8')

    # iOS：不透明品牌绿底 + 白标（App Store 禁 alpha）。
    for name, s in [
        ('Icon-App-20x20@1x.png', 20), ('Icon-App-20x20@2x.png', 40),
        ('Icon-App-20x20@3x.png', 60), ('Icon-App-29x29@1x.png', 29),
        ('Icon-App-29x29@2x.png', 58), ('Icon-App-29x29@3x.png', 87),
        ('Icon-App-40x40@1x.png', 40), ('Icon-App-40x40@2x.png', 80),
        ('Icon-App-40x40@3x.png', 120), ('Icon-App-60x60@2x.png', 120),
        ('Icon-App-60x60@3x.png', 180), ('Icon-App-76x76@1x.png', 76),
        ('Icon-App-76x76@2x.png', 152), ('Icon-App-83.5x83.5@2x.png', 167),
        ('Icon-App-1024x1024@1x.png', 1024),
    ]:
        composite_on_green(mark_white, s).convert('RGB').save(IOS_APPICON / name)

    # Windows：多尺寸 ico。
    composite_on_green(mark_white, 256).save(
        WIN_ICO, sizes=[(16, 16), (24, 24), (32, 32), (48, 48),
                        (64, 64), (128, 128), (256, 256)])
    print('完成：Android legacy 圆标 + 自适应前景/背景色、iOS AppIcon 全套（绿底白标）、Windows app_icon.ico')


if __name__ == '__main__':
    main()
