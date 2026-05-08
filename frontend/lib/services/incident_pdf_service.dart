import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class IncidentPdfPayload {
  IncidentPdfPayload({
    required this.incidentTitle,
    required this.incidentType,
    required this.incidentDescription,
    required this.incidentStatus,
    required this.createdAt,
    required this.resolvedAt,
    required this.reporterName,
    required this.technicianName,
    required this.locationLabel,
    required this.imageUrl,
    required this.solutionText,
  });

  final String incidentTitle;
  final String incidentType;
  final String incidentDescription;
  final String incidentStatus;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final String reporterName;
  final String technicianName;
  final String? locationLabel;
  final String? imageUrl;
  final String solutionText;
}

class IncidentPdfService {
  Future<Uint8List> buildIncidentPdf(IncidentPdfPayload payload) async {
    final doc = pw.Document();
    final logoBytes = await _loadAssetBytes('assets/images/OCP_LOGO.png');
    final logoImage = logoBytes == null ? null : pw.MemoryImage(logoBytes);
    final incidentImageBytes = await _downloadNetworkImage(payload.imageUrl);
    final incidentImage =
        incidentImageBytes == null ? null : pw.MemoryImage(incidentImageBytes);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
        footer:
            (context) => pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Document généré automatiquement par Smart Incident Reporter',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ),
        build:
            (context) => [
              if (logoImage != null)
                pw.Center(
                  child: pw.Image(logoImage, height: 54),
                ),
              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text(
                  'RAPPORT D`INCIDENT INDUSTRIEL',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
              ),
              pw.SizedBox(height: 18),
              _sectionTitle('Informations incident'),
              _infoTable([
                ['Titre', payload.incidentTitle],
                ['Type', payload.incidentType],
                ['Description', payload.incidentDescription],
                ['Statut', payload.incidentStatus],
                ['Date création', _formatDate(payload.createdAt)],
                ['Date résolution', _formatDate(payload.resolvedAt)],
              ]),
              pw.SizedBox(height: 14),
              _sectionTitle('Employé déclarant'),
              _paragraph(payload.reporterName),
              pw.SizedBox(height: 12),
              _sectionTitle('Technicien assigné'),
              _paragraph(payload.technicianName),
              pw.SizedBox(height: 12),
              _sectionTitle('Localisation'),
              _paragraph(payload.locationLabel ?? 'Non renseignée'),
              if (incidentImage != null) ...[
                pw.SizedBox(height: 14),
                _sectionTitle('Image incident'),
                pw.SizedBox(height: 6),
                pw.Container(
                  height: 220,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Image(incidentImage, fit: pw.BoxFit.contain),
                ),
              ],
              pw.SizedBox(height: 14),
              _sectionTitle('Solution technique appliquée'),
              _paragraph(payload.solutionText.trim().isEmpty ? '—' : payload.solutionText.trim()),
            ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#E8EEF7'),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
      ),
    );
  }

  static pw.Widget _paragraph(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 11, height: 1.35)),
    );
  }

  static pw.Widget _infoTable(List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FixedColumnWidth(120),
        1: const pw.FlexColumnWidth(),
      },
      headers: const ['Champ', 'Valeur'],
      data: rows,
    );
  }

  static Future<Uint8List?> _loadAssetBytes(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _downloadNetworkImage(String? url) async {
    final imageUrl = url?.trim();
    if (imageUrl == null || imageUrl.isEmpty) return null;
    try {
      final resp = await http.get(Uri.parse(imageUrl));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return resp.bodyBytes;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }
}

