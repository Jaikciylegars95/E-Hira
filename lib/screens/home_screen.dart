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

class _HomeScreenState extends State<HomeScreen> {
  List<Partition> _partitions = [];
  List<Partition> _filtered = [];
  bool _isLoading = true;
  bool _showFavoritesOnly = false;

  final _searchController = TextEditingController();
  final _player = AudioPlayer();

  final String _apiUrl = "http://192.168.88.9:8000/api/partitions";
  final String _serverBaseUrl = "http://192.168.88.9:8000/";

  @override
  void initState() {
    super.initState();
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
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode != 200) return;

      final List data = jsonDecode(response.body);
      bool hasChanges = false;

      for (final item in data) {
        final p = Partition.fromJson(item, baseUrl: _serverBaseUrl);

        final existing = _partitions.firstWhereOrNull((e) => e.id == p.id);

        if (existing == null || (existing.version ?? 0) < (p.version ?? 1)) {
          if (p.pdfUrl.isNotEmpty) {
            final path = await FileHelper.getLocalFilePath("${p.titre}.pdf");
            if (!await File(path).exists()) {
              try {
                final file = await FileHelper.downloadFile(p.pdfUrl, "${p.titre}.pdf");
                p.localPdfPath = file.path;
              } catch (e) {
                debugPrint("Échec PDF ${p.titre} : $e");
              }
            } else {
              p.localPdfPath = path;
            }
          }

          if (p.audioUrl.isNotEmpty) {
            final path = await FileHelper.getLocalFilePath("${p.titre}.mp3");
            if (!await File(path).exists()) {
              try {
                final file = await FileHelper.downloadFile(p.audioUrl, "${p.titre}.mp3");
                p.localAudioPath = file.path;
              } catch (e) {
                debugPrint("Échec audio ${p.titre} : $e");
              }
            } else {
              p.localAudioPath = path;
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("🎼 Chorale"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _showFavoritesOnly ? Colors.red : null,
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue, Colors.indigo]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Bienvenue 👋",
                          style: TextStyle(color: Colors.white, fontSize: 22)),
                      const SizedBox(height: 6),
                      Text("${_partitions.length} partitions",
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: "Rechercher...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text("Aucune partition trouvée"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final p = _filtered[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.titre,
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            p.isFavorite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: p.isFavorite
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                          onPressed: () async {
                                            setState(() {
                                              p.isFavorite = !p.isFavorite;
                                            });
                                            await DBHelper.updateFavorite(
                                                p.id, p.isFavorite);
                                          },
                                        ),
                                      ],
                                    ),
                                    Text(
                                      p.categorie,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        CustomButton(
                                          text: "PDF",
                                          onPressed: p.localPdfPath != null &&
                                                  p.localPdfPath!.isNotEmpty
                                              ? () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          DetailScreen(
                                                              partition: p),
                                                    ),
                                                  );
                                                }
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        CustomButton(
                                          text: "Audio",
                                          onPressed: p.localAudioPath != null &&
                                                  p.localAudioPath!.isNotEmpty
                                              ? () => _playAudio(
                                                  p.localAudioPath!)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ],
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
    _player.dispose();
    _searchController.dispose();
    super.dispose();
  }
}