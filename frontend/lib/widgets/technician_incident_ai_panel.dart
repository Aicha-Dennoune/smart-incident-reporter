import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import '../theme/industrial_tokens.dart';
import 'industrial/neo_card.dart';

/// Bouton + carte pour afficher une suggestion IA (détail incident technicien).
class TechnicianIncidentAiPanel extends StatefulWidget {
  const TechnicianIncidentAiPanel({super.key, required this.description});

  final String description;

  @override
  State<TechnicianIncidentAiPanel> createState() => _TechnicianIncidentAiPanelState();
}

class _TechnicianIncidentAiPanelState extends State<TechnicianIncidentAiPanel> {
  final _ai = AIService();
  bool _loading = false;
  String? _solution;
  String? _error;

  Future<void> _fetchSuggestion() async {
    final text = widget.description.trim();
    if (text.isEmpty) {
      setState(() {
        _error = 'Aucune description à analyser.';
        _solution = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _solution = null;
    });
    try {
      final solution = await _ai.suggestSolution(text);
      if (!mounted) return;
      setState(() {
        _solution = solution;
        _loading = false;
      });
    } on AIServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur réseau ou serveur : $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: IndustrialTokens.neonMuted, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Assistance IA',
                  style: TextStyle(
                    color: IndustrialTokens.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _fetchSuggestion,
            icon:
                _loading
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.lightbulb_outline),
            label: Text(_loading ? 'Analyse…' : 'Suggestion IA'),
            style: OutlinedButton.styleFrom(
              foregroundColor: IndustrialTokens.neon,
              side: const BorderSide(color: IndustrialTokens.neonMuted, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                color: IndustrialTokens.statRed,
                height: 1.35,
              ),
            ),
          ],
          if (_solution != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: IndustrialTokens.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: IndustrialTokens.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Proposition',
                    style: TextStyle(
                      color: IndustrialTokens.neonMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _solution!,
                    style: const TextStyle(
                      color: IndustrialTokens.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
