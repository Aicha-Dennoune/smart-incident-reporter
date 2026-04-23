import 'package:flutter/material.dart';

import '../../theme/industrial_tokens.dart';

class NeoCard extends StatelessWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accentColor,
    this.accentWidth = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final double accentWidth;

  @override
  Widget build(BuildContext context) {
    final showAccent = accentWidth > 0 && accentColor != null;
    final resolved = padding.resolve(Directionality.of(context));

    return Container(
      decoration: BoxDecoration(
        color: IndustrialTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IndustrialTokens.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (showAccent)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: accentWidth,
                child: ColoredBox(color: accentColor!),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                resolved.left + (showAccent ? accentWidth : 0),
                resolved.top,
                resolved.right,
                resolved.bottom,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
