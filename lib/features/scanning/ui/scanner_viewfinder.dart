import 'package:flutter/material.dart';

/// El recuadro donde hay que poner la etiqueta.
///
/// No recorta nada: `mobile_scanner` lee el cuadro entero y un código fuera del
/// recuadro también se detecta. Es una instrucción, no una restricción — sirve
/// para que alguien sepa a qué distancia ponerse y dónde mirar, que es lo que
/// falta cuando la pantalla es una imagen de cámara sin nada encima.
///
/// Oscurecer alrededor tiene el mismo propósito y un efecto extra: con la
/// pantalla a pantalla completa, el texto blanco de arriba y de abajo se lee
/// sobre cualquier cosa que esté enfocando la cámara.
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

    // El velo se pinta entero y se recorta el hueco: `difference` deja el
    // interior del recuadro sin oscurecer sin necesidad de componer cuatro
    // rectángulos alrededor, que es donde aparecen las costuras de un píxel.
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

    // Solo las esquinas: un marco cerrado se lee como un borde de la imagen y
    // deja de señalar el centro.
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
