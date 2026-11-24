class VoiceoverModel {
  final String id;
  final String sceneId;
  final String projectId;
  final String ownerId;
  final String? audioUrl;
  final String? localPath;
  final double durationSeconds;
  final String sourceType; // 'recorded', 'uploaded', 'tts'
  final String? voiceId;
  final String language; // 'en', 'hi', 'gu'
  final double volume; // 0.0 to 2.0
  final int fadeInMs;
  final int fadeOutMs;
  final DateTime createdAt;
  final DateTime updatedAt;

  VoiceoverModel({
    required this.id,
    required this.sceneId,
    required this.projectId,
    required this.ownerId,
    this.audioUrl,
    this.localPath,
    this.durationSeconds = 5.0,
    this.sourceType = 'recorded',
    this.voiceId,
    this.language = 'en',
    this.volume = 1.0,
    this.fadeInMs = 100,
    this.fadeOutMs = 100,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  VoiceoverModel copyWith({
    String? id,
    String? sceneId,
    String? projectId,
    String? ownerId,
    String? audioUrl,
    String? localPath,
    double? durationSeconds,
    String? sourceType,
    String? voiceId,
    String? language,
    double? volume,
    int? fadeInMs,
    int? fadeOutMs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VoiceoverModel(
      id: id ?? this.id,
      sceneId: sceneId ?? this.sceneId,
      projectId: projectId ?? this.projectId,
      ownerId: ownerId ?? this.ownerId,
      audioUrl: audioUrl ?? this.audioUrl,
      localPath: localPath ?? this.localPath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sourceType: sourceType ?? this.sourceType,
      voiceId: voiceId ?? this.voiceId,
      language: language ?? this.language,
      volume: volume ?? this.volume,
      fadeInMs: fadeInMs ?? this.fadeInMs,
      fadeOutMs: fadeOutMs ?? this.fadeOutMs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scene_id': sceneId,
      'project_id': projectId,
      'owner_id': ownerId,
      'audio_url': audioUrl,
      'local_path': localPath,
      'duration_seconds': durationSeconds,
      'source_type': sourceType,
      'voice_id': voiceId,
      'language': language,
      'volume': volume,
      'fade_in_ms': fadeInMs,
      'fade_out_ms': fadeOutMs,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory VoiceoverModel.fromMap(Map<String, dynamic> map) {
    return VoiceoverModel(
      id: map['id']?.toString() ?? '',
      sceneId: map['scene_id']?.toString() ?? '',
      projectId: map['project_id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      audioUrl: map['audio_url']?.toString(),
      localPath: map['local_path']?.toString(),
      durationSeconds: map['duration_seconds'] is num
          ? (map['duration_seconds'] as num).toDouble()
          : double.tryParse(map['duration_seconds']?.toString() ?? '5.0') ?? 5.0,
      sourceType: map['source_type']?.toString() ?? 'recorded',
      voiceId: map['voice_id']?.toString(),
      language: map['language']?.toString() ?? 'en',
      volume: map['volume'] is num
          ? (map['volume'] as num).toDouble()
          : double.tryParse(map['volume']?.toString() ?? '1.0') ?? 1.0,
      fadeInMs: map['fade_in_ms'] is int ? map['fade_in_ms'] : int.tryParse(map['fade_in_ms']?.toString() ?? '100') ?? 100,
      fadeOutMs: map['fade_out_ms'] is int ? map['fade_out_ms'] : int.tryParse(map['fade_out_ms']?.toString() ?? '100') ?? 100,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
