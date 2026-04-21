import 'package:flutter/material.dart';

import '../../widgets/app_top_bar.dart';

class TechnicienHomePage extends StatelessWidget {
  const TechnicienHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppTopBar(title: 'Technicien'),
      body: Center(
        child: Text(
          'Connexion réussie - Technicien',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
