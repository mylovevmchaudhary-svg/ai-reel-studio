import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/prompt_generator.dart';
import '../../../data/models/scene_model.dart';
import '../../../data/repositories/project_repository.dart';

class ScenePromptEditorScreen extends StatefulWidget {
  final SceneModel scene;

  const ScenePromptEditorScreen({Key? key, required this.scene}) : super(key: key);

  @override
  State<ScenePromptEditorScreen> createState() => _ScenePromptEditorScreenState();
}

class _ScenePromptEditorScreenState extends State<ScenePromptEditorScreen> {
  final ProjectRepository _repo = ProjectRepository();

  late TextEditingController _titleController;
  late TextEditingController _narrationController;
  late TextEditingController _visualPromptController;
  late TextEditingController _negativePromptController;

  late String _selectedCameraAngle;
  late String _selectedLighting;
  late double _duration;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.scene.title ?? '');
    _narrationController = TextEditingController(text: widget.scene.narration ?? '');
    _visualPromptController = TextEditingController(text: widget.scene.visualPrompt);
    _negativePromptController = TextEditingController(text: widget.scene.negativePrompt ?? '');

    _selectedCameraAngle = widget.scene.cameraAngle;
    _selectedLighting = widget.scene.lighting;
    _duration = widget.scene.durationSeconds;
  }

  void _copyMasterPrompt() {
    final fullPrompt = PromptGenerator.buildImageGenerationPrompt(
      sceneDescription: _visualPromptController.text.trim(),
      characterDescription: '',
      visualStyle: 'Cinematic Hyper-Realistic',
      cameraAngle: _selectedCameraAngle,
      lighting: _selectedLighting,
      aspectRatio: '9:16',
    );

    Clipboard.setData(ClipboardData(text: fullPrompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image Generation Prompt copied to clipboard! 📋 Ready for ChatGPT / Midjourney / SD.'),
        backgroundColor: AppColors.accentPurple,
      ),
    );
  }

  Future<void> _saveScene() async {
    final updated = widget.scene.copyWith(
      title: _titleController.text.trim(),
      narration: _narrationController.text.trim(),
      visualPrompt: _visualPromptController.text.trim(),
      negativePrompt: _negativePromptController.text.trim(),
      cameraAngle: _selectedCameraAngle,
      lighting: _selectedLighting,
      durationSeconds: _duration,
    );

    await _repo.saveScene(updated);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scene prompt updated successfully! ✅')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text('Edit Scene ${widget.scene.sceneIndex} Prompt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy Prompt for ChatGPT',
            onPressed: _copyMasterPrompt,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _saveScene,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text('Scene Headline', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Scene Title'),
            ),
            const SizedBox(height: 20),

            // Voiceover Script
            const Text('Spoken Voiceover Script (Narration)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _narrationController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Enter spoken narration for this scene...'),
            ),
            const SizedBox(height: 20),

            // Visual Prompt
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Visual Image Prompt', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                TextButton.icon(
                  onPressed: _copyMasterPrompt,
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Copy Prompt', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _visualPromptController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Describe visual elements, subjects, background, action...'),
            ),
            const SizedBox(height: 20),

            // Camera Angle Picker
            const Text('Camera Angle', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  value: AppConstants.cameraAngles.contains(_selectedCameraAngle) ? _selectedCameraAngle : AppConstants.cameraAngles.first,
                  isExpanded: true,
                  dropdownColor: AppColors.cardNavy,
                  items: AppConstants.cameraAngles.map((angle) {
                    return DropdownMenuItem<String>(value: angle, child: Text(angle, style: const TextStyle(color: Colors.white, fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCameraAngle = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Lighting Picker
            const Text('Lighting Atmosphere', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  value: AppConstants.lightingStyles.contains(_selectedLighting) ? _selectedLighting : AppConstants.lightingStyles.first,
                  isExpanded: true,
                  dropdownColor: AppColors.cardNavy,
                  items: AppConstants.lightingStyles.map((light) {
                    return DropdownMenuItem<String>(value: light, child: Text(light, style: const TextStyle(color: Colors.white, fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLighting = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Duration Slider
            Text('Duration: ${_duration.toStringAsFixed(1)}s', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            Slider(
              value: _duration,
              min: 1.0,
              max: 20.0,
              divisions: 38,
              label: '${_duration.toStringAsFixed(1)}s',
              onChanged: (val) => setState(() => _duration = val),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveScene,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
