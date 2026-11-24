import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/project_model.dart';
import '../../data/models/story_model.dart';
import '../../data/models/character_model.dart';
import '../../data/models/scene_model.dart';
import '../../data/models/scene_asset_model.dart';
import '../../data/models/voiceover_model.dart';
import '../../data/models/caption_model.dart';
import '../../data/models/audio_track_model.dart';
import '../../data/models/video_export_model.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  factory SupabaseService() => instance;
  SupabaseService._internal();

  // Supabase Configuration (can be dynamically set from settings or environment)
  String supabaseUrl = 'https://yrcpohwezjawmoanlqfz.supabase.co';
  String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlyY3BvaHdlemphd21vYW5scWZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTU1MTk4NzksImV4cCI6MjExMTA5NTg3OX0.5bVaOLgq24LK2D64-jPx6HlFONUVvBpZWr2nuLKEkFE';
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client {
    if (_isInitialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Guest / Offline fallback user id
  String _guestUserId = 'guest_user_${DateTime.now().millisecondsSinceEpoch}';
  bool _isGuestMode = false;
  bool get isGuestMode => _isGuestMode;

  String get currentUserId {
    if (_isGuestMode) return _guestUserId;
    final user = client?.auth.currentUser;
    return user?.id ?? _guestUserId;
  }

  String? get currentUserEmail {
    if (_isGuestMode) return 'guest@aireelstudio.local';
    return client?.auth.currentUser?.email;
  }

  bool get isAuthenticated => _isGuestMode || (client?.auth.currentUser != null);

  /// Initializes Supabase Flutter SDK safely
  Future<bool> initialize({String? customUrl, String? customKey}) async {
    if (customUrl != null && customUrl.isNotEmpty) supabaseUrl = customUrl;
    if (customKey != null && customKey.isNotEmpty) supabaseAnonKey = customKey;

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('[SupabaseService] Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Offline or fallback mode enabled: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Guest Login Mode
  void signInAsGuest() {
    _isGuestMode = true;
  }

  /// Sign Up with Email and Password
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!_isInitialized || client == null) {
      _isGuestMode = true;
      return null;
    }
    try {
      final res = await client!.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': displayName ?? email.split('@').first},
      );
      _isGuestMode = false;
      return res;
    } catch (e) {
      debugPrint('[SupabaseService] SignUp Error: $e');
      rethrow;
    }
  }

  /// Sign In with Email and Password
  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized || client == null) {
      _isGuestMode = true;
      return null;
    }
    try {
      final res = await client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _isGuestMode = false;
      return res;
    } catch (e) {
      debugPrint('[SupabaseService] SignIn Error: $e');
      rethrow;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    if (_isInitialized && client != null) {
      try {
        await client!.auth.signOut();
      } catch (_) {}
    }
    _isGuestMode = false;
  }

  // =========================================================================
  // CLOUD DATABASE SYNC METHODS
  // =========================================================================

  /// Sync Project to Supabase
  Future<bool> syncProject(ProjectModel project) async {
    if (!_isInitialized || client == null || _isGuestMode) return false;
    try {
      await client!.from('projects').upsert(project.toMap());
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] syncProject error: $e');
      return false;
    }
  }

  /// Fetch Projects from Supabase
  Future<List<ProjectModel>> fetchProjects() async {
    if (!_isInitialized || client == null || _isGuestMode) return [];
    try {
      final res = await client!
          .from('projects')
          .select()
          .eq('owner_id', currentUserId)
          .order('updated_at', ascending: false);
      return (res as List).map((e) => ProjectModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('[SupabaseService] fetchProjects error: $e');
      return [];
    }
  }

  /// Delete Project from Supabase
  Future<bool> deleteProject(String projectId) async {
    if (!_isInitialized || client == null || _isGuestMode) return false;
    try {
      await client!.from('projects').delete().eq('id', projectId);
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] deleteProject error: $e');
      return false;
    }
  }

  /// Sync Story to Supabase
  Future<bool> syncStory(StoryModel story) async {
    if (!_isInitialized || client == null || _isGuestMode) return false;
    try {
      await client!.from('stories').upsert(story.toMap());
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] syncStory error: $e');
      return false;
    }
  }

  /// Sync Character to Supabase
  Future<bool> syncCharacter(CharacterModel character) async {
    if (!_isInitialized || client == null || _isGuestMode) return false;
    try {
      await client!.from('characters').upsert(character.toMap());
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] syncCharacter error: $e');
      return false;
    }
  }

  /// Sync Scene to Supabase
  Future<bool> syncScene(SceneModel scene) async {
    if (!_isInitialized || client == null || _isGuestMode) return false;
    try {
      await client!.from('scenes').upsert(scene.toMap());
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] syncScene error: $e');
      return false;
    }
  }

  /// Sync Scene Asset to Supabase
  Future<bool> syncSceneAsset(SceneAssetModel asset) async {
    if (!_isInitialized || client == null || _isGuestMode) return false;
    try {
      await client!.from('scene_assets').upsert(asset.toMap());
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] syncSceneAsset error: $e');
      return false;
    }
  }

  /// Sync Voiceover to Supabase
  Future<bool> syncVoiceover(VoiceoverModel voiceover) async {
    if (!_isInitialized || client == null || _isGuestMode) return false;
    try {
      await client!.from('voiceovers').upsert(voiceover.toMap());
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] syncVoiceover error: $e');
      return false;
    }
  }

  /// Sync Caption to Supabase
  Future<bool> syncCaption(CaptionModel caption) async {
    if (!_isInitialized || client == null || _isGuestMode) return false;
    try {
      await client!.from('captions').upsert(caption.toMap());
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] syncCaption error: $e');
      return false;
    }
  }

  /// Sync Audio Track (BGM) to Supabase
  Future<bool> syncAudioTrack(AudioTrackModel track) async {
    if (!_isInitialized || client == null || _isGuestMode) return false;
    try {
      await client!.from('audio_tracks').upsert(track.toMap());
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] syncAudioTrack error: $e');
      return false;
    }
  }

  /// Sync Video Export Record to Supabase
  Future<bool> syncVideoExport(VideoExportModel export) async {
    if (!_isInitialized || client == null || _isGuestMode) return false;
    try {
      await client!.from('video_exports').upsert(export.toMap());
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] syncVideoExport error: $e');
      return false;
    }
  }

  // =========================================================================
  // SUPABASE STORAGE UPLOADS
  // =========================================================================

  /// Upload file bytes to Supabase Storage bucket with user isolation
  Future<String?> uploadFile({
    required String bucketName,
    required String fileName,
    required Uint8List fileBytes,
    String contentType = 'image/jpeg',
  }) async {
    if (!_isInitialized || client == null || _isGuestMode) return null;
    try {
      final storagePath = '$currentUserId/$fileName';
      await client!.storage.from(bucketName).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );
      final publicUrl = client!.storage.from(bucketName).getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('[SupabaseService] uploadFile error in $bucketName: $e');
      return null;
    }
  }
}
