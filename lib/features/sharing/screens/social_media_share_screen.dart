import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';

class SocialMediaShareScreen extends StatelessWidget {
  final String projectTitle;
  final String videoPath;

  const SocialMediaShareScreen({
    Key? key,
    required this.projectTitle,
    required this.videoPath,
  }) : super(key: key);

  void _shareViaAndroid(BuildContext context) {
    if (File(videoPath).existsSync()) {
      Share.shareXFiles([XFile(videoPath)], text: '$projectTitle #Reel #AIReelStudio');
    } else {
      Share.share('Check out my new video reel: $projectTitle! Created with AI Reel Studio');
    }
  }

  void _copyHashtags(BuildContext context) {
    const tags = '#Reels #ViralVideo #Shorts #Storytelling #AIReelStudio #Cinematic #Creators #TrendingReel';
    Clipboard.setData(const ClipboardData(text: tags));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Viral hashtags copied to clipboard! 📋')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool fileExists = File(videoPath).existsSync();
    final int fileBytes = fileExists ? File(videoPath).lengthSync() : 0;
    final String sizeMb = (fileBytes / (1024 * 1024)).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Share Video Reel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Video Thumbnail & Badge
            Container(
              width: 140,
              height: 220,
              decoration: BoxDecoration(
                gradient: AppColors.heroCardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentPurple.withOpacity(0.4), width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.accentPurple.withOpacity(0.3), blurRadius: 20, spreadRadius: 4),
                ],
              ),
              child: const Center(
                child: Icon(Icons.play_circle_filled, size: 54, color: Colors.white),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              projectTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Format: MP4 (H.264) • Size: $sizeMb MB',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
            ),
            const SizedBox(height: 30),

            // Native Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareViaAndroid(context),
                icon: const Icon(Icons.share),
                label: const Text('Share to Apps (WhatsApp, Instagram, Drive)', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.accentPurple,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Copy Hashtags Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _copyHashtags(context),
                icon: const Icon(Icons.tag),
                label: const Text('Copy Viral Hashtags & Tags'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.accentPink),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Preset Badges
            const Text(
              'Ready for Posting to:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialPlatformIcon('Instagram Reels', Icons.camera_alt),
                _buildSocialPlatformIcon('YouTube Shorts', Icons.play_arrow),
                _buildSocialPlatformIcon('Facebook', Icons.facebook),
                _buildSocialPlatformIcon('WhatsApp', Icons.chat),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialPlatformIcon(String name, IconData icon) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.cardNavy,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}
