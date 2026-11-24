import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/media_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/character_model.dart';
import '../../../data/repositories/project_repository.dart';

class CharacterReferenceScreen extends StatefulWidget {
  final String projectId;

  const CharacterReferenceScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<CharacterReferenceScreen> createState() => _CharacterReferenceScreenState();
}

class _CharacterReferenceScreenState extends State<CharacterReferenceScreen> {
  final ProjectRepository _repo = ProjectRepository();
  final MediaService _media = MediaService.instance;
  final _uuid = const Uuid();

  List<CharacterModel> _characters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() => _isLoading = true);
    _characters = await _repo.getCharacters(widget.projectId);
    setState(() => _isLoading = false);
  }

  void _showAddEditCharacterDialog([CharacterModel? character]) {
    final nameCtrl = TextEditingController(text: character?.name ?? '');
    final roleCtrl = TextEditingController(text: character?.role ?? '');
    final descCtrl = TextEditingController(text: character?.visualDescription ?? '');
    final outfitCtrl = TextEditingController(text: character?.outfit ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        title: Text(character == null ? 'Add Character' : 'Edit Character'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Character Name'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: roleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Role (Protagonist, Mentor, Rival)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Visual Description (Face, Hair, Build)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: outfitCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Signature Outfit / Clothing'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final char = CharacterModel(
                id: character?.id ?? _uuid.v4(),
                projectId: widget.projectId,
                ownerId: SupabaseService.instance.currentUserId,
                name: nameCtrl.text.trim(),
                role: roleCtrl.text.trim(),
                visualDescription: descCtrl.text.trim(),
                outfit: outfitCtrl.text.trim(),
                referenceImageUrl: character?.referenceImageUrl,
              );
              await _repo.saveCharacter(char);
              Navigator.pop(ctx);
              _loadCharacters();
            },
            child: const Text('Save Character'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickReferenceImage(CharacterModel character) async {
    final file = await _media.pickImage(source: ImageSource.gallery, projectId: widget.projectId);
    if (file != null) {
      final updated = character.copyWith(referenceImageUrl: file.path);
      await _repo.saveCharacter(updated);
      _loadCharacters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Character Reference Image saved! 📸')),
        );
      }
    }
  }

  void _copyCharacterPrompt(CharacterModel char) {
    final text = 'Subject: ${char.name}, ${char.visualDescription}, wearing ${char.outfit ?? "signature outfit"}, highly consistent facial features, 8k resolution.';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Character description copied to clipboard! 📋')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Character References'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add Character',
            onPressed: () => _showAddEditCharacterDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : _characters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 48, color: Colors.white38),
                      const SizedBox(height: 12),
                      const Text('No characters defined for this story', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: () => _showAddEditCharacterDialog(), child: const Text('Add Character')),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _characters.length,
                  itemBuilder: (context, index) {
                    final c = _characters[index];
                    final hasRefImage = c.referenceImageUrl != null && File(c.referenceImageUrl!).existsSync();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Reference Avatar / Thumbnail
                              GestureDetector(
                                onTap: () => _pickReferenceImage(c),
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryNavy,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.accentPurple.withOpacity(0.4)),
                                    image: hasRefImage
                                        ? DecorationImage(image: FileImage(File(c.referenceImageUrl!)), fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: !hasRefImage
                                      ? const Center(child: Icon(Icons.add_a_photo, size: 20, color: AppColors.accentPurple))
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                    if (c.role != null)
                                      Text(c.role!, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18, color: AppColors.accentPurple),
                                tooltip: 'Copy Prompt',
                                onPressed: () => _copyCharacterPrompt(c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Colors.white54),
                                tooltip: 'Edit',
                                onPressed: () => _showAddEditCharacterDialog(c),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            c.visualDescription,
                            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.white.withOpacity(0.8)),
                          ),
                          if (c.outfit != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.checkroom, size: 14, color: AppColors.accentCyan),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Outfit: ${c.outfit}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.accentCyan),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
