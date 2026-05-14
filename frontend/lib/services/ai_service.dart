import 'dart:convert';

import 'package:http/http.dart' as http;

/// Appels HTTP vers votre backend / proxy IA.
///
/// Lancer l’app avec par exemple :
/// `flutter run --dart-define=AI_API_BASE_URL=http://10.0.2.2:5000`
///
/// Optionnel (si votre backend vérifie un jeton) :
/// `--dart-define=API_KEY=...` → envoie `Authorization: Bearer ...`
///
/// Endpoints attendus (POST JSON, réponse JSON) :
/// - `{AI_API_BASE_URL}/ai/improve`     body `{"text":"..."}` → `{"text":"..."}` ou `{"improved":"..."}`
/// - `{AI_API_BASE_URL}/ai/suggest-type` body `{"text":"..."}` → `{"type":"Electricite"}` (ou libellé proche)
/// - `{AI_API_BASE_URL}/ai/suggest-solution` body `{"text":"..."}` → `{"solution":"..."}` ou `{"text":"..."}`
/// - `{AI_API_BASE_URL}/ai/classify-priority` body `{"title":"...","description":"..."}` → `{"priority":"Faible|Moyenne|Critique"}`
class AIServiceException implements Exception {
  AIServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AIService {
  AIService({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const String _apiKey = String.fromEnvironment('API_KEY', defaultValue: '');
  static const String _baseUrl = String.fromEnvironment(
    'AI_API_BASE_URL',
    defaultValue: '',
  );

  static const Duration _timeout = Duration(seconds: 45);

  void _ensureConfigured() {
    if (_baseUrl.trim().isEmpty) {
      throw AIServiceException(
        'URL de base manquante. Lancez avec --dart-define=AI_API_BASE_URL=...',
      );
    }
  }

  Uri _uri(String path) {
    var base = _baseUrl.trim();
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw AIServiceException('Réponse JSON invalide (objet attendu).');
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    _ensureConfigured();
    final uri = _uri(path);
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_apiKey.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer $_apiKey';
    }

    final response = await _client
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AIServiceException(
        'Erreur HTTP ${response.statusCode}: ${response.body}',
      );
    }
    return _decodeObject(response.body);
  }

  static String? _firstNonEmptyString(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  /// Retourne une description reformulée / enrichie.
  Future<String> improveDescription(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw AIServiceException('La description est vide.');
    }
    final json = await _post('/ai/improve', {'text': trimmed});
    final out = _firstNonEmptyString(json, ['text', 'improved', 'description', 'result']);
    if (out == null || out.isEmpty) {
      throw AIServiceException('Réponse IA vide pour improve.');
    }
    return out;
  }

  /// Retourne un code type parmi : Electricite, Mecanique, IT, Eau (ou null si non reconnu).
  Future<String?> suggestType(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw AIServiceException('La description est vide.');
    }
    final json = await _post('/ai/suggest-type', {'text': trimmed});
    final raw = _firstNonEmptyString(json, ['type', 'incidentType', 'category', 'result']);
    return normalizeIncidentType(raw);
  }

  /// Retourne une proposition de solution pour le technicien.
  Future<String> suggestSolution(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw AIServiceException('La description est vide.');
    }
    final json = await _post('/ai/suggest-solution', {'text': trimmed});
    final out = _firstNonEmptyString(json, ['solution', 'text', 'result', 'message']);
    if (out == null || out.isEmpty) {
      throw AIServiceException('Réponse IA vide pour la solution.');
    }
    return out;
  }

  Future<String?> suggestPriority({
    required String title,
    required String description,
  }) async {
    final t = title.trim();
    final d = description.trim();
    if (t.isEmpty && d.isEmpty) {
      throw AIServiceException('Titre et description vides.');
    }
    final json = await _post('/ai/classify-priority', {
      'title': t,
      'description': d,
    });
    final raw = _firstNonEmptyString(
      json,
      ['priority', 'priorite', 'result', 'text'],
    );
    return normalizePriority(raw);
  }

  static String? normalizeIncidentType(String? raw) {
    if (raw == null) return null;
    var t = raw.trim().toLowerCase();
    t = t.replaceAll('é', 'e').replaceAll('è', 'e');
    if (t.contains('electric')) return 'Electricite';
    if (t.contains('meca')) return 'Mecanique';
    if (t.contains('eau') || t.contains('water')) return 'Eau';
    if (t == 'it' || t.contains('info') || t.contains('informatique')) return 'IT';
    if (t == 'electricite') return 'Electricite';
    if (t == 'mecanique') return 'Mecanique';
    if (t == 'eau') return 'Eau';
    return null;
  }

  static String? normalizePriority(String? raw) {
    if (raw == null) return null;
    var t = raw.trim().toLowerCase();
    t = t.replaceAll('é', 'e').replaceAll('è', 'e');
    if (t.contains('crit')) return 'Critique';
    if (t.contains('moy')) return 'Moyenne';
    if (t.contains('faib')) return 'Faible';
    return null;
  }
}
