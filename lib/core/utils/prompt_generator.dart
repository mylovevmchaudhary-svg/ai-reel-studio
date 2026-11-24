class PromptGenerator {
  /// Builds a complete, copyable prompt for external image generators (ChatGPT, Midjourney, Stable Diffusion)
  static String buildImageGenerationPrompt({
    required String sceneDescription,
    required String characterDescription,
    required String visualStyle,
    required String cameraAngle,
    required String lighting,
    required String aspectRatio,
  }) {
    final StringBuffer sb = StringBuffer();
    sb.writeln('Masterpiece photograph/artwork depicting: $sceneDescription.');
    
    if (characterDescription.trim().isNotEmpty) {
      sb.writeln('Subject details: $characterDescription.');
    }
    
    sb.writeln('Visual Style: $visualStyle.');
    sb.writeln('Camera Perspective: $cameraAngle.');
    sb.writeln('Lighting & Atmosphere: $lighting.');
    sb.writeln('Quality: hyper-detailed, intricate textures, 8k resolution, cinematic composition, color graded.');
    
    // Add aspect ratio flags
    if (aspectRatio == '9:16') {
      sb.writeln('Format: 9:16 vertical reel / portrait, --ar 9:16');
    } else if (aspectRatio == '16:9') {
      sb.writeln('Format: 16:9 landscape widescreen, --ar 16:9');
    } else {
      sb.writeln('Format: 1:1 square, --ar 1:1');
    }
    
    sb.writeln('Negative prompt: low quality, blurry, distorted anatomy, extra limbs, watermark, text, grainy, low resolution.');
    return sb.toString();
  }

  /// Builds a ChatGPT Master Prompt to generate scenes & scripts
  static String buildChatGptStoryPrompt({
    required String userIdea,
    required String language,
    required int targetDurationSeconds,
    required int sceneCount,
  }) {
    return '''
Act as a professional viral short-form video director and screenwriter.
I want to create a video of duration $targetDurationSeconds seconds ($sceneCount scenes, ~${(targetDurationSeconds / sceneCount).toStringAsFixed(1)}s each).

Topic / Idea: "$userIdea"
Language: $language

Generate a JSON object with this exact structure:
{
  "title": "Short Catchy Title",
  "synopsis": "Brief 1-2 sentence hook",
  "genre": "Genre name",
  "characters": [
    {
      "name": "Character Name",
      "visualDescription": "Detailed visual appearance for image consistency",
      "role": "Role in the story"
    }
  ],
  "scenes": [
    {
      "sceneIndex": 1,
      "title": "Scene 1 Headline",
      "narration": "Spoken voiceover script in $language (concise, fits duration)",
      "visualPrompt": "Detailed visual description for image generation",
      "cameraAngle": "Cinematic Medium Shot",
      "lighting": "Golden Hour Dramatic",
      "durationSeconds": ${(targetDurationSeconds / sceneCount).toStringAsFixed(1)}
    }
  ]
}
''';
  }
}
