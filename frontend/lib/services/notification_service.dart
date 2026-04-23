import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static int _createdAtMillis(Map<String, dynamic> data) {
    final v = data['createdAt'];
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    if (v is int) return v;
    return 0;
  }

  /// Stream brut (pas de .map) — tri côté UI avec [sortedNotificationDocs].
  ///
  /// OR sur plusieurs noms de champ : les docs ajoutés à la main dans la
  /// console utilisent parfois `userId` au lieu de `targetUserId`.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchForUser(String uid) {
    return _firestore
        .collection('notifications')
        .where(
          Filter.or(
            Filter('targetUserId', isEqualTo: uid),
            Filter('userId', isEqualTo: uid),
            Filter('target_user_id', isEqualTo: uid),
          ),
        )
        .snapshots(includeMetadataChanges: true);
  }

  static List<QueryDocumentSnapshot<Map<String, dynamic>>> sortedNotificationDocs(
    QuerySnapshot<Map<String, dynamic>>? snap,
  ) {
    if (snap == null) return [];
    final docs = snap.docs.toList();
    docs.sort(
      (a, b) => _createdAtMillis(
        b.data(),
      ).compareTo(_createdAtMillis(a.data())),
    );
    return docs;
  }

  Future<void> createForUser({
    required String targetUserId,
    required String title,
    required String message,
    String? incidentId,
    String type = 'info',
  }) async {
    await _firestore.collection('notifications').add({
      'targetUserId': targetUserId,
      'title': title,
      'message': message,
      'incidentId': incidentId,
      'type': type,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createForRole({
    required String role,
    required String title,
    required String message,
    String? incidentId,
    String type = 'info',
  }) async {
    final users =
        await _firestore
            .collection('users')
            .where('role', isEqualTo: role)
            .get();

    final batch = _firestore.batch();
    for (final doc in users.docs) {
      final uid =
          doc.data()['uid']?.toString().isNotEmpty == true
              ? doc.data()['uid'].toString()
              : doc.id;
      final ref = _firestore.collection('notifications').doc();
      batch.set(ref, {
        'targetUserId': uid,
        'title': title,
        'message': message,
        'incidentId': incidentId,
        'type': type,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
