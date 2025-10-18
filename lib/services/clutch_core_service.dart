import 'webrtc_stats_adapter.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

// =====================================================
//  MODELLO BASE
// =====================================================

class VibeUser {
  final String id;
  final String displayName;
  final String avatarUrl;
  const VibeUser({required this.id, required this.displayName, required this.avatarUrl});
}

class NetStats {
  final int pingMs;
  final double packetLossPct;
  final int jitterMs;
  final int voiceLatencyMs;
  final int connectionScore;
  final DateTime ts;

  const NetStats({
    required this.pingMs,
    required this.packetLossPct,
    required this.jitterMs,
    required this.voiceLatencyMs,
    required this.connectionScore,
    required this.ts,
  });
}

class PeerNetSnapshot {
  final VibeUser user;
  final NetStats stats;
  const PeerNetSnapshot({required this.user, required this.stats});
}

// =====================================================
//  CLUTCH CORE MANAGER
// =====================================================

class ClutchCoreManager with ChangeNotifier {
  bool _isActive = false;
  DateTime? _activatedAt;
  final _events = <String>[];

  bool get isActive => _isActive;
  DateTime? get activatedAt => _activatedAt;
  List<String> get events => List.unmodifiable(_events);

  void activate({String reason = 'last-man-standing'}) {
    if (_isActive) return;
    _isActive = true;
    _activatedAt = DateTime.now();
    _events.add('[${_activatedAt!.toIso8601String()}] CLUTCH: on ($reason)');
    notifyListeners();
  }

  ClutchReport deactivateAndBuildReport(Iterable<PeerNetSnapshot> netPulse) {
    if (!_isActive) return ClutchReport.empty();

    final endedAt = DateTime.now();
    _events.add('[${endedAt.toIso8601String()}] CLUTCH: off');
    final duration = endedAt.difference(_activatedAt!);
    _isActive = false;
    _activatedAt = null;
    notifyListeners();

    return ClutchReport(
      duration: duration,
      focusIndex: _estimateFocusIndex(duration),
      netSnapshots: netPulse.toList(),
      events: List.unmodifiable(_events),
      createdAt: endedAt,
    );
  }

  int _estimateFocusIndex(Duration duration) {
    final raw = (duration.inSeconds * 4).clamp(0, 100);
    return raw;
  }
}

class ClutchReport {
  final Duration duration;
  final int focusIndex;
  final List<PeerNetSnapshot> netSnapshots;
  final List<String> events;
  final DateTime createdAt;

  const ClutchReport({
    required this.duration,
    required this.focusIndex,
    required this.netSnapshots,
    required this.events,
    required this.createdAt,
  });

  factory ClutchReport.empty() => ClutchReport(
        duration: Duration.zero,
        focusIndex: 0,
        netSnapshots: const [],
        events: const [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
}

// =====================================================
//  NETPULSE SERVICE
// =====================================================

class NetPulseService {
  final Map<String, VibeUser> peers;
  NetPulseService({required this.peers});

  final _statsCtrl = BehaviorSubject<List<PeerNetSnapshot>>.seeded(const []);
  Stream<List<PeerNetSnapshot>> get snapshots$ => _statsCtrl.stream;

  Timer? _timer;

  void startPolling({Duration interval = const Duration(seconds: 1)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      final now = DateTime.now();
      final rnd = Random();
      final data = peers.values.map((u) {
        final ping = 25 + rnd.nextInt(80);
        final loss = (rnd.nextDouble() * 3.0);
        final jitter = 5 + rnd.nextInt(25);
        final vlat = ping + rnd.nextInt(15);
        final score = _connectionScore(ping, loss, jitter);
        return PeerNetSnapshot(
          user: u,
          stats: NetStats(
            pingMs: ping,
            packetLossPct: double.parse(loss.toStringAsFixed(2)),
            jitterMs: jitter,
            voiceLatencyMs: vlat,
            connectionScore: score,
            ts: now,
          ),
        );
      }).toList();
      _statsCtrl.add(data);
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  int _connectionScore(int ping, double loss, int jitter) {
    var score = 100;
    score -= ((ping - 20) / 2).clamp(0, 50).toInt();
    score -= (loss * 10).clamp(0, 30).toInt();
    score -= ((jitter - 5) * 1.2).clamp(0, 20).toInt();
    return score.clamp(0, 100);
  }

  void dispose() {
    stopPolling();
    _statsCtrl.close();
  }
}
