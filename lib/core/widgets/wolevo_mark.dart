import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The Wolevo mark as vector geometry.
///
/// The supplied artwork is a raster in which the mark is only 143x129px, which
/// would blur at splash sizes, so the outline was traced once (see
/// `tool/generate_brand_assets.py`, which rasterises the same coordinates for
/// the native launch screen) and is drawn as a path here. Same source of truth,
/// so the OS splash and the in-app animation cannot drift apart.
abstract final class WolevoMarkGeometry {
  /// Mark bounding box in the traced coordinate space.
  static const double sourceWidth = 143;
  static const double sourceHeight = 129;

  /// Aspect ratio, for laying the mark out at any width.
  static const double aspectRatio = sourceWidth / sourceHeight;

  /// Outline of the three slanted bars, in source coordinates offset so the
  /// bounding box starts at (0, 0).
  static const List<Offset> wOutline = [
    Offset(34, 0), Offset(40, 2), Offset(40, 39), Offset(9, 70),
    Offset(10, 78), Offset(82, 6), Offset(88, 7), Offset(87, 46),
    Offset(63, 70), Offset(64, 78), Offset(136, 6), Offset(142, 7),
    Offset(141, 47), Offset(62, 126), Offset(56, 127), Offset(54, 125),
    Offset(53, 80), Offset(6, 127), Offset(2, 127), Offset(0, 125),
    Offset(0, 34),
  ];

  static const Offset dotCentre = Offset(122, 111);
  static const double dotRadius = 17.5;

  /// The W outline scaled to fill [size].
  static Path wPath(Size size) {
    final sx = size.width / sourceWidth;
    final sy = size.height / sourceHeight;
    final path = Path()..moveTo(wOutline.first.dx * sx, wOutline.first.dy * sy);
    for (final point in wOutline.skip(1)) {
      path.lineTo(point.dx * sx, point.dy * sy);
    }
    return path..close();
  }

  static Rect dotRect(Size size, {double scale = 1}) {
    final sx = size.width / sourceWidth;
    final sy = size.height / sourceHeight;
    return Rect.fromCircle(
      center: Offset(dotCentre.dx * sx, dotCentre.dy * sy),
      radius: dotRadius * sx * scale,
    );
  }
}

/// Static mark, sized by its parent's width.
class WolevoMark extends StatelessWidget {
  const WolevoMark({
    super.key,
    this.width = 96,
    this.color = AppColors.primary,
  });

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width / WolevoMarkGeometry.aspectRatio,
      child: CustomPaint(painter: _MarkPainter(color: color)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    canvas.drawPath(WolevoMarkGeometry.wPath(size), paint);
    canvas.drawOval(WolevoMarkGeometry.dotRect(size), paint);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.color != color;
}

/// The mark, revealed by a diagonal wipe that runs along the direction of the
/// strokes, with the dot popping in behind it.
///
/// [wipe] and [dot] are 0..1 progress values so the splash can drive them from
/// one controller.
class AnimatedWolevoMark extends StatelessWidget {
  const AnimatedWolevoMark({
    super.key,
    required this.width,
    required this.wipe,
    required this.dot,
    this.color = AppColors.primary,
  });

  final double width;
  final double wipe;
  final double dot;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width / WolevoMarkGeometry.aspectRatio,
      child: CustomPaint(
        painter: _AnimatedMarkPainter(color: color, wipe: wipe, dot: dot),
      ),
    );
  }
}

class _AnimatedMarkPainter extends CustomPainter {
  const _AnimatedMarkPainter({
    required this.color,
    required this.wipe,
    required this.dot,
  });

  final Color color;
  final double wipe;
  final double dot;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    if (wipe > 0) {
      canvas.save();
      // A slanted clip matching the ~40° stroke angle, swept left to right, so
      // the bars appear to be drawn rather than simply faded in.
      final slant = size.height * 0.85;
      final edge = (size.width + slant) * wipe;
      canvas.clipPath(
        Path()
          ..moveTo(-slant, 0)
          ..lineTo(edge, 0)
          ..lineTo(edge - slant, size.height)
          ..lineTo(-slant * 2, size.height)
          ..close(),
      );
      canvas.drawPath(WolevoMarkGeometry.wPath(size), paint);
      canvas.restore();
    }

    if (dot > 0) {
      canvas.drawOval(WolevoMarkGeometry.dotRect(size, scale: dot), paint);
    }
  }

  @override
  bool shouldRepaint(_AnimatedMarkPainter old) =>
      old.wipe != wipe || old.dot != dot || old.color != color;
}
