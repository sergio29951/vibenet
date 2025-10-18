import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/vibe_ui.dart';
import '../screens/login_screen.dart';
import '../widgets/room_tile_3d.dart';
import 'vibe_chat_screen.dart';
import 'voice_room.dart';

class RoomSelectScreen extends StatefulWidget {
  final String username;
  final bool isAdmin;

  const RoomSelectScreen({
    super.key,
    required this.username,
    this.isAdmin = false,
  });

  @override
  State<RoomSelectScreen> createState() => _RoomSelectScreenState();
}

class _RoomSelectScreenState extends State<RoomSelectScreen> {
  StreamSubscription<DatabaseEvent>? _subPrivate;
  StreamSubscription<DatabaseEvent>? _subVoice;
  int _onlineCount = 0;

  // 🔮 Gradienti “Deep Vibe” per le stanze testuali
  final Map<String, List<Color>> vibeRoomGradients = {
    "Arte 🎨": [const Color(0xFF2C0E37), const Color(0xFF4B2C69)],
    "Filosofia 🧠": [const Color(0xFF0A1A2F), const Color(0xFF243B55)],
    "Tech 💻": [const Color(0xFF0D1B1E), const Color(0xFF233D3C)],
    "Musica 🎧": [const Color(0xFF1C0A27), const Color(0xFF3A0CA3)],
    "Relax 🌙": [const Color(0xFF050505), const Color(0xFF1A1A1A)],
  };

  Map<String, String> _privateRooms = {};
  Map<String, Map<String, dynamic>> _voiceRooms = {};

  @override
  void initState() {
    super.initState();

    FirebaseDatabase.instance.ref('online_users').onValue.listen((event) {
      final data = (event.snapshot.value as Map?) ?? {};
      setState(() => _onlineCount = data.length);
    });

    _subPrivate =
        FirebaseDatabase.instance.ref('private_rooms').onValue.listen((event) {
      final data = (event.snapshot.value as Map?) ?? {};
      final rooms = <String, String>{};
      for (final e in data.entries) {
        rooms[e.key] = (e.value as Map?)?['password'] ?? '';
      }
      setState(() => _privateRooms = rooms);
    });

    _subVoice =
        FirebaseDatabase.instance.ref('voice_rooms').onValue.listen((event) {
      final data = (event.snapshot.value as Map?) ?? {};
      final rooms = <String, Map<String, dynamic>>{};
      for (final e in data.entries) {
        final value = (e.value as Map?) ?? {};
        rooms[e.key] = {
          'creator': value['creator'] ?? 'Sconosciuto',
          'users': (value['users'] as Map?)?.length ?? 0,
        };
      }
      setState(() => _voiceRooms = rooms);
    });
  }

  @override
  void dispose() {
    _subPrivate?.cancel();
    _subVoice?.cancel();
    super.dispose();
  }

  // ───────────────────────────── PRIVATE ROOMS ─────────────────────────────

  Future<void> _createPrivateRoom() async {
    final name = await showVibeTextPrompt(
      context,
      title: "Crea stanza privata",
      label: "Nome stanza",
    );
    if (name == null || name.isEmpty) return;

    final pass = await showVibeTextPrompt(
      context,
      title: "Password stanza",
      label: "Password",
    );
    if (pass == null || pass.isEmpty) return;

    await FirebaseDatabase.instance.ref('private_rooms/$name').set({
      'password': pass,
      'creator': widget.username,
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<void> _deletePrivateRoom(String name) async {
    final ok = await showVibePasswordCheck(
      context,
      title: "Elimina stanza privata",
      label: "Password",
      realPassword: _privateRooms[name] ?? '',
      confirmLabel: "Conferma",
    );
    if (ok == true) {
      await FirebaseDatabase.instance.ref('private_rooms/$name').remove();
    }
  }

  // ───────────────────────────── VOICE ROOMS ─────────────────────────────

  Future<void> _createVoiceRoom() async {
    final vr = await showVibeTextPrompt(
      context,
      title: "Crea stanza vocale",
      label: "Nome stanza vocale",
      confirmLabel: "Crea",
    );
    if (vr == null || vr.isEmpty) return;

    await FirebaseDatabase.instance.ref('voice_rooms/$vr').set({
      'creator': widget.username,
      'users': {widget.username: {'mic': true}},
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<void> _deleteVoiceRoom(String name) async {
    final ok = await showVibeConfirm(
      context,
      title: "Elimina stanza vocale",
      message: "Vuoi davvero eliminare “$name”?",
      confirmLabel: "Elimina",
      confirmColor: Colors.redAccent,
    );
    if (ok == true) {
      await FirebaseDatabase.instance.ref('voice_rooms/$name').remove();
    }
  }

  // ───────────────────────────── NAVIGATION ─────────────────────────────

  Future<void> _openRoom(String name, List<Color> colors) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VibeChatScreen(
          username: widget.username,
          roomName: name,
          gradientColors: colors,
          isPrivate: false,
        ),
      ),
    );
  }

  Future<void> _openPrivateRoom(String name, List<Color> colors) async {
    final passC = TextEditingController();
    final passOk = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text("🔒 $name", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: passC,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Password",
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () {
              final real = _privateRooms[name] ?? '';
              Navigator.pop(c, passC.text.trim() == real);
            },
            child: const Text("Entra"),
          ),
        ],
      ),
    );

    if (passOk == true) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VibeChatScreen(
            username: widget.username,
            roomName: name,
            gradientColors: colors,
            isPrivate: true,
          ),
        ),
      );
    }
  }

  // ───────────────────────────── BUILD ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scegli la tua stanza"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.blueAccent),
            tooltip: 'Crea stanza vocale',
            onPressed: _createVoiceRoom,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _OnlineBadge(count: _onlineCount),
          ),
        ],
      ),

      // 🔥 Gradiente di sfondo “Deep Vibe” ripristinato
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B0B10), // nero profondo con tinta blu
              Color(0xFF111726), // blu notte
              Color(0xFF0C0F17), // nota scura
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Stanze di testo e private
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  crossAxisCount: width > 720 ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    RoomTile3D(
                      title: "Crea nuova stanza privata",
                      colors: const [Colors.amberAccent, Colors.orange],
                      centerIcon: Icons.add_circle_outline,
                      onTap: _createPrivateRoom,
                    ),
                    ...vibeRoomGradients.entries.map((e) => RoomTile3D(
                          title: e.key,
                          colors: e.value,
                          centerIcon: Icons.forum_rounded,
                          onTap: () => _openRoom(e.key, e.value),
                        )),
                    ..._privateRooms.keys.map((name) => RoomTile3D(
                          title: name,
                          colors: const [Color(0xFFFFD700), Color(0xFFFFC107)],
                          centerIcon: Icons.lock_outline,
                          onTap: () => _openPrivateRoom(
                            name,
                            const [Color(0xFFFFD700), Color(0xFFFFC107)],
                          ),
                          onLongPress: () async => await _deletePrivateRoom(name),
                        )),
                  ],
                ),
              ),
            ),

            // Pannello stanze vocali con leggero gradiente scuro
            Container(
              width: width > 720 ? 280 : 220,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF141923).withOpacity(0.9),
                    const Color(0xFF0E131B).withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.15),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Stanze Vocali 🎙️",
                      style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: _voiceRooms.isEmpty
                        ? const Center(
                            child: Text("Nessuna stanza",
                                style: TextStyle(color: Colors.white54)),
                          )
                        : ListView(
                            children: _voiceRooms.entries.map((entry) {
                              final isOwner =
                                  entry.value['creator'] == widget.username;
                              final count = entry.value['users'];
                              return ListTile(
                                dense: true,
                                title: Text(entry.key,
                                    style: const TextStyle(color: Colors.white)),
                                subtitle: Text(
                                  "🎧 $count online",
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                trailing: isOwner
                                    ? IconButton(
                                        icon: const Icon(Icons.delete_forever,
                                            color: Colors.redAccent, size: 20),
                                        onPressed: () => _deleteVoiceRoom(entry.key),
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VoiceRoom(
                                        roomName: entry.key,
                                        username: widget.username,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Crea vocale"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _createVoiceRoom,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  final int count;
  const _OnlineBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Color(0xFF4FC3F7), size: 10),
          const SizedBox(width: 8),
          Text("$count connessi", style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
