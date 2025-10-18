import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => setState(() => _t = e.inMilliseconds / 1000))
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return CustomPaint(
      size: size,
      painter: _AuroraPainter(t: _t),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  _AuroraPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.plus;

    // sfondo gradiente di base
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0C0019),
        const Color(0xFF090015),
        const Color(0xFF080012),
        const Color(0xFF0A0020),
      ],
    );
    final rect = Offset.zero & size;
    paint.shader = bgGradient.createShader(rect);
    canvas.drawRect(rect, paint);

    final blobs = [
      _Blob(Colors.purpleAccent.withOpacity(0.22), 320, 0.9, 1.0),
      _Blob(Colors.blueAccent.withOpacity(0.24), 260, 1.2, 1.6),
      _Blob(Colors.pinkAccent.withOpacity(0.18), 280, 0.8, 0.7),
      _Blob(Colors.cyanAccent.withOpacity(0.16), 300, 1.1, 1.4),
      _Blob(Colors.deepPurpleAccent.withOpacity(0.25), 220, 0.6, 1.8),
      _Blob(Colors.lightBlueAccent.withOpacity(0.15), 360, 0.5, 0.9),
    ];

    for (int i = 0; i < blobs.length; i++) {
      final b = blobs[i];
      final x = size.width * (0.5 + sin(t * b.speed * 0.3 + i) * 0.4);
      final y = size.height * (0.5 + cos(t * b.speed * 0.4 + i) * 0.3);

      final radial = RadialGradient(
        colors: [
          b.color.withOpacity(0.8),
          b.color.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      paint.shader = radial.createShader(Rect.fromCircle(center: Offset(x, y), radius: b.radius));
      canvas.drawCircle(Offset(x, y), b.radius, paint);
    }

    // aggiunta "nebbiolina" soft (leggera luce diffusa)
    final fog = RadialGradient(
      colors: [
        Colors.white.withOpacity(0.06),
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    );
    paint.shader = fog.createShader(Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.4),
      radius: size.width * 0.9,
    ));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), size.width * 0.9, paint);
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) => true;
}

class _Blob {
  final Color color;
  final double radius;
  final double speed;
  final double amp;

  _Blob(this.color, this.radius, this.speed, this.amp);
}
