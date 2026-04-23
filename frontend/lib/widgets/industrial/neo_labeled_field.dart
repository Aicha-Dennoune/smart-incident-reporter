import 'package:flutter/material.dart';

import '../../theme/industrial_tokens.dart';

class NeoLabeledField extends StatelessWidget {
  const NeoLabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: IndustrialTokens.neon,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

InputDecoration neoInputDecoration({
  String? hint,
  int maxLines = 1,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: IndustrialTokens.textSecondary.withValues(alpha: 0.7),
    ),
    filled: true,
    fillColor: IndustrialTokens.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: IndustrialTokens.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: IndustrialTokens.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: IndustrialTokens.neonMuted, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: IndustrialTokens.statRed),
    ),
  );
}
