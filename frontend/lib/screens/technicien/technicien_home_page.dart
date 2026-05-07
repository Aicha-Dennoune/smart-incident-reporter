import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/incident_service.dart';
import '../../services/notification_service.dart';
import '../../utils/firestore_debug.dart';
import '../../theme/industrial_tokens.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/industrial/neo_card.dart';
import '../../widgets/industrial/section_title.dart';
import '../chat/incident_chat_page.dart';
import '../../services/chat_service.dart';
import 'technicien_incident_detail_page.dart';

class TechnicienHomePage extends StatefulWidget {
  const TechnicienHomePage({super.key});

  @override
  State<TechnicienHomePage> createState() => _TechnicienHomePageState();
}

class _TechnicienHomePageState extends State<TechnicienHomePage> {
  int _currentIndex = 0;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  late final List<Widget> _pages = [
    _TechHomeTab(key: const ValueKey('tech_home'), uid: _uid),
    _TechIncidentsTab(key: const ValueKey('tech_incidents'), uid: _uid),
    _TechActivitesTab(key: const ValueKey('tech_activites'), uid: _uid),
    _TechDiscussionsTab(key: const ValueKey<String>('tech_discussions'), uid: _uid),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Mes Incidents',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            label: 'Activités',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Discussions',
          ),
        ],
      ),
    );
  }
}

class _TechHomeTab extends StatelessWidget {
  const _TechHomeTab({super.key, required this.uid});

  final String? uid;

  static String _initials(String nom, String prenom) {
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final v = '$p$n';
    return v.isEmpty ? '?' : v;
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Non connecté')),
      );
    }
    final service = IncidentService();
    return Scaffold(
      appBar: const AppTopBar(title: 'Espace Technicien'),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
        builder: (context, userSnap) {
          final u = userSnap.data?.data() ?? {};
          final nom = u['nom']?.toString() ?? '';
          final prenom = u['prenom']?.toString() ?? '';
          final spec = u['specialite']?.toString() ?? '';
          final score = u['score'] ?? 0;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.watchIncidents(),
            builder: (context, incSnap) {
              if (incSnap.hasError) {
                return Center(child: firestoreErrorPanel(incSnap.error!));
              }
              if (!incSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = IncidentService.incidentsForAssignee(
                incSnap.data,
                uid!,
              );
              final assignes =
                  docs
                      .where((d) => d.data()['status'] == 'in_progress')
                      .length;
              final resolus =
                  docs.where((d) => d.data()['status'] == 'closed').length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  NeoCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: IndustrialTokens.neon.withValues(
                            alpha: 0.25,
                          ),
                          child: Text(
                            _initials(nom, prenom),
                            style: const TextStyle(
                              color: IndustrialTokens.bg,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$prenom $nom'.trim().isEmpty
                                    ? 'Technicien'
                                    : '$prenom $nom'.trim(),
                                style: const TextStyle(
                                  color: IndustrialTokens.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Spécialité : ${_specFr(spec)}',
                                style: const TextStyle(
                                  color: IndustrialTokens.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFD54F),
                                  size: 28,
                                ),
                                Text(
                                  '$score',
                                  style: const TextStyle(
                                    color: IndustrialTokens.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'points score',
                              style: TextStyle(
                                color: IndustrialTokens.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: NeoCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                '$assignes',
                                style: const TextStyle(
                                  color: IndustrialTokens.statOrange,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Assignés',
                                style: TextStyle(
                                  color: IndustrialTokens.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NeoCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                '$resolus',
                                style: const TextStyle(
                                  color: IndustrialTokens.neon,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Résolus',
                                style: TextStyle(
                                  color: IndustrialTokens.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const SectionTitle('Mes incidents assignés'),
                  const SizedBox(height: 10),
                  ...docs.take(4).map((doc) {
                    final data = doc.data();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _IncidentPreviewCard(
                        docId: doc.id,
                        data: data,
                        technicianUid: uid!,
                        compact: true,
                      ),
                    );
                  }),
                  if (docs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Aucun incident assigné pour le moment.',
                        style: TextStyle(color: IndustrialTokens.textSecondary),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static String _specFr(String s) {
    switch (s) {
      case 'Electricite':
        return 'Électricité';
      case 'Mecanique':
        return 'Mécanique';
      default:
        return s.isEmpty ? '—' : s;
    }
  }
}

class _TechIncidentsTab extends StatelessWidget {
  const _TechIncidentsTab({super.key, required this.uid});

  final String? uid;

  @override
  Widget build(BuildContext context) {
    final service = IncidentService();
    return Scaffold(
      appBar: const AppTopBar(title: 'Mes Incidents'),
      body:
          uid == null
              ? const Center(child: Text('Non connecté'))
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: service.watchIncidents(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: firestoreErrorPanel(snapshot.error!));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = IncidentService.incidentsForAssignee(
                    snapshot.data,
                    uid!,
                  );
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun incident assigné.',
                        style: TextStyle(color: IndustrialTokens.textSecondary),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final doc = docs[i];
                      return _IncidentPreviewCard(
                        docId: doc.id,
                        data: doc.data(),
                        technicianUid: uid!,
                        compact: false,
                      );
                    },
                  );
                },
              ),
    );
  }
}

class _IncidentPreviewCard extends StatelessWidget {
  const _IncidentPreviewCard({
    required this.docId,
    required this.data,
    required this.technicianUid,
    required this.compact,
  });

  final String docId;
  final Map<String, dynamic> data;
  final String technicianUid;
  final bool compact;

  static Color _accent(String? type) {
    switch (type) {
      case 'Mecanique':
        return IndustrialTokens.neonMuted;
      case 'Eau':
        return const Color(0xFF42A5F5);
      case 'Electricite':
        return const Color(0xFFFFEE58);
      default:
        return const Color(0xFF90CAF9);
    }
  }

  static String _ago(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

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
        return 'En validation';
      case 'closed':
        return 'Résolu';
      default:
        return s ?? '';
    }
  }

  static Widget _pill(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'in_progress':
        bg = IndustrialTokens.statOrange;
        fg = IndustrialTokens.bg;
        break;
      case 'open':
        bg = const Color(0xFF1565C0);
        fg = const Color(0xFFBBDEFB);
        break;
      default:
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
        _statusFr(status),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'Sans titre';
    final type = _typeFr(data['type']?.toString());
    final st = IncidentService.normStatus(data['status']?.toString());
    final status = st.isEmpty ? 'open' : st;
    final createdAt = data['createdAt'] as Timestamp?;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder:
                (_) => TechnicienIncidentDetailPage(
                  incidentId: docId,
                  technicianUid: technicianUid,
                ),
          ),
        );
      },
      child: NeoCard(
        accentColor: _accent(data['type']?.toString()),
        accentWidth: 5,
        child: Row(
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
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$type • ${_ago(createdAt)}',
                    style: const TextStyle(
                      color: IndustrialTokens.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (!compact && data['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      data['description']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: IndustrialTokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _pill(status),
          ],
        ),
      ),
    );
  }
}

class _TechActivitesTab extends StatelessWidget {
  const _TechActivitesTab({super.key, required this.uid});

  final String? uid;

  @override
  Widget build(BuildContext context) {
    final notif = NotificationService();
    return Scaffold(
      appBar: const AppTopBar(title: 'Activités'),
      body:
          uid == null
              ? const Center(child: Text('Non connecté'))
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: notif.watchForUser(uid!),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: firestoreErrorPanel(snapshot.error!));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = NotificationService.sortedNotificationDocs(
                    snapshot.data,
                  );
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune notification.',
                        style: TextStyle(color: IndustrialTokens.textSecondary),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final d = docs[i].data();
                      return NeoCard(
                        padding: const EdgeInsets.all(14),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.notifications_active_outlined,
                            color: IndustrialTokens.neonMuted,
                          ),
                          title: Text(
                            d['title']?.toString() ?? '',
                            style: const TextStyle(
                              color: IndustrialTokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            d['message']?.toString() ?? '',
                            style: const TextStyle(
                              color: IndustrialTokens.textSecondary,
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

class _TechDiscussionsTab extends StatelessWidget {
  const _TechDiscussionsTab({super.key, required this.uid});

  final String? uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Non connecté')));
    }
    final service = IncidentService();
    return Scaffold(
      appBar: const AppTopBar(title: 'Discussions'),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.watchIncidents(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: firestoreErrorPanel(snapshot.error!));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = IncidentService.incidentsForAssignee(snapshot.data, uid!);
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Aucune discussion disponible.',
                style: TextStyle(color: IndustrialTokens.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final doc = docs[i];
              return _DiscussionIncidentCard(
                incidentId: doc.id,
                incidentData: doc.data(),
                technicianUid: uid!,
              );
            },
          );
        },
      ),
    );
  }
}

class _DiscussionIncidentCard extends StatelessWidget {
  const _DiscussionIncidentCard({
    required this.incidentId,
    required this.incidentData,
    required this.technicianUid,
  });

  final String incidentId;
  final Map<String, dynamic> incidentData;
  final String technicianUid;

  @override
  Widget build(BuildContext context) {
    final chat = ChatService();
    final title = incidentData['title']?.toString() ?? 'Incident';
    final creatorUid = IncidentService.creatorUid(incidentData);
    return NeoCard(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: chat.watchLatestMessage(incidentId),
        builder: (context, latestSnap) {
          final latest = latestSnap.data?.docs.isNotEmpty == true
              ? latestSnap.data!.docs.first.data()
              : null;
          final lastText = latest?['text']?.toString() ?? 'Aucun message';
          final lastTs = latest?['createdAt'] as Timestamp?;
          final hh = lastTs == null
              ? '--:--'
              : '${lastTs.toDate().hour.toString().padLeft(2, '0')}:${lastTs.toDate().minute.toString().padLeft(2, '0')}';

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => IncidentChatPage(
                    incidentId: incidentId,
                    incidentTitle: title,
                    currentUserId: technicianUid,
                    currentUserRole: 'technicien',
                    otherUserId: creatorUid ?? '',
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: IndustrialTokens.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (creatorUid != null)
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(creatorUid)
                              .snapshots(),
                          builder: (context, creatorSnap) {
                            final c = creatorSnap.data?.data() ?? {};
                            final name =
                                '${c['prenom'] ?? ''} ${c['nom'] ?? ''}'.trim();
                            return Text(
                              'Employé: ${name.isEmpty ? creatorUid : name}',
                              style: const TextStyle(
                                color: IndustrialTokens.textSecondary,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 4),
                      Text(
                        lastText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: IndustrialTokens.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hh,
                      style: const TextStyle(
                        color: IndustrialTokens.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _UnreadBadge(incidentId: incidentId, currentUserId: technicianUid),
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

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.incidentId, required this.currentUserId});

  final String incidentId;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final chat = ChatService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: chat.watchMessages(incidentId),
      builder: (context, snapshot) {
        var unread = 0;
        if (snapshot.hasData) {
          for (final m in snapshot.data!.docs) {
            final d = m.data();
            final senderId = d['senderId']?.toString() ?? '';
            final readBy = List<String>.from((d['readBy'] as List?) ?? const []);
            if (senderId != currentUserId && !readBy.contains(currentUserId)) {
              unread++;
            }
          }
        }
        if (unread <= 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            unread > 99 ? '99+' : '$unread',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}
