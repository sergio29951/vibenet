import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/netpulse_firebase_service.dart';
import '../widgets/netpulse_overlay.dart';

class VoiceRoom extends StatefulWidget {
  final String roomName;
  final String username;

  const VoiceRoom({
    super.key,
    required this.roomName,
    required this.username,
  });

  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> with SingleTickerProviderStateMixin {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  late DatabaseReference _roomRef;
  MediaStream? _localStream;
  bool _micEnabled = true;
  bool _joined = false;
  late AnimationController _animController;

  late stt.SpeechToText _speech;
  bool _listening = false;

  late NetPulseFirebaseSync _netPulse;
  StreamSubscription? _pulseSub;
  bool _showNetPulse = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _roomRef = _db.ref('voice_rooms/${widget.roomName}');
    _initVoiceRoom();
  }

  Future<void> _initVoiceRoom() async {
    final snapshot = await _roomRef.get();
    if (!snapshot.exists) {
      await _roomRef.set({
        'creator': widget.username,
        'createdAt': ServerValue.timestamp,
        'users': {widget.username: {'mic': true}},
      });
    } else {
      await _roomRef.child('users/${widget.username}').set({'mic': true});
    }

    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true});
    _joined = true;

    _speech = stt.SpeechToText();
    _startListening();

    _netPulse = NetPulseFirebaseSync(widget.roomName, widget.username);
    _netPulse.start();

    _pulseSub = _netPulse.events$.listen((event) {
      if (event == VoiceEvent.showNetPulse) {
        setState(() => _showNetPulse = true);
        Future.delayed(const Duration(seconds: 7), () {
          if (mounted) setState(() => _showNetPulse = false);
        });
      }
    });

    setState(() {});
  }

  void _startListening() async {
    if (_listening) return;
    _listening = true;

    final available = await _speech.initialize(
      onError: (err) => debugPrint('❌ Errore STT: $err'),
      onStatus: (status) => debugPrint('🎧 Stato STT: $status'),
    );

    if (!available) {
      debugPrint('⚠️ Riconoscimento vocale non disponibile.');
      return;
    }

    Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!_listening) {
        timer.cancel();
        return;
      }

      if (!_speech.isListening) {
        await _speech.listen(
          localeId: 'it_IT',
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          onResult: (result) async {
            final text = result.recognizedWords.toLowerCase().trim();
            if (text.isNotEmpty) debugPrint('🎙️ Riconosciuto: $text');

            if (text.contains('ping') || text.contains('pping')) {
              debugPrint('⚡ Comando vocale rilevato!');
              await _netPulse.sendPing(byUserId: widget.username);
            }
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseSub?.cancel();
    _netPulse.dispose();
    _speech.stop();
    _localStream?.dispose();
    _animController.dispose();
    _roomRef.child('users/${widget.username}').remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_joined) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.roomName, style: const TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          StreamBuilder(
            stream: _roomRef.child('users').onValue,
            builder: (context, snapshot) {
              final users = (snapshot.data?.snapshot.value as Map?) ?? {};
              return Center(
                child: Wrap(
                  spacing: 28,
                  runSpacing: 28,
                  alignment: WrapAlignment.center,
                  children: users.keys.map<Widget>((name) {
                    final micOn = users[name]['mic'] ?? true;
                    return _buildUserCircle(name, micOn);
                  }).toList(),
                ),
              );
            },
          ),
          if (_showNetPulse)
            Positioned(
              bottom: 20,
              right: 20,
              child: NetPulseOverlay(snapshots$: _netPulse.snapshots$),
            ),
        ],
      ),
    );
  }

  Widget _buildUserCircle(String name, bool micOn) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final scale = 1.0 + math.sin(_animController.value * math.pi * 2) * 0.04;
        return Transform.scale(
          scale: scale,
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: micOn ? Colors.blueAccent : Colors.grey,
                  boxShadow: [
                    if (micOn)
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(name, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        );
      },
    );
  }
}
