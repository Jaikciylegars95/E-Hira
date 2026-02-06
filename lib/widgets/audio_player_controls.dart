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

  @override
  void initState() {
    super.initState();
    widget.player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  Future<void> _play() async {
    if (widget.audioPath == null) return;
    try {
      await widget.player.setFilePath(widget.audioPath!);
      await widget.player.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lecture : $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.audioPath == null) {
      return const Text("Aucun fichier audio disponible");
    }

    return Column(
      children: [
        // Slider de progression
        StreamBuilder<Duration>(
          stream: widget.player.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            return StreamBuilder<Duration?>(
              stream: widget.player.durationStream,
              builder: (context, snapshot) {
                final duration = snapshot.data ?? Duration.zero;
                return Slider(
                  value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                  max: duration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    widget.player.seek(Duration(milliseconds: value.toInt()));
                  },
                );
              },
            );
          },
        ),

        // Contrôles
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 40,
              icon: const Icon(Icons.stop),
              onPressed: () async => await widget.player.stop(),
            ),
            const SizedBox(width: 24),
            IconButton.filled(
              iconSize: 56,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _isPlaying
                  ? () async => await widget.player.pause()
                  : _play,
            ),
          ],
        ),
      ],
    );
  }
}