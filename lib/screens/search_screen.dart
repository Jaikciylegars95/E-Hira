import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../database/db_helper.dart';
import '../models/partition.dart';
import '../widgets/partition_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  List<Partition> _allPartitions = [];
  List<Partition> _filtered = [];
  final _searchController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animation identique à HomeContentScreen
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

    _loadPartitions();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadPartitions() async {
    final all = await DBHelper.getAllPartitions();
    setState(() {
      _allPartitions = all;
      _filtered = all;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = _allPartitions.where((p) {
        return p.titre.toLowerCase().contains(query) ||
            p.categorie.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header IDENTIQUE à HomeContentScreen (couleur, hauteur, logo, police)
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
          // Champ de recherche (juste en dessous, comme dans Home)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),

          // Liste des résultats
          _filtered.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "Aucune partition trouvée",
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return PartitionCard(partition: _filtered[index]);
                      },
                      childCount: _filtered.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }
}