import 'package:flutter/material.dart';

/// Shape painted behind the mark. Each store and launcher wants a different
/// one: iOS and Play mask a full-bleed square themselves, Android adaptive
/// icons need a transparent foreground, legacy launchers a rounded square.
enum BrandBackground { square, roundedSquare, circle, none }

/// The app mark: a "cochina" (double six) wrapped by a ribbon in the colours
/// of the Venezuelan flag, on black. Drawn as vectors on a 1024 grid so every
/// icon size is rendered sharp instead of scaled from a small bitmap.
class BrandMarkPainter extends CustomPainter {
  final BrandBackground background;

  /// Fraction of the canvas the 1024 design occupies.
  final double contentScale;

  const BrandMarkPainter({
    this.background = BrandBackground.square,
    this.contentScale = 1,
  });

  static const black = Color(0xFF000000);
  static const yellow = Color(0xFFFFCC00);
  static const blue = Color(0xFF00247D);
  static const red = Color(0xFFCF142B);
  static const tileWhite = Color(0xFFFFFFFF);

  // Tile geometry on the 1024 grid.
  static const _tile = Rect.fromLTRB(320, 153, 707, 867);
  static const _pipRadius = 37.0;
  static const _pipColumns = [413.0, 614.0];
  static const _topRows = [248.0, 341.0, 434.0];
  static const _bottomRows = [594.0, 687.0, 780.0];

  // Ribbon stripes across the band: yellow, blue, red (outer to inner).
  static const _stripes = [
    (0.0, 0.42, yellow),
    (0.42, 0.58, blue),
    (0.58, 1.0, red),
  ];

  // Back arc, hidden behind the tile on its way round.
  static const _backOuter = [
    [Offset(560, 300), Offset(380, 215), Offset(150, 300), Offset(118, 440)],
  ];
  static const _backInner = [
    [Offset(560, 420), Offset(420, 350), Offset(240, 400), Offset(200, 505)],
  ];

  // Front sweep: starts where the back arc ends (the ribbon folds over
  // there), crosses the lower-left of the tile, passes under its base and
  // tapers into a tail on the right.
  static const _frontTop = [
    [Offset(118, 440), Offset(240, 560), Offset(390, 760), Offset(560, 900)],
    [Offset(560, 900), Offset(700, 975), Offset(830, 780), Offset(895, 600)],
  ];
  static const _frontBottom = [
    [Offset(200, 505), Offset(150, 640), Offset(340, 930), Offset(560, 985)],
    [Offset(560, 985), Offset(790, 1040), Offset(875, 800), Offset(895, 600)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1024, size.height / 1024);

    final bg = Paint()..color = black;
    switch (background) {
      case BrandBackground.square:
        canvas.drawRect(const Rect.fromLTWH(0, 0, 1024, 1024), bg);
      case BrandBackground.roundedSquare:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 1024, 1024),
            const Radius.circular(184),
          ),
          bg,
        );
      case BrandBackground.circle:
        canvas.drawCircle(const Offset(512, 512), 512, bg);
      case BrandBackground.none:
        break;
    }

    canvas.translate(512, 512);
    canvas.scale(contentScale);
    canvas.translate(-512, -512);

    _band(canvas, _backOuter, _backInner);
    // The whole front sweep is laid down behind the tile first, so the part
    // that wraps behind its right side stays hidden...
    _band(canvas, _frontTop, _frontBottom);
    _drawTile(canvas);
    // ...then the lower-left crossing is painted again on top of it.
    canvas.save();
    canvas.clipPath(
      Path()
        ..addRect(const Rect.fromLTRB(-200, -200, 640, 1300))
        ..addRect(const Rect.fromLTRB(-200, 867, 1300, 1300)),
    );
    _band(canvas, _frontTop, _frontBottom);
    canvas.restore();

    canvas.restore();
  }

  void _drawTile(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(_tile, const Radius.circular(34)),
      Paint()..color = tileWhite,
    );
    final ink = Paint()..color = black;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(352, 504, 675, 518),
        const Radius.circular(7),
      ),
      ink,
    );
    for (final rows in [_topRows, _bottomRows]) {
      for (final y in rows) {
        for (final x in _pipColumns) {
          canvas.drawCircle(Offset(x, y), _pipRadius, ink);
        }
      }
    }
  }

  /// Fills each stripe between two edges made of matching cubic segments.
  /// Intermediate curves are interpolated control point by control point.
  void _band(
    Canvas canvas,
    List<List<Offset>> edgeA,
    List<List<Offset>> edgeB,
  ) {
    List<Offset> lerpSegment(int i, double t) => [
          for (var k = 0; k < 4; k++) Offset.lerp(edgeA[i][k], edgeB[i][k], t)!,
        ];

    for (final (from, to, color) in _stripes) {
      final path = Path();
      final a = [for (var i = 0; i < edgeA.length; i++) lerpSegment(i, from)];
      final b = [for (var i = 0; i < edgeA.length; i++) lerpSegment(i, to)];

      path.moveTo(a.first[0].dx, a.first[0].dy);
      for (final seg in a) {
        path.cubicTo(
            seg[1].dx, seg[1].dy, seg[2].dx, seg[2].dy, seg[3].dx, seg[3].dy);
      }
      final last = b.last[3];
      path.lineTo(last.dx, last.dy);
      for (final seg in b.reversed) {
        path.cubicTo(
            seg[2].dx, seg[2].dy, seg[1].dx, seg[1].dy, seg[0].dx, seg[0].dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(BrandMarkPainter oldDelegate) =>
      oldDelegate.background != background ||
      oldDelegate.contentScale != contentScale;
}
