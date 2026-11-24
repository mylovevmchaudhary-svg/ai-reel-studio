import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/media_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/scene_asset_model.dart';
import '../../../data/models/scene_model.dart';
import '../../../data/repositories/project_repository.dart';

class ImageUploadScreen extends StatefulWidget {
  final String projectId;
  final String? sceneId;

  const ImageUploadScreen({Key? key, required this.projectId, this.sceneId}) : super(key: key);

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final ProjectRepository _repo = ProjectRepository();
  final MediaService _media = MediaService.instance;
  final _uuid = const Uuid();

  List<SceneModel> _scenes = [];
  List<SceneAssetModel> _assets = [];
  String? _selectedSceneId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedSceneId = widget.sceneId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _scenes = await _repo.getScenes(widget.projectId);
    _assets = await _repo.getAssetsForProject(widget.projectId);
    if (_selectedSceneId == null && _scenes.isNotEmpty) {
      _selectedSceneId = _scenes.first.id;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickAndAttachImage(ImageSource source) async {
    if (_selectedSceneId == null) return;

    final file = await _media.pickImage(source: source, projectId: widget.projectId);
    if (file != null) {
      final asset = SceneAssetModel(
        id: _uuid.v4(),
        sceneId: _selectedSceneId!,
        projectId: widget.projectId,
        ownerId: SupabaseService.instance.currentUserId,
        assetType: 'image',
        assetUrl: file.path,
        localPath: file.path,
        aspectRatio: '9:16',
        isActive: true,
      );

      await _repo.saveSceneAsset(asset);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded and attached to scene! 🖼️')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeScene = _scenes.where((s) => s.id == _selectedSceneId).firstOrNull;
    final activeAsset = _assets.where((a) => a.sceneId == _selectedSceneId && a.isActive).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Image Upload & Assets'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select Scene Dropdown
                  const Text('Select Target Scene', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSceneId,
                        isExpanded: true,
                        dropdownColor: AppColors.cardNavy,
                        items: _scenes.map((s) {
                          return DropdownMenuItem<String>(
                            value: s.id,
                            child: Text('Scene ${s.sceneIndex}: ${s.title ?? "Untitled"}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSceneId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Scene Visual Prompt Reference
                  if (activeScene != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.warning),
                              const SizedBox(width: 6),
                              Text('Expected Scene Visual (${activeScene.cameraAngle})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            activeScene.visualPrompt,
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Current Image Display / Preview
                  Center(
                    child: Container(
                      width: 220,
                      height: 330, // 9:16 aspect preview
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.12), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: activeAsset != null && File(activeAsset.localPath ?? '').existsSync()
                            ? Image.file(File(activeAsset.localPath!), fit: BoxFit.cover)
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.white.withOpacity(0.3)),
                                  const SizedBox(height: 12),
                                  const Text('No Image Attached', style: TextStyle(color: Colors.white54, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('Upload 9:16 image for this scene', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Upload Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickAndAttachImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('From Gallery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentPurple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickAndAttachImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Capture Camera'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
