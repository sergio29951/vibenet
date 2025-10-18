import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String username;

  const AdminDashboardScreen({super.key, required this.username});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  StreamSubscription<DatabaseEvent>? _subOnline;
  StreamSubscription<DatabaseEvent>? _subRooms;

  int _onlineCount = 0;
  List<_OnlineUser> _onlineUsers = [];
  List<_RoomStat> _rooms = [];

  @override
  void initState() {
    super.initState();

    _subOnline = FirebaseDatabase.instance.ref('online_users').onValue.listen((e) {
      final m = (e.snapshot.value as Map?) ?? {};
      _onlineCount = m.length;
      final list = <_OnlineUser>[];
      m.forEach((nick, data) {
        if (data is Map) {
          final room = (data['room'] ?? 'Nessuna').toString();
          final status = (data['status'] ?? 'online').toString();
          list.add(_OnlineUser(nick.toString(), room, status));
        } else if (data == true) {
          list.add(_OnlineUser(nick.toString(), 'Nessuna', 'online'));
        }
      });
      setState(() {
        _onlineUsers = list..sort((a, b) => a.name.compareTo(b.name));
      });
    });

    _subRooms = FirebaseDatabase.instance.ref('rooms').onValue.listen((e) {
      final m = (e.snapshot.value as Map?) ?? {};
      final stats = <_RoomStat>[];
      m.forEach((roomName, data) {
        final users = ((data as Map?)?['users'] as Map?) ?? {};
        stats.add(_RoomStat(roomName.toString(), users.length));
      });
      setState(() {
        _rooms = stats..sort((a, b) => b.count.compareTo(a.count));
      });
    });
  }

  @override
  void dispose() {
    _subOnline?.cancel();
    _subRooms?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statCard("Utenti online", _onlineCount.toString(), Icons.people_alt_outlined),
          const SizedBox(height: 16),
          const Text("Online users", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          _glass(
            child: Column(
              children: _onlineUsers.isEmpty
                  ? [const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Nessuno online', style: TextStyle(color: Colors.white54)),
                    )]
                  : _onlineUsers.map((u) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.circle, color: Colors.lightBlueAccent, size: 10),
                        title: Text(u.name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text('Stanza: ${u.room}', style: const TextStyle(color: Colors.white70)),
                        trailing: Text(u.status, style: const TextStyle(color: Colors.white54)),
                      );
                    }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Occupazione stanze", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          _glass(
            child: Column(
              children: _rooms.isEmpty
                  ? [const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Nessuna stanza attiva', style: TextStyle(color: Colors.white54)),
                    )]
                  : _rooms.map((r) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.forum, color: Colors.amberAccent),
                        title: Text(r.name, style: const TextStyle(color: Colors.white)),
                        trailing: Text('${r.count} online', style: const TextStyle(color: Colors.white70)),
                      );
                    }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return _glass(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.purpleAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white70)),
            ),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _glass({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: child,
    );
  }
}

class _OnlineUser {
  final String name;
  final String room;
  final String status;
  _OnlineUser(this.name, this.room, this.status);
}

class _RoomStat {
  final String name;
  final int count;
  _RoomStat(this.name, this.count);
}
