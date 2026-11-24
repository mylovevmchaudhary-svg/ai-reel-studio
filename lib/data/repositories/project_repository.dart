import '../../data/local/database_helper.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/project_model.dart';
import '../../data/models/story_model.dart';
import '../../data/models/character_model.dart';
import '../../data/models/scene_model.dart';
import '../../data/models/scene_asset_model.dart';
import '../../data/models/voiceover_model.dart';
import '../../data/models/caption_model.dart';
import '../../data/models/audio_track_model.dart';
import '../../data/models/video_export_model.dart';

class ProjectRepository {
  final DatabaseHelper _localDb = DatabaseHelper.instance;
  final SupabaseService _supabase = SupabaseService.instance;

  // --- PROJECTS ---
  Future<void> saveProject(ProjectModel project) async {
    await _localDb.insertOrUpdateProject(project);
    _supabase.syncProject(project); // background cloud sync
  }

  Future<List<ProjectModel>> getProjects() async {
    final localProjects = await _localDb.getAllProjects(ownerId: _supabase.currentUserId);
    // If local is empty and cloud is available, try cloud fetch
    if (localProjects.isEmpty && _supabase.isAuthenticated && !_supabase.isGuestMode) {
      final cloudProjects = await _supabase.fetchProjects();
      for (final p in cloudProjects) {
        await _localDb.insertOrUpdateProject(p);
      }
      return cloudProjects;
    }
    return localProjects;
  }

  Future<ProjectModel?> getProject(String id) async {
    return await _localDb.getProjectById(id);
  }

  Future<void> deleteProject(String id) async {
    await _localDb.deleteProject(id);
    _supabase.deleteProject(id);
  }

  // --- STORIES ---
  Future<void> saveStory(StoryModel story) async {
    await _localDb.insertOrUpdateStory(story);
    _supabase.syncStory(story);
  }

  Future<StoryModel?> getStory(String projectId) async {
    return await _localDb.getStoryByProjectId(projectId);
  }

  // --- CHARACTERS ---
  Future<void> saveCharacter(CharacterModel character) async {
    await _localDb.insertOrUpdateCharacter(character);
    _supabase.syncCharacter(character);
  }

  Future<List<CharacterModel>> getCharacters(String projectId) async {
    return await _localDb.getCharactersByProjectId(projectId);
  }

  Future<void> deleteCharacter(String id) async {
    await _localDb.deleteCharacter(id);
  }

  // --- SCENES ---
  Future<void> saveScene(SceneModel scene) async {
    await _localDb.insertOrUpdateScene(scene);
    _supabase.syncScene(scene);
  }

  Future<List<SceneModel>> getScenes(String projectId) async {
    return await _localDb.getScenesByProjectId(projectId);
  }

  Future<void> deleteScene(String id) async {
    await _localDb.deleteScene(id);
  }

  // --- SCENE ASSETS ---
  Future<void> saveSceneAsset(SceneAssetModel asset) async {
    await _localDb.insertOrUpdateSceneAsset(asset);
    _supabase.syncSceneAsset(asset);
  }

  Future<List<SceneAssetModel>> getAssetsForScene(String sceneId) async {
    return await _localDb.getAssetsBySceneId(sceneId);
  }

  Future<List<SceneAssetModel>> getAssetsForProject(String projectId) async {
    return await _localDb.getAssetsByProjectId(projectId);
  }

  // --- VOICEOVERS ---
  Future<void> saveVoiceover(VoiceoverModel voiceover) async {
    await _localDb.insertOrUpdateVoiceover(voiceover);
    _supabase.syncVoiceover(voiceover);
  }

  Future<VoiceoverModel?> getVoiceoverForScene(String sceneId) async {
    return await _localDb.getVoiceoverBySceneId(sceneId);
  }

  Future<List<VoiceoverModel>> getVoiceoversForProject(String projectId) async {
    return await _localDb.getVoiceoversByProjectId(projectId);
  }

  // --- CAPTIONS ---
  Future<void> saveCaption(CaptionModel caption) async {
    await _localDb.insertOrUpdateCaption(caption);
    _supabase.syncCaption(caption);
  }

  Future<List<CaptionModel>> getCaptions(String projectId) async {
    return await _localDb.getCaptionsByProjectId(projectId);
  }

  Future<void> deleteCaption(String id) async {
    await _localDb.deleteCaption(id);
  }

  // --- AUDIO TRACKS ---
  Future<void> saveAudioTrack(AudioTrackModel track) async {
    await _localDb.insertOrUpdateAudioTrack(track);
    _supabase.syncAudioTrack(track);
  }

  Future<List<AudioTrackModel>> getAudioTracks(String projectId) async {
    return await _localDb.getAudioTracksByProjectId(projectId);
  }

  // --- VIDEO EXPORTS ---
  Future<void> saveVideoExport(VideoExportModel export) async {
    await _localDb.insertOrUpdateVideoExport(export);
    _supabase.syncVideoExport(export);
  }

  Future<List<VideoExportModel>> getVideoExports() async {
    return await _localDb.getAllVideoExports(ownerId: _supabase.currentUserId);
  }
}
