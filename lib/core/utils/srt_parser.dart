import '../../data/models/caption_model.dart';

class SrtParser {
  /// Parses SRT file contents into a list of CaptionModel
  static List<CaptionModel> parse(String srtContent, String projectId, String ownerId) {
    final List<CaptionModel> captions = [];
    final List<String> blocks = srtContent.replaceAll('\r\n', '\n').split('\n\n');

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length >= 3) {
        // Line 0 is index, Line 1 is timestamp range, Line 2+ is text
        final timeLine = lines[1];
        final timeParts = timeLine.split('-->');
        if (timeParts.length == 2) {
          final int startMs = parseTimestampToMs(timeParts[0].trim());
          final int endMs = parseTimestampToMs(timeParts[1].trim());
          final String text = lines.sublist(2).join('\n').trim();

          if (text.isNotEmpty && endMs > startMs) {
            captions.add(
              CaptionModel(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                projectId: projectId,
                ownerId: ownerId,
                startTimeMs: startMs,
                endTimeMs: endMs,
                text: text,
              ),
            );
          }
        }
      }
    }
    return captions;
  }

  /// Exports captions to SRT formatted string
  static String exportToSrt(List<CaptionModel> captions) {
    final StringBuffer sb = StringBuffer();
    // Sort captions by start time
    final sorted = List<CaptionModel>.from(captions)
      ..sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));

    for (int i = 0; i < sorted.length; i++) {
      final c = sorted[i];
      sb.writeln('${i + 1}');
      sb.writeln('${msToTimestamp(c.startTimeMs)} --> ${msToTimestamp(c.endTimeMs)}');
      sb.writeln(c.text);
      sb.writeln();
    }

    return sb.toString();
  }

  static int parseTimestampToMs(String timestamp) {
    try {
      // Format: 00:01:23,456 or 00:01:23.456
      final cleaned = timestamp.replaceAll(',', '.');
      final parts = cleaned.split(':');
      final int hours = int.parse(parts[0]);
      final int minutes = int.parse(parts[1]);
      final secParts = parts[2].split('.');
      final int seconds = int.parse(secParts[0]);
      final int millis = secParts.length > 1 ? int.parse(secParts[1].padRight(3, '0').substring(0, 3)) : 0;
      return (hours * 3600000) + (minutes * 60000) + (seconds * 1000) + millis;
    } catch (_) {
      return 0;
    }
  }

  static String msToTimestamp(int ms) {
    final int hours = ms ~/ 3600000;
    final int remaining1 = ms % 3600000;
    final int minutes = remaining1 ~/ 60000;
    final int remaining2 = remaining1 % 60000;
    final int seconds = remaining2 ~/ 1000;
    final int millis = remaining2 % 1000;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')},${millis.toString().padLeft(3, '0')}';
  }
}
