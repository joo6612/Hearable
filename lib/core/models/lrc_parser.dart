/// A single parsed line from an .lrc file
class LyricLine {
  final Duration timestamp;
  final String text;
  const LyricLine({required this.timestamp, required this.text});
}

/// Parses raw LRC (or plain text) content into a list of [LyricLine]s.
class LrcParser {
  static final _timePattern = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');

  static List<LyricLine> parse(String lrc) {
    final lines = <LyricLine>[];
    for (final raw in lrc.split('\n')) {
      final stripped = raw.trim();
      if (stripped.isEmpty) continue;

      // Check for LRC timestamp tags
      final match = _timePattern.firstMatch(stripped);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centisStr = match.group(3)!;
        final centis = int.parse(centisStr);
        final ms = centisStr.length == 2 ? centis * 10 : centis;

        final ts = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: ms,
        );

        // Text is everything after the last timestamp bracket
        final text = stripped.replaceAll(_timePattern, '').trim();
        if (text.isNotEmpty) {
          lines.add(LyricLine(timestamp: ts, text: text));
        }
      } else {
        // Plain lyric line without timestamp – treat as offset 0
        if (lines.isEmpty) {
          lines.add(
              LyricLine(timestamp: Duration.zero, text: stripped));
        }
      }
    }
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }

  /// Find the active line index for a given playback position.
  static int activeIndex(List<LyricLine> lines, Duration position) {
    if (lines.isEmpty) return -1;
    int idx = 0;
    for (int i = 0; i < lines.length; i++) {
      if (position >= lines[i].timestamp) {
        idx = i;
      } else {
        break;
      }
    }
    return idx;
  }
}

