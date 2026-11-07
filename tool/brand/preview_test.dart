// Quick look at the mark while tweaking it:
//   flutter test tool/brand/preview_test.dart
// Writes build/brand_preview.png (ignored by git).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'brand_mark.dart';
import 'render_helpers.dart';

void main() {
  testWidgets('preview', (tester) async {
    await renderPng(
      tester,
      const CustomPaint(painter: BrandMarkPainter(contentScale: 0.95)),
      const Size.square(768),
      'build/brand_preview.png',
    );
  });
}
