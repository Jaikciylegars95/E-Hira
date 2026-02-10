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

    debugPrint("AudioPlayerControls initState | audioPath reçu : ${widget.audioPath ?? 'NULL'}");

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
      _showError("Aucun fichier audio disponible");
      debugPrint("→ AudioPath est vide ou null");
      return;
    }

    final file = File(widget.audioPath!);
    if (!await file.exists()) {
      _showError("Fichier audio introuvable sur le disque");
      debugPrint("→ Fichier n'existe pas : ${widget.audioPath}");
      return;
    }

    final size = await file.length();
    debugPrint("Tentative lecture audio : ${widget.audioPath} | taille ${size} octets");

    try {
      if (_isPlaying) {
        debugPrint("Pause demandé");
        await widget.player.pause();
      } else {
        debugPrint("Play demandé – état actuel : ${widget.player.processingState}");
        if (widget.player.processingState == ProcessingState.idle ||
            widget.player.processingState == ProcessingState.completed) {
          debugPrint("setFilePath en cours sur : ${widget.audioPath}");
          await widget.player.setFilePath(widget.audioPath!);
          debugPrint("setFilePath terminé avec succès");
        }
        debugPrint("Lancement play...");
        await widget.player.play();
        debugPrint("Play lancé avec succès");
      }
    } on PlayerException catch (e) {
      debugPrint("PlayerException : code=${e.code} message=${e.message}");
      _showError("Erreur just_audio : ${e.message ?? e.code}");
    } catch (e, stack) {
      debugPrint("Erreur inattendue lecture audio : $e");
      debugPrint("Stack : $stack");
      _showError("Erreur lecture : $e");
    }
  }

  Future<void> _stop() async {
    try {
      debugPrint("Stop demandé");
      await widget.player.stop();
    } catch (e) {
      debugPrint("Erreur stop : $e");
      _showError("Erreur stop : $e");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    debugPrint("AudioPlayerControls build | audioPath = ${widget.audioPath ?? 'NULL'}");

    if (widget.audioPath == null || widget.audioPath!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "Aucun fichier audio disponible",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    final file = File(widget.audioPath!);
    if (!file.existsSync()) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "Fichier audio introuvable",
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    debugPrint("Boutons audio affichés normalement (chemin valide)");

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(_formatDuration(_position), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
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
              Text(_formatDuration(_duration), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                iconSize: 32,
                icon: const Icon(Icons.stop_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _stop,
              ),

              const SizedBox(width: 32),

              IconButton.filled(
                iconSize: 56,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: _isBuffering
                      ? const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : _isPlaying
                          ? const Icon(Icons.pause_rounded, key: ValueKey('pause'))
                          : const Icon(Icons.play_arrow_rounded, key: ValueKey('play')),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _playOrPause,
              ),
            ],
          ),
        ],
      ),
    );
  }
}