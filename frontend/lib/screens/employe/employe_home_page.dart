import 'package:flutter/material.dart';

import '../../widgets/app_top_bar.dart';

class EmployeHomePage extends StatelessWidget {
  const EmployeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppTopBar(title: 'Employé'),
      body: Center(
        child: Text(
          'Connexion réussie - Employé',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
