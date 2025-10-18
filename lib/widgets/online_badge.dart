import 'package:flutter/material.dart';

class OnlineBadge extends StatelessWidget {
  final int count;

  const OnlineBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueAccent, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: Colors.lightBlueAccent, size: 10),
          const SizedBox(width: 5),
          Text(
            "$count online",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
