import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/character_model.dart';
import '../../../data/models/scene_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../../scenes/screens/scene_manager_screen.dart';
import '../../characters/screens/character_reference_screen.dart';
import '../../editor/screens/video_timeline_editor_screen.dart';

class StoryEditorScreen extends StatefulWidget {
  final String projectId;
  final StoryModel story;
  final List<CharacterModel> characters;
  final List<SceneModel> scenes;
  final String suggestedBgm;

  const StoryEditorScreen({
    Key? key,
    required this.projectId,
    required this.story,
    required this.characters,
    required this.scenes,
    required this.suggestedBgm,
  }) : super(key: key);

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final ProjectRepository _repo = ProjectRepository();
  late StoryModel _story;
  late List<CharacterModel> _characters;
  late List<SceneModel> _scenes;

  @override
  void initState() {
    super.initState();
    _story = widget.story;
    _characters = widget.characters;
    _scenes = widget.scenes;
  }

  void _editStoryInfo() {
    final titleCtrl = TextEditingController(text: _story.storyTitle);
    final synopsisCtrl = TextEditingController(text: _story.synopsis ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        title: const Text('Edit Story Overview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Story Title'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: synopsisCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Synopsis / Hook'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updated = _story.copyWith(
                storyTitle: titleCtrl.text.trim(),
                synopsis: synopsisCtrl.text.trim(),
              );
              await _repo.saveStory(updated);
              setState(() => _story = updated);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Story & Scene Breakdown'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Title & Hook',
            onPressed: _editStoryInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Story Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.heroCardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _story.genre,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentPurple),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('• ${_scenes.length} Scenes', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _story.storyTitle,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (_story.synopsis != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _story.synopsis!,
                      style: TextStyle(fontSize: 13, height: 1.4, color: Colors.white.withOpacity(0.75)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.music_note, size: 14, color: AppColors.accentCyan),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Suggested BGM: ${widget.suggestedBgm}',
                          style: const TextStyle(fontSize: 11, color: AppColors.accentCyan),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Characters Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Characters & Consistency',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CharacterReferenceScreen(projectId: widget.projectId)),
                    );
                  },
                  icon: const Icon(Icons.people_outline, size: 16),
                  label: const Text('Manage', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._characters.map((c) => _buildCharacterCard(c)),
            const SizedBox(height: 20),

            // 3. Scenes Sequence Overview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scenes Sequence',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SceneManagerScreen(projectId: widget.projectId)),
                    );
                  },
                  icon: const Icon(Icons.dashboard_customize_outlined, size: 16),
                  label: const Text('Scene Manager', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._scenes.map((s) => _buildSceneOverviewCard(s)),
            const SizedBox(height: 24),

            // Open Timeline Video Editor CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VideoTimelineEditorScreen(projectId: widget.projectId)),
                  );
                },
                icon: const Icon(Icons.view_timeline),
                label: const Text('Open Multi-Track Timeline Editor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.accentPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCard(CharacterModel char) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.purplePinkGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Icon(Icons.face, color: Colors.white, size: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(char.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                    const SizedBox(width: 6),
                    if (char.role != null)
                      Text('(${char.role})', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  char.visualDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneOverviewCard(SceneModel scene) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Scene ${scene.sceneIndex}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentPurple)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  scene.title ?? 'Scene Headline',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${scene.durationSeconds.toStringAsFixed(1)}s',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
              ),
            ],
          ),
          if (scene.narration != null) ...[
            const SizedBox(height: 6),
            Text(
              'Voiceover: "${scene.narration}"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ],
      ),
    );
  }
}
