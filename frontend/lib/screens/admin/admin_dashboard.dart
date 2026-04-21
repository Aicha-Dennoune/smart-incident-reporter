import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_colors.dart';
import 'admin_home_page.dart';
import 'user_management_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    AdminHomePage(),
    UserManagementPage(),
    _ComingSoonPage(title: 'Affectation'),
    _ComingSoonPage(title: 'Incidents'),
    _ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        indicatorColor: AppColors.primaryGreen.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            label: 'Utilisateurs',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_ind_outlined),
            label: 'Affectation',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            label: 'Incidents',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title - bientot disponible',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Deconnexion reussie.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Se deconnecter'),
        ),
      ),
    );
  }
}
