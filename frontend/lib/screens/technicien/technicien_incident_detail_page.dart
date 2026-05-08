import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/incident_pdf_service.dart';
import '../../services/incident_service.dart';
import '../../theme/industrial_tokens.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/industrial/neo_card.dart';
import '../../widgets/technician_incident_ai_panel.dart';
import 'package:cached_network_image/cached_network_image.dart';
/// URL photo : uniquement le champ Firestore `imageUrl` (pas d’autres clés).
String? _imageUrlFromIncidentMap(Map<String, dynamic> incident) {
  final v = incident['imageUrl'];
  if (v == null) return null;
  if (v is String) {
    final s = v.trim();
    return s.isEmpty ? null : s;
  }
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

class TechnicienIncidentDetailPage extends StatelessWidget {
  const TechnicienIncidentDetailPage({
    super.key,
    required this.incidentId,
    required this.technicianUid,
  });

  final String incidentId;
  final String technicianUid;

  static String _typeFr(String? t) {
    switch (t) {
      case 'Electricite':
        return 'Électricité';
      case 'Mecanique':
        return 'Mécanique';
      default:
        return t ?? '';
    }
  }

  static String _statusFr(String? s) {
    switch (s) {
      case 'open':
        return 'Ouvert';
      case 'in_progress':
        return 'En cours';
      case 'resolved_pending_validation':
        return 'À valider';
      case 'closed':
        return 'Résolu';
      default:
        return s ?? '';
    }
  }

  static Widget _statusBadge(String? status) {
    final fr = _statusFr(status);
    Color bg;
    Color fg;
    switch (status) {
      case 'in_progress':
        bg = const Color(0xFF5D4037);
        fg = IndustrialTokens.statOrange;
        break;
      case 'open':
        bg = const Color(0xFF1E3A5F);
        fg = const Color(0xFF90CAF9);
        break;
      default:
        bg = IndustrialTokens.card;
        fg = IndustrialTokens.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        fr,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = IncidentService();
    final short = incidentId.length > 4 ? incidentId.substring(incidentId.length - 4) : incidentId;

    return Scaffold(
      appBar: AppTopBar(title: 'Détail incident #$short'),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('incidents')
                .doc(incidentId)
                .snapshots(includeMetadataChanges: true),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Incident introuvable.'));
          }
          final data = snap.data!.data() ?? {};
          final title = data['title']?.toString() ?? '';
          final type = _typeFr(data['type']?.toString());
          final description = data['description']?.toString() ?? '';
          final status = data['status']?.toString();
          final imageUrl = _imageUrlFromIncidentMap(data);
          final location = IncidentService.locationFrom(data);
          // ignore: avoid_print, prefer_interpolation_to_compose_strings
          print('Image URL: ' + (imageUrl ?? ''));
          final createdBy = data['createdBy']?.toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NeoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: IndustrialTokens.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  type,
                                  style: const TextStyle(
                                    color: IndustrialTokens.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _statusBadge(status),
                        ],
                      ),
                      const Divider(
                        height: 28,
                        color: IndustrialTokens.cardBorder,
                      ),
                      const Text(
                        'Description',
                        style: TextStyle(
                          color: IndustrialTokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          color: IndustrialTokens.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TechnicianIncidentAiPanel(
                  key: ValueKey<String>(description),
                  description: description,
                ),
                const SizedBox(height: 14),
                NeoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photo de l\'incident',
                        style: TextStyle(
                          color: IndustrialTokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: AspectRatio(
    aspectRatio: 16 / 9,
    child: (imageUrl != null && imageUrl.isNotEmpty)
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: IndustrialTokens.bg,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) {
              // ignore: avoid_print
              print("Erreur image: $error");
              return Container(
                color: IndustrialTokens.bg,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: IndustrialTokens.textSecondary,
                ),
              );
            },
          )
        : Container(
            color: IndustrialTokens.bg,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_outlined,
              color: IndustrialTokens.textSecondary,
              size: 40,
            ),
          ),
  ),
),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _IncidentLocationCard(location: location),
                const SizedBox(height: 14),
                if (createdBy != null && createdBy.isNotEmpty)
                  _ReporterCard(createdByUid: createdBy),
                const SizedBox(height: 14),
                _ExportPdfButton(
                  incidentId: incidentId,
                  incidentTitle: title,
                  incidentType: type,
                  incidentDescription: description,
                  incidentStatus: _statusFr(status),
                  createdAt: data['createdAt'] as Timestamp?,
                  resolvedAt: data['resolvedAt'] as Timestamp?,
                  createdByKey: createdBy,
                  technicianUid: technicianUid,
                  location: location,
                  imageUrl: imageUrl,
                ),
                const SizedBox(height: 20),
                if (status == 'in_progress')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              () => service.markResolvedPendingValidation(
                                incidentId: incidentId,
                                technicianUid: technicianUid,
                              ),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Résoudre'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: IndustrialTokens.neon,
                            side: const BorderSide(
                              color: IndustrialTokens.neonMuted,
                              width: 1.4,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4A1515),
                            foregroundColor: const Color(0xFFFF8A80),
                          ),
                          onPressed:
                              () => service.markImpossibleToResolve(
                                incidentId: incidentId,
                                technicianUid: technicianUid,
                              ),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Impossible'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _IncidentLocationCard extends StatelessWidget {
  const _IncidentLocationCard({required this.location});

  final GeoPoint? location;

  Future<void> _openInGoogleMaps(BuildContext context) async {
    if (location == null) return;
    final lat = location!.latitude;
    final lng = location!.longitude;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    final ok = await launchUrl(url, mode: LaunchMode.platformDefault);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir Google Maps.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Localisation',
            style: TextStyle(
              color: IndustrialTokens.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              child:
                  location == null
                      ? Container(
                        color: IndustrialTokens.bg,
                        alignment: Alignment.center,
                        child: const Text(
                          'Aucune localisation',
                          style: TextStyle(
                            color: IndustrialTokens.textSecondary,
                          ),
                        ),
                      )
                      : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(location!.latitude, location!.longitude),
                          zoom: 16,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('incident_location'),
                            position: LatLng(
                              location!.latitude,
                              location!.longitude,
                            ),
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        compassEnabled: false,
                      ),
            ),
          ),
          if (location != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _openInGoogleMaps(context),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Ouvrir dans Google Maps'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: IndustrialTokens.neon,
                  side: const BorderSide(color: IndustrialTokens.neonMuted),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReporterCard extends StatelessWidget {
  const _ReporterCard({required this.createdByUid});

  final String createdByUid;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      accentColor: IndustrialTokens.statOrange,
      accentWidth: 5,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(createdByUid)
                .snapshots(),
        builder: (context, snap) {
          final d = snap.data?.data() ?? {};
          final nom = d['nom']?.toString() ?? '';
          final prenom = d['prenom']?.toString() ?? '';
          final label =
              '$prenom $nom'.trim().isEmpty
                  ? 'Employé'
                  : '$prenom $nom'.trim();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signalé par $label',
                style: const TextStyle(
                  color: IndustrialTokens.neonMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Aujourd\'hui',
                style: TextStyle(
                  color: IndustrialTokens.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExportPdfButton extends StatefulWidget {
  const _ExportPdfButton({
    required this.incidentId,
    required this.incidentTitle,
    required this.incidentType,
    required this.incidentDescription,
    required this.incidentStatus,
    required this.createdAt,
    required this.resolvedAt,
    required this.createdByKey,
    required this.technicianUid,
    required this.location,
    required this.imageUrl,
  });

  final String incidentId;
  final String incidentTitle;
  final String incidentType;
  final String incidentDescription;
  final String incidentStatus;
  final Timestamp? createdAt;
  final Timestamp? resolvedAt;
  final String? createdByKey;
  final String technicianUid;
  final GeoPoint? location;
  final String? imageUrl;

  @override
  State<_ExportPdfButton> createState() => _ExportPdfButtonState();
}

class _ExportPdfButtonState extends State<_ExportPdfButton> {
  final _pdfService = IncidentPdfService();
  bool _busy = false;

  Future<String> _displayNameByUserKey(String? key) async {
    final value = key?.trim() ?? '';
    if (value.isEmpty) return '—';
    final users = FirebaseFirestore.instance.collection('users');
    DocumentSnapshot<Map<String, dynamic>>? doc;

    if (!value.contains('@')) {
      final byId = await users.doc(value).get();
      if (byId.exists) doc = byId;
    } else {
      final q = await users.where('email', isEqualTo: value).limit(1).get();
      if (q.docs.isNotEmpty) doc = q.docs.first;
    }
    if (doc == null || !doc.exists) return value;
    final d = doc.data() ?? {};
    final name = '${d['prenom'] ?? ''} ${d['nom'] ?? ''}'.trim();
    return name.isEmpty ? value : name;
  }

  Future<void> _onExportPressed() async {
    final solutionController = TextEditingController();
    final solution = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Solution technique appliquée'),
            content: TextField(
              controller: solutionController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Décrivez la solution appliquée…',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed:
                    () => Navigator.of(ctx).pop(solutionController.text.trim()),
                child: const Text('Générer le PDF'),
              ),
            ],
          ),
    );
    solutionController.dispose();
    if (!mounted || solution == null) return;

    setState(() => _busy = true);
    try {
      final reporterName = await _displayNameByUserKey(widget.createdByKey);
      final technicianName = await _displayNameByUserKey(widget.technicianUid);
      final locationLabel =
          widget.location == null
              ? null
              : 'Latitude: ${widget.location!.latitude.toStringAsFixed(6)}\n'
                  'Longitude: ${widget.location!.longitude.toStringAsFixed(6)}';

      final bytes = await _pdfService.buildIncidentPdf(
        IncidentPdfPayload(
          incidentTitle: widget.incidentTitle,
          incidentType: widget.incidentType,
          incidentDescription: widget.incidentDescription,
          incidentStatus: widget.incidentStatus,
          createdAt: widget.createdAt?.toDate(),
          resolvedAt: widget.resolvedAt?.toDate(),
          reporterName: reporterName,
          technicianName: technicianName,
          locationLabel: locationLabel,
          imageUrl: widget.imageUrl,
          solutionText: solution,
        ),
      );

      final filename = 'rapport_incident_${widget.incidentId}.pdf';
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: filename,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur PDF: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _onExportPressed,
        icon:
            _busy
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.picture_as_pdf_outlined),
        label: Text(_busy ? 'Génération…' : 'Exporter PDF'),
        style: OutlinedButton.styleFrom(
          foregroundColor: IndustrialTokens.neon,
          side: const BorderSide(color: IndustrialTokens.neonMuted),
        ),
      ),
    );
  }
}
