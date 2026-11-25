import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../data/models/scene_model.dart';
import '../../data/models/scene_asset_model.dart';
import '../../data/repositories/project_repository.dart';

class SceneVisualGenerator {
  static final SceneVisualGenerator instance = SceneVisualGenerator._internal();
  factory SceneVisualGenerator() => instance;
  SceneVisualGenerator._internal();

  final _uuid = const Uuid();
  final ProjectRepository _repo = ProjectRepository();

  /// Pre-defined rich cinematic themes for scenes
  static final List<List<Color>> _cinematicGradients = [
    [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)], // Deep Ocean
    [const Color(0xFF141E30), const Color(0xFF243B55), const Color(0xFF0B0C10)], // Midnight Cyber
    [const Color(0xFF3A1C71), const Color(0xFFD76D77), const Color(0xFFFFAF7B)], // Sunset Horizon
    [const Color(0xFF1A002C), const Color(0xFF4A0E4E), const Color(0xFF880E4F)], // Royal Majestic
    [const Color(0xFF000428), const Color(0xFF004E92), const Color(0xFF001F3F)], // Cosmic Nebula
    [const Color(0xFF16222A), const Color(0xFF3A6073), const Color(0xFF1A2930)], // Epic Adventure
    [const Color(0xFF232526), const Color(0xFF414345), const Color(0xFF1B1B1B)], // Dramatic Shadow
    [const Color(0xFF42275A), const Color(0xFF734B6D), const Color(0xFFB53471)], // Neon Fantasy
  ];

  /// Generates a high-resolution, cinematic scene image file and saves it to local disk
  Future<SceneAssetModel> generateSceneImage({
    required SceneModel scene,
    required String aspectRatio, // '9:16', '16:9', '1:1'
    required String visualStyle,
    required String storyTitle,
    String? language,
  }) async {
    // 1. Safe, optimized dimensions for fast generation and universal hardware compatibility
    double width = 720;
    double height = 1280;
    if (aspectRatio == '16:9') {
      width = 1280;
      height = 720;
    } else if (aspectRatio == '1:1') {
      width = 720;
      height = 720;
    }

    // 2. Determine Theme
    final themeIndex = (scene.sceneIndex - 1).clamp(0, 9999) % _cinematicGradients.length;
    final gradientColors = _cinematicGradients[themeIndex];

    // 3. Paint using PictureRecorder & Canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // A. Draw Gradient Background
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(width, height),
        gradientColors,
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    // B. Draw Atmospheric Glowing Orbs
    final glowPaint1 = Paint()
      ..shader = ui.Gradient.radial(
        Offset(width * 0.3, height * 0.25),
        width * 0.5,
        [Colors.white.withOpacity(0.18), Colors.transparent],
      );
    canvas.drawCircle(Offset(width * 0.3, height * 0.25), width * 0.5, glowPaint1);

    final glowPaint2 = Paint()
      ..shader = ui.Gradient.radial(
        Offset(width * 0.75, height * 0.7),
        width * 0.6,
        [const Color(0xFF8A2BE2).withOpacity(0.25), Colors.transparent],
      );
    canvas.drawCircle(Offset(width * 0.75, height * 0.7), width * 0.6, glowPaint2);

    // C. Draw Geometric Cinematic Overlays / Grid Accent
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(width / 2, height * 0.45), width * 0.28, linePaint);
    canvas.drawCircle(Offset(width / 2, height * 0.45), width * 0.32, linePaint);

    // D. Draw Top Studio Header Badge
    final badgeBgPaint = Paint()..color = Colors.black.withOpacity(0.5);
    final badgeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.08, height * 0.05, width * 0.84, height * 0.05),
      const Radius.circular(24),
    );
    canvas.drawRRect(badgeRRect, badgeBgPaint);

    // Header Text using TextPainter (Unicode and language safe)
    final headerPainter = TextPainter(
      text: TextSpan(
        text: '🎬 AI REEL STUDIO  •  SCENE ${scene.sceneIndex}',
        style: TextStyle(
          color: const Color(0xFF00F0FF),
          fontSize: width * 0.034,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: width * 0.84);
    headerPainter.paint(
      canvas,
      Offset(width * 0.08 + (width * 0.84 - headerPainter.width) / 2, height * 0.05 + (height * 0.05 - headerPainter.height) / 2),
    );

    // E. Draw Hero Motif in Center
    final heroPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(width / 2, height * 0.42);
    final radius = width * 0.16;
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi) / 4;
      final r = (i % 2 == 0) ? radius : radius * 0.45;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, heroPaint);

    // Fill emblem center
    final heroFill = Paint()..color = Colors.white.withOpacity(0.12);
    canvas.drawPath(path, heroFill);

    // F. Draw Bottom Cinematic Information Card
    final cardHeight = height * 0.38;
    final cardY = height - cardHeight - (height * 0.04);
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.06, cardY, width * 0.88, cardHeight),
      const Radius.circular(24),
    );

    final cardBg = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, cardY),
        Offset(0, cardY + cardHeight),
        [const Color(0xEE0A0E1A), const Color(0xFA060810)],
      );
    canvas.drawRRect(cardRect, cardBg);

    final cardBorder = Paint()
      ..color = const Color(0xFF8A2BE2).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(cardRect, cardBorder);

    // G. Title Text inside Card (Unicode and script safe)
    final sceneTitle = scene.title?.trim().isNotEmpty == true ? scene.title! : 'Scene ${scene.sceneIndex}';
    final titlePainter = TextPainter(
      text: TextSpan(
        text: sceneTitle,
        style: TextStyle(
          color: Colors.white,
          fontSize: width * 0.050,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: width * 0.76);
    titlePainter.paint(canvas, Offset(width * 0.12, cardY + (cardHeight * 0.08)));

    // H. Narration / Dialogue Text inside Card (Handles Hindi, Gujarati, English without crash)
    final narrationText = (scene.narration?.trim().isNotEmpty == true)
        ? scene.narration!
        : ((scene.visualPrompt?.trim().isNotEmpty == true) ? scene.visualPrompt! : 'Cinematic Scene Visual');

    final narrationPainter = TextPainter(
      text: TextSpan(
        text: narrationText,
        style: TextStyle(
          color: const Color(0xFFE2E8F0),
          fontSize: width * 0.036,
          height: 1.35,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 4,
      ellipsis: '...',
    )..layout(maxWidth: width * 0.76);
    narrationPainter.paint(canvas, Offset(width * 0.12, cardY + (cardHeight * 0.28)));

    // I. Duration & Style Pill at bottom of card
    final pillPaint = Paint()..color = const Color(0xFF8A2BE2).withOpacity(0.4);
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.12, cardY + (cardHeight * 0.74), width * 0.45, cardHeight * 0.16),
      const Radius.circular(12),
    );
    canvas.drawRRect(pillRect, pillPaint);

    final pillPainter = TextPainter(
      text: TextSpan(
        text: '⏱ ${scene.durationSeconds.toStringAsFixed(1)}s • $visualStyle',
        style: TextStyle(
          color: Colors.white,
          fontSize: width * 0.030,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: width * 0.43);
    pillPainter.paint(canvas, Offset(width * 0.14, cardY + (cardHeight * 0.78)));

    // 4. Render to Image and Encode PNG
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();
    img.dispose();

    // 5. Save to Local Application Storage
    final appDir = await getApplicationDocumentsDirectory();
    final scenesDir = Directory(p.join(appDir.path, 'projects', scene.projectId, 'scenes'));
    if (!await scenesDir.exists()) {
      await scenesDir.create(recursive: true);
    }

    final filePath = p.join(scenesDir.path, 'scene_${scene.id}_${DateTime.now().millisecondsSinceEpoch}.png');
    final file = File(filePath);
    await file.writeAsBytes(pngBytes);

    // 6. Save Asset Model into Database
    final asset = SceneAssetModel(
      id: _uuid.v4(),
      sceneId: scene.id,
      projectId: scene.projectId,
      ownerId: scene.ownerId,
      assetType: 'image',
      assetUrl: filePath,
      localPath: filePath,
      aspectRatio: aspectRatio,
      isActive: true,
    );

    await _repo.saveSceneAsset(asset);
    return asset;
  }

  /// Automatically generates high-definition visual assets for all scenes in a story
  Future<List<SceneAssetModel>> generateVisualsForProject({
    required List<SceneModel> scenes,
    required String aspectRatio,
    required String visualStyle,
    required String storyTitle,
    String? language,
  }) async {
    final List<SceneAssetModel> results = [];
    for (final scene in scenes) {
      try {
        final asset = await generateSceneImage(
          scene: scene,
          aspectRatio: aspectRatio,
          visualStyle: visualStyle,
          storyTitle: storyTitle,
          language: language,
        );
        results.add(asset);
      } catch (e) {
        debugPrint('[SceneVisualGenerator] Error generating visual for scene ${scene.id}: $e');
      }
    }
    return results;
  }
}
