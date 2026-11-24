import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/scene_model.dart';
import '../../../data/models/scene_asset_model.dart';
import '../../../data/models/voiceover_model.dart';
import '../../../data/repositories/project_repository.dart';
import 'scene_prompt_editor_screen.dart';
import '../../images/screens/image_upload_screen.dart';
import '../../voiceover/screens/voiceover_studio_screen.dart';
import '../../editor/screens/video_timeline_editor_screen.dart';

class SceneManagerScreen extends StatefulWidget {
  final String projectId;

  const SceneManagerScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<SceneManagerScreen> createState() => _SceneManagerScreenState();
}

class _SceneManagerScreenState extends State<SceneManagerScreen> {
  final ProjectRepository _repo = ProjectRepository();
  bool _isLoading = true;
  List<SceneModel> _scenes = [];
  List<SceneAssetModel> _assets = [];
  List<VoiceoverModel> _voiceovers = [];

  @override
  void initState() {
    super.initState();
    _loadScenes();
  }

  Future<void> _loadScenes() async {
    setState(() => _isLoading = true);
    _scenes = await _repo.getScenes(widget.projectId);
    _assets = await _repo.getAssetsForProject(widget.projectId);
    _voiceovers = await _repo.getVoiceoversForProject(widget.projectId);
    setState(() => _isLoading = false);
  }

  Future<void> _addNewScene() async {
    final newIndex = _scenes.length + 1;
    final scene = SceneModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      projectId: widget.projectId,
      ownerId: 'owner',
      sceneIndex: newIndex,
      title: 'Scene $newIndex (Custom)',
      visualPrompt: 'High quality cinematic visual, detailed textures, 8k resolution',
      durationSeconds: 5.0,
      transitionType: 'fade',
    );
    await _repo.saveScene(scene);
    _loadScenes();
  }

  Future<void> _deleteScene(String sceneId) async {
    await _repo.deleteScene(sceneId);
    _loadScenes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Scene Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Scene',
            onPressed: _addNewScene,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VideoTimelineEditorScreen(projectId: widget.projectId)),
          );
        },
        backgroundColor: AppColors.accentPurple,
        icon: const Icon(Icons.view_timeline),
        label: const Text('Timeline Editor'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : _scenes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.movie_creation_outlined, size: 48, color: Colors.white38),
                      const SizedBox(height: 12),
                      const Text('No scenes created yet', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _addNewScene, child: const Text('Add First Scene')),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                  itemCount: _scenes.length,
                  itemBuilder: (context, index) {
                    final scene = _scenes[index];
                    final hasImage = _assets.any((a) => a.sceneId == scene.id && a.isActive);
                    final hasVoiceover = _voiceovers.any((v) => v.sceneId == scene.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accentPurple,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Scene ${scene.sceneIndex}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  scene.title ?? 'Scene Headline',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${scene.durationSeconds.toStringAsFixed(1)}s',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18, color: Colors.white54),
                                color: AppColors.cardNavy,
                                onSelected: (val) {
                                  if (val == 'delete') _deleteScene(scene.id);
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'delete', child: Text('Delete Scene', style: TextStyle(color: AppColors.error))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Visual Prompt Summary
                          Text(
                            scene.visualPrompt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 12),

                          // Badges & Action Buttons
                          Row(
                            children: [
                              // Image Status Pill
                              _buildStatusBadge(
                                icon: hasImage ? Icons.check_circle : Icons.image_outlined,
                                label: hasImage ? 'Image Ready' : 'Add Image',
                                color: hasImage ? AppColors.success : Colors.white38,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ImageUploadScreen(projectId: widget.projectId, sceneId: scene.id)),
                                  );
                                  _loadScenes();
                                },
                              ),
                              const SizedBox(width: 8),

                              // Voiceover Status Pill
                              _buildStatusBadge(
                                icon: hasVoiceover ? Icons.mic : Icons.mic_none,
                                label: hasVoiceover ? 'VO Added' : 'Add VO',
                                color: hasVoiceover ? AppColors.accentCyan : Colors.white38,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => VoiceoverStudioScreen(projectId: widget.projectId, initialSceneId: scene.id)),
                                  );
                                  _loadScenes();
                                },
                              ),
                              const Spacer(),

                              // Edit Prompt Button
                              IconButton(
                                icon: const Icon(Icons.edit_note, color: AppColors.accentPurple),
                                tooltip: 'Edit Prompt & Script',
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ScenePromptEditorScreen(scene: scene),
                                    ),
                                  );
                                  _loadScenes();
                                },
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

  Widget _buildStatusBadge({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
