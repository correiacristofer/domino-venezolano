// Renders every icon and store graphic from the vector mark.
//
//   flutter test tool/brand/render_brand_assets_test.dart
//
// Writes straight into the platform folders and store/; commit the results.
// iOS icons must not carry an alpha channel; run tool/brand/flatten_ios_icons.ps1
// afterwards (needs ffmpeg) to strip it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'brand_mark.dart';
import 'render_helpers.dart';

Widget _mark(BrandBackground background, double scale) => CustomPaint(
      painter: BrandMarkPainter(background: background, contentScale: scale),
    );

const _android = 'android/app/src/main/res';
const _ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

void main() {
  testWidgets('icons', (tester) async {
    Future<void> icon(String path, double size, BrandBackground bg,
            double scale) =>
        renderPng(tester, _mark(bg, scale), Size.square(size), path);

    // Master and store icons.
    await icon('assets/icon/app_icon_1024.png', 1024,
        BrandBackground.square, 0.95);
    await icon('store/play/icon_512.png', 512, BrandBackground.square, 0.9);

    // iOS: full-bleed squares, the system applies the mask.
    const iosSizes = {
      'Icon-App-20x20@1x.png': 20.0,
      'Icon-App-20x20@2x.png': 40.0,
      'Icon-App-20x20@3x.png': 60.0,
      'Icon-App-29x29@1x.png': 29.0,
      'Icon-App-29x29@2x.png': 58.0,
      'Icon-App-29x29@3x.png': 87.0,
      'Icon-App-40x40@1x.png': 40.0,
      'Icon-App-40x40@2x.png': 80.0,
      'Icon-App-40x40@3x.png': 120.0,
      'Icon-App-60x60@2x.png': 120.0,
      'Icon-App-60x60@3x.png': 180.0,
      'Icon-App-76x76@1x.png': 76.0,
      'Icon-App-76x76@2x.png': 152.0,
      'Icon-App-83.5x83.5@2x.png': 167.0,
      'Icon-App-1024x1024@1x.png': 1024.0,
    };
    for (final entry in iosSizes.entries) {
      await icon('$_ios/${entry.key}', entry.value, BrandBackground.square,
          0.95);
    }

    // Android: legacy square and round icons, plus the adaptive foreground
    // (108dp canvas, content kept inside the 66dp safe circle).
    const densities = {
      'mdpi': 1.0,
      'hdpi': 1.5,
      'xhdpi': 2.0,
      'xxhdpi': 3.0,
      'xxxhdpi': 4.0,
    };
    for (final entry in densities.entries) {
      final dir = '$_android/mipmap-${entry.key}';
      await icon('$dir/ic_launcher.png', 48 * entry.value,
          BrandBackground.roundedSquare, 0.9);
      await icon('$dir/ic_launcher_round.png', 48 * entry.value,
          BrandBackground.circle, 0.8);
      await icon('$dir/ic_launcher_foreground.png', 108 * entry.value,
          BrandBackground.none, 0.62);
    }

    // Web / PWA. iOS masks the home screen icon itself, so it gets a
    // full-bleed square like the native app icon.
    await icon('web/icons/apple-touch-icon.png', 180, BrandBackground.square,
        0.95);
    await icon('web/favicon.png', 32, BrandBackground.roundedSquare, 0.9);
    await icon('web/icons/Icon-192.png', 192, BrandBackground.roundedSquare,
        0.9);
    await icon('web/icons/Icon-512.png', 512, BrandBackground.roundedSquare,
        0.9);
    await icon('web/icons/Icon-maskable-192.png', 192, BrandBackground.square,
        0.75);
    await icon('web/icons/Icon-maskable-512.png', 512, BrandBackground.square,
        0.75);
  });
}
