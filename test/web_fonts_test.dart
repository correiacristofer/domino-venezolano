// The web version serves its emoji and symbol fonts from web/gfonts/ instead
// of Google Fonts (see web/gfonts/README.md). The engine asks for those files
// by exact path and version, so after a Flutter upgrade the mirror can go
// stale: emoji would turn into empty boxes. This test compares the mirror with
// the paths the installed engine requests.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fallback fonts mirrored in web/gfonts/. Other scripts (CJK, etc.) are not
/// served on purpose.
final _mirrored = RegExp(
  r"'((?:notocoloremoji|notosanssymbols2?|notosansmath)/v\d+/[\w.-]+\.woff2)'",
);

File? _engineFallbackData() {
  final dartSdkBin = File(Platform.resolvedExecutable).parent;
  final roots = [
    if (Platform.environment['FLUTTER_ROOT'] case final root?) root,
    // <flutter>/bin/cache/dart-sdk/bin/dart
    dartSdkBin.parent.parent.parent.parent.path,
  ];
  for (final root in roots) {
    final file = File(
      '$root/engine/src/flutter/lib/web_ui/lib/src/engine/'
      'font_fallback_data.dart',
    );
    if (file.existsSync()) return file;
  }
  return null;
}

void main() {
  test('the web bootstrap points the engine at the local font mirror', () {
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();
    expect(bootstrap, contains('fontFallbackBaseUrl: "gfonts/"'));
  });

  test('every emoji and symbol font the engine requests is mirrored', () {
    final data = _engineFallbackData();
    if (data == null) {
      markTestSkipped('Engine sources not found in this Flutter SDK.');
      return;
    }
    final requested = _mirrored
        .allMatches(data.readAsStringSync())
        .map((m) => m.group(1)!)
        .toSet();
    expect(requested, isNotEmpty, reason: 'font list format changed');

    final missing = requested
        .where((path) => !File('web/gfonts/$path').existsSync())
        .toList()
      ..sort();
    expect(
      missing,
      isEmpty,
      reason: 'Download each path from https://fonts.gstatic.com/s/<path> '
          'into web/gfonts/ (see web/gfonts/README.md).',
    );
  });
}
