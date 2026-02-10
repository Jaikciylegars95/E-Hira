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

  final String _apiUrl = "http://192.168.88.247:8000/api/partitions";
  final String _serverBaseUrl = "http://192.168.88.247:8000/";

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
    try {
      debugPrint("Tentative sync API : $_apiUrl");
      final response = await http.get(Uri.parse(_apiUrl));
      debugPrint("Réponse API : ${response.statusCode}");

      if (response.statusCode != 200) {
        debugPrint("Erreur sync API : ${response.statusCode} - ${response.body}");
        return;
      }

      final List data = jsonDecode(response.body);
      bool hasChanges = false;

      for (final item in data) {
        final p = Partition.fromJson(item, baseUrl: _serverBaseUrl);

        debugPrint("Partition reçue : ${p.titre} | pdf_url: ${p.pdfUrl} | audio_url: ${p.audioUrl}");

        final existing = _partitions.firstWhereOrNull((e) => e.id == p.id);

        if (existing == null || (existing.version ?? 0) < (p.version ?? 1)) {
          if (p.pdfUrl.isNotEmpty) {
            final path = await FileHelper.getLocalFilePath("${p.titre}.pdf");
            if (!await File(path).exists()) {
              try {
                final file = await FileHelper.downloadFile(p.pdfUrl, "${p.titre}.pdf");
                p.localPdfPath = file.path;
                debugPrint("PDF téléchargé : ${p.localPdfPath}");
              } catch (e) {
                debugPrint("Échec PDF ${p.titre} : $e");
              }
            } else {
              p.localPdfPath = path;
              debugPrint("PDF déjà présent : $path");
            }
          }

          if (p.audioUrl.isNotEmpty) {
            final path = await FileHelper.getLocalFilePath("${p.titre}.mp3");
            if (!await File(path).exists()) {
              try {
                final file = await FileHelper.downloadFile(p.audioUrl, "${p.titre}.mp3");
                p.localAudioPath = file.path;
                debugPrint("Audio téléchargé : ${p.localAudioPath}");
              } catch (e) {
                debugPrint("Échec audio ${p.titre} : $e");
              }
            } else {
              p.localAudioPath = path;
              debugPrint("Audio déjà présent : $path");
            }
          }

          await DBHelper.insertOrUpdatePartition(p);
          hasChanges = true;
        }
      }

      if (hasChanges && mounted) {
        await _loadLocalPartitions();
      }
    } catch (e) {
      debugPrint("Sync background erreur : $e");
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

  Future<void> _playAudio(String path) async {
    try {
      await _player.stop();
      await _player.setFilePath(path);
      await _player.play();
    } on PlayerException catch (e) {
      debugPrint("Erreur just_audio : ${e.code} - ${e.message}");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lecture : ${e.message ?? 'inconnue'}"),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint("Erreur audio inattendue : $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de lire l'audio")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // ← Fond gris clair pour toute la page
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
                                                scale: p.isFavorite ? 1.3 : 1.0,
                                                duration: const Duration(milliseconds: 400),
                                                curve: Curves.elasticOut,
                                                child: IconButton(
                                                  icon: Icon(
                                                    p.isFavorite ? Icons.favorite : Icons.favorite_border,
                                                    color: p.isFavorite ? Colors.redAccent : Colors.grey.shade600,
                                                  ),
                                                  onPressed: () async {
                                                    setState(() {
                                                      p.isFavorite = !p.isFavorite;
                                                    });
                                                    await DBHelper.updateFavorite(p.id, p.isFavorite);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          p.isFavorite
                                                              ? "Ajouté aux favoris ❤️"
                                                              : "Retiré des favoris",
                                                        ),
                                                        duration: const Duration(seconds: 1),
                                                      ),
                                                    );
                                                  },
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
                                                child: CustomButton(
                                                  text: "Audio",
                                                  icon: Icons.play_arrow,
                                                  color: Colors.teal,
                                                  onPressed: p.localAudioPath != null &&
                                                          p.localAudioPath!.isNotEmpty
                                                      ? () => _playAudio(p.localAudioPath!)
                                                      : null,
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
    _animController.dispose();
    _player.dispose();
    _searchController.dispose();
    super.dispose();
  }
}