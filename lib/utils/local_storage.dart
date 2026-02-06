import 'package:hive/hive.dart';
import '../models/partition.dart';

class LocalStorage {
  static const String boxName = "partitions";

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static Future<void> savePartition(Partition p) async {
    var box = Hive.box(boxName);
    box.put(p.id, p.toMap());
  }

  static Partition? getPartition(int id) {
    var box = Hive.box(boxName);
    final data = box.get(id);
    return data != null ? Partition.fromJson(Map<String, dynamic>.from(data)) : null;
  }

  static List<Partition> getAll() {
    var box = Hive.box(boxName);
    return box.values.map((e) => Partition.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
