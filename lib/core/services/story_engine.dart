import 'package:uuid/uuid.dart';
import '../../data/models/story_model.dart';
import '../../data/models/character_model.dart';
import '../../data/models/scene_model.dart';
import '../constants/app_constants.dart';

class GeneratedStoryPackage {
  final StoryModel story;
  final List<CharacterModel> characters;
  final List<SceneModel> scenes;
  final String suggestedBgm;

  GeneratedStoryPackage({
    required this.story,
    required this.characters,
    required this.scenes,
    required this.suggestedBgm,
  });
}

class StoryEngine {
  static const _uuid = Uuid();

  /// Calculate optimal scene count and duration for target video length
  static Map<String, dynamic> calculateSceneBreakdown(int totalDurationSeconds) {
    int sceneCount;
    double perSceneDuration;

    if (totalDurationSeconds <= 5) {
      sceneCount = 1;
      perSceneDuration = totalDurationSeconds.toDouble();
    } else if (totalDurationSeconds <= 10) {
      sceneCount = 2;
      perSceneDuration = 5.0;
    } else if (totalDurationSeconds <= 15) {
      sceneCount = 3;
      perSceneDuration = 5.0;
    } else if (totalDurationSeconds <= 20) {
      sceneCount = 4;
      perSceneDuration = 5.0;
    } else if (totalDurationSeconds <= 30) {
      sceneCount = 6;
      perSceneDuration = 5.0;
    } else if (totalDurationSeconds <= 40) {
      sceneCount = 8;
      perSceneDuration = 5.0;
    } else if (totalDurationSeconds <= 60) {
      sceneCount = 10;
      perSceneDuration = 6.0;
    } else if (totalDurationSeconds <= 180) {
      sceneCount = 15;
      perSceneDuration = 12.0;
    } else if (totalDurationSeconds <= 300) {
      sceneCount = 20;
      perSceneDuration = 15.0;
    } else {
      sceneCount = 25;
      perSceneDuration = (totalDurationSeconds / 25).clamp(5.0, 30.0);
    }

    return {
      'sceneCount': sceneCount,
      'durationPerScene': perSceneDuration,
    };
  }

  /// Intelligent Multi-lingual Story & Scene Generator (Zero-Paid API Requirement)
  static GeneratedStoryPackage generateStory({
    required String projectId,
    required String ownerId,
    required String userPrompt,
    required String language, // 'en', 'hi', 'gu'
    required int totalDurationSeconds,
    required String visualStyle,
    required String aspectRatio,
    String genre = 'Cinematic',
    String tone = 'Viral & Inspiring',
  }) {
    final breakdown = calculateSceneBreakdown(totalDurationSeconds);
    final int sceneCount = breakdown['sceneCount'] as int;
    final double durationPerScene = breakdown['durationPerScene'] as double;

    final String storyId = _uuid.v4();

    // Determine characters based on prompt context
    final List<CharacterModel> characters = _inferCharacters(projectId, ownerId, userPrompt, visualStyle);

    // Build multilingual scene templates
    final List<SceneModel> scenes = [];
    for (int i = 0; i < sceneCount; i++) {
      final sceneIndex = i + 1;
      final sceneData = _generateSceneDetails(
        sceneIndex: sceneIndex,
        totalScenes: sceneCount,
        userPrompt: userPrompt,
        language: language,
        characters: characters,
        visualStyle: visualStyle,
        duration: durationPerScene,
      );

      scenes.add(
        SceneModel(
          id: _uuid.v4(),
          projectId: projectId,
          ownerId: ownerId,
          sceneIndex: sceneIndex,
          title: sceneData['title'],
          narration: sceneData['narration'],
          dialogue: sceneData['dialogue'],
          visualPrompt: sceneData['visualPrompt']!,
          negativePrompt: 'blurry, low quality, distorted face, extra limbs, bad anatomy, text, watermark',
          cameraAngle: sceneData['cameraAngle']!,
          lighting: sceneData['lighting']!,
          durationSeconds: durationPerScene,
          transitionType: i == 0 ? 'none' : (i % 2 == 0 ? 'fade' : 'crossfade'),
          transitionDuration: 0.5,
          status: 'ready',
        ),
      );
    }

    final story = StoryModel(
      id: storyId,
      projectId: projectId,
      ownerId: ownerId,
      promptText: userPrompt,
      promptLanguage: language,
      storyTitle: _generateCatchyTitle(userPrompt, language),
      synopsis: _generateSynopsis(userPrompt, language),
      genre: genre,
      tone: tone,
    );

    return GeneratedStoryPackage(
      story: story,
      characters: characters,
      scenes: scenes,
      suggestedBgm: _suggestBgm(genre),
    );
  }

  static List<CharacterModel> _inferCharacters(
    String projectId,
    String ownerId,
    String userPrompt,
    String visualStyle,
  ) {
    final lower = userPrompt.toLowerCase();
    final List<CharacterModel> characters = [];

    if (lower.contains('warrior') || lower.contains('king') || lower.contains('raja') || lower.contains('shivaji')) {
      characters.add(
        CharacterModel(
          id: _uuid.v4(),
          projectId: projectId,
          ownerId: ownerId,
          name: 'Heroic Ruler / Warrior',
          role: 'Protagonist',
          visualDescription: 'Majestic warrior wearing ornate royal armor with golden filigree, intense focused gaze, royal turban or helmet, commanding demeanor, rendered in $visualStyle',
          outfit: 'Royal battle armor with crimson silk cape',
          voicePersona: 'Deep, authoritative and powerful tone',
        ),
      );
    } else if (lower.contains('girl') || lower.contains('woman') || lower.contains('queen') || lower.contains('female')) {
      characters.add(
        CharacterModel(
          id: _uuid.v4(),
          projectId: projectId,
          ownerId: ownerId,
          name: 'Lead Protagonist (Female)',
          role: 'Main Lead',
          visualDescription: 'Confident, expressive young woman with luminous eyes, modern stylish attire, charismatic aura, styled in $visualStyle',
          outfit: 'Contemporary smart-casual with vibrant jewel-toned palette',
          voicePersona: 'Warm, clear, and inspiring delivery',
        ),
      );
    } else {
      characters.add(
        CharacterModel(
          id: _uuid.v4(),
          projectId: projectId,
          ownerId: ownerId,
          name: 'Main Protagonist',
          role: 'Central Character',
          visualDescription: 'Charismatic protagonist with determined expression, expressive eyes, styled elegantly in $visualStyle',
          outfit: 'Modern tailored jacket with clean aesthetics',
          voicePersona: 'Confident, captivating and cinematic narrator tone',
        ),
      );
    }

    return characters;
  }

  static String _generateCatchyTitle(String prompt, String language) {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isNotEmpty) {
      return cleanPrompt;
    }
    if (language == 'hi') return 'मेरी रील कहानी';
    if (language == 'gu') return 'મારી રીલ વાર્તા';
    return 'My Reel Story';
  }

  static String _generateSynopsis(String prompt, String language) {
    if (language == 'hi') {
      return 'यह एक रोमांचक और प्रेरणादायक यात्रा है जो "$prompt" के अनसुने पहलुओं को जीवंत बनाती है।';
    } else if (language == 'gu') {
      return 'આ એક અત્યંત રોમાંચક અને પ્રેરણાદાયી પ્રવાસ છે જે "$prompt" ના રહસ્યોને સાકાર કરે છે.';
    }
    return 'An epic, cinematic reel exploring the transformative journey of "$prompt", capturing audience attention from the very first frame.';
  }

  static Map<String, String> _generateSceneDetails({
    required int sceneIndex,
    required int totalScenes,
    required String userPrompt,
    required String language,
    required List<CharacterModel> characters,
    required String visualStyle,
    required double duration,
  }) {
    final charDesc = characters.isNotEmpty ? characters.first.visualDescription : 'Protagonist';

    // Different phases of storytelling: Hook, Build-up, Climax, Resolution, CTA
    String title;
    String narration;
    String visualPrompt;
    String cameraAngle;
    String lighting;

    if (sceneIndex == 1) {
      // HOOK
      cameraAngle = 'Wide Angle Establishing View';
      lighting = 'Dramatic Rim Light Studio';
      if (language == 'hi') {
        title = 'Scene 1: रहस्यमयी शुरुआत';
        narration = 'क्या आप जानते हैं इस अविश्वसनीय कहानी के पीछे का सबसे बड़ा सच? आइए देखते हैं...';
      } else if (language == 'gu') {
        title = 'Scene 1: રહસ્યમય શરૂઆત';
        narration = 'શું તમે જાણો છો આ અદ્ભુત ઘટના પાછળનું સાચું રહસ્ય? ચાલો જોઈએ...';
      } else {
        title = 'Scene 1: The Powerful Hook';
        narration = 'Have you ever wondered what truly lies behind this incredible tale? Let us discover...';
      }
      visualPrompt = 'Breathtaking establishing shot of $userPrompt, $charDesc standing in front of an awe-inspiring horizon, atmospheric haze, volumetric light rays, style of $visualStyle, 8K ultra detail.';
    } else if (sceneIndex == totalScenes) {
      // FINALE & CALL TO ACTION
      cameraAngle = 'Low Angle Heroic View';
      lighting = 'Golden Hour Sunset Glow';
      if (language == 'hi') {
        title = 'Scene $sceneIndex: विजय और सीख';
        narration = 'यही है सफलता और साहस का वास्तविक रूप! अगर कहानी पसंद आई, तो फॉलो करना न भूलें।';
      } else if (language == 'gu') {
        title = 'Scene $sceneIndex: વિજય અને પ્રેરણા';
        narration = 'આ જ છે ખરી હિંમત અને સફળતાનું રહસ્ય! આવી બીજી વાર્તાઓ માટે આજે જ ફોલો કરો.';
      } else {
        title = 'Scene $sceneIndex: The Grand Resolution';
        narration = 'This is the true essence of triumph and vision. Follow for more captivating stories!';
      }
      visualPrompt = 'Triumphant low-angle cinematic climax featuring $charDesc looking toward a radiant golden sunrise, epic scale, particles floating in air, $visualStyle, ultra-photorealistic.';
    } else if (sceneIndex == (totalScenes ~/ 2) + 1) {
      // CLIMAX / TURNING POINT
      cameraAngle = 'Extreme Close-Up Emotional';
      lighting = 'Neon Moody Cyberpunk';
      if (language == 'hi') {
        title = 'Scene $sceneIndex: चरम सीमा';
        narration = 'और तभी एक ऐसा मोड़ आया जिसने हर किसी की सोच को हमेशा के लिए बदल दिया!';
      } else if (language == 'gu') {
        title = 'Scene $sceneIndex: અણધાર્યો વળાંક';
        narration = 'અને ત્યારે જ એક એવો અણધાર્યો વળાંક આવ્યો જેણે પરિસ્થિતિને હંમેશ માટે બદલી નાખી!';
      } else {
        title = 'Scene $sceneIndex: The Turning Point';
        narration = 'And right at that pivotal second, an unexpected breakthrough changed everything forever!';
      }
      visualPrompt = 'Intense close-up portrait of $charDesc showing determination and astonishment, glowing atmospheric backlighting, hyper-detailed skin textures, $visualStyle.';
    } else {
      // BUILD UP
      cameraAngle = 'Cinematic Medium Shot';
      lighting = 'Soft Diffused Natural Light';
      if (language == 'hi') {
        title = 'Scene $sceneIndex: संघर्ष और गति';
        narration = 'कदम दर कदम, चुनौतियाँ बढ़ती गईं, लेकिन हौसला कभी कम नहीं हुआ।';
      } else if (language == 'gu') {
        title = 'Scene $sceneIndex: સંઘર્ષ અને પ્રગતિ';
        narration = 'એક પછી એક પડકારો સામે આવ્યા, પરંતુ આગળ વધવાનો ઉત્સાહ ક્યારેય ઓછો ન થયો.';
      } else {
        title = 'Scene $sceneIndex: The Rising Action';
        narration = 'With each passing moment, the stakes grew higher and the journey more intense.';
      }
      visualPrompt = 'Dynamic action medium shot of $charDesc engaged in $userPrompt, cinematic depth of field, motion blur accents, vibrant textures, $visualStyle.';
    }

    return {
      'title': title,
      'narration': narration,
      'dialogue': '',
      'visualPrompt': visualPrompt,
      'cameraAngle': cameraAngle,
      'lighting': lighting,
    };
  }

  static String _suggestBgm(String genre) {
    final lower = genre.toLowerCase();
    if (lower.contains('myth') || lower.contains('historic')) {
      return 'Epic Orchestral War Drums & Flute';
    } else if (lower.contains('horror') || lower.contains('thrill')) {
      return 'Dark Ambient Tension Strings & Sub-Bass';
    } else if (lower.contains('motivat') || lower.contains('inspire')) {
      return 'Uplifting Piano & Orchestral Rise';
    } else if (lower.contains('comedy')) {
      return 'Playful Pizzicato Strings & Upbeat Whistle';
    }
    return 'Modern Lo-Fi Cinematic Beat';
  }
}
