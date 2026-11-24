class ProjectModel {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final String aspectRatio; // '9:16', '16:9', '1:1'
  final int targetDurationSeconds;
  final int fps;
  final String resolution; // '720p', '1080p'
  final String status; // 'draft', 'generating', 'editing', 'exported'
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectModel({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    this.aspectRatio = '9:16',
    this.targetDurationSeconds = 15,
    this.fps = 30,
    this.resolution = '1080p',
    this.status = 'draft',
    this.thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ProjectModel copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    String? aspectRatio,
    int? targetDurationSeconds,
    int? fps,
    String? resolution,
    String? status,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      targetDurationSeconds: targetDurationSeconds ?? this.targetDurationSeconds,
      fps: fps ?? this.fps,
      resolution: resolution ?? this.resolution,
      status: status ?? this.status,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'aspect_ratio': aspectRatio,
      'target_duration_seconds': targetDurationSeconds,
      'fps': fps,
      'resolution': resolution,
      'status': status,
      'thumbnail_url': thumbnailUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled Project',
      description: map['description']?.toString(),
      aspectRatio: map['aspect_ratio']?.toString() ?? '9:16',
      targetDurationSeconds: map['target_duration_seconds'] is int
          ? map['target_duration_seconds']
          : int.tryParse(map['target_duration_seconds']?.toString() ?? '15') ?? 15,
      fps: map['fps'] is int ? map['fps'] : int.tryParse(map['fps']?.toString() ?? '30') ?? 30,
      resolution: map['resolution']?.toString() ?? '1080p',
      status: map['status']?.toString() ?? 'draft',
      thumbnailUrl: map['thumbnail_url']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
