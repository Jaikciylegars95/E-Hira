import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        centerTitle: true,
      ),
      body: Center(
        child: CustomButton(
          text: "Clique ici",
          icon: Icons.touch_app, // ✅ AJOUT OBLIGATOIRE
          color: Colors.blue,    // optionnel mais joli
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Bouton cliqué 🎉"),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }
}
