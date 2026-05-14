import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/notification_service.dart';
import '../utils/firestore_debug.dart';
import '../theme/industrial_tokens.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.showLogout = true,
    this.actionsPrefix = const <Widget>[],
  });

  final String title;
  final bool showLogout;

  /// Inséré avant la cloche (ex. badge urgent sur le dashboard admin).
  final List<Widget> actionsPrefix;

  Future<void> _openNotifications(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid;
    if (uid == null) return;
    debugPrint('UID connecté: $uid');
    final notifService = NotificationService();
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
                      stream: notifService.watchForUser(uid),
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
                        debugPrint(
                          '[Notifications] snapshot.hasData=${snapshot.hasData} docs=${docs.length}',
                        );
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          notifService.markAllAsReadForUser(uid);
                        });
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
        ...actionsPrefix,
        IconButton(
          onPressed: () => _openNotifications(context),
          tooltip: 'Notifications',
          icon: _NotificationBellIcon(),
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

class _NotificationBellIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Icon(Icons.notifications_none_rounded);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: NotificationService().watchUnreadForUser(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Icon(Icons.notifications_none_rounded);
        }
        final unread = snapshot.data?.docs.length ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded),
            if (unread > 0)
              Positioned(
                right: -4,
                top: -3,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
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
