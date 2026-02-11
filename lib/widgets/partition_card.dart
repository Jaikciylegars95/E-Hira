import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/partition.dart';
import '../screens/detail_screen.dart';

class PartitionCard extends StatefulWidget {
  final Partition partition;
  final VoidCallback? onFavoriteChanged; // Callback optionnel pour rafraîchir la liste parent si besoin

  const PartitionCard({
    super.key,
    required this.partition,
    this.onFavoriteChanged,
  });

  @override
  State<PartitionCard> createState() => _PartitionCardState();
}

class _PartitionCardState extends State<PartitionCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.partition.isFavorite; // État local initial
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite; // Changement immédiat visuel
    });

    // Sauvegarde dans la base de données
    await DBHelper.updateFavorite(widget.partition.id, _isFavorite);

    // Si parent veut être notifié (ex : pour rafraîchir la liste entière)
    widget.onFavoriteChanged?.call();

    // SnackBar de confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? "Ajouté aux favoris ❤️" : "Retiré des favoris",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: const Icon(Icons.music_note, color: Colors.indigo),
        ),
        title: Text(widget.partition.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(widget.partition.categorie),
        trailing: IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : null,
          ),
          onPressed: _toggleFavorite, // Fonction locale qui gère tout
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(partition: widget.partition)),
          );
        },
      ),
    );
  }
}