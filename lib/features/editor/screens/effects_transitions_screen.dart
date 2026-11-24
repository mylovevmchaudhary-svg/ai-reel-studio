import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/scene_model.dart';
import '../../../data/repositories/project_repository.dart';

class EffectsTransitionsScreen extends StatefulWidget {
  final String projectId;

  const EffectsTransitionsScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<EffectsTransitionsScreen> createState() => _EffectsTransitionsScreenState();
}

class _EffectsTransitionsScreenState extends State<EffectsTransitionsScreen> {
  final ProjectRepository _repo = ProjectRepository();
  List<SceneModel> _scenes = [];
  bool _isLoading = true;
  String _globalTransition = 'Crossfade';
  double _transitionDuration = 0.5;

  @override
  void initState() {
    super.initState();
    _loadScenes();
  }

  Future<void> _loadScenes() async {
    setState(() => _isLoading = true);
    _scenes = await _repo.getScenes(widget.projectId);
    setState(() => _isLoading = false);
  }

  Future<void> _applyGlobalTransition() async {
    for (final s in _scenes) {
      final updated = s.copyWith(
        transitionType: _globalTransition.toLowerCase().replaceAll(' ', '_'),
        transitionDuration: _transitionDuration,
      );
      await _repo.saveScene(updated);
    }
    _loadScenes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Applied $_globalTransition transition to all ${_scenes.length} scenes! ✨')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Effects & Transitions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Global Transition Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroCardGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Apply Transition to All Scenes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppConstants.transitions.map((t) {
                            final isSelected = _globalTransition.toLowerCase() == t.toLowerCase();
                            return ChoiceChip(
                              label: Text(t),
                              selected: isSelected,
                              selectedColor: AppColors.accentPurple,
                              onSelected: (_) => setState(() => _globalTransition = t),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        Text('Transition Duration: ${_transitionDuration.toStringAsFixed(1)}s', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                        Slider(
                          value: _transitionDuration,
                          min: 0.2,
                          max: 1.5,
                          divisions: 13,
                          label: '${_transitionDuration.toStringAsFixed(1)}s',
                          onChanged: (val) => setState(() => _transitionDuration = val),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _applyGlobalTransition,
                          icon: const Icon(Icons.auto_fix_high),
                          label: const Text('Apply to All Scenes'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPink),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Per-Scene Transitions
                  const Text('Per-Scene Transitions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _scenes.length,
                    itemBuilder: (context, index) {
                      final s = _scenes[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardNavy,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentPurple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Scene ${s.sceneIndex}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.accentPurple)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.title ?? 'Scene Headline',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                s.transitionType.toUpperCase(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
