import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

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
    NotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService =
           notificationService ?? NotificationService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;
  static const String _cloudinaryCloudName = 'dqkqezb7y';
  static const String _cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'incident_upload',
  );

  Future<String?> _adminId() async {
    final snap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;

    // IMPORTANT: on utilise doc.id comme UID admin demandé.
    final adminId = snap.docs.first.id;
    debugPrint('Admin ID: $adminId');
    return adminId;
  }

  Future<void> _notifyAdminsDirect({
    required String title,
    required String message,
    required String type,
    String? incidentId,
  }) async {
    final adminId = await _adminId();
    if (adminId == null || adminId.isEmpty) return;
    await _notificationService.sendNotification(
      targetUserId: adminId,
      title: title,
      message: message,
      type: type,
      incidentId: incidentId,
    );
  }

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

  static String? creatorUid(Map<String, dynamic> data) {
    final key = creatorKey(data);
    if (key == null || key.isEmpty) return null;
    if (key.contains('@')) return null;
    return key;
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
        final url = await _uploadImageToCloudinary(
          imageBytes: imageBytes,
          imageName: imageName,
        );
        await docRef.update({'imageUrl': url});
      } catch (e) {
        imageError = e.toString();
      }
    }

    try {
      await _notifyAdminsDirect(
        title: 'Nouvel incident',
        message: 'Un nouvel incident a été déclaré, veuillez l’affecter',
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
    final incidentRef = _firestore.collection('incidents').doc(incidentId);
    final incidentSnap = await incidentRef.get();
    final incidentData = incidentSnap.data() ?? {};
    final previousAssignee = assigneeKey(incidentData);
    final creatorUidValue = creatorUid(incidentData);
    final isReassignment =
        previousAssignee != null &&
        previousAssignee.isNotEmpty &&
        previousAssignee != technicianUid;

    final batch = _firestore.batch();
    final techRef = _firestore.collection('users').doc(technicianUid);

    batch.update(incidentRef, {
      'assignedTo': technicianUid,
      'status': 'in_progress',
    });
    batch.update(techRef, {'lastAssignedAt': FieldValue.serverTimestamp()});

    await batch.commit();

    await _notificationService.sendNotification(
      targetUserId: technicianUid,
      title: isReassignment ? 'Incident réassigné' : 'Incident assigné',
      message:
          isReassignment
              ? 'Un incident vous a été réaffecté ($incidentType)'
              : 'Un nouvel incident vous a été assigné ($incidentType)',
      incidentId: incidentId,
      type: isReassignment ? 'reassignment' : 'assignment',
    );

    if (creatorUidValue != null && creatorUidValue.isNotEmpty) {
      await _notificationService.sendNotification(
        targetUserId: creatorUidValue,
        title: isReassignment ? 'Incident réaffecté' : 'Incident affecté',
        message:
            isReassignment
                ? 'Votre incident a été réaffecté à un autre technicien'
                : 'Votre incident a été pris en charge par un technicien',
        incidentId: incidentId,
        type: isReassignment ? 'incident_reassigned' : 'incident_assigned',
      );

      await _notificationService.sendNotification(
        targetUserId: creatorUidValue,
        title: 'Incident en cours',
        message: 'Votre incident est en cours de traitement',
        incidentId: incidentId,
        type: 'incident_in_progress',
      );
    }
  }

  Future<void> markResolvedPendingValidation({
    required String incidentId,
    required String technicianUid,
  }) async {
    final incidentRef = _firestore.collection('incidents').doc(incidentId);
    final incident = await incidentRef.get();
    final data = incident.data() ?? {};
    final createdBy = creatorUid(data);

    await incidentRef.update({
      'status': 'resolved_pending_validation',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': technicianUid,
    });

    if (createdBy != null &&
        createdBy.isNotEmpty) {
      await _notificationService.createForUser(
        targetUserId: createdBy,
        title: 'Incident resolu',
        message: 'Incident résolu, veuillez valider',
        incidentId: incidentId,
        type: 'resolved_pending_validation',
      );
    }

    await _notificationService.createForRole(
      role: 'admin',
      title: 'Incident résolu',
      message: 'Un incident a été résolu (en attente de validation)',
      incidentId: incidentId,
      type: 'resolved_waiting_validation',
    );
  }

  Future<void> markImpossibleToResolve({
    required String incidentId,
    required String technicianUid,
  }) async {
    final incidentRef = _firestore.collection('incidents').doc(incidentId);
    final incident = await incidentRef.get();
    final data = incident.data() ?? {};
    final createdBy = creatorUid(data);
    await incidentRef.update({
      'status': 'open',
      'assignedTo': null,
      'lastRejectedBy': technicianUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notifyAdminsDirect(
      title: 'Reaffectation necessaire',
      message:
          'Un incident n’a pas pu être résolu, une réaffectation est nécessaire',
      incidentId: incidentId,
      type: 'technician_refused',
    );

    if (createdBy != null && createdBy.isNotEmpty) {
      await _notificationService.sendNotification(
        targetUserId: createdBy,
        title: 'Incident non résolu',
        message: 'Votre incident n’a pas pu être traité, il sera réaffecté',
        incidentId: incidentId,
        type: 'incident_unresolved',
      );
    }
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
    final createdBy = creatorUid(data);

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
      await _notifyAdminsDirect(
        title: 'Validation employé',
        message: 'L’employé a validé la résolution de l’incident',
        incidentId: incidentId,
        type: 'resolution_validated',
      );
      if (technicianUid != null && technicianUid.isNotEmpty) {
        await _notificationService.sendNotification(
          targetUserId: technicianUid,
          title: 'Validation confirmée',
          message: 'La résolution de votre incident a été validée',
          incidentId: incidentId,
          type: 'resolution_approved',
        );
      }
      if (createdBy != null && createdBy.isNotEmpty) {
        await _notificationService.sendNotification(
          targetUserId: createdBy,
          title: 'Validation enregistrée',
          message: 'Votre validation a été enregistrée, incident clôturé',
          incidentId: incidentId,
          type: 'validation_confirmed',
        );
      }
      return;
    }

    await incidentRef.update({
      'status': 'in_progress',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (technicianUid != null && technicianUid.isNotEmpty) {
      await _notificationService.sendNotification(
        targetUserId: technicianUid,
        title: 'Resolution refusee',
        message:
            'La résolution de l’incident a été refusée, veuillez vérifier',
        incidentId: incidentId,
        type: 'validation_rejected',
      );
    }
    await _notificationService.createForRole(
      role: 'admin',
      title: 'Validation refusée',
      message: 'La résolution d’un incident a été refusée',
      incidentId: incidentId,
      type: 'resolution_refused',
    );
  }

  static bool _isPngName(String name) => name.toLowerCase().endsWith('.png');

  static String _replaceExtension(String fileName, String extension) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0) return '$fileName.$extension';
    return '${fileName.substring(0, dot)}.$extension';
  }

  static ({
    Uint8List bytes,
    String fileName,
    String contentType,
  }) _normalizeImageForUpload({
    required Uint8List sourceBytes,
    required String sourceFileName,
  }) {
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      // Fallback: bytes d'origine (Cloudinary gère la détection).
      return (
        bytes: sourceBytes,
        fileName: sourceFileName,
        contentType: 'application/octet-stream',
      );
    }

    if (_isPngName(sourceFileName)) {
      final pngBytes = Uint8List.fromList(img.encodePng(decoded));
      final pngName = _replaceExtension(sourceFileName, 'png');
      return (bytes: pngBytes, fileName: pngName, contentType: 'image/png');
    }

    final jpgBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
    final jpgName = _replaceExtension(sourceFileName, 'jpg');
    return (bytes: jpgBytes, fileName: jpgName, contentType: 'image/jpeg');
  }

  static String _sanitizeFileName(String name) {
    var s = name.replaceAll(RegExp(r'[^\w\.\-]'), '_').replaceAll('__', '_');
    if (s.isEmpty) s = 'photo.jpg';
    if (s.length > 120) s = s.substring(0, 120);
    return s;
  }

  String _optimizedCloudinaryUrl(String secureUrl) {
    return secureUrl.replaceFirst('/upload/', '/upload/f_auto,q_auto/');
  }

  Future<String> _uploadImageToCloudinary({
    required Uint8List imageBytes,
    String? imageName,
  }) async {
    final rawName = imageName?.trim().isNotEmpty == true ? imageName! : 'photo.jpg';
    final normalized = _normalizeImageForUpload(
      sourceBytes: imageBytes,
      sourceFileName: rawName,
    );
    final safeName = _sanitizeFileName(normalized.fileName);
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload',
    );

    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          normalized.bytes,
          filename: safeName,
        ),
      );

    final response = await req.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): $body',
      );
    }
    final json = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
    final secureUrl = (json['secure_url'] ?? '').toString().trim();
    if (secureUrl.isEmpty) {
      throw Exception('Cloudinary did not return secure_url.');
    }
    return _optimizedCloudinaryUrl(secureUrl);
  }
}
