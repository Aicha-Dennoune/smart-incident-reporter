import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Aide au diagnostic quand une requête renvoie 0 document (mauvais projet, règles, nom de collection).
String firestoreListDebugFooter(QuerySnapshot<Map<String, dynamic>>? snap) {
  final pid = Firebase.app().options.projectId;
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '(non connecté)';
  final cache = snap?.metadata.isFromCache ?? false;
  final pending = snap?.metadata.hasPendingWrites ?? false;
  final n = snap?.docs.length ?? 0;
  return 'Diagnostic Firestore\n'
      '• Projet : $pid\n'
      '• UID Auth : $uid\n'
      '• Documents dans cette réponse : $n\n'
      '• Réponse cache : $cache\n'
      '• Écritures en attente : $pending\n'
      '• La collection doit s\'appeler exactement : incidents';
}

/// Texte pour erreur Firestore / permission.
Widget firestoreErrorPanel(Object error) {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: SelectableText(
      'Erreur Firestore :\n$error',
      style: const TextStyle(color: Colors.redAccent, height: 1.4),
    ),
  );
}
