import 'dart:math';
import 'package:flutter/material.dart';

class AvatarGlow extends StatelessWidget {
  final String name;
  final Color color;
  final double t;

  const AvatarGlow({
    super.key,
    required this.name,
    required this.color,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final pulse = (sin(t * 1.5) + 1) / 2;
    final initials = name.isNotEmpty
        ? name.trim()[0].toUpperCase()
        : "?";

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.5 + pulse * 0.4),
            color.withOpacity(0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 12 + 8 * pulse,
            spreadRadius: 2 + 2 * pulse,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
