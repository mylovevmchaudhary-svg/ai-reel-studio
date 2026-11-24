import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/media_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/screens/login_screen.dart';

class SettingsStorageScreen extends StatefulWidget {
  const SettingsStorageScreen({Key? key}) : super(key: key);

  @override
  State<SettingsStorageScreen> createState() => _SettingsStorageScreenState();
}

class _SettingsStorageScreenState extends State<SettingsStorageScreen> {
  final MediaService _media = MediaService.instance;
  final SupabaseService _supabase = SupabaseService.instance;

  Map<String, dynamic> _storageStats = {'totalMb': '0.0', 'projectCount': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
  }

  Future<void> _loadStorageStats() async {
    setState(() => _isLoading = true);
    final stats = await _media.getStorageUsage();
    setState(() {
      _storageStats = stats;
      _isLoading = false;
    });
  }

  Future<void> _clearCache() async {
    await _media.clearCache();
    await _loadStorageStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Temporary media cache cleared! 🧹')),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await _supabase.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Settings & Storage'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Storage Usage Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroCardGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.storage, color: AppColors.accentCyan),
                            SizedBox(width: 8),
                            Text('Storage Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${_storageStats['totalMb']} MB Used',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Across ${_storageStats['projectCount']} local projects & export caches',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _clearCache,
                          icon: const Icon(Icons.cleaning_services, size: 16),
                          label: const Text('Clear Temp Cache'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentPurple,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Supabase Account / Cloud Status
                  const Text('Cloud Sync & Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.cloud_done, color: AppColors.success),
                          title: const Text('Database Engine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            _supabase.isGuestMode ? 'Guest / Local SQLite Mode' : 'Supabase Cloud PostgreSQL & Auth',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55)),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.person, color: AppColors.accentPurple),
                          title: const Text('Logged In As', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            _supabase.currentUserEmail ?? 'Offline Guest Creator',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55)),
                          ),
                          trailing: TextButton(
                            onPressed: _handleSignOut,
                            child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Zero Paid API Transparency Notice (Section 3)
                  const Text('AI & API Transparency', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user_outlined, color: AppColors.accentPink, size: 20),
                            SizedBox(width: 8),
                            Text('Zero-Paid-API Architecture', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• All core video editing, multi-track mixing, and MP4 rendering run locally on-device via FFmpeg without paid subscriptions.\n'
                          '• Visual image generation is powered through structured prompts ready for ChatGPT / Midjourney or local uploads.\n'
                          '• Text-to-speech uses on-device native synthesis supporting English, Hindi, and Gujarati.',
                          style: TextStyle(fontSize: 12, height: 1.5, color: Colors.white.withOpacity(0.75)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Version
                  Center(
                    child: Text(
                      'AI Reel Studio v${AppConstants.appVersion}',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
