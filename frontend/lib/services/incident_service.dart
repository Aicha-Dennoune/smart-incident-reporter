import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'notification_service.dart';

/// Résultat de [IncidentService.createIncident].
class IncidentCreateResult {
  const IncidentCreateResult({required this.id, this.imageError});

  final String id;
  final String? imageError;
}

class IncidentService {
  IncidentService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    NotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _notificationService =
           notificationService ?? NotificationService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final NotificationService _notificationService;

  // ---------------------------------------------------------------------------
  // Streams Firestore bruts (pas de .map).
  // Chaque appel crée un nouveau Stream (broadcast côté plugin) : plusieurs
  // StreamBuilder peuvent écouter sans « Stream has already been listened to ».
  // includeMetadataChanges : sur desktop / cache, une 1ʳᵉ émission peut être vide
  // puis le serveur remplit — sans ça, l’UI peut rester bloquée sur vide.
  // ---------------------------------------------------------------------------

  /// Tous les documents de la collection `incidents`.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchIncidents() {
    return _firestore
        .collection('incidents')
        .snapshots(includeMetadataChanges: true);
  }

  /// Tous les utilisateurs avec rôle technicien (filtrage spécialité côté UI).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchTechnicians() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'technicien')
        .snapshots(includeMetadataChanges: true);
  }

  // ---------------------------------------------------------------------------
  // Lecture tolérante des champs
  // ---------------------------------------------------------------------------

  static String? _stringField(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      if (v is DocumentReference) return v.id;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static String normStatus(String? raw) =>
      (raw ?? '').toString().toLowerCase().trim();

  /// Créateur de l'incident (UID ou email selon ce qui est stocké).
  static String? creatorKey(Map<String, dynamic> m) => _stringField(m, [
    'createdBy',
    'created_by',
    'createdByUid',
    'created_by_uid',
    'creatorUid',
    'creator_uid',
    'creatorId',
    'creator_id',
    'userId',
    'user_id',
    'reporterUid',
    'reporter_id',
    'employeId',
    'employe_id',
    'authorId',
    'author_id',
    'submittedBy',
    'submitted_by',
  ]);

  static String? assigneeKey(Map<String, dynamic> m) => _stringField(m, [
    'assignedTo',
    'assigned_to',
    'technicianUid',
    'technician_id',
  ]);

  static String? imageUrlFrom(Map<String, dynamic> m) {
    final u = _stringField(m, [
      'imageUrl',
      'image_url',
      'photoUrl',
      'photo_url',
      'image',
    ]);
    return u;
  }

  static bool matchesCreator(
    Map<String, dynamic> data,
    String uid,
    String? email,
  ) {
    final key = creatorKey(data);
    if (key == null) return false;
    if (key == uid) return true;
    final em = email?.trim().toLowerCase();
    if (em != null && em.isNotEmpty && key.toLowerCase() == em) return true;
    return false;
  }

  static bool matchesAssignee(Map<String, dynamic> data, String uid) {
    final key = assigneeKey(data);
    return key != null && key == uid;
  }

  static String canonicalSpeciality(String? raw) {
    if (raw == null) return 'it';
    var t =
        raw
            .trim()
            .toLowerCase()
            .replaceAll('é', 'e')
            .replaceAll('è', 'e')
            .replaceAll('ê', 'e');
    if (t.contains('electric')) return 'electricite';
    if (t.contains('meca')) return 'mecanique';
    if (t.contains('eau') || t.contains('water')) return 'eau';
    if (t == 'it' || t.contains('info') || t.contains('informatique')) {
      return 'it';
    }
    return t;
  }

  static int _createdAtMillis(Map<String, dynamic> data) {
    for (final k in ['createdAt', 'created_at', 'date', 'timestamp']) {
      final v = data[k];
      if (v is Timestamp) return v.millisecondsSinceEpoch;
      if (v is int) return v;
    }
    return 0;
  }

  static void _sortByCreatedAtDesc(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    docs.sort(
      (a, b) => _createdAtMillis(b.data()).compareTo(_createdAtMillis(a.data())),
    );
  }

  /// Tous les incidents, triés (à partir d'un snapshot Firestore).
  static List<QueryDocumentSnapshot<Map<String, dynamic>>> sortedIncidentDocs(
    QuerySnapshot<Map<String, dynamic>>? snap,
  ) {
    if (snap == null) return [];
    final docs = snap.docs.toList();
    _sortByCreatedAtDesc(docs);
    return docs;
  }

  /// Incidents d'un employé.
  static List<QueryDocumentSnapshot<Map<String, dynamic>>> incidentsForCreator(
    QuerySnapshot<Map<String, dynamic>>? snap,
    String uid,
    String? email,
  ) {
    if (snap == null) return [];
    final docs =
        snap.docs.where((d) => matchesCreator(d.data(), uid, email)).toList();
    _sortByCreatedAtDesc(docs);
    return docs;
  }

  /// Incidents assignés au technicien.
  static List<QueryDocumentSnapshot<Map<String, dynamic>>> incidentsForAssignee(
    QuerySnapshot<Map<String, dynamic>>? snap,
    String uid,
  ) {
    if (snap == null) return [];
    final docs =
        snap.docs.where((d) => matchesAssignee(d.data(), uid)).toList();
    _sortByCreatedAtDesc(docs);
    return docs;
  }

  static int _lastAssignedMillis(Map<String, dynamic> data) {
    final v = data['lastAssignedAt'];
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    return 0;
  }

  static List<QueryDocumentSnapshot<Map<String, dynamic>>> techniciansForSpeciality(
    QuerySnapshot<Map<String, dynamic>>? snap,
    String speciality,
  ) {
    if (snap == null) return [];
    final target = canonicalSpeciality(speciality);
    final docs =
        snap.docs.where((doc) {
          final spec = doc.data()['specialite']?.toString();
          return canonicalSpeciality(spec) == target;
        }).toList();
    docs.sort(
      (a, b) => _lastAssignedMillis(
        a.data(),
      ).compareTo(_lastAssignedMillis(b.data())),
    );
    return docs;
  }

  /// File pour le « tour » : même spécialité que l’incident si possible, sinon tous
  /// les techniciens — tri par [lastAssignedAt] croissant (prochain = le plus ancien).
  static List<QueryDocumentSnapshot<Map<String, dynamic>>> techniciansRoundRobinPool(
    QuerySnapshot<Map<String, dynamic>> techSnap,
    String incidentTypeRaw,
  ) {
    if (techSnap.docs.isEmpty) return [];
    var pool = techniciansForSpeciality(techSnap, incidentTypeRaw);
    if (pool.isNotEmpty) return pool;
    final all = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(techSnap.docs);
    all.sort(
      (a, b) => _lastAssignedMillis(
        a.data(),
      ).compareTo(_lastAssignedMillis(b.data())),
    );
    return all;
  }

  static String technicianUidFromUserDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final u = doc.data()['uid']?.toString().trim();
    if (u != null && u.isNotEmpty) return u;
    return doc.id;
  }

  /// Affecte au technicien en tête de la file [techniciansRoundRobinPool] (tour simple).
  Future<void> assignIncidentRoundRobin({
    required String incidentId,
    required String incidentTypeRaw,
  }) async {
    final techSnap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'technicien')
        .get();
    final pool = techniciansRoundRobinPool(techSnap, incidentTypeRaw);
    if (pool.isEmpty) {
      throw StateError('Aucun technicien.');
    }
    final uid = technicianUidFromUserDoc(pool.first);
    final label =
        incidentTypeRaw.trim().isEmpty ? 'IT' : incidentTypeRaw.trim();
    await assignIncident(
      incidentId: incidentId,
      technicianUid: uid,
      incidentType: label,
    );
  }

  Future<IncidentCreateResult> createIncident({
    required String title,
    required String description,
    required String type,
    required String createdBy,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final docRef = _firestore.collection('incidents').doc();

    await docRef.set({
      'title': title.trim(),
      'description': description.trim(),
      'type': type.trim(),
      'imageUrl': '',
      'status': 'open',
      'createdBy': createdBy,
      'assignedTo': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    String? imageError;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        final url = await _uploadImage(
          imageBytes: imageBytes,
          imageName: imageName,
          createdBy: createdBy,
          incidentId: docRef.id,
        );
        await docRef.update({'imageUrl': url});
      } catch (e) {
        imageError = e.toString();
        await docRef.update({
          'imageUploadFailed': true,
          'imageUploadError': imageError,
        });
      }
    }

    try {
      await _notificationService.createForRole(
        role: 'admin',
        title: 'Nouvel incident',
        message: title.trim().isEmpty
            ? 'Un nouvel incident a ete signale.'
            : 'Nouvel incident : ${title.trim()}',
        incidentId: docRef.id,
        type: 'new_incident',
      );
    } catch (_) {}

    return IncidentCreateResult(id: docRef.id, imageError: imageError);
  }

  Future<void> assignIncident({
    required String incidentId,
    required String technicianUid,
    required String incidentType,
  }) async {
    final batch = _firestore.batch();
    final incidentRef = _firestore.collection('incidents').doc(incidentId);
    final techRef = _firestore.collection('users').doc(technicianUid);

    batch.update(incidentRef, {
      'assignedTo': technicianUid,
      'status': 'in_progress',
    });
    batch.update(techRef, {'lastAssignedAt': FieldValue.serverTimestamp()});

    await batch.commit();

    await _notificationService.createForUser(
      targetUserId: technicianUid,
      title: 'Nouvel incident assigne',
      message: 'Incident type $incidentType assigne a votre file.',
      incidentId: incidentId,
      type: 'assignment',
    );
  }

  Future<void> markResolvedPendingValidation({
    required String incidentId,
    required String technicianUid,
  }) async {
    final incidentRef = _firestore.collection('incidents').doc(incidentId);
    final incident = await incidentRef.get();
    final data = incident.data() ?? {};
    final createdBy = creatorKey(data);

    await incidentRef.update({
      'status': 'resolved_pending_validation',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': technicianUid,
    });

    if (createdBy != null &&
        createdBy.isNotEmpty &&
        !createdBy.contains('@')) {
      await _notificationService.createForUser(
        targetUserId: createdBy,
        title: 'Incident resolu',
        message: 'Incident résolu, veuillez valider',
        incidentId: incidentId,
        type: 'resolved_pending_validation',
      );
    }
  }

  Future<void> markImpossibleToResolve({
    required String incidentId,
    required String technicianUid,
  }) async {
    final incidentRef = _firestore.collection('incidents').doc(incidentId);
    await incidentRef.update({
      'status': 'open',
      'assignedTo': null,
      'lastRejectedBy': technicianUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notificationService.createForRole(
      role: 'admin',
      title: 'Reaffectation necessaire',
      message: 'Incident non résolu, réaffectation requise',
      incidentId: incidentId,
      type: 'technician_refused',
    );
  }

  Future<void> validateResolvedIncident({
    required String incidentId,
    required bool accepted,
  }) async {
    final incidentRef = _firestore.collection('incidents').doc(incidentId);
    final incident = await incidentRef.get();
    final data = incident.data() ?? {};
    final technicianUid =
        (data['resolvedBy'] ?? assigneeKey(data))?.toString();

    if (accepted) {
      final batch = _firestore.batch();
      batch.update(incidentRef, {
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
      });
      if (technicianUid != null && technicianUid.isNotEmpty) {
        batch.set(
          _firestore.collection('users').doc(technicianUid),
          {'score': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      await _notificationService.createForRole(
        role: 'admin',
        title: 'Validation employé',
        message: 'Incident résolu avec succès',
        incidentId: incidentId,
        type: 'resolution_validated',
      );
      return;
    }

    await incidentRef.update({
      'status': 'in_progress',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (technicianUid != null && technicianUid.isNotEmpty) {
      await _notificationService.createForUser(
        targetUserId: technicianUid,
        title: 'Resolution refusee',
        message: 'L\'employe a refuse la resolution, veuillez reprendre.',
        incidentId: incidentId,
        type: 'validation_rejected',
      );
    }
  }

  static String _contentTypeForFileName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  static String _sanitizeFileName(String name) {
    var s = name.replaceAll(RegExp(r'[^\w\.\-]'), '_').replaceAll('__', '_');
    if (s.isEmpty) s = 'photo.jpg';
    if (s.length > 120) s = s.substring(0, 120);
    return s;
  }

  Future<String> _uploadImage({
    required Uint8List imageBytes,
    required String createdBy,
    required String incidentId,
    String? imageName,
  }) async {
    final rawName = imageName?.trim().isNotEmpty == true ? imageName! : 'photo.jpg';
    final safeName = _sanitizeFileName(rawName);
    final filePath = 'incidents/$createdBy/$incidentId/$safeName';
    final ref = _storage.ref().child(filePath);
    final contentType = _contentTypeForFileName(safeName);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(imageBytes, metadata);
    return ref.getDownloadURL();
  }
}
