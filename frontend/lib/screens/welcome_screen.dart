import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/industrial_background.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndustrialBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Expanded(
                flex: 7,
                child: _TopSection(),
              ),
              Expanded(
                flex: 3,
                child: _BottomCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopSection extends StatelessWidget {
  const _TopSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Image.asset(
              'assets/images/OCP_LOGO.png',
              height: 72,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.business,
                  color: AppColors.white,
                  size: 64,
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Smart Incident Reporter',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'OCP - INDUSTRIAL PLATFORM',
            style: TextStyle(
              color: AppColors.accentGreen,
              fontSize: 14,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: const Text(
              'Une gestion intelligente des incidents industriels — rapide, fiable, securisee.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.45,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(
                child: _FeatureItem(
                  icon: Icons.verified_user_outlined,
                  label: 'Securise',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _FeatureItem(
                  icon: Icons.schedule,
                  label: 'Temps reel',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _FeatureItem(
                  icon: Icons.analytics_outlined,
                  label: 'Analytique',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _FeatureItem(
                  icon: Icons.groups_outlined,
                  label: 'Equipes',
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(
            icon,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.gray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BottomCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Acces a votre espace',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connectez-vous pour declarer et suivre les incidents en toute securite.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF5C6B73),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_outline),
                label: const Text('Se connecter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1F2D2A),
                  side: const BorderSide(color: AppColors.gray),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 18, color: AppColors.primaryGreen),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Acces reserve au personnel autorise',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
