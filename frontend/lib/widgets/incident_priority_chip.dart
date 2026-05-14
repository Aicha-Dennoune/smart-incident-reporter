import 'package:flutter/material.dart';

import '../services/incident_service.dart';
import '../theme/industrial_tokens.dart';

/// Badge priorité incident (rouge / orange / vert).
class IncidentPriorityChip extends StatelessWidget {
  const IncidentPriorityChip({super.key, required this.priorityRaw});

  final String? priorityRaw;

  static Color colorForBadgeLabel(String label) {
    switch (label) {
      case 'CRITIQUE':
        return IndustrialTokens.statRed;
      case 'MOYENNE':
        return IndustrialTokens.statOrange;
      default:
        return IndustrialTokens.statGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = IncidentService.priorityBadgeLabel(priorityRaw);
    final color = colorForBadgeLabel(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
