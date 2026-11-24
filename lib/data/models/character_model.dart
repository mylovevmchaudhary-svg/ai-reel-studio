class CharacterModel {
  final String id;
  final String projectId;
  final String ownerId;
  final String name;
  final String? role;
  final String visualDescription;
  final String? outfit;
  final String? referenceImageUrl;
  final String? voicePersona;
  final DateTime createdAt;
  final DateTime updatedAt;

  CharacterModel({
    required this.id,
    required this.projectId,
    required this.ownerId,
    required this.name,
    this.role,
    required this.visualDescription,
    this.outfit,
    this.referenceImageUrl,
    this.voicePersona,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  CharacterModel copyWith({
    String? id,
    String? projectId,
    String? ownerId,
    String? name,
    String? role,
    String? visualDescription,
    String? outfit,
    String? referenceImageUrl,
    String? voicePersona,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CharacterModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      role: role ?? this.role,
      visualDescription: visualDescription ?? this.visualDescription,
      outfit: outfit ?? this.outfit,
      referenceImageUrl: referenceImageUrl ?? this.referenceImageUrl,
      voicePersona: voicePersona ?? this.voicePersona,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'owner_id': ownerId,
      'name': name,
      'role': role,
      'visual_description': visualDescription,
      'outfit': outfit,
      'reference_image_url': referenceImageUrl,
      'voice_persona': voicePersona,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CharacterModel.fromMap(Map<String, dynamic> map) {
    return CharacterModel(
      id: map['id']?.toString() ?? '',
      projectId: map['project_id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Character',
      role: map['role']?.toString(),
      visualDescription: map['visual_description']?.toString() ?? '',
      outfit: map['outfit']?.toString(),
      referenceImageUrl: map['reference_image_url']?.toString(),
      voicePersona: map['voice_persona']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
