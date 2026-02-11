import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerControls extends StatefulWidget {
  final AudioPlayer player;
  final String? audioPath;

  const AudioPlayerControls({
    super.key,
    required this.player,
    this.audioPath,
  });

  @override
  State<AudioPlayerControls> createState() => _AudioPlayerControlsState();
}

class _AudioPlayerControlsState extends State<AudioPlayerControls> {
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Subscriptions
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  // Débounce pour slider
  Timer? _debounceTimer;

  // Protection contre clics rapides sur +10s / -10s
  int _rapidClicks = 0;
  Timer? _clickResetTimer;

  @override
  void initState() {
    super.initState();

    _stateSubscription = widget.player.playerStateStream.listen(
      (state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            _isBuffering = state.processingState == ProcessingState.buffering;
          });
        }
      },
      cancelOnError: true,
    );

    _positionSubscription = widget.player.positionStream.listen(
      (pos) {
        if (mounted) setState(() => _position = pos);
      },
      cancelOnError: true,
    );

    _durationSubscription = widget.player.durationStream.listen(
      (dur) {
        if (mounted) setState(() => _duration = dur ?? Duration.zero);
      },
      cancelOnError: true,
    );
  }

  Future<void> _playOrPause() async {
    if (widget.audioPath == null || widget.audioPath!.isEmpty) return;

    final file = File(widget.audioPath!);
    if (!await file.exists()) return;

    try {
      if (_isPlaying) {
        await widget.player.pause();
      } else {
        if (widget.player.processingState == ProcessingState.idle ||
            widget.player.processingState == ProcessingState.completed) {
          await widget.player.setFilePath(widget.audioPath!);
        }
        await widget.player.play();
      }
    } catch (_) {}
  }

  Future<void> _stop() async {
    try {
      await widget.player.stop();
    } catch (_) {}
  }

  Future<void> _handleSeek(bool forward) async {
    if (!mounted) return;

    // Limite : max 2 clics rapides successifs
    _rapidClicks++;
    if (_rapidClicks > 2) {
      // On ignore les clics supplémentaires
      return;
    }

    // Réinitialise le compteur après 1 seconde sans clic
    _clickResetTimer?.cancel();
    _clickResetTimer = Timer(const Duration(seconds: 1), () {
      _rapidClicks = 0;
    });

    try {
      Duration newPos;
      if (forward) {
        newPos = _position + const Duration(seconds: 10);
        newPos = newPos < _duration ? newPos : _duration;
      } else {
        newPos = _position - const Duration(seconds: 10);
        newPos = newPos > Duration.zero ? newPos : Duration.zero;
      }

      await widget.player.seek(newPos);
    } catch (_) {
      // Silence total : pas de flash rouge
    }
  }

  void _debouncedSeek(double value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        try {
          widget.player.seek(Duration(milliseconds: value.toInt()));
        } catch (_) {}
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.audioPath == null || widget.audioPath!.isEmpty) {
      return const SizedBox.shrink();
    }

    final file = File(widget.audioPath!);
    if (!file.existsSync()) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider + temps
          Row(
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                    activeTrackColor: const Color(0xFF4F46E5),
                    inactiveTrackColor: Colors.grey.shade300,
                    thumbColor: const Color(0xFF4F46E5),
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble()),
                    max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                    onChanged: _debouncedSeek,
                  ),
                ),
              ),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Boutons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 28,
                icon: const Icon(Icons.replay_10_rounded),
                color: Colors.grey.shade700,
                onPressed: () => _handleSeek(false),
              ),
              const SizedBox(width: 8),
              IconButton(
                iconSize: 28,
                icon: const Icon(Icons.stop_rounded),
                color: Colors.grey.shade700,
                onPressed: _stop,
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                iconSize: 44,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isBuffering
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : _isPlaying
                          ? const Icon(Icons.pause_rounded, key: ValueKey('pause'))
                          : const Icon(Icons.play_arrow_rounded, key: ValueKey('play')),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _playOrPause,
              ),
              const SizedBox(width: 8),
              IconButton(
                iconSize: 28,
                icon: const Icon(Icons.forward_10_rounded),
                color: Colors.grey.shade700,
                onPressed: () => _handleSeek(true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _debounceTimer?.cancel();
    _clickResetTimer?.cancel();
    super.dispose();
  }
}