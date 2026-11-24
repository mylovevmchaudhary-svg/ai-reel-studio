import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AudioService {
  static final AudioService instance = AudioService._internal();
  factory AudioService() => instance;
  AudioService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  String? _currentRecordingPath;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Initialize Audio & TTS
  Future<void> init() async {
    try {
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _player.onPlayerStateChanged.listen((state) {
        _isPlaying = state == PlayerState.playing;
      });
    } catch (e) {
      debugPrint('[AudioService] init error: $e');
    }
  }

  /// Start Recording Voiceover
  Future<String?> startRecording({required String sceneId}) async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final voiceDir = Directory(p.join(dir.path, 'voiceovers'));
        if (!await voiceDir.exists()) {
          await voiceDir.create(recursive: true);
        }

        final filePath = p.join(voiceDir.path, 'vo_${sceneId}_${DateTime.now().millisecondsSinceEpoch}.m4a');
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
          path: filePath,
        );

        _isRecording = true;
        _currentRecordingPath = filePath;
        return filePath;
      }
    } catch (e) {
      debugPrint('[AudioService] startRecording error: $e');
    }
    return null;
  }

  /// Stop Recording Voiceover
  Future<String?> stopRecording() async {
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        _isRecording = false;
        return path ?? _currentRecordingPath;
      }
    } catch (e) {
      debugPrint('[AudioService] stopRecording error: $e');
    }
    _isRecording = false;
    return null;
  }

  /// Play Audio from Local Path or URL
  Future<void> playAudio(String pathOrUrl, {double volume = 1.0}) async {
    try {
      await _player.stop();
      await _player.setVolume(volume.clamp(0.0, 1.0));

      if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
        await _player.play(UrlSource(pathOrUrl));
      } else {
        await _player.play(DeviceFileSource(pathOrUrl));
      }
      _isPlaying = true;
    } catch (e) {
      debugPrint('[AudioService] playAudio error: $e');
    }
  }

  /// Stop Audio Playback
  Future<void> stopAudio() async {
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('[AudioService] stopAudio error: $e');
    }
  }

  /// Free Native TTS Speak
  Future<void> speakText(String text, {String language = 'en'}) async {
    try {
      String langCode = 'en-US';
      if (language == 'hi') {
        langCode = 'hi-IN';
      } else if (language == 'gu') {
        langCode = 'gu-IN';
      }
      await _tts.setLanguage(langCode);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[AudioService] speakText error: $e');
    }
  }

  /// Stop TTS Speech
  Future<void> stopTts() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _tts.stop();
  }
}
