import 'package:chorale_app/screens/all_partitions_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  expandedHeight: 50, // Hauteur suffisante pour logo + animation
  floating: false,
  pinned: true,
  flexibleSpace: FlexibleSpaceBar(
    titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo avec bordure arrondie et ombre
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/logo.png', // ← ton chemin correct
              height: 20, // Taille élégante dans l'AppBar
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Texte "E-Hira" avec police Playwrite CU
        Text(
          "E-Hira",
          style: GoogleFonts.playwriteCu(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ],
    ),

    // Fond dégradé indigo (s'adapte au style du logo)
    background: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 0, 1, 6), // Indigo très foncé
            Color.fromARGB(255, 0, 5, 34), // Indigo moyen
            Color.fromARGB(255, 0, 1, 53), // Indigo plus clair
          ],
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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carte d'accueil stylée
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade50,
                Colors.indigo.shade100,
                Colors.purple.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre + icône
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade700.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      size: 32,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Bienvenue dans E-Hira",
                      style: GoogleFonts.playfairDisplay( // ou playwriteCu si tu préfères
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sous-titre descriptif
              Text(
                "Découvrez et pratiquez vos partitions préférées avec audio intégré.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Bouton d'action élégant
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigation vers toutes les partitions si tu veux
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllPartitionsScreen()),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text("Voir toutes les partitions"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Titre "Partitions récentes" stylé
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            "Partitions récentes",
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.indigo.shade800,
              letterSpacing: -0.3,
            ),
          ),
        ),

        const SizedBox(height: 16),
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