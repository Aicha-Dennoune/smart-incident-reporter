import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _messagesRef(String incidentId) {
    return _firestore
        .collection('incidents')
        .doc(incidentId)
        .collection('messages');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String incidentId) {
    return _messagesRef(
      incidentId,
    ).orderBy('createdAt', descending: false).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchLatestMessage(String incidentId) {
    return _messagesRef(
      incidentId,
    ).orderBy('createdAt', descending: true).limit(1).snapshots();
  }

  Future<void> sendMessage({
    required String incidentId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
  }) async {
    final content = text.trim();
    if (content.isEmpty) return;
    await _messagesRef(incidentId).add({
      'senderId': senderId,
      'senderName': senderName.trim().isEmpty ? 'Utilisateur' : senderName.trim(),
      'senderRole': senderRole,
      'text': content,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [senderId],
    });
  }

  Future<void> markAllAsRead({
    required String incidentId,
    required String currentUserId,
  }) async {
    final snap = await _messagesRef(incidentId).get();
    final batch = _firestore.batch();
    var updates = 0;
    for (final doc in snap.docs) {
      final d = doc.data();
      final senderId = d['senderId']?.toString() ?? '';
      final readBy = List<String>.from((d['readBy'] as List?) ?? const []);
      if (senderId == currentUserId) continue;
      if (readBy.contains(currentUserId)) continue;
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([currentUserId]),
      });
      updates++;
    }
    if (updates > 0) {
      await batch.commit();
    }
  }
}

