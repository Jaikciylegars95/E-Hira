import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:http/http.dart' as http;

class FileHelper {
  static String safeFilename(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // caractères interdits
        .replaceAll(RegExp(r'\s+'), '_')          // espaces → underscore
        .trim();
  }

  static Future<String> getLocalFilePath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = safeFilename(filename);
    final fullPath = path_pkg.join(dir.path, safeName);
    debugPrint("Chemin calculé pour '$filename' → $fullPath");
    return fullPath;
  }

  static Future<File> downloadFile(String url, String filename) async {
    debugPrint("\n" + "═" * 60);
    debugPrint("DÉBUT TÉLÉCHARGEMENT");
    debugPrint("URL          : $url");
    debugPrint("Nom original : $filename");

    if (url.isEmpty || url.trim().isEmpty) {
      throw Exception("URL vide ou invalide pour le fichier '$filename'");
    }

    final localPath = await getLocalFilePath(filename);
    final file = File(localPath);

    // Vérification existence + taille
    if (await file.exists()) {
      final size = await file.length();
      debugPrint("Fichier existe déjà : $localPath");
      debugPrint("Taille actuelle : $size octets");

      if (size > 1000) { // > 1 Ko → probablement OK
        debugPrint("Fichier semble valide → retour immédiat");
        return file;
      } else {
        debugPrint("Fichier existant mais vide ou corrompu → suppression");
        await file.delete();
      }
    }

    debugPrint("Téléchargement lancé...");

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request).timeout(const Duration(seconds: 60));

      debugPrint("Réponse HTTP reçue : ${response.statusCode}");

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        debugPrint("Corps réponse (début) : ${body.substring(0, body.length.clamp(0, 200))}...");
        throw Exception(
          "Échec téléchargement - code ${response.statusCode} pour $filename\n"
          "Message serveur : $body",
        );
      }

      final totalBytes = response.contentLength ?? 0;
      debugPrint("Taille attendue : $totalBytes octets");

      final sink = file.openWrite();
      int received = 0;

      await response.stream.listen(
        (List<int> chunk) {
          received += chunk.length;
          sink.add(chunk);
          debugPrint("Progression : $received / $totalBytes octets");
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
        },
        onError: (e) async {
          debugPrint("Erreur stream : $e");
          await sink.close();
          if (await file.exists()) await file.delete();
        },
        cancelOnError: true,
      ).asFuture();

      final finalSize = await file.length();
      debugPrint("Téléchargement terminé : ${file.path}");
      debugPrint("Taille finale : $finalSize octets");

      if (finalSize == 0) {
        await file.delete();
        throw Exception("Fichier téléchargé mais vide (taille 0)");
      }

      return file;
    } catch (e, stack) {
      debugPrint("ERREUR TÉLÉCHARGEMENT : $e");
      debugPrint("Stack trace : $stack");
      if (await file.exists()) {
        debugPrint("Suppression fichier partiel : $localPath");
        await file.delete();
      }
      rethrow;
    } finally {
      debugPrint("═" * 60 + "\n");
    }
  }
}