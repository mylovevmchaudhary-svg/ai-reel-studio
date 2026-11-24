class VideoExportModel {
  final String id;
  final String projectId;
  final String ownerId;
  final String? exportUrl;
  final String? localPath;
  final String resolution; // '720p', '1080p'
  final int fps;
  final String aspectRatio; // '9:16', '16:9', '1:1'
  final double? durationSeconds;
  final int? fileSizeBytes;
  final String status; // 'processing', 'completed', 'failed'
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  VideoExportModel({
    required this.id,
    required this.projectId,
    required this.ownerId,
    this.exportUrl,
    this.localPath,
    this.resolution = '1080p',
    this.fps = 30,
    this.aspectRatio = '9:16',
    this.durationSeconds,
    this.fileSizeBytes,
    this.status = 'completed',
    this.errorMessage,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  VideoExportModel copyWith({
    String? id,
    String? projectId,
    String? ownerId,
    String? exportUrl,
    String? localPath,
    String? resolution,
    int? fps,
    String? aspectRatio,
    double? durationSeconds,
    int? fileSizeBytes,
    String? status,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return VideoExportModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      ownerId: ownerId ?? this.ownerId,
      exportUrl: exportUrl ?? this.exportUrl,
      localPath: localPath ?? this.localPath,
      resolution: resolution ?? this.resolution,
      fps: fps ?? this.fps,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'owner_id': ownerId,
      'export_url': exportUrl,
      'local_path': localPath,
      'resolution': resolution,
      'fps': fps,
      'aspect_ratio': aspectRatio,
      'duration_seconds': durationSeconds,
      'file_size_bytes': fileSizeBytes,
      'status': status,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory VideoExportModel.fromMap(Map<String, dynamic> map) {
    return VideoExportModel(
      id: map['id']?.toString() ?? '',
      projectId: map['project_id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      exportUrl: map['export_url']?.toString(),
      localPath: map['local_path']?.toString(),
      resolution: map['resolution']?.toString() ?? '1080p',
      fps: map['fps'] is int ? map['fps'] : int.tryParse(map['fps']?.toString() ?? '30') ?? 30,
      aspectRatio: map['aspect_ratio']?.toString() ?? '9:16',
      durationSeconds: map['duration_seconds'] is num
          ? (map['duration_seconds'] as num).toDouble()
          : double.tryParse(map['duration_seconds']?.toString() ?? ''),
      fileSizeBytes: map['file_size_bytes'] is int
          ? map['file_size_bytes']
          : int.tryParse(map['file_size_bytes']?.toString() ?? ''),
      status: map['status']?.toString() ?? 'completed',
      errorMessage: map['error_message']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      completedAt: map['completed_at'] != null ? DateTime.tryParse(map['completed_at'].toString()) : null,
    );
  }
}
