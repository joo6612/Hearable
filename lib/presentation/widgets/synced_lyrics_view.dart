import 'package:flutter/material.dart';
import '../../core/models/lrc_parser.dart';

/// Live karaoke-style synced lyrics view.
/// Auto-scrolls with spring physics; active verse is enlarged & full-white,
/// past/future verses are dim (opacity 0.35) – matching Apple Music reference.
class SyncedLyricsView extends StatefulWidget {
  final String? lrcContent;
  final Duration position;
  final Color accent;
  final TextAlign lyricsAlignment;
  final double lyricsFontSize;
  final bool reflectionGlow;
  final void Function(Duration) onSeek;

  const SyncedLyricsView({
    super.key,
    required this.lrcContent,
    required this.position,
    required this.accent,
    required this.lyricsAlignment,
    required this.lyricsFontSize,
    required this.reflectionGlow,
    required this.onSeek,
  });

  @override
  State<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<SyncedLyricsView> {
  final ScrollController _scrollController = ScrollController();
  List<LyricLine> _lines = [];
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    _parseLines();
  }

  @override
  void didUpdateWidget(SyncedLyricsView old) {
    super.didUpdateWidget(old);
    if (old.lrcContent != widget.lrcContent) _parseLines();
    _maybeScroll();
  }

  void _parseLines() {
    if (widget.lrcContent != null && widget.lrcContent!.isNotEmpty) {
      _lines = LrcParser.parse(widget.lrcContent!);
    } else {
      _lines = [];
    }
  }

  void _maybeScroll() {
    if (_lines.isEmpty || !_scrollController.hasClients) return;
    final activeIdx = LrcParser.activeIndex(_lines, widget.position);
    if (activeIdx == _lastActiveIndex) return;
    _lastActiveIndex = activeIdx;

    // Spring-scroll the active verse into the centre of the view
    const itemHeight = 60.0;
    final viewportHeight = _scrollController.position.viewportDimension;
    final targetOffset =
        (activeIdx * itemHeight) - (viewportHeight / 2) + itemHeight / 2;
    _scrollController.animateTo(
      targetOffset.clamp(
          0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) {
      return Center(
        child: Text(
          widget.lrcContent == null
              ? 'No lyrics available'
              : 'Instrumental',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.45),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final activeIdx = LrcParser.activeIndex(_lines, widget.position);

    // Schedule scroll after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeScroll());

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: _lines.length,
      itemBuilder: (context, idx) {
        final line = _lines[idx];
        final isActive = idx == activeIdx;
        final isPast = idx < activeIdx;

        return GestureDetector(
          onTap: () => widget.onSeek(line.timestamp),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: isActive
                    ? (widget.lyricsFontSize + 4).clamp(22.0, 32.0)
                    : widget.lyricsFontSize,
                fontWeight:
                    isActive ? FontWeight.w900 : FontWeight.w500,
                letterSpacing: isActive ? -0.5 : 0.0,
                color: Colors.white,
                shadows: isActive && widget.reflectionGlow
                    ? [
                        Shadow(
                          color: widget.accent.withValues(alpha: 0.85),
                          blurRadius: 20,
                        ),
                      ]
                    : null,
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: isActive
                    ? 1.0
                    : isPast
                        ? 0.25
                        : 0.35,
                child: Text(
                  line.text,
                  textAlign: widget.lyricsAlignment,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

