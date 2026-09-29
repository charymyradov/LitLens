import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class LzLogo extends StatelessWidget {
  const LzLogo({super.key, this.size = 26});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _LogoPainter()),
  );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 26.0;
    canvas.drawCircle(
      const Offset(12, 13) * s,
      10 * s,
      Paint()
        ..color = LzColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * s,
    );
    canvas.drawCircle(
      const Offset(16, 10) * s,
      3.2 * s,
      Paint()..color = LzColors.terracotta,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class UmbraMark extends StatelessWidget {
  const UmbraMark({super.key, this.size = 28, this.bg = LzColors.dark});
  final double size;
  final Color bg;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _UmbraPainter(bg)),
  );
}

class _UmbraPainter extends CustomPainter {
  _UmbraPainter(this.bg);
  final Color bg;
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 28.0;
    canvas.drawCircle(
      const Offset(14, 14) * s,
      12 * s,
      Paint()..color = LzColors.creamWarm,
    );
    canvas.drawCircle(const Offset(16.5, 12) * s, 11 * s, Paint()..color = bg);
  }

  @override
  bool shouldRepaint(_UmbraPainter old) => old.bg != bg;
}
