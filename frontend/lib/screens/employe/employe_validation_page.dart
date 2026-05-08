import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/incident_service.dart';
import '../../theme/industrial_tokens.dart';
import '../../utils/firestore_debug.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/industrial/neo_card.dart';

class EmployeValidationPage extends StatefulWidget {
  const EmployeValidationPage({super.key});

  @override
  State<EmployeValidationPage> createState() => _EmployeValidationPageState();
}

class _EmployeValidationPageState extends State<EmployeValidationPage> {
  final Set<String> _processing = <String>{};

  Future<_SatisfactionResult?> _askSatisfaction() async {
    return showDialog<_SatisfactionResult>(
      context: context,
      builder: (_) => const _SatisfactionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final email = user?.email;
    final service = IncidentService();
    return Scaffold(
      appBar: const AppTopBar(title: 'Validation'),
      body:
          uid == null
              ? const Center(child: Text('Non connecté'))
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: service.watchIncidents(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: firestoreErrorPanel(snapshot.error!));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final mine = IncidentService.incidentsForCreator(
                    snapshot.data,
                    uid,
                    email,
                  );
                  final docs =
                      mine
                          .where(
                            (d) =>
                                IncidentService.normStatus(
                                  d.data()['status']?.toString(),
                                ) ==
                                'resolved_pending_validation',
                          )
                          .toList();
                  if (docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucune résolution en attente de votre validation.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: IndustrialTokens.textSecondary),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final doc = docs[i];
                      final data = doc.data();
                      return NeoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title']?.toString() ?? 'Incident',
                              style: const TextStyle(
                                color: IndustrialTokens.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['description']?.toString() ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: IndustrialTokens.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _processing.contains(doc.id)
                                            ? null
                                            : () => service.validateResolvedIncident(
                                              incidentId: doc.id,
                                              accepted: false,
                                            ),
                                    icon: const Icon(Icons.close_rounded),
                                    label: const Text('Refuser'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: IndustrialTokens.statOrange,
                                      side: const BorderSide(
                                        color: IndustrialTokens.statOrange,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed:
                                        _processing.contains(doc.id)
                                            ? null
                                            : () async {
                                              final sat = await _askSatisfaction();
                                              if (sat == null || !context.mounted) {
                                                return;
                                              }
                                              setState(() => _processing.add(doc.id));
                                              try {
                                                await service.validateResolvedIncident(
                                                  incidentId: doc.id,
                                                  accepted: true,
                                                  rating: sat.rating,
                                                  ratingComment: sat.comment,
                                                  ratedByUserId: uid,
                                                );
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Erreur: $e')),
                                                );
                                              } finally {
                                                if (mounted) {
                                                  setState(() => _processing.remove(doc.id));
                                                }
                                              }
                                            },
                                    icon: const Icon(Icons.check_rounded),
                                    label:
                                        _processing.contains(doc.id)
                                            ? const Text('Envoi...')
                                            : const Text('Valider'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}

class _SatisfactionResult {
  _SatisfactionResult({required this.rating, required this.comment});
  final int rating;
  final String comment;
}

class _SatisfactionDialog extends StatefulWidget {
  const _SatisfactionDialog();

  @override
  State<_SatisfactionDialog> createState() => _SatisfactionDialogState();
}

class _SatisfactionDialogState extends State<_SatisfactionDialog> {
  final _commentController = TextEditingController();
  int _selectedRating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitting) return;
    setState(() => _submitting = true);
    Navigator.of(context).pop(
      _SatisfactionResult(
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Votre avis sur l’intervention'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                final selected = star <= _selectedRating;
                return IconButton(
                  onPressed:
                      _submitting
                          ? null
                          : () => setState(() => _selectedRating = star),
                  icon: AnimatedScale(
                    duration: const Duration(milliseconds: 160),
                    scale: selected ? 1.12 : 1.0,
                    child: Icon(
                      Icons.star_rounded,
                      color:
                          selected
                              ? const Color(0xFFFFD54F)
                              : IndustrialTokens.textSecondary,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              minLines: 3,
              maxLines: 5,
              enabled: !_submitting,
              decoration: const InputDecoration(
                labelText: 'Ajouter un commentaire',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
