import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/scene_model.dart';
import '../../../data/models/scene_asset_model.dart';
import '../../../data/models/voiceover_model.dart';
import '../../../data/models/caption_model.dart';
import '../../../data/models/audio_track_model.dart';

class MultiTrackTimeline extends StatefulWidget {
  final List<SceneModel> scenes;
  final List<SceneAssetModel> assets;
  final List<VoiceoverModel> voiceovers;
  final List<CaptionModel> captions;
  final List<AudioTrackModel> audioTracks;
  final double currentPositionSeconds;
  final double totalDurationSeconds;
  final ValueChanged<double> onSeek;
  final ValueChanged<int>? onSelectScene;
  final int selectedSceneIndex;

  const MultiTrackTimeline({
    Key? key,
    required this.scenes,
    required this.assets,
    required this.voiceovers,
    required this.captions,
    required this.audioTracks,
    required this.currentPositionSeconds,
    required this.totalDurationSeconds,
    required this.onSeek,
    this.onSelectScene,
    this.selectedSceneIndex = 0,
  }) : super(key: key);

  @override
  State<MultiTrackTimeline> createState() => _MultiTrackTimelineState();
}

class _MultiTrackTimelineState extends State<MultiTrackTimeline> {
  final ScrollController _scrollController = ScrollController();
  double _zoomScale = 1.0; // 0.5x, 1.0x, 2.0x, 4.0x
  static const double basePixelsPerSecond = 35.0;

  double get pixelsPerSecond => basePixelsPerSecond * _zoomScale;

  @override
  Widget build(BuildContext context) {
    final double timelineWidth = (widget.totalDurationSeconds * pixelsPerSecond) + 300.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Column(
        children: [
          // Timeline Controls (Zoom & Timecode)
          _buildTimelineHeader(),

          // Multi-Track Timeline Content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: timelineWidth,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time Ruler
                        _buildTimeRuler(timelineWidth),
                        const SizedBox(height: 4),

                        // Track 1: Master Video / Scene Sequence Track
                        _buildTrackLabel('SCENES / VIDEO', AppColors.accentPurple),
                        _buildSceneTrack(),
                        const SizedBox(height: 6),

                        // Track 2: Visual Images Track
                        _buildTrackLabel('IMAGES / ASSETS', AppColors.accentPink),
                        _buildAssetTrack(),
                        const SizedBox(height: 6),

                        // Track 3: Voiceover Track
                        _buildTrackLabel('VOICEOVER', AppColors.accentCyan),
                        _buildVoiceoverTrack(),
                        const SizedBox(height: 6),

                        // Track 4: Background Music Track
                        _buildTrackLabel('BGM / MUSIC', AppColors.success),
                        _buildBgmTrack(),
                        const SizedBox(height: 6),

                        // Track 5: Subtitles & Captions Track
                        _buildTrackLabel('SUBTITLES', AppColors.warning),
                        _buildCaptionTrack(),
                        const SizedBox(height: 8),
                      ],
                    ),

                    // Playhead Line Indicator
                    Positioned(
                      left: 120.0 + (widget.currentPositionSeconds * pixelsPerSecond),
                      top: 0,
                      bottom: 0,
                      child: _buildPlayhead(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Icon(Icons.movie_creation_outlined, color: AppColors.accentPurple, size: 18),
          const SizedBox(width: 8),
          Text(
            '${widget.currentPositionSeconds.toStringAsFixed(1)}s / ${widget.totalDurationSeconds.toStringAsFixed(1)}s',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
          ),
          const Spacer(),
          // Zoom scale pills
          Text('Zoom:', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
          const SizedBox(width: 6),
          _buildZoomPill(0.5, '0.5x'),
          const SizedBox(width: 4),
          _buildZoomPill(1.0, '1x'),
          const SizedBox(width: 4),
          _buildZoomPill(2.0, '2x'),
          const SizedBox(width: 4),
          _buildZoomPill(4.0, '4x'),
        ],
      ),
    );
  }

  Widget _buildZoomPill(double scale, String label) {
    final isSelected = _zoomScale == scale;
    return InkWell(
      onTap: () => setState(() => _zoomScale = scale),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPurple : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRuler(double width) {
    return Container(
      height: 24,
      width: width,
      margin: const EdgeInsets.only(left: 120),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: CustomPaint(
        painter: _RulerPainter(
          totalSeconds: widget.totalDurationSeconds,
          pixelsPerSecond: pixelsPerSecond,
        ),
      ),
    );
  }

  Widget _buildTrackLabel(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 2),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- Track 1: Scenes Sequence ---
  Widget _buildSceneTrack() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(left: 120),
      child: Row(
        children: widget.scenes.map((scene) {
          final width = scene.durationSeconds * pixelsPerSecond;
          final isSelected = widget.selectedSceneIndex == (scene.sceneIndex - 1);

          return GestureDetector(
            onTap: () {
              widget.onSelectScene?.call(scene.sceneIndex - 1);
            },
            child: Container(
              width: width,
              margin: const EdgeInsets.only(right: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentPurple : const Color(0xFF27354E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'Scene ${scene.sceneIndex}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        '${scene.durationSeconds.toStringAsFixed(1)}s',
                        style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                  if (scene.title != null)
                    Text(
                      scene.title!,
                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Track 2: Images Track ---
  Widget _buildAssetTrack() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(left: 120),
      child: Row(
        children: widget.scenes.map((scene) {
          final width = scene.durationSeconds * pixelsPerSecond;
          final hasAsset = widget.assets.any((a) => a.sceneId == scene.id);

          return Container(
            width: width,
            margin: const EdgeInsets.only(right: 3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: hasAsset ? const Color(0xFF831843) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasAsset ? AppColors.accentPink : Colors.white.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasAsset ? Icons.image : Icons.image_not_supported_outlined,
                  size: 14,
                  color: hasAsset ? Colors.white : Colors.white38,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hasAsset ? 'Image Attached' : 'No Image',
                    style: TextStyle(
                      fontSize: 10,
                      color: hasAsset ? Colors.white : Colors.white38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Track 3: Voiceover Track ---
  Widget _buildVoiceoverTrack() {
    return Container(
      height: 36,
      margin: const EdgeInsets.only(left: 120),
      child: Row(
        children: widget.scenes.map((scene) {
          final width = scene.durationSeconds * pixelsPerSecond;
          final vo = widget.voiceovers.where((v) => v.sceneId == scene.id).firstOrNull;

          return Container(
            width: width,
            margin: const EdgeInsets.only(right: 3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: vo != null ? const Color(0xFF0E7490) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: vo != null ? AppColors.accentCyan : Colors.white.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  vo != null ? Icons.mic : Icons.mic_none,
                  size: 14,
                  color: vo != null ? Colors.white : Colors.white38,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    vo != null ? 'VO (${vo.sourceType})' : 'Add VO',
                    style: TextStyle(
                      fontSize: 10,
                      color: vo != null ? Colors.white : Colors.white38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Track 4: Background Music Track ---
  Widget _buildBgmTrack() {
    final width = widget.totalDurationSeconds * pixelsPerSecond;
    final bgm = widget.audioTracks.firstOrNull;

    return Container(
      height: 34,
      width: width,
      margin: const EdgeInsets.only(left: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgm != null ? const Color(0xFF065F46) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: bgm != null ? AppColors.success : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.music_note, size: 14, color: bgm != null ? Colors.white : Colors.white38),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              bgm != null ? '${bgm.title} (Vol: ${(bgm.volume * 100).toInt()}%)' : 'Add Background Music Track',
              style: TextStyle(
                fontSize: 10,
                color: bgm != null ? Colors.white : Colors.white38,
                fontWeight: bgm != null ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- Track 5: Subtitles & Captions Track ---
  Widget _buildCaptionTrack() {
    final width = widget.totalDurationSeconds * pixelsPerSecond;

    return Container(
      height: 34,
      width: width,
      margin: const EdgeInsets.only(left: 120),
      child: Stack(
        children: widget.captions.map((caption) {
          final startSec = caption.startTimeMs / 1000.0;
          final endSec = caption.endTimeMs / 1000.0;
          final durationSec = (endSec - startSec).clamp(0.5, 30.0);

          final left = startSec * pixelsPerSecond;
          final itemWidth = durationSec * pixelsPerSecond;

          return Positioned(
            left: left,
            child: Container(
              width: itemWidth,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF78350F),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.warning),
              ),
              child: Text(
                caption.text,
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlayhead() {
    return Column(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 4, spreadRadius: 1),
            ],
          ),
          child: const Center(
            child: Icon(Icons.arrow_drop_down, size: 14, color: AppColors.accentPurple),
          ),
        ),
        Expanded(
          child: Container(
            width: 2,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double totalSeconds;
  final double pixelsPerSecond;

  _RulerPainter({required this.totalSeconds, required this.pixelsPerSecond});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int sec = 0; sec <= totalSeconds.ceil() + 5; sec++) {
      final x = sec * pixelsPerSecond;
      final isMajor = sec % 5 == 0;
      final lineHeight = isMajor ? 14.0 : 6.0;

      canvas.drawLine(Offset(x, size.height - lineHeight), Offset(x, size.height), paint);

      if (isMajor) {
        textPainter.text = TextSpan(
          text: '${sec}s',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.bold),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + 2, 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return oldDelegate.totalSeconds != totalSeconds || oldDelegate.pixelsPerSecond != pixelsPerSecond;
  }
}
