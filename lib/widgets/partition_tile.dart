import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/partition.dart';
import '../screens/detail_screen.dart';

class PartitionTile extends StatefulWidget {
  final Partition partition;
  final VoidCallback? onFavoriteChanged; // Callback pour rafraîchir la liste parent (optionnel)

  const PartitionTile({
    super.key,
    required this.partition,
    this.onFavoriteChanged,
  });

  @override
  State<PartitionTile> createState() => _PartitionTileState();
}

class _PartitionTileState extends State<PartitionTile> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.partition.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    final newState = !_isFavorite;

    setState(() {
      _isFavorite = newState;
    });

    // Sauvegarde en base
    await DBHelper.updateFavorite(widget.partition.id, newState);

    // Notification au parent (ex : pour rafraîchir la liste si mode favoris actif)
    widget.onFavoriteChanged?.call();

    // Confirmation visuelle
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState ? "Ajouté aux favoris ❤️" : "Retiré des favoris",
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: newState ? Colors.green.shade700 : Colors.grey.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailScreen(partition: widget.partition),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône à gauche
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.indigo.shade100,
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Colors.indigo,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Contenu principal (titre + catégorie)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.partition.titre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.partition.categorie,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Bouton favori
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.redAccent : Colors.grey.shade600,
                  size: 28,
                ),
                onPressed: _toggleFavorite,
                tooltip: _isFavorite ? "Retirer des favoris" : "Ajouter aux favoris",
              ),
            ],
          ),
        ),
      ),
    );
  }
}