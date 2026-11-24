class AudioTrackModel {
  final String id;
  final String projectId;
  final String ownerId;
  final String title;
  final String trackType; // 'bgm', 'sfx'
  final String? audioUrl;
  final String? localPath;
  final double durationSeconds;
  final double volume; // 0.0 to 1.0
  final bool loop;
  final int fadeInMs;
  final int fadeOutMs;
  final DateTime createdAt;
  final DateTime updatedAt;

  AudioTrackModel({
    required this.id,
    required this.projectId,
    required this.ownerId,
    required this.title,
    this.trackType = 'bgm',
    this.audioUrl,
    this.localPath,
    this.durationSeconds = 30.0,
    this.volume = 0.35,
    this.loop = true,
    this.fadeInMs = 500,
    this.fadeOutMs = 1000,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  AudioTrackModel copyWith({
    String? id,
    String? projectId,
    String? ownerId,
    String? title,
    String? trackType,
    String? audioUrl,
    String? localPath,
    double? durationSeconds,
    double? volume,
    bool? loop,
    int? fadeInMs,
    int? fadeOutMs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AudioTrackModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      trackType: trackType ?? this.trackType,
      audioUrl: audioUrl ?? this.audioUrl,
      localPath: localPath ?? this.localPath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      volume: volume ?? this.volume,
      loop: loop ?? this.loop,
      fadeInMs: fadeInMs ?? this.fadeInMs,
      fadeOutMs: fadeOutMs ?? this.fadeOutMs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'owner_id': ownerId,
      'title': title,
      'track_type': trackType,
      'audio_url': audioUrl,
      'local_path': localPath,
      'duration_seconds': durationSeconds,
      'volume': volume,
      'loop': loop ? 1 : 0,
      'fade_in_ms': fadeInMs,
      'fade_out_ms': fadeOutMs,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AudioTrackModel.fromMap(Map<String, dynamic> map) {
    return AudioTrackModel(
      id: map['id']?.toString() ?? '',
      projectId: map['project_id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Background Music',
      trackType: map['track_type']?.toString() ?? 'bgm',
      audioUrl: map['audio_url']?.toString(),
      localPath: map['local_path']?.toString(),
      durationSeconds: map['duration_seconds'] is num
          ? (map['duration_seconds'] as num).toDouble()
          : double.tryParse(map['duration_seconds']?.toString() ?? '30.0') ?? 30.0,
      volume: map['volume'] is num
          ? (map['volume'] as num).toDouble()
          : double.tryParse(map['volume']?.toString() ?? '0.35') ?? 0.35,
      loop: map['loop'] == 1 || map['loop'] == true,
      fadeInMs: map['fade_in_ms'] is int ? map['fade_in_ms'] : int.tryParse(map['fade_in_ms']?.toString() ?? '500') ?? 500,
      fadeOutMs: map['fade_out_ms'] is int ? map['fade_out_ms'] : int.tryParse(map['fade_out_ms']?.toString() ?? '1000') ?? 1000,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
