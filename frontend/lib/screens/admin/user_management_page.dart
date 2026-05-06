import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/backend_api_service.dart';
import '../../theme/industrial_tokens.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/add_user_form.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _apiService = BackendApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  bool _isDeleting = false;

  void _handleSearchChanged() {
    final value = _searchController.text;
    if (_searchQuery.value != value) {
      _searchQuery.value = value;
    }
  }

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
          backgroundColor: IndustrialTokens.card,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Confirmer la suppression',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: IndustrialTokens.textPrimary),
                ),
              ),
            ],
          ),
          content: const Text(
            'Voulez-vous vraiment supprimer cet utilisateur ?',
            style: TextStyle(color: IndustrialTokens.textSecondary),
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
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchQuery.dispose();
    super.dispose();
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
        backgroundColor: IndustrialTokens.neon,
        foregroundColor: IndustrialTokens.bg,
        onPressed: _isDeleting ? null : () => _openAddUserDialog(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Ajouter utilisateur'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ValueListenableBuilder<String>(
              valueListenable: _searchQuery,
              builder: (context, query, _) {
                return TextField(
                  focusNode: _searchFocusNode,
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Rechercher (nom, email, rôle...)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        query.trim().isEmpty
                            ? null
                            : IconButton(
                              onPressed: () => _searchController.clear(),
                              icon: const Icon(Icons.close),
                            ),
                    filled: true,
                    fillColor: IndustrialTokens.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: IndustrialTokens.cardBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: IndustrialTokens.cardBorder,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

                final docs =
                    (snapshot.data?.docs ?? [])
                        .where(
                          (doc) =>
                              (doc.data()['role']
                                          ?.toString()
                                          .toLowerCase()
                                          .trim() ??
                                      '') !=
                              'admin',
                        )
                        .toList();
                if (docs.isEmpty) {
                  return const Center(child: Text('Aucun utilisateur trouve.'));
                }

                return ValueListenableBuilder<String>(
                  valueListenable: _searchQuery,
                  builder: (context, queryValue, _) {
                    final query = queryValue.trim().toLowerCase();
                    final filteredDocs =
                        query.isEmpty
                            ? docs
                            : docs.where((doc) {
                              final data = doc.data();
                              final nom =
                                  data['nom']?.toString().toLowerCase() ?? '';
                              final prenom =
                                  data['prenom']?.toString().toLowerCase() ?? '';
                              final email =
                                  data['email']?.toString().toLowerCase() ?? '';
                              final role =
                                  data['role']?.toString().toLowerCase() ?? '';
                              final specialite =
                                  data['specialite']
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';
                              return nom.contains(query) ||
                                  prenom.contains(query) ||
                                  email.contains(query) ||
                                  role.contains(query) ||
                                  specialite.contains(query);
                            }).toList();

                    if (filteredDocs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucun utilisateur ne correspond a la recherche.',
                        ),
                      );
                    }

                    final technicians =
                        filteredDocs.where((doc) {
                          final role =
                              doc.data()['role']?.toString().toLowerCase().trim();
                          return role == 'technicien';
                        }).toList()
                          ..sort((a, b) {
                            final sa = (a.data()['score'] as num?)?.toInt() ?? 0;
                            final sb = (b.data()['score'] as num?)?.toInt() ?? 0;
                            return sb.compareTo(sa);
                          });
                    final employees =
                        filteredDocs.where((doc) {
                          final role =
                              doc.data()['role']?.toString().toLowerCase().trim();
                          return role == 'employe';
                        }).toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      children: [
                        const _UserSectionTitle('Techniciens'),
                        const SizedBox(height: 8),
                        if (technicians.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Aucun technicien.',
                              style: TextStyle(
                                color: IndustrialTokens.textSecondary,
                              ),
                            ),
                          )
                        else
                          ...technicians.map((doc) {
                            final data = doc.data();
                            final nom = data['nom']?.toString() ?? '';
                            final prenom = data['prenom']?.toString() ?? '';
                            final role = data['role']?.toString() ?? '';
                            final email = data['email']?.toString() ?? '';
                            final uid =
                                data['uid']?.toString().trim().isNotEmpty == true
                                    ? data['uid'].toString()
                                    : doc.id;
                            final score = (data['score'] as num?)?.toInt() ?? 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _UserCard(
                                initials: _initials(nom, prenom),
                                fullName: '$nom $prenom'.trim(),
                                email: email,
                                role: role,
                                specialite: data['specialite']?.toString() ?? '',
                                trailingInfo: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$score',
                                      style: const TextStyle(
                                        color: IndustrialTokens.neonMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                onDelete:
                                    _isDeleting
                                        ? null
                                        : () => _confirmAndDeleteUser(uid: uid),
                              ),
                            );
                          }),
                        const SizedBox(height: 16),
                        const _UserSectionTitle('Employés'),
                        const SizedBox(height: 8),
                        if (employees.isEmpty)
                          const Text(
                            'Aucun employé.',
                            style: TextStyle(color: IndustrialTokens.textSecondary),
                          )
                        else
                          ...employees.map((doc) {
                            final data = doc.data();
                            final nom = data['nom']?.toString() ?? '';
                            final prenom = data['prenom']?.toString() ?? '';
                            final role = data['role']?.toString() ?? '';
                            final email = data['email']?.toString() ?? '';
                            final uid =
                                data['uid']?.toString().trim().isNotEmpty == true
                                    ? data['uid'].toString()
                                    : doc.id;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _UserCard(
                                initials: _initials(nom, prenom),
                                fullName: '$nom $prenom'.trim(),
                                email: email,
                                role: role,
                                specialite: '',
                                trailingInfo: null,
                                onDelete:
                                    _isDeleting
                                        ? null
                                        : () => _confirmAndDeleteUser(uid: uid),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
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

class _UserSectionTitle extends StatelessWidget {
  const _UserSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: IndustrialTokens.neon,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.initials,
    required this.fullName,
    required this.email,
    required this.role,
    required this.specialite,
    required this.trailingInfo,
    required this.onDelete,
  });

  final String initials;
  final String fullName;
  final String email;
  final String role;
  final String specialite;
  final Widget? trailingInfo;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: IndustrialTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IndustrialTokens.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: IndustrialTokens.neon.withValues(alpha: 0.15),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: IndustrialTokens.neon,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: IndustrialTokens.textPrimary,
                        ),
                      ),
                      if (specialite.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Spécialité : $specialite',
                          style: const TextStyle(
                            color: IndustrialTokens.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.mail_outline,
                            size: 15,
                            color: IndustrialTokens.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: IndustrialTokens.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: IndustrialTokens.bg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: IndustrialTokens.cardBorder),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          color: IndustrialTokens.neonMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (trailingInfo != null) ...[
                      const SizedBox(height: 6),
                      trailingInfo!,
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
