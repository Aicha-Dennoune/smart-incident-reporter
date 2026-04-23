import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme/industrial_tokens.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/industrial/neo_card.dart';
import '../../widgets/industrial/section_title.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  static String _techInitials(Map<String, dynamic> d) {
    final p = (d['prenom'] as String?) ?? '';
    final n = (d['nom'] as String?) ?? '';
    final a = p.isNotEmpty ? p[0].toUpperCase() : '';
    final b = n.isNotEmpty ? n[0].toUpperCase() : '';
    final v = '$a$b';
    return v.isEmpty ? '?' : v;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Tableau de bord'),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('incidents')
            .snapshots(includeMetadataChanges: true),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur incidents : ${snapshot.error}',
                style: const TextStyle(color: IndustrialTokens.statRed),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final incidents = snapshot.data!.docs;
          final total = incidents.length;
          final open =
              incidents.where((i) => i.data()['status'] == 'open').length;
          final inProgress =
              incidents
                  .where((i) => i.data()['status'] == 'in_progress')
                  .length;
          final closed =
              incidents.where((i) => i.data()['status'] == 'closed').length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _MiniStat(value: '$total', label: 'Total', color: IndustrialTokens.statBlue),
                  _MiniStat(value: '$open', label: 'Ouverts', color: const Color(0xFF90CAF9)),
                  _MiniStat(
                    value: '$inProgress',
                    label: 'En cours',
                    color: IndustrialTokens.statOrange,
                  ),
                  _MiniStat(
                    value: '$closed',
                    label: 'Résolus',
                    color: IndustrialTokens.statGreen,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const SectionTitle('Top techniciens'),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'technicien')
                    .snapshots(includeMetadataChanges: true),
                builder: (context, techSnapshot) {
                  final techs = techSnapshot.data?.docs ?? [];
                  if (techs.isEmpty) {
                    return const Text(
                      'Aucun technicien',
                      style: TextStyle(color: IndustrialTokens.textSecondary),
                    );
                  }
                  final sorted = [...techs]..sort((a, b) {
                    final sa = (a.data()['score'] as num?)?.toInt() ?? 0;
                    final sb = (b.data()['score'] as num?)?.toInt() ?? 0;
                    return sb.compareTo(sa);
                  });
                  return Column(
                    children:
                        sorted.take(6).map((doc) {
                          final d = doc.data();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: NeoCard(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: IndustrialTokens.neon
                                        .withValues(alpha: 0.2),
                                    child: Text(
                                      _techInitials(d),
                                      style: const TextStyle(
                                        color: IndustrialTokens.neon,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${d['prenom'] ?? ''} ${d['nom'] ?? ''}'
                                              .trim(),
                                          style: const TextStyle(
                                            color: IndustrialTokens.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'Spécialité : ${d['specialite'] ?? ''}',
                                          style: const TextStyle(
                                            color:
                                                IndustrialTokens.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${d['score'] ?? 0}',
                                    style: const TextStyle(
                                      color: IndustrialTokens.neon,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
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
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: IndustrialTokens.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
