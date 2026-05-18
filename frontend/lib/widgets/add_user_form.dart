import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../services/auth_service.dart';

class AddUserForm extends StatefulWidget {
  const AddUserForm({super.key, required this.onSubmit});

  final Future<void> Function(AddUserData data) onSubmit;

  @override
  State<AddUserForm> createState() => _AddUserFormState();
}

class _AddUserFormState extends State<AddUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = UserRole.employe.value;
  String? _specialite;
  bool _loading = false;
  String? _error;

  bool get _isTechnicien => _role == UserRole.technicien.value;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.onSubmit(
        AddUserData(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          telephone: _telephoneController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _role,
          specialite: _isTechnicien ? _specialite : null,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = AuthService.messageForFirebaseAuth(e);
      });
    } catch (_) {
      setState(() {
        _error = 'Impossible d\'ajouter cet utilisateur.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFE8F5E9),
      title: const Text(
        'Ajouter utilisateur',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      content: SizedBox(
        width: 460,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDFF2E1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                _buildTextField(
                  controller: _nomController,
                  label: 'Nom',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _prenomController,
                  label: 'Prenom',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _telephoneController,
                  label: 'Telephone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email requis.';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return '6 caracteres minimum.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _role,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Role',
                    labelStyle: const TextStyle(color: Colors.black87),
                    prefixIcon: const Icon(
                      Icons.assignment_ind_outlined,
                      color: Colors.black87,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD9E0E5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2E7D32),
                        width: 1.4,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items:
                      UserRole.values
                          .map(
                            (role) => DropdownMenuItem<String>(
                              value: role.value,
                              child: Text(role.value),
                            ),
                          )
                          .toList(),
                  onChanged:
                      _loading
                          ? null
                          : (value) {
                            if (value == null) return;
                            setState(() {
                              _role = value;
                              if (!_isTechnicien) {
                                _specialite = null;
                              }
                            });
                          },
                ),
                if (_isTechnicien) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _specialite,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Specialite',
                      labelStyle: const TextStyle(color: Colors.black87),
                      prefixIcon: const Icon(
                        Icons.build_circle_outlined,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD9E0E5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2E7D32),
                          width: 1.4,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items:
                        _specialites
                            .map(
                              (specialite) => DropdownMenuItem<String>(
                                value: specialite,
                                child: Text(specialite),
                              ),
                            )
                            .toList(),
                    onChanged:
                        _loading
                            ? null
                            : (value) {
                              setState(() => _specialite = value);
                            },
                    validator: (value) {
                      if (_isTechnicien &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Specialite requise pour technicien.';
                      }
                      return null;
                    },
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _handleSubmit,
          icon:
              _loading
                  ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Ajouter'),
        ),
      ],
    );
  }

  TextFormField _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),
        prefixIcon: Icon(icon, color: Colors.black87),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9E0E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.4),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label requis.';
            }
            return null;
          },
    );
  }
}

class AddUserData {
  const AddUserData({
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.email,
    required this.password,
    required this.role,
    required this.specialite,
  });

  final String nom;
  final String prenom;
  final String telephone;
  final String email;
  final String password;
  final String role;
  final String? specialite;
}

const List<String> _specialites = ['IT', 'Electricite', 'Mecanique', 'Eau'];

enum UserRole {
  employe('employe'),
  technicien('technicien');

  const UserRole(this.value);
  final String value;
}

class AdminUserCreator {
  const AdminUserCreator();

  Future<UserCredential> createUser({
    required String email,
    required String password,
  }) async {
    final appName = 'secondary-${DateTime.now().millisecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await secondaryAuth.signOut();
      return credential;
    } finally {
      await secondaryApp.delete();
    }
  }
}
