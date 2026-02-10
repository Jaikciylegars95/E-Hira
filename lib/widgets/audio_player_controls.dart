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

  @override
  void initState() {
    super.initState();

    widget.player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isBuffering = state.processingState == ProcessingState.buffering;
        });
      }
    });

    widget.player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    widget.player.durationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    });
  }

  Future<void> _playOrPause() async {
    if (widget.audioPath == null || widget.audioPath!.isEmpty) {
      _showSnack("Aucun fichier audio disponible");
      return;
    }

    final file = File(widget.audioPath!);
    if (!await file.exists()) {
      _showSnack("Fichier audio introuvable");
      return;
    }

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
    } catch (e) {
      _showSnack("Erreur lecture : $e");
    }
  }

  Future<void> _stop() async {
    try {
      await widget.player.stop();
    } catch (e) {
      _showSnack("Erreur stop : $e");
    }
  }

  Future<void> _seekForward() async {
    try {
      final newPos = _position + const Duration(seconds: 10);
      if (newPos < (_duration)) {
        await widget.player.seek(newPos);
      } else {
        await widget.player.seek(_duration);
      }
    } catch (e) {
      _showSnack("Erreur avance : $e");
    }
  }

  Future<void> _seekBackward() async {
    try {
      final newPos = _position - const Duration(seconds: 10);
      if (newPos > Duration.zero) {
        await widget.player.seek(newPos);
      } else {
        await widget.player.seek(Duration.zero);
      }
    } catch (e) {
      _showSnack("Erreur recul : $e");
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black87,
      ),
    );
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
          // Slider + temps (compact)
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
                    onChanged: (value) {
                      widget.player.seek(Duration(milliseconds: value.toInt()));
                    },
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

          // Boutons (plus petits)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reculer 10s
              IconButton(
                iconSize: 28,
                icon: const Icon(Icons.replay_10_rounded),
                color: Colors.grey.shade700,
                onPressed: _seekBackward,
              ),

              const SizedBox(width: 8),

              // Stop
              IconButton(
                iconSize: 28,
                icon: const Icon(Icons.stop_rounded),
                color: Colors.grey.shade700,
                onPressed: _stop,
              ),

              const SizedBox(width: 8),

              // Play/Pause (bouton principal)
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

              // Avancer 10s
              IconButton(
                iconSize: 28,
                icon: const Icon(Icons.forward_10_rounded),
                color: Colors.grey.shade700,
                onPressed: _seekForward,
              ),
            ],
          ),
        ],
      ),
    );
  }
}