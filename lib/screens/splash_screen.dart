import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../database/db_helper.dart';
import '../models/partition.dart';
import '../utils/file_helper.dart';

import '../screens/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  bool _isSyncing = true;
  double _progress = 0.0;
  String _syncStatus = "Préparation...";

  final String _apiUrl = "http://192.168.88.247:8000/api/partitions";
  final String _serverBaseUrl = "http://192.168.88.247:8000/";

  // Animations emojis très discrètes
  late List<AnimationController> _emojiControllers;
  late List<Animation<double>> _emojiFloats;
  late List<Animation<double>> _emojiFades;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _emojiControllers = List.generate(6, (_) => AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true));

    _emojiFloats = _emojiControllers.map((c) => Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOutSine),
    )).toList();

    _emojiFades = _emojiControllers.map((c) => Tween<double>(begin: 0.1, end: 0.4).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOut),
    )).toList();

    _performRealSync();
  }

  Future<void> _performRealSync() async {
    setState(() {
      _syncStatus = "Chargement des partitions...";
      _progress = 0.1;
    });

    try {
      debugPrint("Tentative connexion API : $_apiUrl");
      final response = await http.get(Uri.parse(_apiUrl));
      debugPrint("Réponse API : ${response.statusCode}");

      if (response.statusCode != 200) {
        throw Exception("Erreur serveur : ${response.statusCode} - ${response.body}");
      }

      setState(() => _progress = 0.3);

      final List data = jsonDecode(response.body);
      final int total = data.length;
      int processed = 0;

      for (final item in data) {
        final p = Partition.fromJson(item, baseUrl: _serverBaseUrl); // ← CORRECTION ICI

        debugPrint("Partition reçue : ${p.titre} | pdf_url: ${p.pdfUrl} | audio_url: ${p.audioUrl}");

        final existing = await DBHelper.getAllPartitions();
        final match = existing.firstWhere(
          (e) => e.id == p.id,
          orElse: () => Partition(id: 0, titre: '', categorie: '', pdfUrl: '', audioUrl: '', version: 0),
        );

        if (match.id == 0 || (match.version ?? 0) < (p.version ?? 1)) {
          if (p.pdfUrl.isNotEmpty) {
            final pdfPath = await FileHelper.getLocalFilePath("${p.titre}.pdf");
            if (!await File(pdfPath).exists()) {
              try {
                final file = await FileHelper.downloadFile(p.pdfUrl, "${p.titre}.pdf");
                p.localPdfPath = file.path;
                debugPrint("PDF téléchargé : ${p.localPdfPath}");
              } catch (e) {
                debugPrint("Échec PDF ${p.titre} : $e");
              }
            } else {
              p.localPdfPath = pdfPath;
              debugPrint("PDF déjà présent : $pdfPath");
            }
          }

          if (p.audioUrl.isNotEmpty) {
            final audioPath = await FileHelper.getLocalFilePath("${p.titre}.mp3");
            if (!await File(audioPath).exists()) {
              try {
                final file = await FileHelper.downloadFile(p.audioUrl, "${p.titre}.mp3");
                p.localAudioPath = file.path;
                debugPrint("Audio téléchargé : ${p.localAudioPath}");
              } catch (e) {
                debugPrint("Échec audio ${p.titre} : $e");
              }
            } else {
              p.localAudioPath = audioPath;
              debugPrint("Audio déjà présent : $audioPath");
            }
          }

          await DBHelper.insertOrUpdatePartition(p);
        }

        processed++;
        setState(() {
          _progress = 0.3 + (0.6 * (processed / total));
          _syncStatus = "Traitement $processed/$total...";
        });
      }

      setState(() {
        _progress = 1.0;
        _syncStatus = "Prêt !";
      });

      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      debugPrint("Erreur synchro complète : $e");
      setState(() {
        _syncStatus = "Mode hors-ligne (erreur)";
        _progress = 1.0;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var c in _emojiControllers) c.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 8,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white24,
                        child: const Icon(
                          Icons.music_note_rounded,
                          size: 70,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 140,
              child: Text(
                "chante avec style",
                style: TextStyle(
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 1.8,
                  height: 1.2,
                ),
              ),
            ),

            ...List.generate(6, (index) {
              final angle = index * 60.0;
              final radius = 100.0;
              final offset = Offset(
                radius * math.cos(angle * math.pi / 180),
                radius * math.sin(angle * math.pi / 180),
              );

              final emojis = ['🎵', '🎶', '🎼', '🎤', '🎧', '🎸'];

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 2000),
                curve: Curves.easeOut,
                top: MediaQuery.of(context).size.height / 2 + offset.dy - 50,
                left: MediaQuery.of(context).size.width / 2 + offset.dx - 50,
                child: AnimatedOpacity(
                  opacity: _progress > 0.3 && _progress < 0.85 ? 0.45 : 0.0,
                  duration: const Duration(milliseconds: 1500),
                  child: AnimatedBuilder(
                    animation: _emojiControllers[index],
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _emojiFloats[index].value * 0.5),
                        child: Opacity(
                          opacity: _emojiFades[index].value * 0.4,
                          child: Text(
                            emojis[index],
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),

            Positioned(
              bottom: 60,
              left: 40,
              right: 40,
              child: Column(
                children: [
                  Text(
                    _syncStatus,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}