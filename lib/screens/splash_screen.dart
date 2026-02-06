import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'dart:convert';

// Imports nécessaires pour la synchro réelle
import '../database/db_helper.dart';
import '../models/partition.dart';
import '../utils/file_helper.dart';

// Import de l'écran principal (adapte le chemin si besoin)
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

  final String _apiUrl = "http://192.168.88.9:8000/api/partitions";
  final String _serverBaseUrl = "http://192.168.88.9:8000/";

  // Animation pour les emojis flottants
  late List<AnimationController> _emojiControllers;
  late List<Animation<double>> _emojiFloats;
  late List<Animation<double>> _emojiFades;

  @override
  void initState() {
    super.initState();

    // Plein écran immersif
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialisation des animations pour 6 emojis
    _emojiControllers = List.generate(6, (_) => AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true));

    _emojiFloats = _emojiControllers.map((c) => Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOutSine),
    )).toList();

    _emojiFades = _emojiControllers.map((c) => Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOut),
    )).toList();

    // Lancer la vraie synchronisation
    _performRealSync();
  }

  Future<void> _performRealSync() async {
    setState(() {
      _syncStatus = "Chargement des partitions...";
      _progress = 0.1;
    });

    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode != 200) throw Exception("Erreur serveur ${response.statusCode}");

      setState(() => _progress = 0.3);

      final List data = jsonDecode(response.body);
      final int total = data.length;
      int processed = 0;

      for (final item in data) {
        final p = Partition.fromJson(item, baseUrl: _serverBaseUrl);

        final existing = await DBHelper.getAllPartitions();
        final match = existing.firstWhere(
          (e) => e.id == p.id,
          orElse: () => Partition(id: 0, titre: '', categorie: '', pdfUrl: '', audioUrl: '', version: 0),
        );

        if (match.id == 0 || (match.version) < (p.version)) {
          // PDF
          if (p.pdfUrl.isNotEmpty) {
            final pdfPath = await FileHelper.getLocalFilePath("${p.titre}.pdf");
            if (!await File(pdfPath).exists()) {
              final file = await FileHelper.downloadFile(p.pdfUrl, "${p.titre}.pdf");
              p.localPdfPath = file.path;
            } else {
              p.localPdfPath = pdfPath;
            }
          }

          // Audio
          if (p.audioUrl.isNotEmpty) {
            final audioPath = await FileHelper.getLocalFilePath("${p.titre}.mp3");
            if (!await File(audioPath).exists()) {
              final file = await FileHelper.downloadFile(p.audioUrl, "${p.titre}.mp3");
              p.localAudioPath = file.path;
            } else {
              p.localAudioPath = audioPath;
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

      // Attendre un peu avant de passer à l'écran principal
      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      debugPrint("Erreur synchro : $e");
      setState(() {
        _syncStatus = "Mode hors-ligne";
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
    for (var c in _emojiControllers) {
      c.dispose();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827), // Bleu nuit / gris-noir élégant
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Logo fixe et parfaitement centré
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 50,
                        spreadRadius: 15,
                        offset: const Offset(0, 25),
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
                          size: 160,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Petits emojis musicaux animés autour du logo
            ...List.generate(8, (index) {
              final angle = index * 45.0;
              final radius = 180.0 + (index % 2) * 40; // alternance de distance
              final offset = Offset(
                radius * math.cos(angle * math.pi / 180),
                radius * math.sin(angle * math.pi / 180),
              );

              final emojis = ['🎵', '🎶', '🎼', '🎤', '🎧', '🎸', '🎹', '🎻'];
              final delay = index * 0.12;

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
                top: MediaQuery.of(context).size.height / 2 + offset.dy - 140,
                left: MediaQuery.of(context).size.width / 2 + offset.dx - 140,
                child: AnimatedOpacity(
                  opacity: _progress > delay ? 0.9 : 0.0,
                  duration: const Duration(milliseconds: 800),
                  child: AnimatedBuilder(
                    animation: _emojiControllers[index % _emojiControllers.length],
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _emojiFloats[index % _emojiFloats.length].value),
                        child: Opacity(
                          opacity: _emojiFades[index % _emojiFades.length].value,
                          child: Text(
                            emojis[index],
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),

            // Barre de progression et statut (en bas)
            Positioned(
              bottom: 80,
              left: 40,
              right: 40,
              child: Column(
                children: [
                  Text(
                    _syncStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
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