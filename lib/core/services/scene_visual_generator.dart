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
    // 1. Dimensions
    double width = 1080;
    double height = 1920;
    if (aspectRatio == '16:9') {
      width = 1920;
      height = 1080;
    } else if (aspectRatio == '1:1') {
      width = 1080;
      height = 1080;
    }

    // 2. Determine Theme
    final themeIndex = (scene.sceneIndex - 1) % _cinematicGradients.length;
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
    final badgeBgPaint = Paint()..color = Colors.black.withOpacity(0.45);
    final badgeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.08, height * 0.06, width * 0.84, height * 0.045),
      const Radius.circular(30),
    );
    canvas.drawRRect(badgeRRect, badgeBgPaint);

    // Header Text
    final headerBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: width * 0.032,
        fontWeight: FontWeight.bold,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const Color(0xFF00F0FF)))
      ..addText('AI REEL STUDIO  •  SCENE ${scene.sceneIndex}')
      ..pop();
    final headerParagraph = headerBuilder.build()..layout(ui.ParagraphConstraints(width: width * 0.84));
    canvas.drawParagraph(headerParagraph, Offset(width * 0.08, height * 0.07));

    // E. Draw Hero Motif in Center
    final heroPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Draw diamond / star emblem
    final center = Offset(width / 2, height * 0.45);
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
    final cardHeight = height * 0.36;
    final cardY = height - cardHeight - (height * 0.04);
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.06, cardY, width * 0.88, cardHeight),
      const Radius.circular(28),
    );

    final cardBg = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, cardY),
        Offset(0, cardY + cardHeight),
        [const Color(0xDD0A0E1A), const Color(0xF5060810)],
      );
    canvas.drawRRect(cardRect, cardBg);

    final cardBorder = Paint()
      ..color = const Color(0xFF8A2BE2).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(cardRect, cardBorder);

    // G. Title Text inside Card
    final titleBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: width * 0.052,
        fontWeight: FontWeight.bold,
      ),
    )
      ..pushStyle(ui.TextStyle(color: Colors.white))
      ..addText(scene.title ?? 'Scene ${scene.sceneIndex}')
      ..pop();
    final titleParagraph = titleBuilder.build()..layout(ui.ParagraphConstraints(width: width * 0.76));
    canvas.drawParagraph(titleParagraph, Offset(width * 0.12, cardY + (cardHeight * 0.1)));

    // H. Narration / Dialogue Text inside Card
    final narrationText = scene.narration ?? scene.visualPrompt;
    final narrationBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: width * 0.038,
        height: 1.4,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const Color(0xFFE2E8F0)))
      ..addText(narrationText.length > 140 ? '${narrationText.substring(0, 137)}...' : narrationText)
      ..pop();
    final narrationParagraph = narrationBuilder.build()..layout(ui.ParagraphConstraints(width: width * 0.76));
    canvas.drawParagraph(narrationParagraph, Offset(width * 0.12, cardY + (cardHeight * 0.34)));

    // I. Duration & Style Pill at bottom of card
    final pillPaint = Paint()..color = const Color(0xFF8A2BE2).withOpacity(0.35);
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.12, cardY + (cardHeight * 0.78), width * 0.35, cardHeight * 0.14),
      const Radius.circular(12),
    );
    canvas.drawRRect(pillRect, pillPaint);

    final pillBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: width * 0.030,
        fontWeight: FontWeight.bold,
      ),
    )
      ..pushStyle(ui.TextStyle(color: Colors.white))
      ..addText('⏱ ${scene.durationSeconds.toStringAsFixed(1)}s  •  $visualStyle')
      ..pop();
    final pillParagraph = pillBuilder.build()..layout(ui.ParagraphConstraints(width: width * 0.35));
    canvas.drawParagraph(pillParagraph, Offset(width * 0.12, cardY + (cardHeight * 0.81)));

    // 4. Render to Image and Encode PNG
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

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
