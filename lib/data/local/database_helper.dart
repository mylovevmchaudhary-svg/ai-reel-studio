import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/project_model.dart';
import '../models/story_model.dart';
import '../models/character_model.dart';
import '../models/scene_model.dart';
import '../models/scene_asset_model.dart';
import '../models/voiceover_model.dart';
import '../models/caption_model.dart';
import '../models/audio_track_model.dart';
import '../models/video_export_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ai_reel_studio.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Projects
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        aspect_ratio TEXT NOT NULL,
        target_duration_seconds INTEGER NOT NULL,
        fps INTEGER NOT NULL,
        resolution TEXT NOT NULL,
        status TEXT NOT NULL,
        thumbnail_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Stories
    await db.execute('''
      CREATE TABLE stories (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        prompt_text TEXT NOT NULL,
        prompt_language TEXT NOT NULL,
        story_title TEXT NOT NULL,
        synopsis TEXT,
        genre TEXT,
        tone TEXT,
        raw_response TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // 3. Characters
    await db.execute('''
      CREATE TABLE characters (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT,
        visual_description TEXT NOT NULL,
        outfit TEXT,
        reference_image_url TEXT,
        voice_persona TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // 4. Scenes
    await db.execute('''
      CREATE TABLE scenes (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        scene_index INTEGER NOT NULL,
        title TEXT,
        narration TEXT,
        dialogue TEXT,
        visual_prompt TEXT NOT NULL,
        negative_prompt TEXT,
        camera_angle TEXT,
        lighting TEXT,
        duration_seconds REAL NOT NULL,
        transition_type TEXT,
        transition_duration REAL,
        status TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // 5. Scene Assets
    await db.execute('''
      CREATE TABLE scene_assets (
        id TEXT PRIMARY KEY,
        scene_id TEXT NOT NULL,
        project_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        asset_type TEXT NOT NULL,
        asset_url TEXT NOT NULL,
        local_path TEXT,
        aspect_ratio TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (scene_id) REFERENCES scenes (id) ON DELETE CASCADE,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // 6. Voiceovers
    await db.execute('''
      CREATE TABLE voiceovers (
        id TEXT PRIMARY KEY,
        scene_id TEXT NOT NULL,
        project_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        audio_url TEXT,
        local_path TEXT,
        duration_seconds REAL,
        source_type TEXT NOT NULL,
        voice_id TEXT,
        language TEXT,
        volume REAL,
        fade_in_ms INTEGER,
        fade_out_ms INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (scene_id) REFERENCES scenes (id) ON DELETE CASCADE,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // 7. Captions
    await db.execute('''
      CREATE TABLE captions (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        scene_id TEXT,
        owner_id TEXT NOT NULL,
        start_time_ms INTEGER NOT NULL,
        end_time_ms INTEGER NOT NULL,
        text TEXT NOT NULL,
        font_family TEXT,
        font_size INTEGER,
        text_color TEXT,
        background_color TEXT,
        animation_type TEXT,
        position TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // 8. Audio Tracks
    await db.execute('''
      CREATE TABLE audio_tracks (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        title TEXT NOT NULL,
        track_type TEXT NOT NULL,
        audio_url TEXT,
        local_path TEXT,
        duration_seconds REAL,
        volume REAL,
        loop INTEGER,
        fade_in_ms INTEGER,
        fade_out_ms INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // 9. Video Exports
    await db.execute('''
      CREATE TABLE video_exports (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        export_url TEXT,
        local_path TEXT,
        resolution TEXT,
        fps INTEGER,
        aspect_ratio TEXT,
        duration_seconds REAL,
        file_size_bytes INTEGER,
        status TEXT,
        error_message TEXT,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- CRUD: PROJECTS ---
  Future<void> insertOrUpdateProject(ProjectModel project) async {
    final db = await database;
    await db.insert('projects', project.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ProjectModel>> getAllProjects({String? ownerId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = ownerId != null && ownerId.isNotEmpty
        ? await db.query('projects', where: 'owner_id = ?', whereArgs: [ownerId], orderBy: 'updated_at DESC')
        : await db.query('projects', orderBy: 'updated_at DESC');
    return maps.map((e) => ProjectModel.fromMap(e)).toList();
  }

  Future<ProjectModel?> getProjectById(String id) async {
    final db = await database;
    final maps = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return ProjectModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
    await db.delete('stories', where: 'project_id = ?', whereArgs: [id]);
    await db.delete('characters', where: 'project_id = ?', whereArgs: [id]);
    await db.delete('scenes', where: 'project_id = ?', whereArgs: [id]);
    await db.delete('scene_assets', where: 'project_id = ?', whereArgs: [id]);
    await db.delete('voiceovers', where: 'project_id = ?', whereArgs: [id]);
    await db.delete('captions', where: 'project_id = ?', whereArgs: [id]);
    await db.delete('audio_tracks', where: 'project_id = ?', whereArgs: [id]);
    await db.delete('video_exports', where: 'project_id = ?', whereArgs: [id]);
  }

  // --- CRUD: STORIES ---
  Future<void> insertOrUpdateStory(StoryModel story) async {
    final db = await database;
    await db.insert('stories', story.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<StoryModel?> getStoryByProjectId(String projectId) async {
    final db = await database;
    final maps = await db.query('stories', where: 'project_id = ?', whereArgs: [projectId]);
    if (maps.isNotEmpty) {
      return StoryModel.fromMap(maps.first);
    }
    return null;
  }

  // --- CRUD: CHARACTERS ---
  Future<void> insertOrUpdateCharacter(CharacterModel character) async {
    final db = await database;
    await db.insert('characters', character.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CharacterModel>> getCharactersByProjectId(String projectId) async {
    final db = await database;
    final maps = await db.query('characters', where: 'project_id = ?', whereArgs: [projectId]);
    return maps.map((e) => CharacterModel.fromMap(e)).toList();
  }

  Future<void> deleteCharacter(String id) async {
    final db = await database;
    await db.delete('characters', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD: SCENES ---
  Future<void> insertOrUpdateScene(SceneModel scene) async {
    final db = await database;
    await db.insert('scenes', scene.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SceneModel>> getScenesByProjectId(String projectId) async {
    final db = await database;
    final maps = await db.query('scenes', where: 'project_id = ?', whereArgs: [projectId], orderBy: 'scene_index ASC');
    return maps.map((e) => SceneModel.fromMap(e)).toList();
  }

  Future<void> deleteScene(String id) async {
    final db = await database;
    await db.delete('scenes', where: 'id = ?', whereArgs: [id]);
    await db.delete('scene_assets', where: 'scene_id = ?', whereArgs: [id]);
    await db.delete('voiceovers', where: 'scene_id = ?', whereArgs: [id]);
  }

  // --- CRUD: SCENE ASSETS ---
  Future<void> insertOrUpdateSceneAsset(SceneAssetModel asset) async {
    final db = await database;
    await db.insert('scene_assets', asset.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SceneAssetModel>> getAssetsBySceneId(String sceneId) async {
    final db = await database;
    final maps = await db.query('scene_assets', where: 'scene_id = ?', whereArgs: [sceneId]);
    return maps.map((e) => SceneAssetModel.fromMap(e)).toList();
  }

  Future<List<SceneAssetModel>> getAssetsByProjectId(String projectId) async {
    final db = await database;
    final maps = await db.query('scene_assets', where: 'project_id = ?', whereArgs: [projectId]);
    return maps.map((e) => SceneAssetModel.fromMap(e)).toList();
  }

  // --- CRUD: VOICEOVERS ---
  Future<void> insertOrUpdateVoiceover(VoiceoverModel voiceover) async {
    final db = await database;
    await db.insert('voiceovers', voiceover.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<VoiceoverModel?> getVoiceoverBySceneId(String sceneId) async {
    final db = await database;
    final maps = await db.query('voiceovers', where: 'scene_id = ?', whereArgs: [sceneId]);
    if (maps.isNotEmpty) {
      return VoiceoverModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<VoiceoverModel>> getVoiceoversByProjectId(String projectId) async {
    final db = await database;
    final maps = await db.query('voiceovers', where: 'project_id = ?', whereArgs: [projectId]);
    return maps.map((e) => VoiceoverModel.fromMap(e)).toList();
  }

  // --- CRUD: CAPTIONS ---
  Future<void> insertOrUpdateCaption(CaptionModel caption) async {
    final db = await database;
    await db.insert('captions', caption.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CaptionModel>> getCaptionsByProjectId(String projectId) async {
    final db = await database;
    final maps = await db.query('captions', where: 'project_id = ?', whereArgs: [projectId], orderBy: 'start_time_ms ASC');
    return maps.map((e) => CaptionModel.fromMap(e)).toList();
  }

  Future<void> deleteCaption(String id) async {
    final db = await database;
    await db.delete('captions', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD: AUDIO TRACKS (BGM) ---
  Future<void> insertOrUpdateAudioTrack(AudioTrackModel track) async {
    final db = await database;
    await db.insert('audio_tracks', track.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AudioTrackModel>> getAudioTracksByProjectId(String projectId) async {
    final db = await database;
    final maps = await db.query('audio_tracks', where: 'project_id = ?', whereArgs: [projectId]);
    return maps.map((e) => AudioTrackModel.fromMap(e)).toList();
  }

  // --- CRUD: VIDEO EXPORTS ---
  Future<void> insertOrUpdateVideoExport(VideoExportModel export) async {
    final db = await database;
    await db.insert('video_exports', export.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<VideoExportModel>> getAllVideoExports({String? ownerId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = ownerId != null && ownerId.isNotEmpty
        ? await db.query('video_exports', where: 'owner_id = ?', whereArgs: [ownerId], orderBy: 'created_at DESC')
        : await db.query('video_exports', orderBy: 'created_at DESC');
    return maps.map((e) => VideoExportModel.fromMap(e)).toList();
  }
}
