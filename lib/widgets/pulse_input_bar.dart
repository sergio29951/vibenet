import 'dart:ui';
import 'package:flutter/material.dart';

class PulseInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSendText;
  final VoidCallback onStartPTT;
  final VoidCallback onStopPTT;
  final bool isRecording;
  final List<Color> roomGradient;

  const PulseInputBar({
    super.key,
    required this.controller,
    required this.onSendText,
    required this.onStartPTT,
    required this.onStopPTT,
    required this.isRecording,
    required this.roomGradient,
  });

  @override
  State<PulseInputBar> createState() => _PulseInputBarState();
}

class _PulseInputBarState extends State<PulseInputBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.roomGradient;
    // 🔥 Contrasto forzato sempre visibile (icone mai invisibili)
    final Color contrastColor =
        (gradient.first.computeLuminance() > 0.4 || gradient.last.computeLuminance() > 0.4)
            ? Colors.black
            : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 56, // 💡 aumentata del 40% rispetto a prima
            width: MediaQuery.of(context).size.width * 0.55,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🎙️ PTT button
                GestureDetector(
                  onTapDown: (_) => widget.onStartPTT(),
                  onTapUp: (_) => widget.onStopPTT(),
                  child: AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (context, child) {
                      double scale = 1 + (_animCtrl.value * 0.05);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.isRecording
                                ? Colors.redAccent
                                : contrastColor.withOpacity(0.15),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2), width: 1),
                            boxShadow: [
                              if (widget.isRecording)
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.5),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                )
                            ],
                          ),
                          child: Icon(
                            widget.isRecording ? Icons.mic : Icons.mic_none,
                            color: contrastColor,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 10),

                // ✏️ TextField
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    style: TextStyle(
                      color: contrastColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    cursorColor: contrastColor,
                    decoration: InputDecoration(
                      hintText: "Scrivi un messaggio...",
                      hintStyle: TextStyle(color: contrastColor.withOpacity(0.6)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (_) => widget.onSendText(),
                  ),
                ),

                // 🚀 Send button
                AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (context, _) {
                    final glow = (_animCtrl.value * 0.5) + 0.5;
                    return GestureDetector(
                      onTap: widget.onSendText,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              gradient.last.withOpacity(0.9),
                              gradient.first.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.last.withOpacity(0.45 * glow),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: contrastColor,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
