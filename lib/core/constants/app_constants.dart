class AppConstants {
  static const String appName = 'AI Reel Studio';
  static const String appTagline = 'Create Studio-Quality Reels & Stories in Minutes';
  static const String appVersion = '1.0.0';

  // Video Duration Presets in seconds
  static const List<int> durationPresets = [
    5,
    10,
    15,
    20,
    30,
    40,
    60,   // 1 minute
    180,  // 3 minutes
    300,  // 5 minutes
    600,  // 10 minutes
  ];

  static String formatDurationLabel(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final int minutes = seconds ~/ 60;
    return '${minutes}m';
  }

  // Aspect Ratios
  static const String ratio9x16 = '9:16';
  static const String ratio16x9 = '16:9';
  static const String ratio1x1 = '1:1';

  static const List<String> aspectRatios = [ratio9x16, ratio16x9, ratio1x1];

  // Resolutions
  static const List<String> resolutions = ['720p (HD)', '1080p (Full HD)'];
  static const List<int> frameRates = [24, 30, 60];

  // Supported Languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'हिंदी (Hindi)',
    'gu': 'ગુજરાતી (Gujarati)',
  };

  // Visual Styles for Image Generation Prompts
  static const List<String> visualStyles = [
    'Cinematic Hyper-Realistic 8K',
    'Anime / Manga Masterpiece',
    '3D Pixar / Disney Animation',
    'Photorealistic Portrait',
    'Cyberpunk Neo-Tokyo Glow',
    'Vintage 70s Bollywood Classic',
    'Vibrant Watercolor & Ink',
    'Dark Fantasy Unreal Engine 5',
    'Graphic Comic Book Vector',
  ];

  // Camera Angles
  static const List<String> cameraAngles = [
    'Cinematic Medium Shot',
    'Extreme Close-Up Emotional',
    'Wide Angle Establishing View',
    'Drone Aerial Top-Down',
    'Low Angle Heroic View',
    'Over the Shoulder (OTS)',
    'Dutch Tilt Dynamic Angle',
  ];

  // Lighting Styles
  static const List<String> lightingStyles = [
    'Golden Hour Sunset Glow',
    'Dramatic Rim Light Studio',
    'Neon Moody Cyberpunk',
    'Soft Diffused Natural Light',
    'Dark Shadows & Chiaroscuro',
    'Bioluminescent Magical Glow',
  ];

  // Transitions
  static const List<String> transitions = [
    'Fade',
    'Crossfade',
    'Slide Left',
    'Slide Right',
    'Zoom In',
    'Zoom Out',
    'None',
  ];

  // Font Choices for Subtitles
  static const List<String> subtitleFonts = [
    'Roboto',
    'Poppins',
    'Montserrat',
    'Oswald',
    'Caveat',
  ];

  // Subtitle Animations
  static const List<String> subtitleAnimations = [
    'Pop',
    'Fade',
    'Typewriter',
    'Word-by-Word (Karaoke)',
    'None',
  ];
}
