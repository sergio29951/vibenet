import 'package:flutter/material.dart';

class EnergyTransition extends StatefulWidget {
  final Color startColor;
  final Color endColor;
  const EnergyTransition({super.key, required this.startColor, required this.endColor});
  @override
  State<EnergyTransition> createState() => _EnergyTransitionState();
}

class _EnergyTransitionState extends State<EnergyTransition> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final p = Curves.easeOutCubic.transform(_c.value);
        final r = size.longestSide * p * 1.2;
        final flash = (p > 0.45 && p < 0.55) ? (1 - ((p - 0.5).abs() * 18)) : 0.0;
        return Stack(
          children: [
            Center(
              child: Container(
                width: r, height: r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.startColor.withOpacity(0.85),
                      widget.endColor.withOpacity(0.38),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            if (flash > 0) Container(color: Colors.white.withOpacity(flash * 0.35)),
          ],
        );
      },
    );
  }
}
