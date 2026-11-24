import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/media_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/scene_model.dart';
import '../../../data/models/voiceover_model.dart';
import '../../../data/repositories/project_repository.dart';

class VoiceoverStudioScreen extends StatefulWidget {
  final String projectId;
  final String? initialSceneId;

  const VoiceoverStudioScreen({Key? key, required this.projectId, this.initialSceneId}) : super(key: key);

  @override
  State<VoiceoverStudioScreen> createState() => _VoiceoverStudioScreenState();
}

class _VoiceoverStudioScreenState extends State<VoiceoverStudioScreen> {
  final ProjectRepository _repo = ProjectRepository();
  final AudioService _audio = AudioService.instance;
  final MediaService _media = MediaService.instance;
  final _uuid = const Uuid();

  List<SceneModel> _scenes = [];
  List<VoiceoverModel> _voiceovers = [];
  String? _selectedSceneId;
  bool _isLoading = true;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _selectedSceneId = widget.initialSceneId;
    _loadData();
  }

  @override
  void dispose() {
    _audio.stopAudio();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _scenes = await _repo.getScenes(widget.projectId);
    _voiceovers = await _repo.getVoiceoversForProject(widget.projectId);
    if (_selectedSceneId == null && _scenes.isNotEmpty) {
      _selectedSceneId = _scenes.first.id;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleRecording() async {
    if (_selectedSceneId == null) return;

    if (_isRecording) {
      final path = await _audio.stopRecording();
      setState(() => _isRecording = false);
      if (path != null) {
        final vo = VoiceoverModel(
          id: _uuid.v4(),
          sceneId: _selectedSceneId!,
          projectId: widget.projectId,
          ownerId: SupabaseService.instance.currentUserId,
          localPath: path,
          sourceType: 'recorded',
          durationSeconds: 5.0,
        );
        await _repo.saveVoiceover(vo);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voiceover recorded and saved! 🎙️')),
        );
      }
    } else {
      final path = await _audio.startRecording(sceneId: _selectedSceneId!);
      if (path != null) {
        setState(() => _isRecording = true);
      }
    }
  }

  Future<void> _pickAudioFile() async {
    if (_selectedSceneId == null) return;

    final file = await _media.pickAudioFile(projectId: widget.projectId);
    if (file != null) {
      final vo = VoiceoverModel(
        id: _uuid.v4(),
        sceneId: _selectedSceneId!,
        projectId: widget.projectId,
        ownerId: SupabaseService.instance.currentUserId,
        localPath: file.path,
        sourceType: 'uploaded',
        durationSeconds: 5.0,
      );
      await _repo.saveVoiceover(vo);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio file attached to scene! 🎵')),
      );
    }
  }

  Future<void> _generateTts(SceneModel scene) async {
    final text = scene.narration ?? scene.title ?? 'Scene narration';
    await _audio.speakText(text, language: 'en');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Playing offline TTS narration preview... 🗣️')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeScene = _scenes.where((s) => s.id == _selectedSceneId).firstOrNull;
    final activeVo = _voiceovers.where((v) => v.sceneId == _selectedSceneId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Voiceover Studio'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select Scene Dropdown
                  const Text('Select Target Scene', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                        value: _selectedSceneId,
                        isExpanded: true,
                        dropdownColor: AppColors.cardNavy,
                        items: _scenes.map((s) {
                          return DropdownMenuItem<String>(
                            value: s.id,
                            child: Text('Scene ${s.sceneIndex}: ${s.title ?? "Untitled"}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSceneId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Teleprompter / Narration Script Box
                  const Text('Teleprompter / Script', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
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
                        Text(
                          activeScene?.narration ?? 'No narration script written yet for this scene.',
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: activeScene != null ? () => _generateTts(activeScene) : null,
                              icon: const Icon(Icons.volume_up, size: 16),
                              label: const Text('Free TTS Preview'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentCyan,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Big Record Button
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _toggleRecording,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _isRecording
                                  ? const LinearGradient(colors: [Colors.redAccent, Colors.red])
                                  : AppColors.purplePinkGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRecording ? Colors.red : AppColors.accentPurple).withOpacity(0.4),
                                  blurRadius: 25,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isRecording ? 'Recording... Tap to Stop' : 'Tap Mic to Record Voiceover',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isRecording ? Colors.redAccent : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Upload Audio Option
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _pickAudioFile,
                      icon: const Icon(Icons.audio_file),
                      label: const Text('Upload Pre-recorded Audio File (.mp3, .wav)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Voiceover Track Info
                  if (activeVo != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.success.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Attached Voiceover (${activeVo.sourceType})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                Text('Volume: ${(activeVo.volume * 100).toInt()}%', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_circle_fill, color: AppColors.accentCyan, size: 30),
                            onPressed: () {
                              if (activeVo.localPath != null && File(activeVo.localPath!).existsSync()) {
                                _audio.playAudio(activeVo.localPath!, volume: activeVo.volume);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
