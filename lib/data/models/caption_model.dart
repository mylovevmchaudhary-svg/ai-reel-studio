class CaptionModel {
  final String id;
  final String projectId;
  final String? sceneId;
  final String ownerId;
  final int startTimeMs;
  final int endTimeMs;
  final String text;
  final String fontFamily;
  final int fontSize;
  final String textColor;
  final String backgroundColor;
  final String animationType; // 'none', 'pop', 'fade', 'typewriter', 'word_by_word'
  final String position; // 'top', 'center', 'bottom'
  final DateTime createdAt;
  final DateTime updatedAt;

  CaptionModel({
    required this.id,
    required this.projectId,
    this.sceneId,
    required this.ownerId,
    required this.startTimeMs,
    required this.endTimeMs,
    required this.text,
    this.fontFamily = 'Roboto',
    this.fontSize = 24,
    this.textColor = '#FFFFFF',
    this.backgroundColor = '#00000088',
    this.animationType = 'pop',
    this.position = 'bottom',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  CaptionModel copyWith({
    String? id,
    String? projectId,
    String? sceneId,
    String? ownerId,
    int? startTimeMs,
    int? endTimeMs,
    String? text,
    String? fontFamily,
    int? fontSize,
    String? textColor,
    String? backgroundColor,
    String? animationType,
    String? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CaptionModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      sceneId: sceneId ?? this.sceneId,
      ownerId: ownerId ?? this.ownerId,
      startTimeMs: startTimeMs ?? this.startTimeMs,
      endTimeMs: endTimeMs ?? this.endTimeMs,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      animationType: animationType ?? this.animationType,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'scene_id': sceneId,
      'owner_id': ownerId,
      'start_time_ms': startTimeMs,
      'end_time_ms': endTimeMs,
      'text': text,
      'font_family': fontFamily,
      'font_size': fontSize,
      'text_color': textColor,
      'background_color': backgroundColor,
      'animation_type': animationType,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CaptionModel.fromMap(Map<String, dynamic> map) {
    return CaptionModel(
      id: map['id']?.toString() ?? '',
      projectId: map['project_id']?.toString() ?? '',
      sceneId: map['scene_id']?.toString(),
      ownerId: map['owner_id']?.toString() ?? '',
      startTimeMs: map['start_time_ms'] is int
          ? map['start_time_ms']
          : int.tryParse(map['start_time_ms']?.toString() ?? '0') ?? 0,
      endTimeMs: map['end_time_ms'] is int
          ? map['end_time_ms']
          : int.tryParse(map['end_time_ms']?.toString() ?? '5000') ?? 5000,
      text: map['text']?.toString() ?? '',
      fontFamily: map['font_family']?.toString() ?? 'Roboto',
      fontSize: map['font_size'] is int
          ? map['font_size']
          : int.tryParse(map['font_size']?.toString() ?? '24') ?? 24,
      textColor: map['text_color']?.toString() ?? '#FFFFFF',
      backgroundColor: map['background_color']?.toString() ?? '#00000088',
      animationType: map['animation_type']?.toString() ?? 'pop',
      position: map['position']?.toString() ?? 'bottom',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
