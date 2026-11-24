import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/ffmpeg_render_engine.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/scene_model.dart';
import '../../../data/models/scene_asset_model.dart';
import '../../../data/models/voiceover_model.dart';
import '../../../data/models/caption_model.dart';
import '../../../data/models/audio_track_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../../sharing/screens/social_media_share_screen.dart';

class ExportProgressScreen extends StatefulWidget {
  final ProjectModel project;
  final String resolution;
  final int fps;
  final String aspectRatio;
  final bool burnInSubtitles;

  const ExportProgressScreen({
    Key? key,
    required this.project,
    required this.resolution,
    required this.fps,
    required this.aspectRatio,
    required this.burnInSubtitles,
  }) : super(key: key);

  @override
  State<ExportProgressScreen> createState() => _ExportProgressScreenState();
}

class _ExportProgressScreenState extends State<ExportProgressScreen> {
  final ProjectRepository _repo = ProjectRepository();
  final FFmpegRenderEngine _renderEngine = FFmpegRenderEngine.instance;

  double _progress = 0.0;
  String _statusMessage = 'Initializing video rendering engine...';
  bool _isCompleted = false;
  bool _isFailed = false;
  String? _outputVideoPath;
  StreamSubscription<RenderProgress>? _renderSub;

  @override
  void initState() {
    super.initState();
    _startRenderPipeline();
  }

  @override
  void dispose() {
    _renderSub?.cancel();
    super.dispose();
  }

  Future<void> _startRenderPipeline() async {
    final scenes = await _repo.getScenes(widget.project.id);
    final assets = await _repo.getAssetsForProject(widget.project.id);
    final voiceovers = await _repo.getVoiceoversForProject(widget.project.id);
    final captions = widget.burnInSubtitles ? await _repo.getCaptions(widget.project.id) : <CaptionModel>[];
    final audioTracks = await _repo.getAudioTracks(widget.project.id);

    final stream = _renderEngine.renderVideo(
      project: widget.project,
      scenes: scenes,
      assets: assets,
      voiceovers: voiceovers,
      captions: captions,
      audioTracks: audioTracks,
      resolution: widget.resolution,
      fps: widget.fps,
      aspectRatio: widget.aspectRatio,
    );

    _renderSub = stream.listen(
      (progress) {
        setState(() {
          _progress = progress.percentage;
          _statusMessage = progress.statusMessage;
          _isCompleted = progress.isCompleted;
          _isFailed = progress.isFailed;
          _outputVideoPath = progress.outputVideoPath;
        });
      },
      onError: (err) {
        setState(() {
          _isFailed = true;
          _statusMessage = 'Export Error: $err';
        });
      },
    );
  }

  void _cancel() {
    _renderEngine.cancelRendering();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Status
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: _isCompleted ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]) : AppColors.purplePinkGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isCompleted ? AppColors.success : AppColors.accentPurple).withOpacity(0.4),
                      blurRadius: 28,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isCompleted ? Icons.check : (_isFailed ? Icons.error_outline : Icons.movie_filter_rounded),
                    size: 44,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Title
              Text(
                _isCompleted ? 'Video Export Complete!' : (_isFailed ? 'Export Encountered Issue' : 'Rendering MP4 Video...'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),

              // Status Message
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 36),

              // Percentage Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 12,
                  color: _isCompleted ? AppColors.success : AppColors.accentPink,
                  backgroundColor: Colors.white.withOpacity(0.08),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${(_progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 48),

              // Action Buttons
              if (_isCompleted && _outputVideoPath != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SocialMediaShareScreen(
                            projectTitle: widget.project.title,
                            videoPath: _outputVideoPath!,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share Video / Open Reel', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to Studio'),
                ),
              ] else if (_isFailed) ...[
                ElevatedButton(
                  onPressed: _startRenderPipeline,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  child: const Text('Retry Video Export'),
                ),
              ] else ...[
                TextButton(
                  onPressed: _cancel,
                  child: const Text('Cancel Export', style: TextStyle(color: Colors.white60)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
