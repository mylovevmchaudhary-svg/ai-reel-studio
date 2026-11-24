import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/media_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/audio_track_model.dart';
import '../../../data/repositories/project_repository.dart';

class MusicLibraryScreen extends StatefulWidget {
  final String projectId;

  const MusicLibraryScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen> {
  final ProjectRepository _repo = ProjectRepository();
  final AudioService _audio = AudioService.instance;
  final MediaService _media = MediaService.instance;
  final _uuid = const Uuid();

  List<AudioTrackModel> _tracks = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _presetTracks = [
    {'title': 'Cinematic Epic War Drums', 'genre': 'Action / Historic', 'duration': '35s'},
    {'title': 'Emotional Piano & Strings', 'genre': 'Motivational / Drama', 'duration': '40s'},
    {'title': 'Cyberpunk Dark Synthwave', 'genre': 'Sci-Fi / Modern', 'duration': '30s'},
    {'title': 'Indian Classical Flute Melody', 'genre': 'Cultural / Peaceful', 'duration': '45s'},
    {'title': 'Upbeat Viral Lo-Fi Beat', 'genre': 'Lifestyle / Vlog', 'duration': '25s'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    _tracks = await _repo.getAudioTracks(widget.projectId);
    setState(() => _isLoading = false);
  }

  Future<void> _attachPresetTrack(Map<String, dynamic> preset) async {
    final track = AudioTrackModel(
      id: _uuid.v4(),
      projectId: widget.projectId,
      ownerId: SupabaseService.instance.currentUserId,
      title: preset['title'] as String,
      trackType: 'bgm',
      volume: 0.35,
      loop: true,
    );
    await _repo.saveAudioTrack(track);
    _loadTracks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attached "${preset['title']}" to Background Music Track! 🎵')),
      );
    }
  }

  Future<void> _uploadCustomTrack() async {
    final file = await _media.pickAudioFile(projectId: widget.projectId);
    if (file != null) {
      final track = AudioTrackModel(
        id: _uuid.v4(),
        projectId: widget.projectId,
        ownerId: SupabaseService.instance.currentUserId,
        title: file.path.split(RegExp(r'[\\/]')).last,
        localPath: file.path,
        trackType: 'bgm',
        volume: 0.35,
        loop: true,
      );
      await _repo.saveAudioTrack(track);
      _loadTracks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom audio track attached to background music! 🎧')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTrack = _tracks.firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Background Music Library'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Track Box
                  if (activeTrack != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroCardGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.success.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                              const SizedBox(width: 8),
                              const Text('ACTIVE BACKGROUND MUSIC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                              const Spacer(),
                              Text('Vol: ${(activeTrack.volume * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            activeTrack.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Upload Custom Audio Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _uploadCustomTrack,
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('Upload Custom BGM Audio (.mp3, .wav)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.accentPurple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Royalty-Free Presets
                  const Text('Royalty-Free Cinematic Presets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _presetTracks.length,
                    itemBuilder: (context, index) {
                      final p = _presetTracks[index];
                      final isSelected = activeTrack?.title == p['title'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentPurple.withOpacity(0.15) : AppColors.cardNavy,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.accentPurple : Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(child: Icon(Icons.music_note, color: AppColors.accentCyan, size: 20)),
                          ),
                          title: Text(p['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          subtitle: Text('${p['genre']} • ${p['duration']}', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
                          trailing: ElevatedButton(
                            onPressed: () => _attachPresetTrack(p),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? AppColors.success : AppColors.accentPurple,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: Text(isSelected ? 'Active' : 'Use Track', style: const TextStyle(fontSize: 11)),
                          ),
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
