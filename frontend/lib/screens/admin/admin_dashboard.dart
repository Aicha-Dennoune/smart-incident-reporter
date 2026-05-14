import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
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
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: AppColors.surface.withValues(alpha: 0.96),
            indicatorColor: AppColors.accent.withValues(alpha: 0.2),
            surfaceTintColor: Colors.transparent,
            elevation: 16,
            shadowColor: Colors.black54,
            height: 72,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: AppColors.accent, size: 26);
              }
              return IconThemeData(color: AppColors.textMuted.withValues(alpha: 0.85), size: 24);
            }),
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                );
              }
              return const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              );
            }),
          ),
        ),
        child: NavigationBar(
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
      ),
    );
  }
}
