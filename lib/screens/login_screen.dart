import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/animated_background.dart';
import 'room_select_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nicknameC = TextEditingController();
  final TextEditingController _emailC = TextEditingController();
  final TextEditingController _passC = TextEditingController();

  late final Ticker _ticker;
  double _t = 0;
  bool _loading = false;
  bool _registerMode = false;
  String? _error;

  late final AnimationController _introController;
  late final Animation<double> _introAnim;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker((e) => setState(() => _t = e.inMilliseconds / 1000))
      ..start();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _introAnim = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutExpo,
    );

    _introController.forward();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _introController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _registerMode = !_registerMode;
      _error = null;
    });
  }

  Future<void> _auth({required bool register}) async {
    final nick = _nicknameC.text.trim();
    final email = _emailC.text.trim();
    final pass = _passC.text.trim();

    if (nick.isEmpty || pass.isEmpty) {
      setState(() => _error = "Inserisci nickname e password.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userRef = FirebaseDatabase.instance.ref('users');
      String? matchedEmail;

      // Trova l'email associata al nickname
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        for (final entry in data.entries) {
          final val = Map<String, dynamic>.from(entry.value);
          if (val['nickname'] == nick) {
            matchedEmail = val['email'];
            break;
          }
        }
      }

      if (register) {
        if (email.isEmpty) {
          setState(() => _error = "Serve un'email per registrarti.");
          return;
        }
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: pass);
        await cred.user!.sendEmailVerification();
        await userRef.child(cred.user!.uid).set({
          'nickname': nick,
          'email': email,
          'role': email == 'sergioeletto29@gmail.com' ? 'admin' : 'user',
          'createdAt': ServerValue.timestamp,
        });
        setState(() => _error =
            "Registrazione completata! Controlla la tua email per la verifica.");
      } else {
        if (matchedEmail == null) {
          setState(() => _error = "Nickname non trovato.");
          return;
        }
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: matchedEmail,
          password: pass,
        );
        if (!cred.user!.emailVerified) {
          setState(() => _error = "Verifica prima la tua email.");
          await FirebaseAuth.instance.signOut();
          return;
        }

        final isAdmin = matchedEmail == 'sergioeletto29@gmail.com';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                RoomSelectScreen(username: nick, isAdmin: isAdmin),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? "Errore di autenticazione.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Evita di costruire il widget finché l'animazione non è pronta
    if (!_introController.isAnimating && _introController.value == 0.0) {
      return const SizedBox.shrink();
    }

    final pulse = 1 + sin(_t * 2.2) * 0.05;
    final glow = (sin(_t * 2.4) + 1) / 2;
    final blur = 8 + glow * 22;
    final spread = 0.5 + glow * 1.5;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const AnimatedBackground(),
          AnimatedBuilder(
            animation: _introAnim,
            builder: (context, _) {
              final introProgress = _introAnim.value;
              final introGlow = Curves.easeInOut.transform(introProgress);

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ⚡ LOGO CON ACCENSIONE E RESPIRO
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (introProgress < 1)
                              Container(
                                width: 300 * introProgress,
                                height: 300 * introProgress,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.purpleAccent
                                          .withOpacity(0.35 * introGlow),
                                      Colors.blueAccent
                                          .withOpacity(0.15 * introGlow),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.7, 1.0],
                                  ),
                                ),
                              ),
                            Transform.scale(
                              scale: pulse *
                                  (0.8 + 0.2 * introProgress.clamp(0.0, 1.0)),
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purpleAccent
                                          .withOpacity(0.4 + glow * 0.4),
                                      blurRadius: blur,
                                      spreadRadius: spread * 2.5,
                                    ),
                                    BoxShadow(
                                      color: Colors.blueAccent
                                          .withOpacity(0.25 + glow * 0.25),
                                      blurRadius: blur * 0.6,
                                      spreadRadius: spread * 1.4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: introProgress,
                              child: Text(
                                "VibeNet",
                                style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.purpleAccent
                                          .withOpacity(0.5 + glow * 0.4),
                                      blurRadius:
                                          blur * (0.5 + introProgress * 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 38),

                        // FORM
                        _field(_nicknameC, "Nickname"),
                        const SizedBox(height: 12),
                        if (_registerMode) ...[
                          _field(_emailC, "Email"),
                          const SizedBox(height: 12),
                        ],
                        _field(_passC, "Password", obscure: true),
                        const SizedBox(height: 14),

                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        if (_loading)
                          const CircularProgressIndicator(
                              color: Colors.purpleAccent)
                        else
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () =>
                                    _auth(register: _registerMode),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purpleAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 14),
                                  textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                  shadowColor:
                                      Colors.purpleAccent.withOpacity(0.6),
                                ),
                                child: Text(
                                  _registerMode ? "Registrati" : "Accedi",
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextButton(
                                onPressed: _toggleMode,
                                child: Text(
                                  _registerMode
                                      ? "Hai già un account? Accedi"
                                      : "Non hai un account? Registrati",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: c,
        obscureText: obscure,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        cursorColor: Colors.purpleAccent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.3,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1.4,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(
              color: Colors.purpleAccent,
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
      ),
    );
  }
}
