import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/notification_service.dart';
import '../utils/firestore_debug.dart';
import '../theme/industrial_tokens.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title, this.showLogout = true});

  final String title;
  final bool showLogout;

  Future<void> _openNotifications(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: IndustrialTokens.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => SizedBox(
            height: 420,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: IndustrialTokens.neon,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: NotificationService().watchForUser(uid),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: firestoreErrorPanel(snapshot.error!));
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: IndustrialTokens.neonMuted,
                            ),
                          );
                        }
                        final docs = NotificationService.sortedNotificationDocs(
                          snapshot.data,
                        );
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'Aucune notification',
                              style: TextStyle(color: IndustrialTokens.textSecondary),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final data = docs[i].data();
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.notifications_active_outlined,
                                color: IndustrialTokens.neonMuted,
                              ),
                              title: Text(
                                data['title']?.toString() ?? 'Notification',
                                style: const TextStyle(
                                  color: IndustrialTokens.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                data['message']?.toString() ?? '',
                                style: const TextStyle(
                                  color: IndustrialTokens.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Deconnexion reussie.')));
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: IndustrialTokens.appBarBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: Text(
        title,
        style: const TextStyle(
          color: IndustrialTokens.neon,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: const IconThemeData(color: IndustrialTokens.textPrimary),
      actions: [
        IconButton(
          onPressed: () => _openNotifications(context),
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        if (showLogout)
          Padding(
            padding: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
            child: OutlinedButton(
              onPressed: () => _logout(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: IndustrialTokens.neon,
                side: const BorderSide(color: IndustrialTokens.neonMuted),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              child: const Text(
                'Déconnexion',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
