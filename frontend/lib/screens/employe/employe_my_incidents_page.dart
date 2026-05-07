import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../chat/incident_chat_page.dart';
import '../../services/chat_service.dart';
import '../../services/incident_service.dart';
import '../../theme/industrial_tokens.dart';
import '../../utils/firestore_debug.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/industrial/neo_card.dart';

class EmployeMyIncidentsPage extends StatelessWidget {
  const EmployeMyIncidentsPage({super.key});

  static String _typeDisplay(String? code) {
    switch (code) {
      case 'Electricite':
        return 'Électricité';
      case 'Mecanique':
        return 'Mécanique';
      default:
        return code ?? '';
    }
  }

  static String _statusFr(String status) {
    switch (status) {
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

  static Color _statusAccent(String status) {
    switch (status) {
      case 'open':
        return IndustrialTokens.statRed;
      case 'in_progress':
        return IndustrialTokens.statOrange;
      case 'resolved_pending_validation':
        return IndustrialTokens.badgePending;
      case 'closed':
        return IndustrialTokens.statGreen;
      default:
        return IndustrialTokens.neonMuted;
    }
  }

  static Widget _statusPill(String status) {
    final fr = _statusFr(status);
    Color bg;
    Color fg;
    switch (status) {
      case 'open':
        bg = const Color(0xFF1E3A5F);
        fg = const Color(0xFF90CAF9);
        break;
      case 'in_progress':
        bg = const Color(0xFF5D4037);
        fg = IndustrialTokens.statOrange;
        break;
      case 'resolved_pending_validation':
        bg = const Color(0xFF4527A0);
        fg = const Color(0xFFB39DDB);
        break;
      case 'closed':
        bg = const Color(0xFF1B5E20);
        fg = IndustrialTokens.statGreen;
        break;
      default:
        bg = IndustrialTokens.card;
        fg = IndustrialTokens.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        fr,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final email = user?.email;
    final service = IncidentService();
    return Scaffold(
      appBar: const AppTopBar(title: 'Mes incidents'),
      body:
          uid == null
              ? const Center(
                child: Text(
                  'Non connecté',
                  style: TextStyle(color: IndustrialTokens.textSecondary),
                ),
              )
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: service.watchIncidents(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: firestoreErrorPanel(snapshot.error!));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final snap = snapshot.data!;
                  final docs = IncidentService.incidentsForCreator(
                    snap,
                    uid,
                    email,
                  );
                  if (docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucun incident pour le moment.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: IndustrialTokens.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final doc = docs[i];
                      final data = doc.data();
                      final title = data['title']?.toString() ?? 'Sans titre';
                      final type = _typeDisplay(data['type']?.toString());
                      final st = IncidentService.normStatus(
                        data['status']?.toString(),
                      );
                      final status = st.isEmpty ? 'open' : st;
                      final assignedTo = IncidentService.assigneeKey(data);
                      final canChat =
                          assignedTo != null && assignedTo.trim().isNotEmpty;
                      return NeoCard(
                        accentColor: _statusAccent(status),
                        accentWidth: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: IndustrialTokens.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$type • ${_statusFr(status)}',
                                        style: const TextStyle(
                                          color: IndustrialTokens.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _statusPill(status),
                              ],
                            ),
                            if (canChat) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _EmployeChatButton(
                                  incidentId: doc.id,
                                  incidentTitle: title,
                                  currentUserId: uid,
                                  technicianUid: assignedTo,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}

class _EmployeChatButton extends StatelessWidget {
  const _EmployeChatButton({
    required this.incidentId,
    required this.incidentTitle,
    required this.currentUserId,
    required this.technicianUid,
  });

  final String incidentId;
  final String incidentTitle;
  final String currentUserId;
  final String technicianUid;

  @override
  Widget build(BuildContext context) {
    final chat = ChatService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: chat.watchMessages(incidentId),
      builder: (context, snap) {
        var unread = 0;
        if (snap.hasData) {
          for (final m in snap.data!.docs) {
            final d = m.data();
            final senderId = d['senderId']?.toString() ?? '';
            final readBy = List<String>.from((d['readBy'] as List?) ?? const []);
            if (senderId != currentUserId && !readBy.contains(currentUserId)) {
              unread++;
            }
          }
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder:
                        (_) => IncidentChatPage(
                          incidentId: incidentId,
                          incidentTitle: incidentTitle,
                          currentUserId: currentUserId,
                          currentUserRole: 'employe',
                          otherUserId: technicianUid,
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Discuter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: IndustrialTokens.neon,
                side: const BorderSide(color: IndustrialTokens.neonMuted),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
