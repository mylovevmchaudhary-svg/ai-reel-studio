import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../../stories/screens/story_prompt_screen.dart';

class CreateNewProjectScreen extends StatefulWidget {
  const CreateNewProjectScreen({Key? key}) : super(key: key);

  @override
  State<CreateNewProjectScreen> createState() => _CreateNewProjectScreenState();
}

class _CreateNewProjectScreenState extends State<CreateNewProjectScreen> {
  final _titleController = TextEditingController();
  final _repo = ProjectRepository();
  final _uuid = const Uuid();

  String _selectedAspectRatio = AppConstants.ratio9x16;
  int _selectedDuration = 15; // default 15s reel
  String _selectedLanguage = 'en';
  String _selectedStyle = AppConstants.visualStyles.first;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Reel Project ${DateTime.now().day}/${DateTime.now().month}';
  }

  Future<void> _proceedToPrompt() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project title')),
      );
      return;
    }

    setState(() => _isCreating = true);

    final projectId = _uuid.v4();
    final project = ProjectModel(
      id: projectId,
      ownerId: SupabaseService.instance.currentUserId,
      title: title,
      aspectRatio: _selectedAspectRatio,
      targetDurationSeconds: _selectedDuration,
      status: 'draft',
    );

    await _repo.saveProject(project);

    if (mounted) {
      setState(() => _isCreating = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StoryPromptScreen(
            projectId: projectId,
            projectTitle: title,
            language: _selectedLanguage,
            durationSeconds: _selectedDuration,
            aspectRatio: _selectedAspectRatio,
            visualStyle: _selectedStyle,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Create New Project'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text('Project Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter title (e.g. Ancient Mysteries of India)',
                prefixIcon: Icon(Icons.edit_outlined, color: AppColors.accentPurple),
              ),
            ),
            const SizedBox(height: 24),

            // Aspect Ratio Picker
            const Text('Select Video Format (Aspect Ratio)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildAspectRatioCard('9:16', 'Reel / Shorts', Icons.phone_android, AppConstants.ratio9x16),
                const SizedBox(width: 10),
                _buildAspectRatioCard('16:9', 'YouTube Wide', Icons.tv, AppConstants.ratio16x9),
                const SizedBox(width: 10),
                _buildAspectRatioCard('1:1', 'Square Post', Icons.crop_square, AppConstants.ratio1x1),
              ],
            ),
            const SizedBox(height: 24),

            // Video Duration Selection (Section 6)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Target Video Duration', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  '${_selectedDuration < 60 ? "$_selectedDuration sec" : "${_selectedDuration ~/ 60} min"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentPurple),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.durationPresets.map((dur) {
                final isSelected = _selectedDuration == dur;
                return ChoiceChip(
                  label: Text(AppConstants.formatDurationLabel(dur)),
                  selected: isSelected,
                  selectedColor: AppColors.accentPurple,
                  backgroundColor: AppColors.cardNavy,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedDuration = dur);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Language Selection
            const Text('Story & Script Language', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Row(
              children: AppConstants.supportedLanguages.entries.map((e) {
                final isSelected = _selectedLanguage == e.key;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedLanguage = e.key),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentPurple.withOpacity(0.2) : AppColors.cardNavy,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.accentPurple : Colors.white.withOpacity(0.06),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          e.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Visual Style Selection
            const Text('Visual Style for Prompts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.cardNavy,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStyle,
                  isExpanded: true,
                  dropdownColor: AppColors.cardNavy,
                  items: AppConstants.visualStyles.map((style) {
                    return DropdownMenuItem<String>(
                      value: style,
                      child: Text(style, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStyle = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Next Step Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _proceedToPrompt,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue to Story Prompt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

  Widget _buildAspectRatioCard(String ratio, String label, IconData icon, String target) {
    final isSelected = _selectedAspectRatio == target;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedAspectRatio = target),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentPurple.withOpacity(0.2) : AppColors.cardNavy,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.accentPurple : Colors.white.withOpacity(0.06),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.accentPurple : Colors.white54, size: 26),
              const SizedBox(height: 8),
              Text(ratio, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
            ],
          ),
        ),
      ),
    );
  }
}
