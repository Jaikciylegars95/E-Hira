import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/partition.dart';
import '../widgets/partition_card.dart';

class AllPartitionsScreen extends StatefulWidget {
  const AllPartitionsScreen({super.key});

  @override
  State<AllPartitionsScreen> createState() => _AllPartitionsScreenState();
}

class _AllPartitionsScreenState extends State<AllPartitionsScreen> {
  List<Partition> partitions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPartitions();
  }

  Future<void> _loadPartitions() async {
    final all = await DBHelper.getAllPartitions();
    setState(() {
      partitions = all;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Toutes les partitions")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : partitions.isEmpty
              ? const Center(child: Text("Aucune partition disponible"))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: partitions.length,
                  itemBuilder: (context, index) {
                    return PartitionCard(partition: partitions[index]);
                  },
                ),
    );
  }
}