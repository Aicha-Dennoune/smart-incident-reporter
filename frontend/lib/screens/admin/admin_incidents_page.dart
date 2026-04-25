import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/incident_service.dart';
import '../../theme/industrial_tokens.dart';
import '../../utils/firestore_debug.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/industrial/neo_card.dart';

class AdminIncidentsPage extends StatefulWidget {
  const AdminIncidentsPage({super.key});

  @override
  State<AdminIncidentsPage> createState() => _AdminIncidentsPageState();
}

class _AdminIncidentsPageState extends State<AdminIncidentsPage> {
  final IncidentService _service = IncidentService();

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _incidents = [];
  bool _loading = true;
  Object? _loadError;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incidentsSub;

  void _applyIncidentsSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final docs = IncidentService.sortedIncidentDocs(snap);
    if (!mounted) return;
    setState(() {
      _incidents = docs;
      _loading = false;
      _loadError = null;
    });
  }

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance.collection('incidents').get().then((snap) {
      if (!mounted) return;
      _applyIncidentsSnapshot(snap);
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    });
    _incidentsSub = FirebaseFirestore.instance
        .collection('incidents')
        .snapshots()
        .listen(
          _applyIncidentsSnapshot,
          onError: (Object e, StackTrace _) {
            if (!mounted) return;
            setState(() {
              _loadError = e;
              _loading = false;
            });
          },
        );
  }

  @override
  void dispose() {
    _incidentsSub?.cancel();
    super.dispose();
  }

  String _normalizeSpeciality(String type) {
    final t = type.trim().toLowerCase();
    if (t == 'électricité' || t == 'electricite') return 'Electricite';
    if (t == 'mécanique' || t == 'mecanique') return 'Mecanique';
    if (t == 'eau') return 'Eau';
    return 'IT';
  }

  Color _accentForStatus(String status) {
    switch (IncidentService.normStatus(status)) {
      case 'in_progress':
        return IndustrialTokens.statOrange;
      case 'open':
        return IndustrialTokens.neonMuted;
      default:
        return IndustrialTokens.statBlue;
    }
  }

  String _statusFr(String status) {
    switch (IncidentService.normStatus(status)) {
      case 'open':
        return 'Ouvert';
      case 'in_progress':
        return 'En cours';
      case 'resolved_pending_validation':
        return 'À valider';
      case 'closed':
        return 'Résolu';
      default:
        return status;
    }
  }

  bool _canAssign(String status) => IncidentService.normStatus(status) == 'open';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Incidents'),
      body:
          _loadError != null
              ? Center(child: firestoreErrorPanel(_loadError!))
              : _loading && _incidents.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _incidents.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: const Text(
                    'Aucun incident.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: IndustrialTokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _incidents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final doc = _incidents[index];
                  final data = doc.data();
                  final title = data['title']?.toString() ?? '';
                  final type = data['type']?.toString() ?? '';
                  final st = IncidentService.normStatus(
                    data['status']?.toString(),
                  );
                  final status = st.isEmpty ? 'open' : st;
                  final createdBy = IncidentService.creatorKey(data);
                  final canAssign = _canAssign(status);

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap:
                        !canAssign
                            ? null
                            :
                        () => _showAssignBottomSheet(
                          context: context,
                          incidentId: doc.id,
                          incidentType: type,
                          status: status,
                        ),
                    child: NeoCard(
                      accentColor: _accentForStatus(status),
                      accentWidth: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title.isEmpty ? 'Incident sans titre' : title,
                                  style: const TextStyle(
                                    color: IndustrialTokens.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              _StatusBadge(
                                rawStatus: status,
                                label: _statusFr(status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Type : $type',
                            style: const TextStyle(
                              color: IndustrialTokens.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          if (createdBy != null && createdBy.isNotEmpty)
                            _CreatorLine(uid: createdBy),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed:
                                  !canAssign
                                      ? null
                                      : () => _showAssignBottomSheet(
                                        context: context,
                                        incidentId: doc.id,
                                        incidentType: type,
                                        status: status,
                                      ),
                              child: const Text('Affecter'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Future<void> _showAssignBottomSheet({
    required BuildContext context,
    required String incidentId,
    required String incidentType,
    required String status,
  }) async {
    if (!_canAssign(status)) return;
    final safeType = _normalizeSpeciality(incidentType);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: IndustrialTokens.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          child: SizedBox(
            height: 420,
            child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'technicien')
                      .get(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: firestoreErrorPanel(
                      snap.error ?? Exception('Erreur inconnue'),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pool = IncidentService.techniciansRoundRobinPool(
                  snap.data!,
                  incidentType,
                );
                if (pool.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun technicien.',
                      style: TextStyle(color: IndustrialTokens.textSecondary),
                    ),
                  );
                }

                Future<void> afterAssign() async {
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                      content: Text('Incident affecté avec succès.'),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Affecter technicien',
                      style: TextStyle(
                        color: IndustrialTokens.neon,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      safeType,
                      style: const TextStyle(
                        color: IndustrialTokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () async {
                        try {
                          await _service.assignIncidentRoundRobin(
                            incidentId: incidentId,
                            incidentTypeRaw: incidentType,
                          );
                          await afterAssign();
                        } catch (e) {
                          if (!sheetContext.mounted) return;
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      },
                      child: const Text('Affecter au prochain (tour)'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ou choisir un technicien :',
                      style: TextStyle(
                        color: IndustrialTokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: pool.length,
                        itemBuilder: (_, index) {
                          final techDoc = pool[index];
                          final tech = techDoc.data();
                          final uid = IncidentService.technicianUidFromUserDoc(
                            techDoc,
                          );
                          final nom = tech['nom']?.toString() ?? '';
                          final prenom = tech['prenom']?.toString() ?? '';
                          final lastAssignedAt =
                              tech['lastAssignedAt'] as Timestamp?;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: NeoCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                title: Text(
                                  '$prenom $nom'.trim(),
                                  style: const TextStyle(
                                    color: IndustrialTokens.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  lastAssignedAt == null
                                      ? 'Jamais affecté'
                                      : 'Dernière affectation : ${lastAssignedAt.toDate()}',
                                  style: const TextStyle(
                                    color: IndustrialTokens.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: FilledButton(
                                  onPressed: () async {
                                    await _service.assignIncident(
                                      incidentId: incidentId,
                                      technicianUid: uid,
                                      incidentType: safeType,
                                    );
                                    await afterAssign();
                                  },
                                  child: const Text('Affecter'),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.rawStatus, required this.label});

  final String rawStatus;
  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = rawStatus.toLowerCase();
    Color bg;
    Color fg;
    if (normalized == 'in_progress') {
      bg = const Color(0xFF5D4037);
      fg = IndustrialTokens.statOrange;
    } else if (normalized == 'open') {
      bg = const Color(0xFF1565C0);
      fg = const Color(0xFFBBDEFB);
    } else if (normalized == 'closed') {
      bg = const Color(0xFF1B5E20);
      fg = IndustrialTokens.statGreen;
    } else {
      bg = IndustrialTokens.cardBorder;
      fg = IndustrialTokens.textPrimary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _CreatorLine extends StatelessWidget {
  const _CreatorLine({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final d = snap.data?.data() ?? {};
        final label = '${d['prenom'] ?? ''} ${d['nom'] ?? ''}'.trim();
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Créateur : ${label.isEmpty ? uid : label}',
            style: const TextStyle(
              color: IndustrialTokens.textSecondary,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }
}
