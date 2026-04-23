import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/incident_service.dart';
import '../../theme/industrial_tokens.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/industrial/dashed_photo_zone.dart';
import '../../widgets/industrial/neo_labeled_field.dart';

class EmployeDeclareIncidentPage extends StatefulWidget {
  const EmployeDeclareIncidentPage({super.key});

  @override
  State<EmployeDeclareIncidentPage> createState() =>
      _EmployeDeclareIncidentPageState();
}

class _EmployeDeclareIncidentPageState extends State<EmployeDeclareIncidentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _service = IncidentService();
  final _picker = ImagePicker();

  String _type = 'Mecanique';
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isSubmitting = false;

  static const _types = ['IT', 'Electricite', 'Mecanique', 'Eau'];

  static String _typeDisplay(String code) {
    switch (code) {
      case 'Electricite':
        return 'Électricité';
      case 'Mecanique':
        return 'Mécanique';
      default:
        return code;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = picked.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await _service.createIncident(
        title: _titleController.text,
        description: _descriptionController.text,
        type: _type,
        createdBy: uid,
        imageBytes: _selectedImageBytes,
        imageName: _selectedImageName,
      );
      if (!mounted) return;
      _formKey.currentState?.reset();
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImageBytes = null;
        _selectedImageName = null;
        _type = 'Mecanique';
      });
      if (result.imageError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Incident enregistré. La photo n\'a pas pu être envoyée (Storage). '
              'Vérifiez les règles Firebase Storage. Détail : ${result.imageError}',
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident soumis avec succès.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Nouvel Incident'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeoLabeledField(
                label: 'Titre',
                child: TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: IndustrialTokens.textPrimary),
                  decoration: neoInputDecoration(
                    hint: 'Panne compresseur ligne 4',
                  ),
                  validator:
                      (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Titre requis.'
                              : null,
                ),
              ),
              const SizedBox(height: 18),
              NeoLabeledField(
                label: 'Description',
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  style: const TextStyle(color: IndustrialTokens.textPrimary),
                  decoration: neoInputDecoration(
                    hint: 'Décrivez le problème…',
                  ),
                  validator:
                      (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Description requise.'
                              : null,
                ),
              ),
              const SizedBox(height: 18),
              NeoLabeledField(
                label: 'Type d\'incident',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      _types.map((t) {
                        final selected = _type == t;
                        return ChoiceChip(
                          label: Text(_typeDisplay(t)),
                          selected: selected,
                          onSelected:
                              _isSubmitting
                                  ? null
                                  : (v) {
                                    if (v) setState(() => _type = t);
                                  },
                          selectedColor: IndustrialTokens.neon,
                          backgroundColor: IndustrialTokens.card,
                          labelStyle: TextStyle(
                            color:
                                selected
                                    ? IndustrialTokens.bg
                                    : IndustrialTokens.neon,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(
                            color:
                                selected
                                    ? IndustrialTokens.neon
                                    : IndustrialTokens.cardBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 18),
              NeoLabeledField(
                label: 'Photo',
                child: DashedPhotoZone(
                  onTap: _isSubmitting ? null : _pickImage,
                  height: 168,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: IndustrialTokens.neon.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: IndustrialTokens.neon,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Ajouter une photo',
                          style: TextStyle(
                            color: IndustrialTokens.neon,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_selectedImageBytes != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    _selectedImageBytes!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: IndustrialTokens.bg,
                            ),
                          )
                          : const Text(
                            'Soumettre l\'incident',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
