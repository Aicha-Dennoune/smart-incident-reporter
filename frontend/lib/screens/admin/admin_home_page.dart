import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme/industrial_tokens.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/industrial/neo_card.dart';
import '../../widgets/industrial/section_title.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

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
              const TopTechniciansWidget(),
              const SizedBox(height: 22),
              const SectionTitle('Répartition des incidents par type'),
              const SizedBox(height: 10),
              IncidentTypeDistributionWidget(incidents: incidents),
            ],
          );
        },
      ),
    );
  }
}

class TopTechniciansWidget extends StatelessWidget {
  const TopTechniciansWidget({super.key});

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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
          children: sorted.take(2).map((doc) {
            final d = doc.data();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NeoCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: IndustrialTokens.neon.withValues(alpha: 0.2),
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
                      child: Text(
                        '${d['prenom'] ?? ''} ${d['nom'] ?? ''}'.trim(),
                        style: const TextStyle(
                          color: IndustrialTokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
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
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class IncidentTypeDistributionWidget extends StatelessWidget {
  const IncidentTypeDistributionWidget({super.key, required this.incidents});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> incidents;

  static const List<String> _types = ['Electricite', 'Mecanique', 'IT', 'Eau'];
  static const Color _barBg = Color(0xFF0F2A1C);

  static Color _colorFor(String type) {
    switch (type) {
      case 'Electricite':
        return const Color(0xFF22C55E);
      case 'Mecanique':
        return const Color(0xFFFBBF24);
      case 'IT':
        return const Color(0xFFA78BFA);
      case 'Eau':
        return const Color(0xFF60A5FA);
      default:
        return IndustrialTokens.neon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{for (final t in _types) t: 0};
    for (final doc in incidents) {
      final type = (doc.data()['type'] ?? '').toString().trim();
      if (counts.containsKey(type)) {
        counts[type] = counts[type]! + 1;
      }
    }
    final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);

    return NeoCard(
      child: Column(
        children: _types.map((type) {
          final value = counts[type] ?? 0;
          final ratio = maxCount == 0 ? 0.0 : value / maxCount;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 55,
                  child: Text(
                    type,
                    style: const TextStyle(
                      color: IndustrialTokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 12,
                      color: _barBg,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: ratio),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return FractionallySizedBox(
                              widthFactor: value.clamp(0.0, 1.0),
                              alignment: Alignment.centerLeft,
                              child: Container(color: _colorFor(type)),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 26,
                  child: Text(
                    '$value',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: IndustrialTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
