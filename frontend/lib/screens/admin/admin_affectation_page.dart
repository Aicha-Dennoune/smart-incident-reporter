import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/incident_service.dart';
import '../../theme/industrial_tokens.dart';
import '../../utils/firestore_debug.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/industrial/neo_card.dart';
import '../../widgets/industrial/section_title.dart';

class AdminAffectationPage extends StatelessWidget {
  const AdminAffectationPage({super.key});

  static String _normalizeSpeciality(String type) {
    final t = type.trim().toLowerCase();
    if (t == 'électricité' || t == 'electricite') return 'Electricite';
    if (t == 'mécanique' || t == 'mecanique') return 'Mecanique';
    if (t == 'eau') return 'Eau';
    return 'IT';
  }

  static String _normSt(String? s) => (s ?? '').toLowerCase().trim();

  static String _statusFr(String? s) {
    switch (_normSt(s)) {
      case 'open':
        return 'Ouvert';
      case 'in_progress':
        return 'En cours';
      case 'resolved_pending_validation':
        return 'À valider';
      case 'closed':
        return 'Résolu';
      default:
        return s ?? '';
    }
  }

  static String _assignLabel(String? status, String? assignedTo) {
    final st = _normSt(status);
    final at = assignedTo?.trim() ?? '';
    if (st == 'open' && at.isEmpty) {
      return 'Non affecté';
    }
    if (st == 'in_progress') return 'En cours';
    return _statusFr(status);
  }

  static Color _accent(String? status, String? assignedTo) {
    final st = _normSt(status);
    final at = assignedTo?.trim() ?? '';
    if (st == 'open' && at.isEmpty) {
      return IndustrialTokens.neon;
    }
    if (st == 'in_progress') return IndustrialTokens.statOrange;
    return IndustrialTokens.statBlue;
  }

  static Widget _chip(String text, {required bool orange}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:
            orange
                ? IndustrialTokens.statOrange
                : const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: orange ? IndustrialTokens.bg : const Color(0xFFBBDEFB),
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  static String _ago(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    final service = IncidentService();
    return Scaffold(
      appBar: const AppTopBar(title: 'Affectation'),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.watchIncidents(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: firestoreErrorPanel(snapshot.error!));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = IncidentService.sortedIncidentDocs(snapshot.data);
          final open =
              all
                  .where((d) {
                    final data = d.data();
                    final s = _normSt(data['status']?.toString());
                    if (s != 'open') return false;
                    final a = IncidentService.assigneeKey(data) ?? '';
                    return a.isEmpty;
                  })
                  .toList();
          final featured = open.isNotEmpty ? open.first : null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              if (featured != null) ...[
                _FeaturedAssignCard(
                  incidentId: featured.id,
                  data: featured.data(),
                  service: service,
                ),
                const SizedBox(height: 20),
              ],
              const SectionTitle('Tous les incidents'),
              const SizedBox(height: 10),
              if (all.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aucun incident dans cette réponse.',
                        style: TextStyle(color: IndustrialTokens.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        firestoreListDebugFooter(snapshot.data),
                        style: const TextStyle(
                          color: IndustrialTokens.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...all.map((doc) {
                  final data = doc.data();
                  final status = data['status']?.toString();
                  final assignedTo = IncidentService.assigneeKey(data);
                  final chipText = _assignLabel(status, assignedTo);
                  final orange = _normSt(status) == 'in_progress';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (_normSt(status) == 'open' &&
                            (assignedTo == null || assignedTo.isEmpty)) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder:
                                  (_) => _AssignIncidentPage(
                                    incidentId: doc.id,
                                    incidentType:
                                        data['type']?.toString() ?? 'IT',
                                  ),
                            ),
                          );
                        }
                      },
                      child: NeoCard(
                        accentColor: _accent(status, assignedTo),
                        accentWidth: 5,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['title']?.toString() ?? 'Sans titre',
                                    style: const TextStyle(
                                      color: IndustrialTokens.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${data['type'] ?? ''} • ${_ago(data['createdAt'] as Timestamp?)}',
                                    style: const TextStyle(
                                      color: IndustrialTokens.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _chip(chipText, orange: orange),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _FeaturedAssignCard extends StatelessWidget {
  const _FeaturedAssignCard({
    required this.incidentId,
    required this.data,
    required this.service,
  });

  final String incidentId;
  final Map<String, dynamic> data;
  final IncidentService service;

  @override
  Widget build(BuildContext context) {
    final type = data['type']?.toString() ?? 'IT';
    final normalized = AdminAffectationPage._normalizeSpeciality(type);
    final status = data['status']?.toString() ?? '';

    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title']?.toString() ?? 'Sans titre',
            style: const TextStyle(
              color: IndustrialTokens.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                color: IndustrialTokens.textSecondary,
                fontSize: 13,
              ),
              children: [
                const TextSpan(text: 'Type : '),
                TextSpan(
                  text: type,
                  style: const TextStyle(color: IndustrialTokens.textPrimary),
                ),
                const TextSpan(text: ' • Statut : '),
                TextSpan(
                  text: AdminAffectationPage._statusFr(status),
                  style: const TextStyle(color: Color(0xFF90CAF9)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Techniciens suggérés ↓',
            style: TextStyle(
              color: IndustrialTokens.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.watchTechnicians(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return firestoreErrorPanel(snapshot.error!);
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final docs = IncidentService.techniciansForSpeciality(
                snapshot.data,
                normalized,
              );
              if (docs.isEmpty) {
                return const Text(
                  'Aucun technicien pour cette spécialité.',
                  style: TextStyle(color: IndustrialTokens.textSecondary),
                );
              }
              return Column(
                children:
                    docs.map((techDoc) {
                      final d = techDoc.data();
                      final uid =
                          d['uid']?.toString().isNotEmpty == true
                              ? d['uid'].toString()
                              : techDoc.id;
                      final nom = '${d['prenom'] ?? ''} ${d['nom'] ?? ''}'.trim();
                      final score = d['score'] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NeoCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: IndustrialTokens.cardBorder,
                                child: Text(
                                  _initials(d),
                                  style: const TextStyle(
                                    color: IndustrialTokens.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nom.isEmpty ? 'Technicien' : nom,
                                      style: const TextStyle(
                                        color: IndustrialTokens.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFFFD54F),
                                          size: 16,
                                        ),
                                        Text(
                                          '$score pts • Libre',
                                          style: const TextStyle(
                                            color:
                                                IndustrialTokens.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton(
                                onPressed: () async {
                                  await service.assignIncident(
                                    incidentId: incidentId,
                                    technicianUid: uid,
                                    incidentType: normalized,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Technicien affecté.'),
                                    ),
                                  );
                                },
                                child: const Text('Affecter'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _initials(Map<String, dynamic> d) {
    final p = (d['prenom'] as String?) ?? '';
    final n = (d['nom'] as String?) ?? '';
    final a = p.isNotEmpty ? p[0].toUpperCase() : '';
    final b = n.isNotEmpty ? n[0].toUpperCase() : '';
    final v = '$a$b';
    return v.isEmpty ? '?' : v;
  }
}

class _AssignIncidentPage extends StatelessWidget {
  const _AssignIncidentPage({
    required this.incidentId,
    required this.incidentType,
  });

  final String incidentId;
  final String incidentType;

  @override
  Widget build(BuildContext context) {
    final service = IncidentService();
    final normalized = AdminAffectationPage._normalizeSpeciality(incidentType);
    return Scaffold(
      appBar: const AppTopBar(title: 'Affecter technicien'),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.watchTechnicians(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: firestoreErrorPanel(snapshot.error!));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = IncidentService.techniciansForSpeciality(
            snapshot.data,
            normalized,
          );
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Aucun technicien disponible.',
                style: TextStyle(color: IndustrialTokens.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final uid =
                  d['uid']?.toString().isNotEmpty == true
                      ? d['uid'].toString()
                      : docs[i].id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NeoCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${d['prenom'] ?? ''} ${d['nom'] ?? ''}'.trim(),
                      style: const TextStyle(
                        color: IndustrialTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Spécialité : ${d['specialite'] ?? ''}',
                      style: const TextStyle(
                        color: IndustrialTokens.textSecondary,
                      ),
                    ),
                    trailing: FilledButton(
                      onPressed: () async {
                        await service.assignIncident(
                          incidentId: incidentId,
                          technicianUid: uid,
                          incidentType: normalized,
                        );
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Incident affecté.')),
                        );
                      },
                      child: const Text('Affecter'),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
