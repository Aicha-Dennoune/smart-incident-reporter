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
import 'employe_declare_incident_page.dart';
import 'employe_my_incidents_page.dart';
import 'employe_validation_page.dart';

class EmployeHomePage extends StatefulWidget {
  const EmployeHomePage({super.key});

  @override
  State<EmployeHomePage> createState() => _EmployeHomePageState();
}

class _EmployeHomePageState extends State<EmployeHomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const _EmployeHomeTab(),
    const EmployeDeclareIncidentPage(),
    EmployeMyIncidentsPage(key: const ValueKey('emp_incidents')),
    EmployeValidationPage(key: const ValueKey('emp_validation')),
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
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.add_alert_outlined),
            label: 'Déclarer',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_list_rounded),
            label: 'Incidents',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            label: 'Validation',
          ),
        ],
      ),
    );
  }
}

class _EmployeHomeTab extends StatelessWidget {
  const _EmployeHomeTab();

  static String _ago(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }

  static Color _dotForType(String? t) {
    switch (t) {
      case 'resolved_pending_validation':
      case 'resolved':
        return IndustrialTokens.statOrange;
      case 'assignment':
        return IndustrialTokens.statBlue;
      default:
        return IndustrialTokens.statGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final email = user?.email;
    final service = IncidentService();
    final notifService = NotificationService();

    return Scaffold(
      appBar: const AppTopBar(title: 'Accueil'),
      body:
          uid == null
              ? const Center(child: Text('Non connecté'))
              : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .snapshots(),
                      builder: (context, snap) {
                        final nom = snap.data?.data()?['nom']?.toString() ?? '';
                        final prenom =
                            snap.data?.data()?['prenom']?.toString() ?? '';
                        final name = '$prenom $nom'.trim();
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                          child: Text(
                            name.isEmpty ? 'Bonjour' : 'Bonjour $name',
                            style: const TextStyle(
                              color: IndustrialTokens.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: service.watchIncidents(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: firestoreErrorPanel(snapshot.error!),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final docs = IncidentService.incidentsForCreator(
                          snapshot.data,
                          uid,
                          email,
                        );
                        final total = docs.length;
                        final closed =
                            docs
                                .where(
                                  (d) =>
                                      IncidentService.normStatus(
                                        d.data()['status']?.toString(),
                                      ) ==
                                      'closed',
                                )
                                .length;
                        final inProgress =
                            docs
                                .where(
                                  (d) =>
                                      IncidentService.normStatus(
                                        d.data()['status']?.toString(),
                                      ) ==
                                      'in_progress',
                                )
                                .length;
                        final open =
                            docs
                                .where(
                                  (d) =>
                                      IncidentService.normStatus(
                                        d.data()['status']?.toString(),
                                      ) ==
                                      'open',
                                )
                                .length;
                        final pct =
                            total == 0
                                ? 0.0
                                : (closed / total).clamp(0.0, 1.0);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.25,
                                children: [
                                  _StatTile(
                                    value: total.toString(),
                                    label: 'Incidents créés',
                                    valueColor: IndustrialTokens.statBlue,
                                  ),
                                  _StatTile(
                                    value: closed.toString(),
                                    label: 'Résolus',
                                    valueColor: IndustrialTokens.statGreen,
                                  ),
                                  _StatTile(
                                    value: inProgress.toString(),
                                    label: 'En cours',
                                    valueColor: IndustrialTokens.statOrange,
                                  ),
                                  _StatTile(
                                    value: open.toString(),
                                    label: 'En attente',
                                    valueColor: IndustrialTokens.statRed,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              NeoCard(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 8,
                                        backgroundColor: IndustrialTokens.bg,
                                        color: IndustrialTokens.neon,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${(pct * 100).round()}% incidents résolus',
                                      style: const TextStyle(
                                        color: IndustrialTokens.neonMuted,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(18, 24, 18, 10),
                      child: SectionTitle('Activité récente'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: notifService.watchForUser(uid),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: firestoreErrorPanel(snapshot.error!),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final docs = NotificationService.sortedNotificationDocs(
                          snapshot.data,
                        ).take(3).toList();
                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18),
                            child: Text(
                              'Aucune activité récente.',
                              style: TextStyle(
                                color: IndustrialTokens.textSecondary,
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          child: Column(
                            children:
                                docs.map((doc) {
                                  final data = doc.data();
                                  final title =
                                      '${data['title'] ?? data['message'] ?? 'Notification'}'
                                          .trim();
                                  final type =
                                      data['type']?.toString() ?? 'info';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: NeoCard(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: _dotForType(type),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: const TextStyle(
                                                color:
                                                    IndustrialTokens.textPrimary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _ago(
                                              data['createdAt'] as Timestamp?,
                                            ),
                                            style: const TextStyle(
                                              color:
                                                  IndustrialTokens.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

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
              color: valueColor,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: IndustrialTokens.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
