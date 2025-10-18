import 'dart:math' as math;
import 'package:flutter/material.dart';

/* ──────────────────────────────────────────────────────────────────────────
   VibeUI: PulseInputBar + FloatingVibeDialog
   - Nessuna dipendenza extra.
   - Solo stile/animazioni. Nessun cambiamento di layout o logica.
   ────────────────────────────────────────────────────────────────────────── */

/// Barra messaggi “viva”: capsule luminosa, onde sottili in movimento,
/// integra icone Send e PTT (push-to-talk). Mantiene la posizione e i ruoli
/// della tua barra attuale (solo stile migliore).
class PulseInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSendText;
  final VoidCallback onStartPTT;
  final VoidCallback onStopPTT;
  final bool isRecording;
  final List<Color> roomGradient; // usa i colori della stanza

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
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.roomGradient;
    final baseA = base.isNotEmpty ? base.first : const Color(0xFF1F2A44);
    final baseB = base.length > 1 ? base.last : const Color(0xFF0D1326);

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Stack(
        children: [
          // capsula glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.03)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: widget.isRecording
                    ? Colors.redAccent.withOpacity(0.6)
                    : Colors.blueAccent.withOpacity(0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isRecording ? Colors.redAccent : baseA)
                      .withOpacity(0.15),
                  blurRadius: 14,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),

          // onde sottili
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _PulseWavesPainter(
                      t: _ctrl.value,
                      colorA: baseA.withOpacity(0.25),
                      colorB: baseB.withOpacity(0.25),
                      boost: widget.isRecording ? 1.6 : 1.0,
                    ),
                  );
                },
              ),
            ),
          ),

          // contenuti (input + icone)
          SizedBox(
            height: 54,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Scrivi un messaggio...',
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => widget.onSendText(),
                  ),
                ),
                IconButton(
                  tooltip: 'Invia',
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: widget.onSendText,
                ),
                // PTT (press & hold)
                GestureDetector(
                  onLongPressStart: (_) => widget.onStartPTT(),
                  onLongPressEnd: (_) => widget.onStopPTT(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: widget.isRecording
                              ? [Colors.redAccent, Colors.red.shade900]
                              : [baseA, baseB],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.isRecording
                                    ? Colors.redAccent
                                    : Colors.blueAccent)
                                .withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Icon(
                        widget.isRecording ? Icons.mic_none : Icons.mic,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseWavesPainter extends CustomPainter {
  final double t; // 0..1
  final Color colorA;
  final Color colorB;
  final double boost;
  _PulseWavesPainter({
    required this.t,
    required this.colorA,
    required this.colorB,
    this.boost = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintA = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = colorA;

    final paintB = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = colorB;

    final midY = size.height / 2;
    final amp = 4.0 * boost;
    final len = size.width;

    Path wave(double phase, double freq) {
      final p = Path()..moveTo(0, midY);
      for (double x = 0; x <= len; x += 6) {
        final y = midY + math.sin((x / len * freq * 2 * math.pi) + phase) * amp;
        p.lineTo(x, y);
      }
      return p;
    }

    canvas.drawPath(wave(t * 2 * math.pi, 3.2), paintA);
    canvas.drawPath(wave(t * 2 * math.pi + 1.1, 4.0), paintB);
  }

  @override
  bool shouldRepaint(covariant _PulseWavesPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.boost != boost;
}

/// Dialog fluttuante “vivo”: bordo glow, dissolve morbida, campi coerenti.
/// Si usa come contenitore: passi contenuto e bottoni (riutilizzabile ovunque).
class FloatingVibeDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const FloatingVibeDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0F12).withOpacity(0.98),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 12),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.blur_on, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                content,
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ──────────────────────────────────────────────────────────────────────────
   Helper per campi testo coerenti con VibeUI
   ────────────────────────────────────────────────────────────────────────── */

InputDecoration vibeInputDecoration(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white24.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
    );

/// Shortcut: dialog di input testuale. Ritorna la stringa o null.
Future<String?> showVibeTextPrompt(
  BuildContext context, {
  required String title,
  required String label,
  String? initialValue,
  String confirmLabel = 'Conferma',
  String cancelLabel = 'Annulla',
}) async {
  final ctrl = TextEditingController(text: initialValue ?? '');
  return showGeneralDialog<String>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    barrierLabel: 'dialog',
    barrierDismissible: true,
    pageBuilder: (_, __, ___) => FloatingVibeDialog(
      title: title,
      content: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: vibeInputDecoration(label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelLabel, style: const TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()),
          child: Text(confirmLabel, style: const TextStyle(color: Colors.blueAccent)),
        ),
      ],
    ),
    transitionBuilder: (_, a, __, child) => Transform.scale(
      scale: 0.98 + a.value * 0.02,
      child: Opacity(opacity: a.value, child: child),
    ),
    transitionDuration: const Duration(milliseconds: 180),
  );
}

/// Shortcut: dialog password nascosta. True/False se combacia, altrimenti null/cancel.
Future<bool?> showVibePasswordCheck(
  BuildContext context, {
  required String title,
  required String label,
  required String realPassword,
  String confirmLabel = 'Entra',
  String cancelLabel = 'Annulla',
}) async {
  final ctrl = TextEditingController();
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    barrierDismissible: true,
    barrierLabel: 'dialog',
    pageBuilder: (_, __, ___) => StatefulBuilder(
      builder: (ctx, setState) => FloatingVibeDialog(
        title: title,
        content: TextField(
          controller: ctrl,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: vibeInputDecoration(label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel, style: const TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim() == realPassword),
            child: Text(confirmLabel, style: const TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    ),
    transitionBuilder: (_, a, __, child) => Transform.scale(
      scale: 0.98 + a.value * 0.02,
      child: Opacity(opacity: a.value, child: child),
    ),
    transitionDuration: const Duration(milliseconds: 180),
  );
  return result;
}

/// Shortcut: conferma stile Vibe. Ritorna true/false.
Future<bool?> showVibeConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Conferma',
  String cancelLabel = 'Annulla',
  Color confirmColor = Colors.redAccent,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    barrierDismissible: true,
    barrierLabel: 'dialog',
    pageBuilder: (_, __, ___) => FloatingVibeDialog(
      title: title,
      content: Text(message, style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(_, false),
          child: Text(cancelLabel, style: const TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(_, true),
          child: Text(confirmLabel, style: TextStyle(color: confirmColor)),
        ),
      ],
    ),
    transitionBuilder: (_, a, __, child) => Transform.scale(
      scale: 0.98 + a.value * 0.02,
      child: Opacity(opacity: a.value, child: child),
    ),
    transitionDuration: const Duration(milliseconds: 180),
  );
}
