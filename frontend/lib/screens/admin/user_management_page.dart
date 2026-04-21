import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/backend_api_service.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/add_user_form.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _apiService = BackendApiService();
  bool _isDeleting = false;

  Future<void> _openAddUserDialog(BuildContext context) async {
    final creator = const AdminUserCreator();
    final firestore = FirebaseFirestore.instance;
    final messenger = ScaffoldMessenger.of(context);
    AddUserData? createdUserData;
    String? emailError;

    final created = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AddUserForm(
          onSubmit: (data) async {
            final userCredential = await creator.createUser(
              email: data.email,
              password: data.password,
            );
            final uid = userCredential.user?.uid;
            if (uid == null) {
              throw Exception('UID utilisateur introuvable.');
            }

            await firestore.collection('users').doc(uid).set({
              'uid': uid,
              'nom': data.nom,
              'prenom': data.prenom,
              'telephone': data.telephone,
              'role': data.role,
              'specialite': data.specialite ?? '',
              'email': data.email,
            });
            createdUserData = data;
          },
        );
      },
    );

    if (created == true && context.mounted) {
      if (createdUserData != null) {
        try {
          await _apiService.sendWelcomeEmail(
            to: createdUserData!.email,
            nom: createdUserData!.nom,
            email: createdUserData!.email,
            password: createdUserData!.password,
            role: createdUserData!.role,
          );
        } catch (error) {
          emailError = error.toString().replaceFirst('Exception: ', '');
        }
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Utilisateur ajoute avec succes.')),
      );
      if (emailError != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Utilisateur cree, email non envoye: $emailError'),
          ),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteUser({required String uid}) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('Confirmer la suppression'),
            ],
          ),
          content: const Text(
            'Voulez-vous vraiment supprimer cet utilisateur ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _apiService.deleteUser(uid);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Utilisateur supprime avec succes.')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur suppression: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersStream =
        FirebaseFirestore.instance
            .collection('users')
            .orderBy('nom')
            .snapshots();

    return Scaffold(
      appBar: const AppTopBar(title: 'Gestion des utilisateurs'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isDeleting ? null : () => _openAddUserDialog(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Ajouter utilisateur'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Aucun utilisateur trouve.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemBuilder: (_, index) {
              final data = docs[index].data();
              final nom = data['nom']?.toString() ?? '';
              final prenom = data['prenom']?.toString() ?? '';
              final role = data['role']?.toString() ?? '';
              final email = data['email']?.toString() ?? '';
              final uid =
                  data['uid']?.toString().trim().isNotEmpty == true
                      ? data['uid'].toString()
                      : docs[index].id;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8F5E9),
                    child: Text(
                      _initials(nom, prenom),
                      style: const TextStyle(color: Color(0xFF2E7D32)),
                    ),
                  ),
                  title: Text(
                    '$nom $prenom'.trim(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.mail_outline, size: 15),
                        const SizedBox(width: 6),
                        Expanded(child: Text(email)),
                      ],
                    ),
                  ),
                  trailing: Container(
                    constraints: const BoxConstraints(minWidth: 110),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed:
                              _isDeleting
                                  ? null
                                  : () => _confirmAndDeleteUser(uid: uid),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Supprimer',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: docs.length,
          );
        },
      ),
    );
  }

  String _initials(String nom, String prenom) {
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final val = '$n$p';
    return val.isEmpty ? '?' : val;
  }
}
