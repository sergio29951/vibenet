// ignore_for_file: undefined_prefixed_name, avoid_web_libraries_in_flutter

// Usa dart:ui_web solo su Web, e fallback a null su mobile
// per compatibilità con flutter_webrtc

// Conditional import
// Importa dart:ui_web solo se disponibile (Web)
import 'dart:ui' as ui show window;
import 'dart:html' as html show window;

/// Espone `platformViewRegistry` per Flutter Web >= 3.22.
/// Alcune versioni di flutter_webrtc lo richiedono esplicitamente.
dynamic get platformViewRegistry {
  // browser web? allora prova a prenderlo
  try {
    // ignore: undefined_prefixed_name
    return (ui.window as dynamic).platformViewRegistry ??
        (html.window as dynamic).platformViewRegistry;
  } catch (_) {
    // fallback: su mobile non serve
    return null;
  }
}
