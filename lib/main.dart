import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/room_select_screen.dart'; // ✅ nome corretto

// ============================================================
// ⚙️ MAIN UFFICIALE — Avvio completo VibeNet (con login Firebase)
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const VibeNetApp());
}

// ============================================================
// 🧭 APP UFFICIALE — Con login automatico e listener Auth
// ============================================================

class VibeNetApp extends StatelessWidget {
  const VibeNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const AuthGate(),
    );
  }
}

// ============================================================
// 🔐 AUTH GATE — Controlla se l’utente è loggato o meno
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          );
        }

        // ✅ Utente loggato → passa il nome alla schermata stanze
        if (snapshot.hasData) {
          final user = FirebaseAuth.instance.currentUser;
          final displayName = user?.displayName ??
              'Utente_${user?.uid.substring(0, 5) ?? 'anon'}';

          return RoomSelectScreen(username: displayName);
        }

        // 🔐 Utente non loggato → mostra schermata di login
        return const LoginScreen();
      },
    );
  }
}

