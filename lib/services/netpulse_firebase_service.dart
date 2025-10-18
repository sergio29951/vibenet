import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

/// Evento vocale per triggerare l'HUD
enum VoiceEvent { showNetPulse }

/// Snapshot dei dati di rete di un utente
class NetPulseSnapshot {
  final String username;
  final double pingMs;
  final double packetLoss;
  final double bitrateKbps;

  NetPulseSnapshot({
    required this.username,
    required this.pingMs,
    required this.packetLoss,
    required this.bitrateKbps,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'pingMs': pingMs,
        'packetLoss': packetLoss,
        'bitrateKbps': bitrateKbps,
      };

  static NetPulseSnapshot fromJson(Map data) => NetPulseSnapshot(
        username: data['username'] ?? '?',
        pingMs: (data['pingMs'] ?? 0).toDouble(),
        packetLoss: (data['packetLoss'] ?? 0).toDouble(),
        bitrateKbps: (data['bitrateKbps'] ?? 0).toDouble(),
      );
}

/// Gestisce sincronizzazione e ping su Firebase
class NetPulseFirebaseSync {
  final String roomName;
  final String username;
  final _db = FirebaseDatabase.instance;

  final _controller = StreamController<List<NetPulseSnapshot>>.broadcast();
  Stream<List<NetPulseSnapshot>> get snapshots$ => _controller.stream;

  final _eventsController = StreamController<VoiceEvent>.broadcast();
  Stream<VoiceEvent> get events$ => _eventsController.stream;

  NetPulseFirebaseSync(this.roomName, this.username);

  void start() {
    // Ascolta i dati di rete della stanza
    _db.ref('voice_rooms/$roomName/netpulse').onValue.listen((event) {
      final data = event.snapshot.value as Map? ?? {};
      final list = data.entries
          .map((e) => NetPulseSnapshot.fromJson(Map.from(e.value)))
          .toList();
      _controller.add(list);
    });

    // Ascolta i "ping" vocali globali
    _db.ref('voice_rooms/$roomName/pings').onChildAdded.listen((event) {
      _eventsController.add(VoiceEvent.showNetPulse);
    });
  }

  /// Simula o invia un ping reale (per test vocale)
  Future<void> sendPing({required String byUserId}) async {
    final random = Random();
    final ping = 20 + random.nextInt(180); // ms
    final loss = random.nextDouble() * 5;
    final bitrate = 300 + random.nextInt(1200);

    await _db.ref('voice_rooms/$roomName/netpulse/$byUserId').set({
      'username': byUserId,
      'pingMs': ping.toDouble(),
      'packetLoss': loss,
      'bitrateKbps': bitrate.toDouble(),
    });

    // Scrive evento per sincronizzazione
    await _db.ref('voice_rooms/$roomName/pings').push().set({
      'user': byUserId,
      'timestamp': ServerValue.timestamp,
    });

    _eventsController.add(VoiceEvent.showNetPulse);
  }

  void dispose() {
    _controller.close();
    _eventsController.close();
  }
}
