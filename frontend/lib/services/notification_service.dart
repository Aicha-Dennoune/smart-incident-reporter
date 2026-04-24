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

  static bool isRead(Map<String, dynamic> data) {
    final v = data['isRead'];
    if (v is bool) return v;
    return false;
  }

  /// Stream brut (pas de .map) — tri côté UI avec [sortedNotificationDocs].
  ///
  /// Basé sur `targetUserId` (structure officielle des notifications).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchForUser(String uid) {
    return _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUnreadForUser(String uid) {
    return _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
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

  static int unreadCount(QuerySnapshot<Map<String, dynamic>>? snap) {
    if (snap == null) return 0;
    return snap.docs.where((d) => !isRead(d.data())).length;
  }

  Future<void> createForUser({
    required String targetUserId,
    required String title,
    required String message,
    String? incidentId,
    String type = 'info',
  }) async {
    await sendNotification(
      targetUserId: targetUserId,
      title: title,
      message: message,
      type: type,
      incidentId: incidentId,
    );
  }

  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String message,
    required String type,
    String? incidentId,
  }) async {
    await _firestore.collection('notifications').add({
      'targetUserId': targetUserId,
      'title': title,
      'message': message,
      'incidentId': incidentId,
      'type': type,
      'isRead': false,
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
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> markAllAsReadForUser(String uid) async {
    final snap = await _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: uid)
        .get();
    if (snap.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (!isRead(data)) {
        batch.update(doc.reference, {
          'isRead': true,
        });
      }
    }
    await batch.commit();
  }
}
