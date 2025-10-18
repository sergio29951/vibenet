import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/pulse_input_bar.dart';

class VibeChatScreen extends StatefulWidget {
  final String username;
  final String roomName;
  final List<Color> gradientColors;
  final bool isPrivate;

  const VibeChatScreen({
    super.key,
    required this.username,
    required this.roomName,
    required this.gradientColors,
    required this.isPrivate,
  });

  @override
  State<VibeChatScreen> createState() => _VibeChatScreenState();
}

class _VibeChatScreenState extends State<VibeChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final DatabaseReference _ref = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _messages = [];
  bool _isRecording = false;
  late AnimationController _animController;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _animController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));

    _listenMessages();
  }

  void _listenMessages() {
    _ref.child('rooms/${widget.roomName}/messages').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) {
        setState(() => _messages = []);
        return;
      }

      final msgs = data.entries.map((e) {
        final val = e.value as Map?;
        return {
          'id': e.key ?? '',
          'user': (val?['user'] ?? 'Anonimo').toString(),
          'text': (val?['text'] ?? '').toString(),
          'timestamp': (val?['timestamp'] ?? 0) as int,
        };
      }).where((m) => m['text'].toString().isNotEmpty).toList()
        ..sort((a, b) =>
            (a['timestamp'] as int).compareTo(b['timestamp'] as int));

      setState(() => _messages = msgs);
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _ref.child('rooms/${widget.roomName}/messages').push().set({
      'user': widget.username,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _controller.clear();
  }

  void _startPTT() {
    setState(() => _isRecording = true);
  }

  void _stopPTT() {
    setState(() => _isRecording = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gradienti scuri e coerenti con la stanza
    final gradient = [
      widget.gradientColors.first.withOpacity(0.3),
      widget.gradientColors.last.withOpacity(0.15),
      Colors.black.withOpacity(0.9),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.roomName,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final msg = _messages[i];
                  final isMe = msg['user'] == widget.username;
                  final text = msg['text'] ?? '';
                  final user = msg['user'] ?? 'Anonimo';

                  return AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: Align(
                          alignment: isMe
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (isMe)
                                  _AvatarBubble(
                                    user: user,
                                    color: widget.gradientColors.first,
                                  ),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.white.withOpacity(0.08)
                                          : Colors.blueAccent.withOpacity(0.15),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(isMe ? 0 : 18),
                                        bottomRight: Radius.circular(isMe ? 18 : 0),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      text,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 15),
                                    ),
                                  ),
                                ),
                                if (!isMe)
                                  _AvatarBubble(
                                    user: user,
                                    color: widget.gradientColors.last,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 🔥 Barra testo moderna
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: PulseInputBar(
                  controller: _controller,
                  onSendText: _sendMessage,
                  onStartPTT: _startPTT,
                  onStopPTT: _stopPTT,
                  isRecording: _isRecording,
                  roomGradient: widget.gradientColors,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  final String user;
  final Color color;
  const _AvatarBubble({required this.user, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: color.withOpacity(0.9),
        child: Text(
          user.isNotEmpty ? user[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
