import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header IDENTIQUE à HomeContentScreen
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
          // Contenu "À propos"
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 100,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "e-Hira Chorale",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Version 3.2.35",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Une application dédiée aux chorales pour gérer, visualiser et écouter vos partitions musicales.",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text("Fonctionnalités principales :"),
                  const SizedBox(height: 8),
                  const Text("• Téléchargement et stockage local"),
                  const Text("• Lecture PDF et audio synchronisée"),
                  const Text("• Favoris et recherche avancée"),
                  const Text("• Mode hors-ligne"),
                  const SizedBox(height: 32),
                  const Text(
                    "Développé avec amour pour la musique",
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  const Text("© 2026 e-Hira"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}