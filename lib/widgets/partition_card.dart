import 'package:flutter/material.dart';
import '../models/partition.dart';
import '../screens/detail_screen.dart';

class PartitionCard extends StatelessWidget {
  final Partition partition;

  const PartitionCard({super.key, required this.partition});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: const Icon(Icons.music_note, color: Colors.indigo),
        ),
        title: Text(partition.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(partition.categorie),
        trailing: IconButton(
          icon: Icon(
            partition.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: partition.isFavorite ? Colors.red : null,
          ),
          onPressed: () {
            // Logique favoris à implémenter si besoin
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(partition: partition)),
          );
        },
      ),
    );
  }
}