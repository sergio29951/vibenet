import 'dart:math';
import 'package:flutter/material.dart';

class ChatMessage {
  final String user;
  final String text;
  final int ts;
  final Color color;
  final double seed;
  ChatMessage({
    required this.user,
    required this.text,
    required this.ts,
    required this.color,
  }) : seed = Random().nextDouble() * pi * 2;
}

Color colorFromName(String name) {
  final hash = name.codeUnits.fold<int>(0, (p, c) => (p * 31 + c) & 0x7fffffff);
  final hue = (hash % 360).toDouble();
  return HSVColor.fromAHSV(1, hue, 0.65, 0.85).toColor();
}
