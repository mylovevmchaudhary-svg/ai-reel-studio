class SceneAssetModel {
  final String id;
  final String sceneId;
  final String projectId;
  final String ownerId;
  final String assetType; // 'image', 'video', 'generated_image'
  final String assetUrl;
  final String? localPath;
  final String aspectRatio; // '9:16', '16:9', '1:1'
  final bool isActive;
  final DateTime createdAt;

  SceneAssetModel({
    required this.id,
    required this.sceneId,
    required this.projectId,
    required this.ownerId,
    this.assetType = 'image',
    required this.assetUrl,
    this.localPath,
    this.aspectRatio = '9:16',
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  SceneAssetModel copyWith({
    String? id,
    String? sceneId,
    String? projectId,
    String? ownerId,
    String? assetType,
    String? assetUrl,
    String? localPath,
    String? aspectRatio,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return SceneAssetModel(
      id: id ?? this.id,
      sceneId: sceneId ?? this.sceneId,
      projectId: projectId ?? this.projectId,
      ownerId: ownerId ?? this.ownerId,
      assetType: assetType ?? this.assetType,
      assetUrl: assetUrl ?? this.assetUrl,
      localPath: localPath ?? this.localPath,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scene_id': sceneId,
      'project_id': projectId,
      'owner_id': ownerId,
      'asset_type': assetType,
      'asset_url': assetUrl,
      'local_path': localPath,
      'aspect_ratio': aspectRatio,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SceneAssetModel.fromMap(Map<String, dynamic> map) {
    return SceneAssetModel(
      id: map['id']?.toString() ?? '',
      sceneId: map['scene_id']?.toString() ?? '',
      projectId: map['project_id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      assetType: map['asset_type']?.toString() ?? 'image',
      assetUrl: map['asset_url']?.toString() ?? '',
      localPath: map['local_path']?.toString(),
      aspectRatio: map['aspect_ratio']?.toString() ?? '9:16',
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
