import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Timeline à partir des notifications admin (même schéma Firestore).
class DashboardActivityTimeline extends StatelessWidget {
  const DashboardActivityTimeline({super.key, required this.docs});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  static String _relative(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'À l’instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }

  static (Color, IconData) _styleForType(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('assign') || t.contains('affect')) {
      return (AppColors.statBlue, Icons.person_add_alt_1_rounded);
    }
    if (t.contains('valid')) {
      return (AppColors.statGreen, Icons.verified_rounded);
    }
    if (t.contains('refus') || t.contains('reject')) {
      return (AppColors.statRed, Icons.cancel_rounded);
    }
    if (t.contains('resolu') || t.contains('resolved') || t.contains('clos')) {
      return (AppColors.accentMuted, Icons.check_circle_outline_rounded);
    }
    if (t.contains('new_incident') || t.contains('incident')) {
      return (AppColors.statOrange, Icons.add_alert_rounded);
    }
    return (AppColors.textMuted, Icons.notifications_none_rounded);
  }

  static String _titleLabel(String? type, String title) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('assign')) return 'Affectation';
    if (t.contains('valid')) return 'Validation';
    if (t.contains('refus')) return 'Refus technicien';
    if (t.contains('resolved') || t.contains('resolu')) return 'Résolution';
    if (t.contains('new_incident')) return 'Incident créé';
    return title.isNotEmpty ? title : 'Activité';
  }

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Aucune activité récente.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Column(
      children: docs.asMap().entries.map((e) {
        final i = e.key;
        final d = e.value.data();
        final title = d['title']?.toString() ?? '';
        final message = d['message']?.toString() ?? '';
        final type = d['type']?.toString();
        final created = d['createdAt'] as Timestamp?;
        final (color, icon) = _styleForType(type);
        final isLast = i == docs.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.45),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withValues(alpha: 0.5),
                                AppColors.border.withValues(alpha: 0.2),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 16, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _titleLabel(type, title),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            _relative(created),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.isNotEmpty ? message : title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
