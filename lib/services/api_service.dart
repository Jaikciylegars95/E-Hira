import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/partition.dart';
import '../utils/local_storage.dart';

class ApiService {
  static const String baseUrl = "http://192.168.88.247:8000/api";

  static Future<List<Partition>> syncPartitions() async {
    final localPartitions = await LocalStorage.getAll();

    int maxVersion = localPartitions.isEmpty
        ? 0
        : localPartitions
            .map((p) => p.version)
            .reduce((a, b) => a > b ? a : b);

    final response = await http.get(
      Uri.parse("$baseUrl/partitions?version=$maxVersion"),
      headers: {
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final newPartitions =
          data.map((e) => Partition.fromJson(e, baseUrl: '')).toList();

      for (var p in newPartitions) {
        await LocalStorage.savePartition(p);
      }

      return newPartitions;
    } else {
      throw Exception(
          "Erreur API ${response.statusCode} : ${response.body}");
    }
  }
}
