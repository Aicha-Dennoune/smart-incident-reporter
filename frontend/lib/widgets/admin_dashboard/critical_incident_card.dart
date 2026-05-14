import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/incident_service.dart';
import '../../theme/app_colors.dart';

class DashboardCriticalIncidentTile extends StatelessWidget {
  const DashboardCriticalIncidentTile({super.key, required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  static String _statusFr(String? s) {
    switch (IncidentService.normStatus(s)) {
      case 'open':
        return 'Ouvert';
      case 'in_progress':
        return 'En cours';
      case 'resolved_pending_validation':
        return 'Validation';
      case 'closed':
        return 'Résolu';
      default:
        return s ?? '—';
    }
  }

  static String _typeFr(String? t) {
    switch (t) {
      case 'Electricite':
        return 'Électricité';
      case 'Mecanique':
        return 'Mécanique';
      default:
        return t ?? '—';
    }
  }

  static Color _statusColor(String? st) {
    switch (IncidentService.normStatus(st)) {
      case 'open':
        return AppColors.statRed;
      case 'in_progress':
        return AppColors.statOrange;
      default:
        return AppColors.statPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final title = data['title']?.toString() ?? 'Incident';
    final type = _typeFr(data['type']?.toString());
    final status = data['status']?.toString();
    final created = data['createdAt'] as Timestamp?;
    final dateStr = created == null
        ? '—'
        : '${created.toDate().day}/${created.toDate().month}/${created.toDate().year}';
    final stColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderMuted),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.statRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.statRed.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.statRed.withValues(alpha: 0.6)),
                            ),
                            child: const Text(
                              'CRITIQUE',
                              style: TextStyle(
                                color: AppColors.statRed,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: stColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: stColor.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              _statusFr(status),
                              style: TextStyle(
                                color: stColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$type • $dateStr',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
