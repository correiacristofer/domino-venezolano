import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads Roboto and Material Icons from the Flutter SDK so rendered text and
/// icons look like the real app instead of the test font's boxes.
Future<void> loadAppFonts() async {
  // flutter_tester lives in <sdk>/bin/cache/artifacts/engine/<platform>/.
  final sdk = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
  final fonts = '$sdk/bin/cache/artifacts/material_fonts';

  final roboto = FontLoader('Roboto');
  for (final weight in ['regular', 'medium', 'bold', 'black', 'italic']) {
    final file = File('$fonts/roboto-$weight.ttf');
    if (file.existsSync()) {
      roboto.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
  }
  await roboto.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(
        File('$fonts/materialicons-regular.otf').readAsBytesSync())));
  await icons.load();
}

/// Sets the test surface to [size] logical pixels at [pixelRatio].
void setSurface(WidgetTester tester, Size size, {double pixelRatio = 1}) {
  tester.view.physicalSize = size * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
}

/// Writes what is currently painted under [key] as PNG to [path].
Future<void> capturePng(
  WidgetTester tester,
  GlobalKey key,
  String path, {
  double pixelRatio = 1,
}) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

/// Renders a static [child] at exactly [size] logical pixels and writes it
/// as PNG to [path].
Future<void> renderPng(
  WidgetTester tester,
  Widget child,
  Size size,
  String path, {
  double pixelRatio = 1,
}) async {
  setSurface(tester, size, pixelRatio: pixelRatio);
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: SizedBox.fromSize(size: size, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await capturePng(tester, key, path, pixelRatio: pixelRatio);
}
