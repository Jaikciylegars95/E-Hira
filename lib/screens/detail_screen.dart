import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:just_audio/just_audio.dart';
import '../models/partition.dart';
import '../utils/file_helper.dart';
import '../database/db_helper.dart';
import '../widgets/audio_player_controls.dart';

class DetailScreen extends StatefulWidget {
  final Partition partition;

  const DetailScreen({super.key, required this.partition});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _player = AudioPlayer();
  bool _isLoading = true;
  File? _pdfFile;

  @override
  void initState() {
    super.initState();
    _prepareFiles();
  }

  Future<void> _prepareFiles() async {
    final p = widget.partition;

    try {
      if (p.localPdfPath != null && await File(p.localPdfPath!).exists()) {
        _pdfFile = File(p.localPdfPath!);
      } else if (p.pdfUrl.isNotEmpty) {
        final file = await FileHelper.downloadFile(p.pdfUrl, "${p.titre}.pdf");
        p.localPdfPath = file.path;
        _pdfFile = file;
        await DBHelper.insertOrUpdatePartition(p);
      }

      // Audio sera chargé à la demande dans AudioPlayerControls
    } catch (e) {
      debugPrint("Erreur préparation : $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.partition;

    return Scaffold(
      appBar: AppBar(title: Text(p.titre)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _pdfFile != null
                      ? PDFView(filePath: _pdfFile!.path)
                      : const Center(child: Text("PDF non disponible")),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: AudioPlayerControls(
                    player: _player,
                    audioPath: p.localAudioPath,
                  ),
                ),
              ],
            ),
    );
  }
}