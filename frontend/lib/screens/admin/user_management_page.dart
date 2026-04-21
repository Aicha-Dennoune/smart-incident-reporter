import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/add_user_form.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  Future<void> _openAddUserDialog(BuildContext context) async {
    final creator = const AdminUserCreator();
    final firestore = FirebaseFirestore.instance;

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
          },
        );
      },
    );

    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur ajoute avec succes.')),
      );
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
      appBar: AppBar(title: const Text('Gestion des utilisateurs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddUserDialog(context),
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

              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(_initials(nom, prenom))),
                  title: Text('$nom $prenom'.trim()),
                  subtitle: Text(email),
                  trailing: Container(
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
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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
