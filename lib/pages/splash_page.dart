import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../database/db_helper.dart';
import '../models/partition.dart';
import '../utils/file_helper.dart';
import '../screens/home_screen.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final String apiUrl = "http://192.168.88.9:8000/api/partitions";
  final String serverBaseUrl = "http://192.168.88.9:8000/";

  String statusMessage = "Chargement...";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startSyncAndNavigate();
  }

  Future<void> _startSyncAndNavigate() async {
    try {
      setState(() => statusMessage = "Récupération des partitions...");

      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        setState(() => statusMessage = "Synchronisation des fichiers...");
        final List data = jsonDecode(response.body);

        for (final item in data) {
          final p = Partition.fromJson(item, baseUrl: serverBaseUrl);

          // Vérifier existence avant download → évite de retélécharger à chaque fois
          if (p.pdfUrl.isNotEmpty) {
            final pdfLocalPath = await FileHelper.getLocalFilePath("${p.titre}.pdf");
            if (!await File(pdfLocalPath).exists()) {
              final file = await FileHelper.downloadFile(p.pdfUrl, "${p.titre}.pdf");
              p.localPdfPath = file.path;
            } else {
              p.localPdfPath = pdfLocalPath;
            }
          }

          if (p.audioUrl.isNotEmpty) {
            final audioLocalPath = await FileHelper.getLocalFilePath("${p.titre}.mp3");
            if (!await File(audioLocalPath).exists()) {
              final file = await FileHelper.downloadFile(p.audioUrl, "${p.titre}.mp3");
              p.localAudioPath = file.path;
            } else {
              p.localAudioPath = audioLocalPath;
            }
          }

          await DBHelper.insertOrUpdatePartition(p);
        }
      } else {
        setState(() => statusMessage = "Erreur serveur (${response.statusCode})");
      }
    } catch (e) {
      print("Erreur sync splash: $e");
      setState(() => statusMessage = "Mode hors-ligne");
      // On continue quand même → on affiche ce qu'on a en local
    }

    if (!mounted) return;

    // Toujours naviguer, même si sync a échoué (offline first)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_note_rounded, size: 90, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                statusMessage,
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}