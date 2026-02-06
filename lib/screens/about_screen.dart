import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("À propos")),
      body: Padding(
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
              "Version 1.0.0",
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
              "Développé avec amour pour la musique chorale",
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            const Text("© 2025 e-Hira Team"),
          ],
        ),
      ),
    );
  }
}