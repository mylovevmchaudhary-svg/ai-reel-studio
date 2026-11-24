import 'dart:convert';

class StoryModel {
  final String id;
  final String projectId;
  final String ownerId;
  final String promptText;
  final String promptLanguage; // 'en', 'hi', 'gu'
  final String storyTitle;
  final String? synopsis;
  final String genre;
  final String tone;
  final Map<String, dynamic>? rawResponse;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoryModel({
    required this.id,
    required this.projectId,
    required this.ownerId,
    required this.promptText,
    this.promptLanguage = 'en',
    required this.storyTitle,
    this.synopsis,
    this.genre = 'Cinematic',
    this.tone = 'Engaging',
    this.rawResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  StoryModel copyWith({
    String? id,
    String? projectId,
    String? ownerId,
    String? promptText,
    String? promptLanguage,
    String? storyTitle,
    String? synopsis,
    String? genre,
    String? tone,
    Map<String, dynamic>? rawResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoryModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      ownerId: ownerId ?? this.ownerId,
      promptText: promptText ?? this.promptText,
      promptLanguage: promptLanguage ?? this.promptLanguage,
      storyTitle: storyTitle ?? this.storyTitle,
      synopsis: synopsis ?? this.synopsis,
      genre: genre ?? this.genre,
      tone: tone ?? this.tone,
      rawResponse: rawResponse ?? this.rawResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'owner_id': ownerId,
      'prompt_text': promptText,
      'prompt_language': promptLanguage,
      'story_title': storyTitle,
      'synopsis': synopsis,
      'genre': genre,
      'tone': tone,
      'raw_response': rawResponse != null ? jsonEncode(rawResponse) : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? parsedJson;
    if (map['raw_response'] != null) {
      if (map['raw_response'] is Map<String, dynamic>) {
        parsedJson = map['raw_response'];
      } else if (map['raw_response'] is String) {
        try {
          parsedJson = jsonDecode(map['raw_response']);
        } catch (_) {}
      }
    }

    return StoryModel(
      id: map['id']?.toString() ?? '',
      projectId: map['project_id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      promptText: map['prompt_text']?.toString() ?? '',
      promptLanguage: map['prompt_language']?.toString() ?? 'en',
      storyTitle: map['story_title']?.toString() ?? 'Untitled Story',
      synopsis: map['synopsis']?.toString(),
      genre: map['genre']?.toString() ?? 'Cinematic',
      tone: map['tone']?.toString() ?? 'Engaging',
      rawResponse: parsedJson,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
