import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenue'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.gradientTop, AppColors.darkGreen],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: _AdminGreeting(uid: user?.uid),
        ),
      ),
    );
  }
}

class _AdminGreeting extends StatelessWidget {
  const _AdminGreeting({required this.uid});

  final String? uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Text(
        'Bonjour',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final nom = data?['nom']?.toString() ?? '';
        final prenom = data?['prenom']?.toString() ?? '';
        final fullName = '$nom $prenom'.trim();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              fullName.isEmpty ? 'Bonjour' : 'Bonjour $fullName',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Espace administration Smart Incident Reporter',
              style: TextStyle(color: AppColors.gray, fontSize: 14),
            ),
          ],
        );
      },
    );
  }
}
