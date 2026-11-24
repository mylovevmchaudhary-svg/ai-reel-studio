import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/video_export_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../../sharing/screens/social_media_share_screen.dart';

class ProjectHistoryScreen extends StatefulWidget {
  const ProjectHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ProjectHistoryScreen> createState() => _ProjectHistoryScreenState();
}

class _ProjectHistoryScreenState extends State<ProjectHistoryScreen> {
  final ProjectRepository _repo = ProjectRepository();
  List<VideoExportModel> _exports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExports();
  }

  Future<void> _loadExports() async {
    setState(() => _isLoading = true);
    _exports = await _repo.getVideoExports();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Export History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : _exports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.white38),
                      const SizedBox(height: 12),
                      const Text('No video exports yet', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text('Your rendered MP4 videos will appear here', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _exports.length,
                  itemBuilder: (context, index) {
                    final exp = _exports[index];
                    final dateStr = DateFormatter.formatShortDate(exp.createdAt);
                    final sizeMb = exp.fileSizeBytes != null ? (exp.fileSizeBytes! / (1024 * 1024)).toStringAsFixed(1) : '2.1';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.purplePinkGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                        title: Text(
                          'Export (${exp.resolution} @ ${exp.fps}fps)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$dateStr • $sizeMb MB • ${exp.aspectRatio}',
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.55)),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.share, color: AppColors.accentPurple, size: 20),
                          tooltip: 'Share Video',
                          onPressed: () {
                            if (exp.localPath != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SocialMediaShareScreen(
                                    projectTitle: 'Rendered Reel',
                                    videoPath: exp.localPath!,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
