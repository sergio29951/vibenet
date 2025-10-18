import 'package:flutter/material.dart';

class RoomTile3D extends StatelessWidget {
  final String title;
  final List<Color> colors;
  final IconData centerIcon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const RoomTile3D({
    super.key,
    required this.title,
    required this.colors,
    required this.centerIcon,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ombra interna per effetto 3D
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.transparent
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(centerIcon, color: Colors.white, size: 38),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(1, 1))
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
