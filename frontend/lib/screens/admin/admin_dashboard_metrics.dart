import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/incident_service.dart';

/// Agrégations pures à partir des snapshots incidents (logique métier inchangée côté Firestore).
class AdminDashboardMetrics {
  AdminDashboardMetrics._(this._docs);

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;

  factory AdminDashboardMetrics.fromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) => AdminDashboardMetrics._(docs);

  int get total => _docs.length;

  int get resolved =>
      _docs.where((d) => IncidentService.normStatus(d.data()['status']?.toString()) == 'closed').length;

  int get inProgress => _docs
      .where((d) => IncidentService.normStatus(d.data()['status']?.toString()) == 'in_progress')
      .length;

  int get unassignedOpen => _docs.where((d) {
    final st = IncidentService.normStatus(d.data()['status']?.toString());
    if (st != 'open') return false;
    final a = IncidentService.assigneeKey(d.data()) ?? '';
    return a.trim().isEmpty;
  }).length;

  int get pendingValidation => _docs
      .where(
        (d) =>
            IncidentService.normStatus(d.data()['status']?.toString()) ==
            'resolved_pending_validation',
      )
      .length;

  /// Indice 0–100 : part d’incidents clôturés (satisfaction opérationnelle).
  int get satisfactionIndex {
    if (total == 0) return 0;
    return ((resolved / total) * 100).round().clamp(0, 100);
  }

  /// Taux de résolution % (incidents fermés / total).
  double get resolutionRatePercent => total == 0 ? 0.0 : (resolved / total) * 100;

  /// Temps moyen de résolution en heures (documents [closed] avec createdAt + closedAt ou resolvedAt).
  double? get averageResolutionHours {
    final durations = <double>[];
    for (final d in _docs) {
      final data = d.data();
      if (IncidentService.normStatus(data['status']?.toString()) != 'closed') continue;
      final created = _tsMillis(data, ['createdAt', 'created_at', 'date']);
      if (created == null) continue;
      final end = _tsMillis(data, ['closedAt', 'resolvedAt', 'updatedAt']);
      if (end == null || end <= created) continue;
      durations.add((end - created) / (1000 * 60 * 60));
    }
    if (durations.isEmpty) return null;
    return durations.reduce((a, b) => a + b) / durations.length;
  }

  static int? _tsMillis(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v is Timestamp) return v.millisecondsSinceEpoch;
      if (v is int) return v;
    }
    return null;
  }

  static const List<String> typesOrder = ['IT', 'Electricite', 'Mecanique', 'Eau'];

  Map<String, int> get countsByType {
    final m = <String, int>{for (final t in typesOrder) t: 0};
    for (final d in _docs) {
      final type = (d.data()['type'] ?? '').toString().trim();
      if (m.containsKey(type)) m[type] = m[type]! + 1;
    }
    return m;
  }

  /// Index 0 = aujourd’hui, 6 = il y a 6 jours (7 valeurs).
  List<int> get incidentsLast7Days {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final buckets = List<int>.filled(7, 0);
    for (final d in _docs) {
      final created = d.data()['createdAt'];
      if (created is! Timestamp) continue;
      final day = DateTime(
        created.toDate().year,
        created.toDate().month,
        created.toDate().day,
      );
      if (day.isBefore(start)) continue;
      final endDay = DateTime(now.year, now.month, now.day);
      if (day.isAfter(endDay)) continue;
      final index = day.difference(start).inDays;
      if (index >= 0 && index < 7) buckets[index]++;
    }
    return buckets;
  }

  /// 30 jours, index 0 = le plus ancien.
  List<int> get incidentsLast30DaysSparkline {
    final now = DateTime.now();
    final endDay = DateTime(now.year, now.month, now.day);
    final start = endDay.subtract(const Duration(days: 29));
    final buckets = List<int>.filled(30, 0);
    for (final d in _docs) {
      final created = d.data()['createdAt'];
      if (created is! Timestamp) continue;
      final day = DateTime(
        created.toDate().year,
        created.toDate().month,
        created.toDate().day,
      );
      if (day.isBefore(start) || day.isAfter(endDay)) continue;
      final index = day.difference(start).inDays;
      if (index >= 0 && index < 30) buckets[index]++;
    }
    return buckets;
  }

  int get urgentCriticalOpenCount => _docs.where((d) {
    final st = IncidentService.normStatus(d.data()['status']?.toString());
    if (st != 'open') return false;
    final p = (d.data()['priority'] ?? '').toString().toLowerCase();
    return p.contains('crit');
  }).length;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get criticalRecent {
    final crit = _docs.where((d) {
      final p = (d.data()['priority'] ?? '').toString().toLowerCase();
      return p.contains('crit');
    }).toList();
    crit.sort((a, b) {
      final ta = a.data()['createdAt'];
      final tb = b.data()['createdAt'];
      final ma = ta is Timestamp ? ta.millisecondsSinceEpoch : 0;
      final mb = tb is Timestamp ? tb.millisecondsSinceEpoch : 0;
      return mb.compareTo(ma);
    });
    return crit.take(6).toList();
  }

  static bool _isCriticalResolved(Map<String, dynamic> data) {
    final st = IncidentService.normStatus(data['status']?.toString());
    if (st != 'closed') return false;
    final p = (data['priority'] ?? '').toString().toLowerCase();
    return p.contains('crit');
  }

  int criticalResolvedForTechnician(String uid) {
    return _docs.where((d) {
      final key = IncidentService.assigneeKey(d.data());
      return key == uid && _isCriticalResolved(d.data());
    }).length;
  }
}
