import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/prompt_generator.dart';
import '../../../core/services/story_engine.dart';
import '../../../core/services/scene_visual_generator.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/caption_model.dart';
import '../../../data/models/voiceover_model.dart';
import '../../../data/repositories/project_repository.dart';
import 'story_editor_screen.dart';

class StoryPromptScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;
  final String language; // 'en', 'hi', 'gu'
  final int durationSeconds;
  final String aspectRatio;
  final String visualStyle;

  const StoryPromptScreen({
    Key? key,
    required this.projectId,
    required this.projectTitle,
    required this.language,
    required this.durationSeconds,
    required this.aspectRatio,
    required this.visualStyle,
  }) : super(key: key);

  @override
  State<StoryPromptScreen> createState() => _StoryPromptScreenState();
}

class _StoryPromptScreenState extends State<StoryPromptScreen> {
  final _promptController = TextEditingController();
  final _repo = ProjectRepository();
  bool _isGenerating = false;

  final List<Map<String, String>> _samplePromptsEn = [
    {'title': 'The Forgotten Fort', 'prompt': 'A young archaeologist unearths a concealed underground passage beneath an ancient Indian fortress.'},
    {'title': 'The Last Cyber-Samurai', 'prompt': 'In a rain-soaked neon cyberpunk city, an elite warrior protects the last memory chip of humanity.'},
    {'title': 'Never Give Up', 'prompt': 'An underdog athlete battles through injuries and self-doubt to conquer the world marathon championship.'},
    {'title': 'The Solar Mystery', 'prompt': 'A space probe approaches the edge of the solar system and detects an unexplained harmonic signal.'},
  ];

  final List<Map<String, String>> _samplePromptsHi = [
    {'title': 'वीर शिवाजी का साहस', 'prompt': 'छत्रपति शिवाजी महाराज की वो रणनीति जिसने दुर्ग जीतने का नया इतिहास रच दिया।'},
    {'title': 'सफलता का रहस्य', 'prompt': 'एक साधारण गाँव के लड़के की प्रेरणादायक यात्रा जिसने अपनी मेहनत से देश का नाम रोशन किया।'},
    {'title': 'प्राचीन भारत के रहस्य', 'prompt': 'सिंधु घाटी सभ्यता के वो अनसुलझे रहस्य जो आज भी वैज्ञानिकों को हैरान कर देते हैं।'},
  ];

  final List<Map<String, String>> _samplePromptsGu = [
    {'title': 'ગુજરાતનો ઐતિહાસિક વારસો', 'prompt': 'પાટણની રાણકી વાવની શિલ્પકળા અને રાણી ઉદયમતિના અદભુત પ્રેમની અમર ગાથા.'},
    {'title': 'સફળતાનો સંઘર્ષ', 'prompt': 'સખત પરિશ્રમ અને અડગ મનોબળથી મુશ્કેલીઓને હરાવીને સફળતા મેળવવાની પ્રેરણાદાયી કહાની.'},
    {'title': 'ગીરના સિંહ અને વન્યજીવન', 'prompt': 'ગીરના જંગલોમાં એશિયાટિક સિંહોનું જીવન અને પ્રકૃતિની અનોખી સુંદરતા.'},
  ];

  List<Map<String, String>> get _activeSamples {
    if (widget.language == 'hi') return _samplePromptsHi;
    if (widget.language == 'gu') return _samplePromptsGu;
    return _samplePromptsEn;
  }

  Future<void> _generateStory() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select a story prompt')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final package = StoryEngine.generateStory(
        projectId: widget.projectId,
        ownerId: SupabaseService.instance.currentUserId,
        userPrompt: text,
        language: widget.language,
        totalDurationSeconds: widget.durationSeconds,
        visualStyle: widget.visualStyle,
        aspectRatio: widget.aspectRatio,
      );

      // Save story, characters, and scenes into local SQLite + Supabase
      await _repo.saveStory(package.story);
      for (final c in package.characters) {
        await _repo.saveCharacter(c);
      }
      for (final s in package.scenes) {
        await _repo.saveScene(s);
      }

      // 1. Auto-generate Real High-Res Visual Photos for all scenes
      await SceneVisualGenerator.instance.generateVisualsForProject(
        scenes: package.scenes,
        aspectRatio: widget.aspectRatio,
        visualStyle: widget.visualStyle,
        storyTitle: package.story.storyTitle,
        language: widget.language,
      );

      // 2. Auto-generate Synchronized Captions & Voiceover links for all scenes
      double cumulativeSec = 0.0;
      for (final s in package.scenes) {
        final startMs = (cumulativeSec * 1000).toInt();
        cumulativeSec += s.durationSeconds;
        final endMs = (cumulativeSec * 1000).toInt();

        final caption = CaptionModel(
          id: const Uuid().v4(),
          projectId: widget.projectId,
          ownerId: package.story.ownerId,
          sceneId: s.id,
          startTimeMs: startMs,
          endTimeMs: endMs,
          text: s.narration ?? s.title ?? 'Scene',
        );
        await _repo.saveCaption(caption);

        // Auto synthesize offline audio file if narration exists
        String? voPath;
        if (s.narration != null && s.narration!.trim().isNotEmpty) {
          try {
            voPath = await AudioService.instance.synthesizeToFile(
              s.narration!,
              s.id,
              language: widget.language,
            );
          } catch (_) {}
        }

        final vo = VoiceoverModel(
          id: const Uuid().v4(),
          sceneId: s.id,
          projectId: widget.projectId,
          ownerId: package.story.ownerId,
          sourceType: 'tts',
          durationSeconds: s.durationSeconds,
          localPath: voPath,
        );
        await _repo.saveVoiceover(vo);
      }

      if (mounted) {
        setState(() => _isGenerating = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StoryEditorScreen(
              projectId: widget.projectId,
              story: package.story,
              characters: package.characters,
              scenes: package.scenes,
              suggestedBgm: package.suggestedBgm,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating story: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _copyChatGptPrompt() {
    final prompt = PromptGenerator.buildChatGptStoryPrompt(
      userIdea: _promptController.text.trim().isNotEmpty
          ? _promptController.text.trim()
          : 'Inspiring story of overcoming challenges',
      language: widget.language,
      targetDurationSeconds: widget.durationSeconds,
      sceneCount: StoryEngine.calculateSceneBreakdown(widget.durationSeconds)['sceneCount'] as int,
    );

    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ChatGPT Master Prompt copied to clipboard! 📋 Paste into ChatGPT or any AI.'),
        backgroundColor: AppColors.accentPurple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Story Prompt Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copy ChatGPT Prompt',
            onPressed: _copyChatGptPrompt,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardNavy,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.accentCyan, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Target: ${widget.durationSeconds}s • Language: ${widget.language.toUpperCase()} • Style: ${widget.visualStyle}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Prompt Input Field
            const Text(
              'Enter Story Idea / Prompt',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _promptController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.language == 'hi'
                    ? 'यहाँ अपनी कहानी का विचार लिखें...'
                    : (widget.language == 'gu'
                        ? 'અહીં તમારી વાર્તાનો વિચાર લખો...'
                        : 'Describe your reel idea, character, theme or message...'),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // Sample Ideas
            const Text(
              'Inspiration Templates',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Column(
              children: _activeSamples.map((sample) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      _promptController.text = sample['prompt']!;
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.warning),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sample['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                const SizedBox(height: 2),
                                Text(sample['prompt']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
                              ],
                            ),
                          ),
                          const Icon(Icons.add_circle_outline, size: 18, color: AppColors.accentPurple),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Generate Story Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateStory,
                icon: _isGenerating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isGenerating ? 'Generating Story & Scenes...' : 'Generate Story & Scenes',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.accentPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
