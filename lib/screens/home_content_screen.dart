import 'package:flutter/material.dart';
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
          ..sort((a, b) => b.id.compareTo(a.id));
        if (recentPartitions.length > 6) {
          recentPartitions = recentPartitions.sublist(0, 6);
        }
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("e-Hira Chorale"),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.indigo.shade700, Colors.indigo.shade400],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 100,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bienvenue dans e-Hira",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Découvrez et pratiquez vos partitions préférées avec audio intégré.",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Partitions récentes",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          loading
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : recentPartitions.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(child: Text("Aucune partition récente")),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return PartitionCard(partition: recentPartitions[index]);
                        },
                        childCount: recentPartitions.length,
                      ),
                    ),
        ],
      ),
    );
  }
}