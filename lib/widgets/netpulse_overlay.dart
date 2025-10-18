import 'dart:async';
import 'package:flutter/material.dart';
import '../services/netpulse_firebase_service.dart';

/// HUD "NetPulseOverlay"
/// Mostra gli utenti connessi e i loro valori di rete in tempo reale.
/// LED superiore mostra lo stato medio della stanza (verde/giallo/rosso).
class NetPulseOverlay extends StatefulWidget {
  final Stream<List<NetPulseSnapshot>> snapshots$;

  const NetPulseOverlay({super.key, required this.snapshots$});

  @override
  State<NetPulseOverlay> createState() => _NetPulseOverlayState();
}

class _NetPulseOverlayState extends State<NetPulseOverlay> {
  late StreamSubscription _sub;
  List<NetPulseSnapshot> _snapshots = [];

  @override
  void initState() {
    super.initState();
    _sub = widget.snapshots$.listen((data) {
      if (mounted) setState(() => _snapshots = data);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Color _colorForPing(double ping) {
    if (ping <= 60) return Colors.greenAccent;
    if (ping <= 120) return Colors.amberAccent;
    return Colors.redAccent;
  }

  Color _ledColorForAverage() {
    if (_snapshots.isEmpty) return Colors.grey;
    final avgPing = _snapshots.map((s) => s.pingMs).reduce((a, b) => a + b) / _snapshots.length;
    return _colorForPing(avgPing);
  }

  @override
  Widget build(BuildContext context) {
    if (_snapshots.isEmpty) return const SizedBox.shrink();

    final ledColor = _ledColorForAverage();

    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 400),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.6), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: ledColor.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔵 LED barra superiore (media della stanza)
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: ledColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 Elenco utenti e metriche
            ..._snapshots.map((s) => _buildUserStat(s)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStat(NetPulseSnapshot snap) {
    final pingColor = _colorForPing(snap.pingMs);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Cerchio dinamico (colore in base al ping)
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pingColor,
              boxShadow: [
                BoxShadow(
                  color: pingColor.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Nome utente
          Expanded(
            child: Text(
              snap.username,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Ping value
          Text(
            '${snap.pingMs.toStringAsFixed(0)} ms',
            style: TextStyle(
              color: pingColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
