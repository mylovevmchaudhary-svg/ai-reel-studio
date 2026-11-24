import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MediaService {
  static final MediaService instance = MediaService._internal();
  factory MediaService() => instance;
  MediaService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery, required String projectId}) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (picked != null) {
        return await saveFileToProject(File(picked.path), projectId, subDir: 'images');
      }
    } catch (e) {
      debugPrint('[MediaService] pickImage error: $e');
    }
    return null;
  }

  /// Pick an audio file (.mp3, .wav, .m4a, .aac)
  Future<File?> pickAudioFile({required String projectId}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
      );

      if (result != null && result.files.single.path != null) {
        return await saveFileToProject(File(result.files.single.path!), projectId, subDir: 'audio');
      }
    } catch (e) {
      debugPrint('[MediaService] pickAudioFile error: $e');
    }
    return null;
  }

  /// Pick an SRT subtitle file
  Future<String?> pickSrtFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['srt', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('[MediaService] pickSrtFile error: $e');
    }
    return null;
  }

  /// Saves a file into the application documents directory under projects/{projectId}/{subDir}/
  Future<File> saveFileToProject(File sourceFile, String projectId, {required String subDir}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(appDir.path, 'projects', projectId, subDir));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final ext = p.extension(sourceFile.path);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$ext';
    final targetFile = File(p.join(targetDir.path, fileName));
    return await sourceFile.copy(targetFile.path);
  }

  /// Get storage stats
  Future<Map<String, dynamic>> getStorageUsage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      int totalBytes = 0;
      int projectCount = 0;

      final projectsDir = Directory(p.join(appDir.path, 'projects'));
      if (await projectsDir.exists()) {
        final list = projectsDir.listSync(recursive: true);
        for (final item in list) {
          if (item is File) {
            totalBytes += await item.length();
          }
        }
        projectCount = projectsDir.listSync().whereType<Directory>().length;
      }

      final mb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
      return {
        'totalMb': mb,
        'projectCount': projectCount,
        'totalBytes': totalBytes,
      };
    } catch (e) {
      return {'totalMb': '0.0', 'projectCount': 0, 'totalBytes': 0};
    }
  }

  /// Clear all cache and temporary media
  Future<void> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (e) {
      debugPrint('[MediaService] clearCache error: $e');
    }
  }
}
