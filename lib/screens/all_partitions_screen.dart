import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../database/db_helper.dart';
import '../models/partition.dart';
import '../widgets/partition_card.dart';

class AllPartitionsScreen extends StatefulWidget {
  const AllPartitionsScreen({super.key});

  @override
  State<AllPartitionsScreen> createState() => _AllPartitionsScreenState();
}

class _AllPartitionsScreenState extends State<AllPartitionsScreen> with SingleTickerProviderStateMixin {
  List<Partition> partitions = [];
  List<Partition> displayedPartitions = []; // Liste affichée (après tri)
  bool loading = true;

  // Contrôle du tri
  String _sortOption = 'Par défaut'; // Valeur initiale

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
  }

  Future<void> _loadPartitions() async {
    final all = await DBHelper.getAllPartitions();
    setState(() {
      partitions = all;
      displayedPartitions = List.from(all); // Copie initiale
      loading = false;
      _applySort(); // Applique le tri par défaut
    });
  }

  // Fonction qui applique le tri selon l'option choisie
  void _applySort() {
    setState(() {
      switch (_sortOption) {
        case 'A à Z':
          displayedPartitions.sort((a, b) => a.titre.compareTo(b.titre));
          break;
        case 'Z à A':
          displayedPartitions.sort((a, b) => b.titre.compareTo(a.titre));
          break;
        case 'Par défaut':
        default:
          displayedPartitions.sort((a, b) => b.id.compareTo(a.id)); // Plus récentes en haut
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header IDENTIQUE à HomeContentScreen (inchangé)
          SliverAppBar(
            expandedHeight: 50,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        'assets/images/logo.png',
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromARGB(255, 0, 1, 6),
                      Color.fromARGB(255, 0, 5, 34),
                      Color.fromARGB(255, 0, 1, 53),
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

          // Section FILTRE / TRI par titre (remplace la recherche)
          SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.sort_rounded, color: Colors.indigo, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortOption,
                    decoration: InputDecoration(
                      labelText: "", // ← taille diminuée
                      labelStyle: TextStyle(
                        color: Colors.indigo,
                        fontSize: 14, // ← diminué de 16 à 14
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    ),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14, // ← augmenté légèrement (les options dans le menu)
                      fontWeight: FontWeight.w500,
                    ),
                    dropdownColor: const Color.fromARGB(255, 255, 255, 255),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                    items: const [
                      DropdownMenuItem(
                        value: 'Par défaut',
                        child: Text('Par défaut'),
                      ),
                      DropdownMenuItem(
                        value: 'A à Z',
                        child: Text('Titre : A à Z'),
                      ),
                      DropdownMenuItem(
                        value: 'Z à A',
                        child: Text('Titre : Z à A'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _sortOption = newValue;
                          _applySort();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

          // Liste des partitions
          loading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.indigo)),
                )
              : displayedPartitions.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          "Aucune partition disponible",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return PartitionCard(partition: displayedPartitions[index]);
                          },
                          childCount: displayedPartitions.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
}