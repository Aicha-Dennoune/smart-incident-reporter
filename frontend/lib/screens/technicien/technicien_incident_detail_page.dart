import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/incident_service.dart';
import '../../theme/industrial_tokens.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/industrial/neo_card.dart';

class TechnicienIncidentDetailPage extends StatelessWidget {
  const TechnicienIncidentDetailPage({
    super.key,
    required this.incidentId,
    required this.technicianUid,
  });

  final String incidentId;
  final String technicianUid;

  static String _typeFr(String? t) {
    switch (t) {
      case 'Electricite':
        return 'Électricité';
      case 'Mecanique':
        return 'Mécanique';
      default:
        return t ?? '';
    }
  }

  static String _statusFr(String? s) {
    switch (s) {
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

  static Widget _statusBadge(String? status) {
    final fr = _statusFr(status);
    Color bg;
    Color fg;
    switch (status) {
      case 'in_progress':
        bg = const Color(0xFF5D4037);
        fg = IndustrialTokens.statOrange;
        break;
      case 'open':
        bg = const Color(0xFF1E3A5F);
        fg = const Color(0xFF90CAF9);
        break;
      default:
        bg = IndustrialTokens.card;
        fg = IndustrialTokens.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        fr,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = IncidentService();
    final short = incidentId.length > 4 ? incidentId.substring(incidentId.length - 4) : incidentId;

    return Scaffold(
      appBar: AppTopBar(title: 'Détail incident #$short'),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('incidents')
                .doc(incidentId)
                .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Incident introuvable.'));
          }
          final data = snap.data!.data() ?? {};
          final title = data['title']?.toString() ?? '';
          final type = _typeFr(data['type']?.toString());
          final description = data['description']?.toString() ?? '';
          final status = data['status']?.toString();
          final imageUrl = IncidentService.imageUrlFrom(data) ?? '';
          final createdBy = data['createdBy']?.toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NeoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: IndustrialTokens.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  type,
                                  style: const TextStyle(
                                    color: IndustrialTokens.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _statusBadge(status),
                        ],
                      ),
                      const Divider(
                        height: 28,
                        color: IndustrialTokens.cardBorder,
                      ),
                      const Text(
                        'Description',
                        style: TextStyle(
                          color: IndustrialTokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          color: IndustrialTokens.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                NeoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photo de l\'incident',
                        style: TextStyle(
                          color: IndustrialTokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child:
                              imageUrl.isEmpty
                                  ? Container(
                                    color: IndustrialTokens.bg,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: IndustrialTokens.textSecondary,
                                      size: 40,
                                    ),
                                  )
                                  : Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          color: IndustrialTokens.bg,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.broken_image_outlined,
                                            color: IndustrialTokens.textSecondary,
                                          ),
                                        ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (createdBy != null && createdBy.isNotEmpty)
                  _ReporterCard(createdByUid: createdBy),
                const SizedBox(height: 20),
                if (status == 'in_progress')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              () => service.markResolvedPendingValidation(
                                incidentId: incidentId,
                                technicianUid: technicianUid,
                              ),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Résoudre'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: IndustrialTokens.neon,
                            side: const BorderSide(
                              color: IndustrialTokens.neonMuted,
                              width: 1.4,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4A1515),
                            foregroundColor: const Color(0xFFFF8A80),
                          ),
                          onPressed:
                              () => service.markImpossibleToResolve(
                                incidentId: incidentId,
                                technicianUid: technicianUid,
                              ),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Impossible'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReporterCard extends StatelessWidget {
  const _ReporterCard({required this.createdByUid});

  final String createdByUid;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      accentColor: IndustrialTokens.statOrange,
      accentWidth: 5,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(createdByUid)
                .snapshots(),
        builder: (context, snap) {
          final d = snap.data?.data() ?? {};
          final nom = d['nom']?.toString() ?? '';
          final prenom = d['prenom']?.toString() ?? '';
          final label =
              '$prenom $nom'.trim().isEmpty
                  ? 'Employé'
                  : '$prenom $nom'.trim();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signalé par $label',
                style: const TextStyle(
                  color: IndustrialTokens.neonMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Aujourd\'hui',
                style: TextStyle(
                  color: IndustrialTokens.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
