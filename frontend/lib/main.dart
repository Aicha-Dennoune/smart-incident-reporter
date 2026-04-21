import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/employe/employe_home_page.dart';
import 'screens/technicien/technicien_home_page.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SmartIncidentApp());
}

class SmartIncidentApp extends StatelessWidget {
  const SmartIncidentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Incident Reporter',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D1F1B),
        fontFamily: 'sans-serif',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF10211E),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF10211E),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2E7D32).withValues(alpha: 0.18),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF1B5E20));
            }
            return const IconThemeData(color: Color(0xFF607D8B));
          }),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w700,
              );
            }
            return const TextStyle(
              color: Color(0xFF607D8B),
              fontWeight: FontWeight.w500,
            );
          }),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user != null) {
          return _RoleGate(uid: user.uid, email: user.email);
        }
        return const WelcomeScreen();
      },
    );
  }
}

class _RoleGate extends StatelessWidget {
  const _RoleGate({required this.uid, required this.email});

  final String uid;
  final String? email;

  Future<String?> _resolveRole() async {
    final firestore = FirebaseFirestore.instance;

    final byUid = await firestore.collection('users').doc(uid).get();
    final roleByUid = byUid.data()?['role']?.toString().toLowerCase().trim();
    if (roleByUid != null && roleByUid.isNotEmpty) {
      return roleByUid;
    }

    final emailValue = email?.trim().toLowerCase();
    if (emailValue == null || emailValue.isEmpty) {
      return null;
    }

    final byEmail =
        await firestore
            .collection('users')
            .where('email', isEqualTo: emailValue)
            .limit(1)
            .get();
    if (byEmail.docs.isEmpty) {
      return null;
    }
    return byEmail.docs.first.data()['role']?.toString().toLowerCase().trim();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolveRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final role = snapshot.data;
        if (role == 'admin') return const AdminDashboard();
        if (role == 'technicien') return const TechnicienHomePage();
        if (role == 'employe') return const EmployeHomePage();

        return const Scaffold(
          body: Center(
            child: Text(
              'Compte connecté, mais rôle introuvable.\nContactez un administrateur.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
