import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:just_audio/just_audio.dart';
import '../models/partition.dart';
import '../widgets/audio_player_controls.dart'; // Assure-toi que ce fichier existe (voir ci-dessous)

class DetailScreen extends StatefulWidget {
  final Partition partition;

  const DetailScreen({super.key, required this.partition});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  final _audioPlayer = AudioPlayer(); // Player dédié à cet écran

  @override
  void initState() {
    super.initState();
    _checkPdfFile();

    // Log pour confirmer que l'audio arrive bien
    debugPrint("DetailScreen ouvert pour ${widget.partition.titre}");
    debugPrint("  → localPdfPath  = ${widget.partition.localPdfPath ?? 'NULL'}");
    debugPrint("  → localAudioPath = ${widget.partition.localAudioPath ?? 'NULL'}");
  }

  Future<void> _checkPdfFile() async {
    final path = widget.partition.localPdfPath;
    if (path == null || path.isEmpty) {
      setState(() {
        _errorMessage = "Aucun PDF disponible";
        _isLoading = false;
      });
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      setState(() {
        _errorMessage = "Fichier PDF introuvable";
        _isLoading = false;
      });
      return;
    }

    final size = await file.length();
    debugPrint("PDF ouvert : $path | taille : $size octets");

    if (size < 1000) {
      setState(() {
        _errorMessage = "PDF vide ou corrompu (taille trop petite)";
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Très important pour libérer les ressources audio
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.partition.titre)),
      body: Column(
        children: [
          // Zone PDF (prend tout l'espace sauf le player en bas)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : PDFView(
                        filePath: widget.partition.localPdfPath,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: false,
                        pageFling: false,
                        onError: (error) {
                          debugPrint("Erreur PDF viewer : $error");
                          setState(() => _errorMessage = "Erreur d'affichage PDF : $error");
                        },
                        onRender: (pages) {
                          debugPrint("PDF rendu avec $pages pages");
                        },
                      ),
          ),

          // Player audio en bas (fixe)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: widget.partition.localAudioPath != null &&
                    widget.partition.localAudioPath!.isNotEmpty
                ? AudioPlayerControls(
                    player: _audioPlayer,
                    audioPath: widget.partition.localAudioPath,
                  )
                : const Text(
                    "Aucun fichier audio disponible pour cette partition",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}