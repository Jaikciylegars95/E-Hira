import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../database/db_helper.dart';
import '../models/partition.dart';
import '../widgets/partition_card.dart';

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  List<Partition> recentPartitions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentPartitions();
  }

  Future<void> _loadRecentPartitions() async {
    try {
      final all = await DBHelper.getAllPartitions();
      setState(() {
        recentPartitions = all
            .where((p) => p.localPdfPath != null || p.localAudioPath != null)
            .toList()
          ..sort((a, b) => b.id.compareTo(a.id)); // plus récentes en haut
        if (recentPartitions.length > 6) {
          recentPartitions = recentPartitions.sublist(0, 6);
        }
        loading = false;
      });
    } catch (e) {
      debugPrint("Erreur chargement : $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SliverAppBar stylé avec logo + texte "E-Hira"
          SliverAppBar(
            expandedHeight: 160, // Hauteur suffisante pour le logo
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo à gauche
                  Image.asset(
                    'assets/images/logo.png',
                    height: 36, // Taille raisonnable dans l'AppBar
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  // Texte "E-Hira" à droite
                  const Text(
                    "E-Hira",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.indigo.shade800, Colors.indigo.shade500],
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: Lottie.asset(
                      'assets/animations/music_note.json',
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            size: 100,
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Contenu principal (inchangé)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bienvenue dans E-Hira",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.indigo.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Découvrez et pratiquez vos partitions préférées avec audio intégré.",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Partitions récentes",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.indigo.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Chargement ou liste
          loading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.indigo)),
                )
              : recentPartitions.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          "Aucune partition récente",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return PartitionCard(partition: recentPartitions[index]);
                          },
                          childCount: recentPartitions.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}