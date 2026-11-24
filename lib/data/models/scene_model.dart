class SceneModel {
  final String id;
  final String projectId;
  final String ownerId;
  final int sceneIndex;
  final String? title;
  final String? narration;
  final String? dialogue;
  final String visualPrompt;
  final String? negativePrompt;
  final String cameraAngle;
  final String lighting;
  final double durationSeconds;
  final String transitionType; // 'none', 'fade', 'crossfade', 'slide_left', 'slide_right', 'zoom_in', 'zoom_out'
  final double transitionDuration;
  final String status; // 'draft', 'ready', 'rendered'
  final DateTime createdAt;
  final DateTime updatedAt;

  SceneModel({
    required this.id,
    required this.projectId,
    required this.ownerId,
    required this.sceneIndex,
    this.title,
    this.narration,
    this.dialogue,
    required this.visualPrompt,
    this.negativePrompt,
    this.cameraAngle = 'Cinematic Medium Shot',
    this.lighting = 'Golden Hour Dramatic',
    this.durationSeconds = 5.0,
    this.transitionType = 'fade',
    this.transitionDuration = 0.5,
    this.status = 'draft',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  SceneModel copyWith({
    String? id,
    String? projectId,
    String? ownerId,
    int? sceneIndex,
    String? title,
    String? narration,
    String? dialogue,
    String? visualPrompt,
    String? negativePrompt,
    String? cameraAngle,
    String? lighting,
    double? durationSeconds,
    String? transitionType,
    double? transitionDuration,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SceneModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      ownerId: ownerId ?? this.ownerId,
      sceneIndex: sceneIndex ?? this.sceneIndex,
      title: title ?? this.title,
      narration: narration ?? this.narration,
      dialogue: dialogue ?? this.dialogue,
      visualPrompt: visualPrompt ?? this.visualPrompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      cameraAngle: cameraAngle ?? this.cameraAngle,
      lighting: lighting ?? this.lighting,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      transitionType: transitionType ?? this.transitionType,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'owner_id': ownerId,
      'scene_index': sceneIndex,
      'title': title,
      'narration': narration,
      'dialogue': dialogue,
      'visual_prompt': visualPrompt,
      'negative_prompt': negativePrompt,
      'camera_angle': cameraAngle,
      'lighting': lighting,
      'duration_seconds': durationSeconds,
      'transition_type': transitionType,
      'transition_duration': transitionDuration,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SceneModel.fromMap(Map<String, dynamic> map) {
    return SceneModel(
      id: map['id']?.toString() ?? '',
      projectId: map['project_id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      sceneIndex: map['scene_index'] is int
          ? map['scene_index']
          : int.tryParse(map['scene_index']?.toString() ?? '1') ?? 1,
      title: map['title']?.toString(),
      narration: map['narration']?.toString(),
      dialogue: map['dialogue']?.toString(),
      visualPrompt: map['visual_prompt']?.toString() ?? '',
      negativePrompt: map['negative_prompt']?.toString(),
      cameraAngle: map['camera_angle']?.toString() ?? 'Cinematic Medium Shot',
      lighting: map['lighting']?.toString() ?? 'Golden Hour Dramatic',
      durationSeconds: map['duration_seconds'] is num
          ? (map['duration_seconds'] as num).toDouble()
          : double.tryParse(map['duration_seconds']?.toString() ?? '5.0') ?? 5.0,
      transitionType: map['transition_type']?.toString() ?? 'fade',
      transitionDuration: map['transition_duration'] is num
          ? (map['transition_duration'] as num).toDouble()
          : double.tryParse(map['transition_duration']?.toString() ?? '0.5') ?? 0.5,
      status: map['status']?.toString() ?? 'draft',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
