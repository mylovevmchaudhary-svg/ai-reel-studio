import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/audio_service.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/scene_model.dart';
import '../../../data/models/scene_asset_model.dart';
import '../../../data/models/voiceover_model.dart';
import '../../../data/models/caption_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../../export/screens/export_settings_screen.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String projectId;

  const VideoPreviewScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  final ProjectRepository _repo = ProjectRepository();
  final AudioService _audio = AudioService.instance;

  bool _isLoading = true;
  ProjectModel? _project;
  StoryModel? _story;
  List<SceneModel> _scenes = [];
  List<SceneAssetModel> _assets = [];
  List<VoiceoverModel> _voiceovers = [];
  List<CaptionModel> _captions = [];

  double _currentPositionSeconds = 0.0;
  bool _isPlaying = false;
  Timer? _timer;
  int _activeSceneIndex = 0;

  double get _totalDuration {
    if (_scenes.isEmpty) return 15.0;
    return _scenes.fold<double>(0.0, (sum, s) => sum + s.durationSeconds);
  }

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audio.stopAudio();
    _audio.stopTts();
    super.dispose();
  }

  Future<void> _loadProject() async {
    setState(() => _isLoading = true);
    _project = await _repo.getProject(widget.projectId);
    _story = await _repo.getStory(widget.projectId);
    _scenes = await _repo.getScenes(widget.projectId);
    _assets = await _repo.getAssetsForProject(widget.projectId);
    _voiceovers = await _repo.getVoiceoversForProject(widget.projectId);
    _captions = await _repo.getCaptions(widget.projectId);
    setState(() => _isLoading = false);
  }

  void _togglePlay() {
    if (_isPlaying) {
      _timer?.cancel();
      _audio.stopAudio();
      _audio.stopTts();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      if (_scenes.isNotEmpty) {
        final firstScene = _scenes[_activeSceneIndex];
        final vo = _voiceovers.where((v) => v.sceneId == firstScene.id).firstOrNull;
        if (vo?.localPath != null && File(vo!.localPath!).existsSync()) {
          _audio.playAudio(vo.localPath!);
        } else if (firstScene.narration != null && firstScene.narration!.isNotEmpty) {
          _audio.speakText(firstScene.narration!, language: _story?.promptLanguage ?? 'hi');
        }
      }
      _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        setState(() {
          _currentPositionSeconds += 0.1;
          if (_currentPositionSeconds >= _totalDuration) {
            _currentPositionSeconds = 0.0;
            _isPlaying = false;
            _timer?.cancel();
            _audio.stopAudio();
            _audio.stopTts();
          } else {
            _syncScene();
          }
        });
      });
    }
  }

  void _syncScene() {
    double acc = 0.0;
    for (int i = 0; i < _scenes.length; i++) {
      acc += _scenes[i].durationSeconds;
      if (_currentPositionSeconds <= acc) {
        if (_activeSceneIndex != i) {
          _activeSceneIndex = i;
          final currentScene = _scenes[i];
          final vo = _voiceovers.where((v) => v.sceneId == currentScene.id).firstOrNull;
          if (vo?.localPath != null && File(vo!.localPath!).existsSync()) {
            _audio.playAudio(vo.localPath!);
          } else if (currentScene.narration != null && currentScene.narration!.isNotEmpty) {
            _audio.speakText(currentScene.narration!, language: _story?.promptLanguage ?? 'hi');
          }
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.accentPurple)),
      );
    }

    final activeScene = _scenes.isNotEmpty ? _scenes[_activeSceneIndex] : null;
    final activeAsset = activeScene != null
        ? _assets.where((a) => a.sceneId == activeScene.id && a.isActive).firstOrNull
        : null;

    final activeCaption = _captions.where((c) {
      final start = c.startTimeMs / 1000.0;
      final end = c.endTimeMs / 1000.0;
      return _currentPositionSeconds >= start && _currentPositionSeconds <= end;
    }).firstOrNull;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_project?.title ?? 'Reel Preview'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ExportSettingsScreen(projectId: widget.projectId)),
              );
            },
            icon: const Icon(Icons.download, color: AppColors.accentPink, size: 18),
            label: const Text('Export', style: TextStyle(color: AppColors.accentPink, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Canvas
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _project?.aspectRatio == '16:9' ? 16 / 9 : (_project?.aspectRatio == '1:1' ? 1.0 : 9 / 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: (activeAsset?.localPath != null && File(activeAsset!.localPath!).existsSync())
                            ? Image.file(
                                File(activeAsset!.localPath!),
                                key: ValueKey<String>(activeAsset.localPath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Container(
                                key: ValueKey<int>(_activeSceneIndex),
                                color: const Color(0xFF131B2E),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.movie, size: 54, color: AppColors.accentPurple),
                                      const SizedBox(height: 12),
                                      Text(activeScene?.title ?? 'Scene ${_activeSceneIndex + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                      ),

                      // Caption
                      if (activeCaption != null)
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 40,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              activeCaption.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.primaryDark,
            child: Row(
              children: [
                IconButton(
                  onPressed: _togglePlay,
                  icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 44, color: AppColors.accentPurple),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_currentPositionSeconds.toStringAsFixed(1)}s / ${_totalDuration.toStringAsFixed(1)}s',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      LinearProgressIndicator(
                        value: _totalDuration > 0 ? (_currentPositionSeconds / _totalDuration).clamp(0.0, 1.0) : 0.0,
                        color: AppColors.accentPink,
                        backgroundColor: Colors.white12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
