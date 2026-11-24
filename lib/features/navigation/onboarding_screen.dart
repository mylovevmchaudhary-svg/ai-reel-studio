import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../auth/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.auto_stories_outlined,
      'title': 'AI Story Generator',
      'subtitle': 'Turn simple ideas in Hindi, Gujarati or English into structured video scripts, characters & scene breakdowns in seconds.',
      'gradient': AppColors.purplePinkGradient,
    },
    {
      'icon': Icons.brush_outlined,
      'title': 'Intelligent Scene Prompts',
      'subtitle': 'Generate studio-grade image prompts with lighting, styles (Cinematic, Anime, Bollywood) and aspect ratios ready for ChatGPT & Midjourney.',
      'gradient': const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)]),
    },
    {
      'icon': Icons.mic_external_on_outlined,
      'title': 'Voiceover Studio & Music',
      'subtitle': 'Record clear voiceovers per scene, use free offline multi-lingual TTS, and mix background music with volume sliders.',
      'gradient': const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
    },
    {
      'icon': Icons.view_timeline_outlined,
      'title': 'Multi-Track Timeline Editor',
      'subtitle': 'Trim, split, reorder clips, add transitions, burn in animated subtitles (SRT), and export high-quality MP4 videos.',
      'gradient': AppColors.accentGlowGradient,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Skip', style: TextStyle(color: Colors.white70)),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: page['gradient'] as Gradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (page['gradient'] as Gradient).colors.first.withOpacity(0.35),
                                blurRadius: 28,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(page['icon'] as IconData, size: 54, color: Colors.white),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          page['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          page['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator Dots & Next / Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? AppColors.accentPurple : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
