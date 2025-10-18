// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';

// Sostituisci i placeholder con i valori presi dalla console Firebase
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBH8lhn43XU958j8Sx97V-oxil-PL-gZ5g",
    authDomain: "vibenet-a4c47.firebaseapp.com",
    databaseURL: "https://vibenet-a4c47-default-rtdb.europe-west1.firebasedatabase.app",
    projectId: "vibenet-a4c47",
    storageBucket: "vibenet-a4c47.firebasestorage.app",
    messagingSenderId: "1070273232761",
    appId: "1:1070273232761:web:99f279bdd1addea32fb9a8",
    measurementId: "G-VK2V09ZH57"
  );
}
