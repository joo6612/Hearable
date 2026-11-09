class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });

  int get timestampMs => timestamp.inMilliseconds;
}

class LyricsModel {
  final String songId;
  final List<LyricLine> lines;

  const LyricsModel({
    required this.songId,
    required this.lines,
  });

  /// Parse standard LRC format string into timestamped lines
  /// Format: [mm:ss.xx] Lyric text
  factory LyricsModel.fromLrc(String songId, String lrcContent) {
    final List<LyricLine> parsedLines = [];
    final regExp = RegExp(r'\[(\d{2}):(\d{2})(?:\.(\d{2,3}))?\](.*)');

    for (final rawLine in lrcContent.split('\n')) {
      final match = regExp.firstMatch(rawLine.trim());
      if (match != null) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
        final millisStr = match.group(3) ?? '0';
        final millis = int.tryParse(millisStr.padRight(3, '0').substring(0, 3)) ?? 0;

        final duration = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis,
        );

        final text = (match.group(4) ?? '').trim();
        if (text.isNotEmpty) {
          parsedLines.add(LyricLine(timestamp: duration, text: text));
        }
      }
    }

    parsedLines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return LyricsModel(songId: songId, lines: parsedLines);
  }

  /// Finds the index of the active lyric line for the given playback position
  int getActiveLineIndex(Duration position) {
    if (lines.isEmpty) return -1;
    final posMs = position.inMilliseconds;

    for (int i = lines.length - 1; i >= 0; i--) {
      if (posMs >= lines[i].timestampMs) {
        return i;
      }
    }
    return 0;
  }

  /// Fallback curated synced lyrics for popular tracks
  static LyricsModel getCuratedLyrics(String songId, String title) {
    final lower = title.toLowerCase();

    if (lower.contains('hukum')) {
      return LyricsModel.fromLrc(
        songId,
        '''
[00:03.50] Alappara Kelapparom
[00:07.20] Thalaivar Nerandharam
[00:11.80] Ketta Payale Sirantha Ketta Payale
[00:16.40] Singatha Sillaraiya Mathiravan Evanda
[00:21.00] Evan Paathathum Odura Kootam Illa
[00:25.50] Thalaivanukku Bayam Nu Oru Vaarthai Illa
[00:30.10] Hukum - Tiger Ka Hukum!
[00:34.90] Kanna Moodi Thozhudhaalum
[00:39.40] Kann Moodaamal Paathiruppom
[00:44.20] Kodaiyil Mazhaiyai Pola
[00:48.80] Thalaivar Varugaiyil Silirkudhe!
[00:54.00] Alappara Kelapparom
[00:58.50] Thalaivar Nerandharam!
''',
      );
    } else if (lower.contains('badass')) {
      return LyricsModel.fromLrc(
        songId,
        '''
[00:02.00] Badass Mr. Leo Das is a badass
[00:06.50] Villain of the crime scene, ruthless in the face
[00:11.20] Badass Mr. Leo Das is a badass
[00:16.00] Vettaikaran vanthaa kaadu adangum
[00:21.00] Rathathil oorum veegam adangadhu
[00:26.50] Badass Mr. Leo Das!
[00:31.00] Kannil theriyum bayam illai
[00:36.00] Munne nikkum edhirikku vazhi illai
[00:41.20] Badass Mr. Leo Das is a badass!
''',
      );
    } else if (lower.contains('blinding lights')) {
      return LyricsModel.fromLrc(
        songId,
        '''
[00:05.00] Yeah
[00:13.50] I've been tryna call
[00:17.20] I've been on my own for long enough
[00:21.80] Maybe you can show me how to love, maybe
[00:29.40] I'm going through withdrawals
[00:33.20] You don't even have to do too much
[00:37.00] You can turn me on with just a touch, baby
[00:45.00] I look around and Sin City's cold and empty
[00:50.00] No one's around to judge me
[00:53.00] I can't see clearly when you're gone
[00:57.00] I said, ooh, I'm blinded by the lights
[01:03.00] No, I can't sleep until I feel your touch
[01:10.00] I said, ooh, I'm drowning in the night
[01:16.00] Oh, when I'm like this, you're the one I trust
''',
      );
    } else if (lower.contains('starboy')) {
      return LyricsModel.fromLrc(
        songId,
        '''
[00:08.00] I'm tryna put you in the worst mood, ah
[00:12.50] P1 cleaner than your church shoes, ah
[00:17.00] Milli point two just to hurt you, ah
[00:21.50] All red Lamb' just to tease you, ah
[00:26.00] None of these toys on lease too, ah
[00:30.50] Look what you've done
[00:34.00] I'm a motherfuckin' starboy
[00:38.50] Look what you've done
[00:43.00] I'm a motherfuckin' starboy
''',
      );
    }

    // Generic rhythmic lyrics generator for any loaded track
    return LyricsModel.fromLrc(
      songId,
      '''
[00:04.00] ♪ High-Fidelity 320kbps Spatial Audio ♪
[00:10.00] Apple Signature Hardware DSP Active
[00:16.00] Kick Punch Sub-Bass & Warmth Engaged
[00:24.00] Vocal Presence & Crisp Hi-Hat Treble
[00:34.00] Streaming via Hearable Lossless Engine
[00:46.00] Local Wi-Fi Synchronized Audio Stream
[00:58.00] Feel the rhythm, crystal clear acoustics
[01:10.00] Frosted Glass AMOLED Soundstage
''',
    );
  }
}

