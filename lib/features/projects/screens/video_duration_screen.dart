import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/story_engine.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';

class VideoDurationScreen extends StatefulWidget {
  final ProjectModel project;

  const VideoDurationScreen({Key? key, required this.project}) : super(key: key);

  @override
  State<VideoDurationScreen> createState() => _VideoDurationScreenState();
}

class _VideoDurationScreenState extends State<VideoDurationScreen> {
  final ProjectRepository _repo = ProjectRepository();
  late int _selectedDuration;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.project.targetDurationSeconds;
  }

  Future<void> _saveDuration() async {
    setState(() => _isSaving = true);
    final updated = widget.project.copyWith(targetDurationSeconds: _selectedDuration);
    await _repo.saveProject(updated);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, _selectedDuration);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Target duration updated to ${AppConstants.formatDurationLabel(_selectedDuration)}!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = StoryEngine.calculateSceneBreakdown(_selectedDuration);
    final sceneCount = breakdown['sceneCount'] as int;
    final durationPerScene = breakdown['durationPerScene'] as double;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Video Duration Selection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Reel / Video Duration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Supported from 5 seconds short hooks up to 10 minutes extended videos.',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),

            // Duration Presets Grid
            Expanded(
              child: GridView.builder(
                itemCount: AppConstants.durationPresets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemBuilder: (context, index) {
                  final dur = AppConstants.durationPresets[index];
                  final isSelected = _selectedDuration == dur;

                  return InkWell(
                    onTap: () => setState(() => _selectedDuration = dur),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentPurple.withOpacity(0.25) : AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.accentPurple : Colors.white.withOpacity(0.08),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.timer_outlined,
                            color: isSelected ? AppColors.accentPurple : Colors.white38,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppConstants.formatDurationLabel(dur),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              ),
                              Text(
                                dur < 60 ? '$dur Seconds' : '${dur ~/ 60} Minutes',
                                style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Automatic Scene Calculation Display (Section 6)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardNavy,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentPurple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.accentPink, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Automatic Scene Calculation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          '$sceneCount Scenes • ${durationPerScene.toStringAsFixed(1)}s per scene',
                          style: const TextStyle(fontSize: 13, color: AppColors.accentCyan),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveDuration,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.accentPurple,
                ),
                child: const Text('Confirm Duration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
