import 'package:flutter/material.dart';

/// The frame the label has to be placed in.
///
/// It crops nothing: `mobile_scanner` reads the whole frame and a code outside
/// the box is detected too. It is an instruction, not a restriction — it is
/// there so somebody knows how far away to stand and where to look, which is
/// what is missing when the screen is a camera image with nothing on it.
///
/// Darkening around it serves the same purpose and has an extra effect: with
/// the screen full of camera, the white text at the top and the bottom reads
/// over whatever the camera happens to be focused on.
class ScannerViewfinder extends StatelessWidget {
  const ScannerViewfinder({super.key, required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final side = constraints.biggest.shortestSide * 0.72;
      final square = Rect.fromCenter(
        center: constraints.biggest.center(Offset.zero),
        width: side,
        height: side,
      );

      return Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _ViewfinderPainter(square)),
          Positioned(
            top: square.bottom + 24,
            left: 32,
            right: 32,
            child: Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      );
    },
  );
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter(this.square);

  final Rect square;

  static const _radius = Radius.circular(18);
  static const _cornerLength = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(square, _radius);

    // The veil is painted whole and the gap is cut out: `difference` leaves the
    // inside of the frame undarkened without composing four rectangles around
    // it, which is where one-pixel seams show up.
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(hole),
      ),
    );
    canvas.drawColor(Colors.black.withValues(alpha: 0.55), BlendMode.srcOver);
    canvas.restore();

    final stroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // The corners only: a closed frame reads as a border of the image and stops
    // pointing at the centre.
    for (final (corner, dx, dy) in [
      (square.topLeft, 1.0, 1.0),
      (square.topRight, -1.0, 1.0),
      (square.bottomRight, -1.0, -1.0),
      (square.bottomLeft, 1.0, -1.0),
    ]) {
      canvas
        ..drawLine(
          corner.translate(0, dy * _radius.y),
          corner.translate(0, dy * _cornerLength),
          stroke,
        )
        ..drawLine(
          corner.translate(dx * _radius.x, 0),
          corner.translate(dx * _cornerLength, 0),
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) =>
      oldDelegate.square != square;
}
