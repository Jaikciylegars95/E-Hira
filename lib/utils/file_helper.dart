import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:http/http.dart' as http;

class FileHelper {
  static String safeFilename(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  static Future<String> getLocalFilePath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = safeFilename(filename);
    return path_pkg.join(dir.path, safeName);
  }

  static Future<File> downloadFile(String url, String filename) async {
    if (url.isEmpty) {
      throw Exception("URL vide pour le fichier : $filename");
    }

    final localPath = await getLocalFilePath(filename);
    final file = File(localPath);

    if (await file.exists() && await file.length() > 0) {
      print("Fichier déjà présent : $localPath");
      return file;
    }

    print("Début téléchargement : $url → $localPath");

    try {
      final response = await http.get(Uri.parse(url));

      print("Réponse HTTP : ${response.statusCode}");

      if (response.statusCode != 200) {
        throw Exception(
          "Échec téléchargement - code ${response.statusCode} pour $filename",
        );
      }

      await file.writeAsBytes(response.bodyBytes, flush: true);
      print("Téléchargement terminé : ${file.path}");

      return file;
    } catch (e) {
      print("Erreur pendant le téléchargement de $url : $e");
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }
}