import 'package:flutter/material.dart';

import 'admin_affectation_page.dart';
import 'admin_incidents_page.dart';
import 'admin_home_page.dart';
import 'user_management_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  /// Pas de `const` sur les écrans avec StreamBuilder pour éviter le cache d'état.
  late final List<Widget> _pages = [
    const AdminHomePage(),
    const UserManagementPage(),
    AdminAffectationPage(key: const ValueKey('admin_affectation')),
    AdminIncidentsPage(key: const ValueKey('admin_incidents')),
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
        animationDuration: const Duration(milliseconds: 350),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            label: 'Utilisateurs',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_rounded),
            label: 'Affectation',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            label: 'Incidents',
          ),
        ],
      ),
    );
  }
}
