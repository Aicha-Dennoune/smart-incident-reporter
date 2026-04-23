import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/employe/employe_home_page.dart';
import 'screens/technicien/technicien_home_page.dart';
import 'screens/welcome_screen.dart';
import 'theme/industrial_tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SmartIncidentApp());
}

class SmartIncidentApp extends StatelessWidget {
  const SmartIncidentApp({super.key});

  static ThemeData get industrialTheme {
    const seed = IndustrialTokens.neonMuted;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: IndustrialTokens.bg,
      fontFamily: 'sans-serif',
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        surface: IndustrialTokens.card,
        primary: IndustrialTokens.neonMuted,
        onPrimary: IndustrialTokens.bg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: IndustrialTokens.appBarBg,
        foregroundColor: IndustrialTokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: IndustrialTokens.neon,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: IndustrialTokens.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: IndustrialTokens.navBg,
        indicatorColor: IndustrialTokens.neon.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shadowColor: Colors.black54,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: IndustrialTokens.neon);
          }
          return const IconThemeData(color: IndustrialTokens.navInactive);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: IndustrialTokens.neon,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: IndustrialTokens.navInactive,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: IndustrialTokens.card,
        contentTextStyle: const TextStyle(color: IndustrialTokens.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: IndustrialTokens.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: IndustrialTokens.neon,
          foregroundColor: IndustrialTokens.bg,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: IndustrialTokens.neonMuted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Incident Reporter',
      theme: industrialTheme,
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
