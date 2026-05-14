import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../screens/admin/admin_dashboard_metrics.dart';
import '../../theme/app_colors.dart';

class TechnicianPodium extends StatelessWidget {
  const TechnicianPodium({
    super.key,
    required this.technicians,
    required this.metrics,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> technicians;
  final AdminDashboardMetrics metrics;

  static String _titleCaseToken(String w) {
    if (w.isEmpty) return '';
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }

  /// Prénom + nom capitalisés ; gère texte collé type « alamirachid » (un seul champ).
  static String formatPersonName(Map<String, dynamic> d) {
    var prenom = (d['prenom'] ?? '').toString().trim();
    var nom = (d['nom'] ?? '').toString().trim();

    if (prenom.isEmpty && nom.isEmpty) {
      final fb =
          (d['displayName'] ?? d['name'] ?? d['fullName'] ?? '').toString().trim();
      if (fb.isEmpty) return '';
      return _formatLooseNameString(fb);
    }

    if (prenom.isNotEmpty && nom.isEmpty && prenom.length >= 6 && !prenom.contains(' ')) {
      final split = _splitGluedLowercase(prenom);
      if (split != null) return split;
    }
    if (nom.isNotEmpty && prenom.isEmpty && nom.length >= 6 && !nom.contains(' ')) {
      final split = _splitGluedLowercase(nom);
      if (split != null) return split;
    }

    final p = _titleCaseToken(prenom);
    final n = _titleCaseToken(nom);
    if (p.isEmpty) return n;
    if (n.isEmpty) return p;
    return '$p $n';
  }

  static String _formatLooseNameString(String raw) {
    final t = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.contains(' ')) {
      return t.split(' ').map(_titleCaseToken).where((e) => e.isNotEmpty).join(' ');
    }
    final camel = _splitCamelCase(t);
    if (camel != null) return camel;
    final glued = _splitGluedLowercase(t);
    return glued ?? _titleCaseToken(t);
  }

  static String? _splitCamelCase(String s) {
    if (s.length < 2) return null;
    final segs = s.split(RegExp(r'(?<=[a-zàâäéèêëïîôùûüç])(?=[A-ZÀÂÄÉÈÊËÏÎÔÙÛÜÇ])'));
    if (segs.length < 2) return null;
    return segs.map(_titleCaseToken).where((e) => e.isNotEmpty).join(' ');
  }

  /// Découpe grossière « prenomnom » tout minuscule (ex. alamirachid → alami | rachid).
  static String? _splitGluedLowercase(String s) {
    if (s.length < 6 || s != s.toLowerCase() || RegExp(r'\s').hasMatch(s)) {
      return null;
    }
    final i = s.length ~/ 2;
    if (i < 2 || i > s.length - 2) return null;
    return '${_titleCaseToken(s.substring(0, i))} ${_titleCaseToken(s.substring(i))}';
  }

  static String _initials(Map<String, dynamic> d) {
    final name = formatPersonName(d);
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.length >= 2
        ? parts.first.substring(0, 2).toUpperCase()
        : parts.first[0].toUpperCase();
  }

  static String _uid(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final u = doc.data()['uid']?.toString().trim();
    if (u != null && u.isNotEmpty) return u;
    return doc.id;
  }

  static String _specFr(String? s) {
    switch (s) {
      case 'Electricite':
        return 'Électricité';
      case 'Mecanique':
        return 'Mécanique';
      default:
        return s ?? '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (technicians.isEmpty) {
      return const Text(
        'Aucun technicien',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    final top = technicians.take(5).toList();
    final podium = top.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (podium.length >= 2)
          SizedBox(
            height: 152,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (podium.length >= 2) _podiumSlot(podium[1], 1, metrics, 118),
                const SizedBox(width: 8),
                if (podium.isNotEmpty) _podiumSlot(podium[0], 0, metrics, 146),
                const SizedBox(width: 8),
                if (podium.length >= 3) _podiumSlot(podium[2], 2, metrics, 108),
              ],
            ),
          )
        else if (podium.isNotEmpty)
          SizedBox(
            height: 144,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 124,
                child: _podiumBody(podium[0], 0, metrics, 128),
              ),
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'Top 5 — performance',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        ...top.asMap().entries.map((e) {
          final i = e.key;
          final doc = e.value;
          final d = doc.data();
          final uid = _uid(doc);
          final crit = metrics.criticalResolvedForTechnician(uid);
          final score = (d['score'] as num?)?.toInt() ?? 0;
          final displayName = formatPersonName(d);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderMuted),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.isEmpty ? 'Technicien' : displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${_specFr(d['specialite']?.toString())} • $crit critique(s) résolu(s)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$score',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  static Widget _podiumSlot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    int rank,
    AdminDashboardMetrics metrics,
    double height,
  ) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: _podiumBody(doc, rank, metrics, height),
      ),
    );
  }

  static Widget _podiumBody(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    int rank,
    AdminDashboardMetrics metrics,
    double height,
  ) {
    final d = doc.data();
    final uid = _uid(doc);
    final crit = metrics.criticalResolvedForTechnician(uid);
    final score = (d['score'] as num?)?.toInt() ?? 0;
    final medal = rank == 0 ? '🥇' : (rank == 1 ? '🥈' : '🥉');
    final fullName = formatPersonName(d);
    final displayName = fullName.isEmpty ? '—' : fullName;

    final compact = height < 124;
    final medalSize = compact ? 17.0 : (rank == 0 ? 21.0 : 19.0);
    final avatarRadius = compact ? 16.0 : (rank == 0 ? 21.0 : 18.0);
    final nameSize = compact ? 12.0 : (rank == 0 ? 13.0 : 12.0);
    final nameLines = compact ? 1 : 2;
    final scoreSize = compact ? 12.0 : 13.0;
    final critSize = compact ? 9.5 : 10.0;
    final initialsSize = compact ? 12.0 : (rank == 0 ? 14.0 : 13.0);

    final pad = EdgeInsets.fromLTRB(
      compact ? 5 : 6,
      compact ? 6 : 8,
      compact ? 5 : 6,
      compact ? 6 : 8,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      height: height,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surfaceHighlight,
              AppColors.surface.withValues(alpha: 0.9),
            ],
          ),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                medal,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: medalSize,
                  height: 1.0,
                ),
              ),
            ),
            SizedBox(height: compact ? 5 : 7),
            Center(
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                child: Text(
                  _initials(d),
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: initialsSize,
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 5 : 7),
            Expanded(
              child: Center(
                child: Text(
                  displayName,
                  maxLines: nameLines,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: nameSize,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            Text(
              '$score',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.accentMuted,
                fontWeight: FontWeight.w900,
                fontSize: scoreSize,
                height: 1.1,
              ),
            ),
            SizedBox(height: compact ? 2 : 3),
            Text(
              '$crit crit.',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: critSize,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
