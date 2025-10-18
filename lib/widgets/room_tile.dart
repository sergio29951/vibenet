import 'package:flutter/material.dart';

class RoomTile3D extends StatefulWidget {
  final String title;
  final List<Color> colors;
  final IconData centerIcon;
  final bool isPrivate;

  const RoomTile3D({
    super.key,
    required this.title,
    required this.colors,
    required this.centerIcon,
    required this.isPrivate,
  });

  @override
  State<RoomTile3D> createState() => _RoomTile3DState();
}

class _RoomTile3DState extends State<RoomTile3D> with SingleTickerProviderStateMixin {
  double _hover = 0;

  @override
  Widget build(BuildContext context) {
    final base = widget.colors.first;
    final end = widget.colors.last;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = 1),
      onExit: (_) => setState(() => _hover = 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color.lerp(base, Colors.black, 0.2)!, Color.lerp(end, Colors.black, 0.4)!],
          ),
          boxShadow: [
            BoxShadow(color: base.withOpacity(0.35 + 0.25 * _hover), blurRadius: 18 + 6 * _hover, spreadRadius: 1 + 1 * _hover, offset: const Offset(0, 6)),
          ],
          border: Border.all(color: Colors.white24, width: 1),
        ),
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            if (widget.isPrivate) const Positioned(top: 6, left: 6, child: Icon(Icons.lock, color: Colors.black, size: 24)),
            Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(widget.centerIcon, color: Colors.white.withOpacity(0.92 + 0.0 * _hover), size: 30),
                const SizedBox(height: 10),
                Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
