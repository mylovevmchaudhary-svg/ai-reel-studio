import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';
import 'export_progress_screen.dart';

class ExportSettingsScreen extends StatefulWidget {
  final String projectId;

  const ExportSettingsScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<ExportSettingsScreen> createState() => _ExportSettingsScreenState();
}

class _ExportSettingsScreenState extends State<ExportSettingsScreen> {
  final ProjectRepository _repo = ProjectRepository();
  ProjectModel? _project;
  bool _isLoading = true;

  String _selectedResolution = '1080p';
  int _selectedFps = 30;
  String _selectedAspectRatio = '9:16';
  bool _burnInSubtitles = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    setState(() => _isLoading = true);
    _project = await _repo.getProject(widget.projectId);
    if (_project != null) {
      _selectedAspectRatio = _project!.aspectRatio;
      _selectedResolution = _project!.resolution;
      _selectedFps = _project!.fps;
    }
    setState(() => _isLoading = false);
  }

  void _applyPreset(String name) {
    setState(() {
      if (name == 'shorts') {
        _selectedAspectRatio = '9:16';
        _selectedResolution = '1080p';
        _selectedFps = 30;
      } else if (name == 'reels') {
        _selectedAspectRatio = '9:16';
        _selectedResolution = '1080p';
        _selectedFps = 30;
      } else if (name == 'yt_long') {
        _selectedAspectRatio = '16:9';
        _selectedResolution = '1080p';
        _selectedFps = 60;
      } else if (name == 'square') {
        _selectedAspectRatio = '1:1';
        _selectedResolution = '1080p';
        _selectedFps = 30;
      }
    });
  }

  void _startExport() {
    if (_project == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExportProgressScreen(
          project: _project!,
          resolution: _selectedResolution,
          fps: _selectedFps,
          aspectRatio: _selectedAspectRatio,
          burnInSubtitles: _burnInSubtitles,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Export Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Social Media Presets
                  const Text('Social Media Presets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPresetCard('Instagram Reels', '9:16 • 1080p', Icons.camera_alt_outlined, () => _applyPreset('reels')),
                      const SizedBox(width: 8),
                      _buildPresetCard('YouTube Shorts', '9:16 • 1080p', Icons.play_arrow_outlined, () => _applyPreset('shorts')),
                      const SizedBox(width: 8),
                      _buildPresetCard('YouTube Long', '16:9 • 60fps', Icons.desktop_windows_outlined, () => _applyPreset('yt_long')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Resolution
                  const Text('Video Resolution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['720p', '1080p'].map((res) {
                      final isSelected = _selectedResolution == res;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(res == '1080p' ? '1080p (Full HD)' : '720p (Standard HD)'),
                            selected: isSelected,
                            selectedColor: AppColors.accentPurple,
                            onSelected: (_) => setState(() => _selectedResolution = res),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Frame Rate (FPS)
                  const Text('Frame Rate (FPS)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    children: [24, 30, 60].map((fps) {
                      final isSelected = _selectedFps == fps;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${fps} FPS'),
                            selected: isSelected,
                            selectedColor: AppColors.accentPurple,
                            onSelected: (_) => setState(() => _selectedFps = fps),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Aspect Ratio
                  const Text('Aspect Ratio (Orientation)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['9:16', '16:9', '1:1'].map((ratio) {
                      final isSelected = _selectedAspectRatio == ratio;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(ratio),
                            selected: isSelected,
                            selectedColor: AppColors.accentPurple,
                            onSelected: (_) => setState(() => _selectedAspectRatio = ratio),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Burn-in Subtitles Switch
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Burn-In Subtitles (SRT)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text('Renders hardcoded subtitles onto the exported MP4 video', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                      value: _burnInSubtitles,
                      activeColor: AppColors.accentPurple,
                      onChanged: (val) => setState(() => _burnInSubtitles = val),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Start Export Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startExport,
                      icon: const Icon(Icons.rocket_launch),
                      label: const Text('Start MP4 Export', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.accentPink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPresetCard(String title, String desc, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.cardNavy,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.accentPurple, size: 22),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.5))),
            ],
          ),
        ),
      ),
    );
  }
}
