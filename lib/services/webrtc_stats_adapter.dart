import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/clutch_core_service.dart';

/// Adattatore che raccoglie e traduce le statistiche WebRTC reali.
/// Compatibile con flutter_webrtc 0.9.48+ (getStats -> List<StatsReport>)
class WebRTCStatsAdapter {
  /// Mappa: userId -> RTCPeerConnection (fornita dal motore vocale)
  Map<String, RTCPeerConnection> peerConns = {};

  void setPeerConnections(Map<String, RTCPeerConnection> map) {
    peerConns = map;
  }

  Future<List<PeerNetSnapshot>> readAll(Map<String, VibeUser> peers) async {
    final now = DateTime.now();
    final out = <PeerNetSnapshot>[];

    for (final entry in peerConns.entries) {
      final userId = entry.key;
      final pc = entry.value;
      final user = peers[userId];
      if (user == null) continue;

      // Ottieni la lista di StatsReport
      final List<StatsReport> reports = await pc.getStats();

      int pingMs = 0;
      double lossPct = 0;
      int jitterMs = 0;
      int voiceLatencyMs = 0;

      // Analizza tutti i report
      for (final stat in reports) {
        final type = stat.type;
        final values = stat.values; // Map<String, dynamic>

        if (type == 'transport' && values.containsKey('rtt')) {
          final rttSec = values['rtt'];
          if (rttSec is num) {
            pingMs = (rttSec * 1000).round();
            voiceLatencyMs = pingMs;
          }
        }

        if (type == 'remote-inbound-rtp' || type == 'inbound-rtp') {
          final j = values['jitter'];
          if (j is num) {
            jitterMs = (j * 1000).round();
          }
        }
      }

      // Packet loss
      int? packetsLost;
      int? packetsReceived;
      for (final stat in reports) {
        final values = stat.values;
        if (stat.type == 'remote-inbound-rtp' || stat.type == 'inbound-rtp') {
          final pl = values['packetsLost'];
          final pr = values['packetsReceived'];
          if (pl is num) packetsLost = pl.toInt();
          if (pr is num) packetsReceived = pr.toInt();
        }
      }

      if (packetsLost != null && packetsReceived != null && (packetsReceived + packetsLost) > 0) {
        lossPct = (packetsLost! / (packetsReceived! + packetsLost!)) * 100.0;
      }

      // Calcola score sintetico
      var score = 100;
      score -= ((pingMs - 20) / 2).clamp(0, 50).toInt();
      score -= (lossPct * 10).clamp(0, 30).toInt();
      score -= ((jitterMs - 5) * 1.2).clamp(0, 20).toInt();
      score = score.clamp(0, 100);

      out.add(
        PeerNetSnapshot(
          user: user,
          stats: NetStats(
            pingMs: pingMs,
            packetLossPct: double.parse(lossPct.toStringAsFixed(2)),
            jitterMs: jitterMs,
            voiceLatencyMs: voiceLatencyMs,
            connectionScore: score,
            ts: now,
          ),
        ),
      );
    }

    return out;
  }
}
