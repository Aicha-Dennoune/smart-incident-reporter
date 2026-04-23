import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/incident_service.dart';
import '../../theme/industrial_tokens.dart';
import '../../utils/firestore_debug.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/industrial/neo_card.dart';

class EmployeValidationPage extends StatelessWidget {
  const EmployeValidationPage({super.key});

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
                                        () => service.validateResolvedIncident(
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
                                        () => service.validateResolvedIncident(
                                          incidentId: doc.id,
                                          accepted: true,
                                        ),
                                    icon: const Icon(Icons.check_rounded),
                                    label: const Text('Valider'),
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
