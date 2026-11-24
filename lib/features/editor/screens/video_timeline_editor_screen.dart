import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/audio_service.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/scene_model.dart';
import '../../../data/models/scene_asset_model.dart';
import '../../../data/models/voiceover_model.dart';
import '../../../data/models/caption_model.dart';
import '../../../data/models/audio_track_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../widgets/multi_track_timeline.dart';
import '../../export/screens/export_settings_screen.dart';

class VideoTimelineEditorScreen extends StatefulWidget {
  final String projectId;

  const VideoTimelineEditorScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<VideoTimelineEditorScreen> createState() => _VideoTimelineEditorScreenState();
}

class _VideoTimelineEditorScreenState extends State<VideoTimelineEditorScreen> {
  final ProjectRepository _repo = ProjectRepository();
  final AudioService _audio = AudioService.instance;

  bool _isLoading = true;
  ProjectModel? _project;
  List<SceneModel> _scenes = [];
  List<SceneAssetModel> _assets = [];
  List<VoiceoverModel> _voiceovers = [];
  List<CaptionModel> _captions = [];
  List<AudioTrackModel> _audioTracks = [];

  int _selectedSceneIndex = 0;
  double _currentPositionSeconds = 0.0;
  bool _isPlaying = false;
  Timer? _playbackTimer;

  // Audio Mixer State
  double _voiceoverVolume = 1.0;
  double _bgmVolume = 0.35;

  double get _totalDurationSeconds {
    if (_scenes.isEmpty) return 15.0;
    return _scenes.fold<double>(0.0, (sum, s) => sum + s.durationSeconds);
  }

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _audio.stopAudio();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    setState(() => _isLoading = true);
    _project = await _repo.getProject(widget.projectId);
    _scenes = await _repo.getScenes(widget.projectId);
    _assets = await _repo.getAssetsForProject(widget.projectId);
    _voiceovers = await _repo.getVoiceoversForProject(widget.projectId);
    _captions = await _repo.getCaptions(widget.projectId);
    _audioTracks = await _repo.getAudioTracks(widget.projectId);

    if (_scenes.isNotEmpty) {
      _selectedSceneIndex = 0;
    }
    setState(() => _isLoading = false);
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    setState(() => _isPlaying = true);
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _currentPositionSeconds += 0.1;
        if (_currentPositionSeconds >= _totalDurationSeconds) {
          _currentPositionSeconds = 0.0;
          _pausePlayback();
        } else {
          _updateActiveSceneFromPosition();
        }
      });
    });
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    _audio.stopAudio();
    setState(() => _isPlaying = false);
  }

  void _seekTo(double seconds) {
    setState(() {
      _currentPositionSeconds = seconds.clamp(0.0, _totalDurationSeconds);
      _updateActiveSceneFromPosition();
    });
  }

  void _updateActiveSceneFromPosition() {
    double accumulated = 0.0;
    for (int i = 0; i < _scenes.length; i++) {
      accumulated += _scenes[i].durationSeconds;
      if (_currentPositionSeconds <= accumulated) {
        if (_selectedSceneIndex != i) {
          _selectedSceneIndex = i;
          // Play voiceover if available
          final vo = _voiceovers.where((v) => v.sceneId == _scenes[i].id).firstOrNull;
          if (vo != null && vo.localPath != null && File(vo.localPath!).existsSync()) {
            _audio.playAudio(vo.localPath!, volume: _voiceoverVolume);
          }
        }
        break;
      }
    }
  }

  // --- CLIP EDITING ACTIONS ---
  Future<void> _updateSceneDuration(double newDuration) async {
    if (_scenes.isEmpty) return;
    final scene = _scenes[_selectedSceneIndex];
    final updated = scene.copyWith(durationSeconds: newDuration);
    await _repo.saveScene(updated);
    setState(() {
      _scenes[_selectedSceneIndex] = updated;
    });
  }

  Future<void> _updateTransition(String transition) async {
    if (_scenes.isEmpty) return;
    final scene = _scenes[_selectedSceneIndex];
    final updated = scene.copyWith(transitionType: transition);
    await _repo.saveScene(updated);
    setState(() {
      _scenes[_selectedSceneIndex] = updated;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transition updated to $transition for Scene ${scene.sceneIndex}')),
    );
  }

  Future<void> _moveScene(int direction) async {
    // direction: -1 (left), 1 (right)
    final targetIndex = _selectedSceneIndex + direction;
    if (targetIndex < 0 || targetIndex >= _scenes.length) return;

    final currentScene = _scenes[_selectedSceneIndex];
    final targetScene = _scenes[targetIndex];

    final updatedCurrent = currentScene.copyWith(sceneIndex: targetScene.sceneIndex);
    final updatedTarget = targetScene.copyWith(sceneIndex: currentScene.sceneIndex);

    await _repo.saveScene(updatedCurrent);
    await _repo.saveScene(updatedTarget);

    setState(() {
      _scenes[_selectedSceneIndex] = updatedTarget;
      _scenes[targetIndex] = updatedCurrent;
      _selectedSceneIndex = targetIndex;
    });
  }

  Future<void> _splitScene() async {
    if (_scenes.isEmpty) return;
    final scene = _scenes[_selectedSceneIndex];
    if (scene.durationSeconds < 2.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scene duration too short to split (min 2.0s)')),
      );
      return;
    }

    final double halfDuration = (scene.durationSeconds / 2.0);
    final updatedFirst = scene.copyWith(durationSeconds: halfDuration);

    final newScene = SceneModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      projectId: scene.projectId,
      ownerId: scene.ownerId,
      sceneIndex: scene.sceneIndex + 1,
      title: '${scene.title ?? "Scene"} (Part 2)',
      narration: scene.narration,
      visualPrompt: scene.visualPrompt,
      durationSeconds: halfDuration,
      cameraAngle: scene.cameraAngle,
      lighting: scene.lighting,
      transitionType: 'crossfade',
    );

    await _repo.saveScene(updatedFirst);
    await _repo.saveScene(newScene);

    await _loadProjectData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scene split into two equal clips! ✂️')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.accentPurple)),
      );
    }

    final activeScene = _scenes.isNotEmpty ? _scenes[_selectedSceneIndex] : null;
    final activeAsset = activeScene != null
        ? _assets.where((a) => a.sceneId == activeScene.id && a.isActive).firstOrNull
        : null;

    final activeCaption = _captions.where((c) {
      final start = c.startTimeMs / 1000.0;
      final end = c.endTimeMs / 1000.0;
      return _currentPositionSeconds >= start && _currentPositionSeconds <= end;
    }).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(_project?.title ?? 'Timeline Editor'),
        actions: [
          // Audio Mixer Dialog Button
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Audio Mixer',
            onPressed: _showAudioMixerDialog,
          ),
          // Export Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExportSettingsScreen(projectId: widget.projectId),
                  ),
                );
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export MP4'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPink,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Live Video Preview Box (with aspect ratio constraints)
          Expanded(
            flex: 5,
            child: _buildVideoPreviewCanvas(activeScene, activeAsset, activeCaption),
          ),

          // 2. Playback Control Bar
          _buildPlaybackControls(),

          // 3. Quick Clip Tools (Trim, Split, Reorder, Transitions)
          _buildClipActionToolbar(activeScene),

          // 4. Multi-Track Timeline
          Expanded(
            flex: 6,
            child: MultiTrackTimeline(
              scenes: _scenes,
              assets: _assets,
              voiceovers: _voiceovers,
              captions: _captions,
              audioTracks: _audioTracks,
              currentPositionSeconds: _currentPositionSeconds,
              totalDurationSeconds: _totalDurationSeconds,
              selectedSceneIndex: _selectedSceneIndex,
              onSeek: _seekTo,
              onSelectScene: (idx) {
                setState(() {
                  _selectedSceneIndex = idx;
                  // Seek to scene start
                  double pos = 0.0;
                  for (int i = 0; i < idx; i++) {
                    pos += _scenes[i].durationSeconds;
                  }
                  _seekTo(pos);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreviewCanvas(
    SceneModel? scene,
    SceneAssetModel? asset,
    CaptionModel? caption,
  ) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: _project?.aspectRatio == '16:9'
              ? 16 / 9
              : (_project?.aspectRatio == '1:1' ? 1.0 : 9 / 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF131B2E),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Visual Image
                if (asset?.localPath != null && File(asset!.localPath!).existsSync())
                  Image.file(File(asset.localPath!), fit: BoxFit.cover)
                else if (asset?.assetUrl.isNotEmpty == true && asset!.assetUrl.startsWith('http'))
                  Image.network(asset.assetUrl, fit: BoxFit.cover)
                else
                  _buildNoAssetPlaceholder(scene),

                // Subtitle Overlay
                if (caption != null)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: caption.position == 'bottom' ? 30 : (caption.position == 'top' ? null : 150),
                    top: caption.position == 'top' ? 40 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        caption.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: caption.fontSize.toDouble().clamp(14.0, 28.0),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                // Scene Index Overlay Watermark
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Scene ${scene?.sceneIndex ?? 1} / ${_scenes.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoAssetPlaceholder(SceneModel? scene) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF161F33),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.palette_outlined, size: 40, color: AppColors.accentPurple.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text(
            scene?.title ?? 'Scene Visual',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            scene?.visualPrompt ?? 'Upload image or copy prompt for ChatGPT/Midjourney',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Jump to Start
          IconButton(
            icon: const Icon(Icons.skip_previous, size: 22),
            onPressed: () => _seekTo(0.0),
          ),
          // Rewind 2s
          IconButton(
            icon: const Icon(Icons.replay_5, size: 22),
            onPressed: () => _seekTo(_currentPositionSeconds - 2.0),
          ),
          const SizedBox(width: 8),
          // Play / Pause Circle Button
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: AppColors.purplePinkGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Fast Forward 2s
          IconButton(
            icon: const Icon(Icons.forward_5, size: 22),
            onPressed: () => _seekTo(_currentPositionSeconds + 2.0),
          ),
          // Jump to End
          IconButton(
            icon: const Icon(Icons.skip_next, size: 22),
            onPressed: () => _seekTo(_totalDurationSeconds),
          ),
        ],
      ),
    );
  }

  Widget _buildClipActionToolbar(SceneModel? scene) {
    if (scene == null) return const SizedBox.shrink();

    return Container(
      color: AppColors.primaryNavy,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text(
            'Scene ${scene.sceneIndex}:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          // Duration Chip / Trim Slider Trigger
          InkWell(
            onTap: () => _showTrimDurationDialog(scene),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.accentPurple),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: AppColors.accentPurple),
                  const SizedBox(width: 4),
                  Text(
                    '${scene.durationSeconds.toStringAsFixed(1)}s (Trim)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Split Clip Button
          OutlinedButton.icon(
            onPressed: _splitScene,
            icon: const Icon(Icons.content_cut, size: 14),
            label: const Text('Split', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
          ),
          const SizedBox(width: 6),
          // Transition Picker
          OutlinedButton.icon(
            onPressed: () => _showTransitionDialog(scene),
            icon: const Icon(Icons.animation, size: 14),
            label: Text(scene.transitionType, style: const TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
          ),
          const Spacer(),
          // Reorder Buttons
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 14),
            tooltip: 'Move Left',
            onPressed: _selectedSceneIndex > 0 ? () => _moveScene(-1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 14),
            tooltip: 'Move Right',
            onPressed: _selectedSceneIndex < _scenes.length - 1 ? () => _moveScene(1) : null,
          ),
        ],
      ),
    );
  }

  void _showTrimDurationDialog(SceneModel scene) {
    double tempDuration = scene.durationSeconds;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.cardNavy,
            title: Text('Trim Scene ${scene.sceneIndex} Duration'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${tempDuration.toStringAsFixed(1)} seconds',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.accentPurple),
                ),
                Slider(
                  value: tempDuration,
                  min: 1.0,
                  max: 30.0,
                  divisions: 58,
                  label: '${tempDuration.toStringAsFixed(1)}s',
                  onChanged: (val) {
                    setDialogState(() => tempDuration = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _updateSceneDuration(tempDuration);
                },
                child: const Text('Save Duration'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTransitionDialog(SceneModel scene) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardNavy,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Clip Transition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.transitions.map((t) {
                  final isSelected = scene.transitionType.toLowerCase() == t.toLowerCase();
                  return ChoiceChip(
                    label: Text(t),
                    selected: isSelected,
                    selectedColor: AppColors.accentPurple,
                    onSelected: (_) {
                      Navigator.pop(ctx);
                      _updateTransition(t.toLowerCase().replaceAll(' ', '_'));
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAudioMixerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.cardNavy,
            title: const Row(
              children: [
                Icon(Icons.tune, color: AppColors.accentPurple),
                SizedBox(width: 8),
                Text('Audio Mixer Tracks'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Voiceover Volume
                Text('Voiceover Volume: ${(_voiceoverVolume * 100).toInt()}%'),
                Slider(
                  value: _voiceoverVolume,
                  min: 0.0,
                  max: 2.0,
                  activeColor: AppColors.accentCyan,
                  onChanged: (val) {
                    setDialogState(() => _voiceoverVolume = val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 10),
                // BGM Volume
                Text('Background Music: ${(_bgmVolume * 100).toInt()}%'),
                Slider(
                  value: _bgmVolume,
                  min: 0.0,
                  max: 1.0,
                  activeColor: AppColors.success,
                  onChanged: (val) {
                    setDialogState(() => _bgmVolume = val);
                    setState(() {});
                  },
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Apply Levels'),
              ),
            ],
          );
        },
      ),
    );
  }
}
