import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../database/db_helper.dart';
import '../models/partition.dart';
import '../widgets/custom_button.dart';
import 'detail_screen.dart';
import 'package:http/http.dart' as http;
import '../utils/file_helper.dart';

// Widget AudioPlayerControls (inchangé ici, mais inclus pour complétude)
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          Row(
            children: [
              Text(_formatDuration(_position), style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
              Text(_formatDuration(_duration), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 28,
                icon: const Icon(Icons.replay_10_rounded),
                color: Colors.grey.shade700,
                onPressed: () async {
                  try {
                    final newPos = _position - const Duration(seconds: 10);
                    await widget.player.seek(newPos > Duration.zero ? newPos : Duration.zero);
                  } catch (_) {}
                },
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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
                onPressed: () async {
                  try {
                    final newPos = _position + const Duration(seconds: 10);
                    await widget.player.seek(newPos < _duration ? newPos : _duration);
                  } catch (_) {}
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==============================================
// HomeScreen – avec bouton favori fonctionnel
// ==============================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Partition> _partitions = [];
  List<Partition> _filtered = [];
  bool _isLoading = true;
  bool _showFavoritesOnly = false;

  final _searchController = TextEditingController();
  final _player = AudioPlayer();

  final String _apiUrl = "http://192.168.88.249:8000/api/partitions";
  final String _serverBaseUrl = "http://192.168.88.249:8000/";

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();

    _initApp();
    _searchController.addListener(_onSearchChanged);

    _player.playerStateStream.listen((state) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initApp() async {
    await _loadLocalPartitions();
    _syncWithServerInBackground();
  }

  Future<void> _loadLocalPartitions() async {
    try {
      final local = await DBHelper.getAllPartitions();
      if (!mounted) return;
      setState(() {
        _partitions = local;
        _filtered = _showFavoritesOnly
            ? local.where((p) => p.isFavorite).toList()
            : local;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur chargement local : $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncWithServerInBackground() async {
    // Ton code de synchro reste inchangé (il est déjà propre)
    debugPrint("\n" + "═" * 80);
    debugPrint("=== LANCEMENT SYNCHRO AUDIO/PDF - ${DateTime.now()} ===");
    debugPrint("API URL : $_apiUrl");
    debugPrint("Base URL : $_serverBaseUrl");

    try {
      debugPrint("Envoi requête HTTP GET...");
      final uri = Uri.parse(_apiUrl);
      debugPrint("URI parsée : $uri");

      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      debugPrint("Réponse reçue ! Status : ${response.statusCode}");
      debugPrint("Headers : ${response.headers}");
      debugPrint("Taille body : ${response.body.length} caractères");

      if (response.statusCode != 200) {
        debugPrint("ERREUR API - Body (début) : ${response.body.substring(0, response.body.length.clamp(0, 300))}...");
        return;
      }

      debugPrint("Décodage JSON...");
      final List data = jsonDecode(response.body);
      debugPrint("Nombre de partitions dans l'API : ${data.length}");

      if (data.isEmpty) {
        debugPrint("!!! AUCUNE PARTITION RENVOYÉE PAR L'API !!!");
        return;
      }

      bool hasChanges = false;

      for (int i = 0; i < data.length; i++) {
        final item = data[i];
        debugPrint("\nPartition #${i+1} / ${data.length} - ID: ${item['id'] ?? 'inconnu'}");

        final p = Partition.fromJson(item, baseUrl: _serverBaseUrl);
        debugPrint("  Titre          : ${p.titre}");
        debugPrint("  Catégorie      : ${p.categorie}");
        debugPrint("  PDF URL        : ${p.pdfUrl}");
        debugPrint("  Audio URL      : ${p.audioUrl}");
        debugPrint("  Version        : ${p.version}");

        final existing = _partitions.firstWhereOrNull((e) => e.id == p.id);
        debugPrint("  Existe déjà ?  : ${existing != null ? 'Oui (version ${existing.version})' : 'Non'}");

        if (existing == null || (existing.version ?? 0) < (p.version ?? 1)) {
          debugPrint("  → Mise à jour nécessaire");

          // PDF (inchangé)
          if (p.pdfUrl.isNotEmpty) {
            final path = await FileHelper.getLocalFilePath("${p.titre}.pdf");
            debugPrint("PDF - chemin calculé : $path");

            final file = File(path);

            bool shouldDownload = true;

            if (await file.exists()) {
              final size = await file.length();
              debugPrint("PDF - fichier existe déjà | taille : $size octets");
              if (size > 1000) {
                debugPrint("PDF - fichier semble valide → on garde le chemin existant");
                p.localPdfPath = path;
                shouldDownload = false;
              } else {
                debugPrint("PDF - fichier vide ou corrompu → suppression et re-téléchargement");
                await file.delete();
              }
            }

            if (shouldDownload) {
              debugPrint("PDF - lancement téléchargement...");
              try {
                final downloadedFile = await FileHelper.downloadFile(p.pdfUrl, "${p.titre}.pdf");
                p.localPdfPath = downloadedFile.path;
                final finalSize = await File(p.localPdfPath!).length();
                debugPrint("PDF - téléchargement terminé | chemin : ${p.localPdfPath}");
                debugPrint("PDF - taille finale : $finalSize octets");
              } catch (e, stack) {
                debugPrint("PDF - ÉCHEC TÉLÉCHARGEMENT : $e");
                debugPrint("Stack : $stack");
              }
            }
          } else {
            debugPrint("PDF - Pas d'URL PDF dans l'API");
          }

          // AUDIO (inchangé)
          if (p.audioUrl.isNotEmpty) {
            final path = await FileHelper.getLocalFilePath("${p.titre}.mp3");
            debugPrint("Audio - chemin calculé : $path");

            final file = File(path);

            bool shouldDownload = true;

            if (await file.exists()) {
              final size = await file.length();
              debugPrint("Audio - fichier existe déjà | taille : $size octets");
              if (size > 1000) {
                debugPrint("Audio - fichier semble valide → on garde le chemin existant");
                p.localAudioPath = path;
                shouldDownload = false;
              } else {
                debugPrint("Audio - fichier vide ou corrompu → suppression et re-téléchargement");
                await file.delete();
              }
            }

            if (shouldDownload) {
              debugPrint("Audio - lancement téléchargement...");
              try {
                final downloadedFile = await FileHelper.downloadFile(p.audioUrl, "${p.titre}.mp3");
                p.localAudioPath = downloadedFile.path;
                final finalSize = await File(p.localAudioPath!).length();
                debugPrint("Audio - téléchargement terminé | chemin : ${p.localAudioPath}");
                debugPrint("Audio - taille finale : $finalSize octets");
              } catch (e, stack) {
                debugPrint("Audio - ÉCHEC TÉLÉCHARGEMENT : $e");
                debugPrint("Stack : $stack");
              }
            }
          } else {
            debugPrint("Audio - Pas d'URL audio dans l'API");
          }

          debugPrint("  Sauvegarde en base...");
          await DBHelper.insertOrUpdatePartition(p);
          debugPrint("  Sauvegarde OK");
          hasChanges = true;
        } else {
          debugPrint("  Pas de mise à jour nécessaire (version déjà à jour)");
        }
      }

      if (hasChanges) {
        debugPrint("Des changements ont été effectués → rechargement local");
        await _loadLocalPartitions();
      } else {
        debugPrint("Aucun changement détecté");
      }

      debugPrint("=== SYNCHRO TERMINÉE AVEC SUCCÈS ===");
    } catch (e, stack) {
      debugPrint("ERREUR GLOBALE SYNCHRO : $e");
      debugPrint("Stack trace : $stack");
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = _partitions.where((p) {
        return p.titre.toLowerCase().contains(query) ||
            p.categorie.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 38,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: AnimatedScale(
              scale: _showFavoritesOnly ? 1.25 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Icon(
                _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                color: _showFavoritesOnly ? Colors.redAccent : Colors.white,
              ),
            ),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
                _filtered = _showFavoritesOnly
                    ? _partitions.where((p) => p.isFavorite).toList()
                    : _partitions;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : Column(
              children: [
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade700, Colors.indigo.shade500],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bienvenue 👋",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_partitions.length} partitions disponibles",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: "Rechercher titre ou catégorie...",
                              hintStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: const Icon(Icons.search, color: Colors.black54),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Text(
                            "Aucune partition trouvée",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final p = _filtered[index];

                            // LOGS DE DIAGNOSTIC AUDIO (inchangés)
                            debugPrint("Pour ${p.titre} → localAudioPath = ${p.localAudioPath ?? 'NULL'}");
                            if (p.localAudioPath != null) {
                              final audioFile = File(p.localAudioPath!);
                              debugPrint("  → Existe ? ${audioFile.existsSync()}");
                              if (audioFile.existsSync()) {
                                debugPrint("  → Taille : ${audioFile.lengthSync()} octets");
                              } else {
                                debugPrint("  → Fichier audio n'existe PAS sur le disque !");
                              }
                            } else {
                              debugPrint("  → localAudioPath est NULL → pas d'audio assigné");
                            }

                            return FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _animController,
                                  curve: Interval(
                                    0.1 * index.clamp(0, 1.0),
                                    0.5 + 0.1 * index.clamp(0, 1.0),
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              ),
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                                  CurvedAnimation(
                                    parent: _animController,
                                    curve: Interval(
                                      0.1 * index.clamp(0, 1.0),
                                      0.5 + 0.1 * index.clamp(0, 1.0),
                                      curve: Curves.easeOutBack,
                                    ),
                                  ),
                                ),
                                child: Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DetailScreen(partition: p),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  p.titre,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              AnimatedScale(
  scale: 1.0,  // plus d'animation
  duration: Duration.zero,
  child: SizedBox(
    width: 48,   // même largeur que l'IconButton original
    height: 48,
    // rien dedans → invisible
  ),
),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            p.categorie,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomButton(
                                                  text: "PDF",
                                                  icon: Icons.picture_as_pdf,
                                                  color: Colors.indigo,
                                                  onPressed: p.localPdfPath != null &&
                                                          p.localPdfPath!.isNotEmpty
                                                      ? () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (_) => DetailScreen(partition: p),
                                                            ),
                                                          );
                                                        }
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: AudioPlayerControls(
                                                  player: _player,
                                                  audioPath: p.localAudioPath,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _player.stop().then((_) {
      _player.seek(Duration.zero);
      debugPrint("Lecture arrêtée et remise à zéro lors de la sortie de l'écran");
    }).catchError((e) {
      debugPrint("Erreur lors du stop/reset player : $e");
    });
    _animController.dispose();
    _player.dispose();
    _searchController.dispose();
    super.dispose();
  }
}