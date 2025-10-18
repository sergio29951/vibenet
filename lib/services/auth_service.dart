import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static String get currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utente non autenticato");
    return user.uid;
  }
}
