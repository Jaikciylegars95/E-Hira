import 'package:flutter/foundation.dart'; // pour debugPrint si besoin

class Partition {
  final int id;
  final String titre;
  final String categorie;
  final String pdfUrl;        // URL distante complète
  final String audioUrl;      // URL distante complète
  final int version;

  String? localPdfPath;
  String? localAudioPath;

  bool isFavorite;

  Partition({
    required this.id,
    required this.titre,
    required this.categorie,
    required this.pdfUrl,
    required this.audioUrl,
    required this.version,
    this.localPdfPath,
    this.localAudioPath,
    this.isFavorite = false,
  });

  factory Partition.fromJson(Map<String, dynamic> json, {required String baseUrl}) {
    // Fonction qui gère correctement les URLs (évite les doubles http)
    String formatUrl(String? rawUrl) {
      if (rawUrl == null || rawUrl.isEmpty) return '';

      // Déjà une URL complète → on la garde telle quelle
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        debugPrint("URL déjà complète depuis serveur : $rawUrl");
        return rawUrl;
      }

      // Chemin relatif → on ajoute baseUrl
      String cleanPath = rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl;
      final result = '$baseUrl$cleanPath';
      debugPrint("URL relative → reconstruite : $result");
      return result;
    }

    return Partition(
      id: json['id'] as int? ?? 0,
      titre: json['titre'] as String? ?? '',
      categorie: json['categorie'] as String? ?? '',
      pdfUrl: formatUrl(json['pdf_url'] as String?),
      audioUrl: formatUrl(json['audio_url'] as String?),
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'categorie': categorie,
      'pdf_url': pdfUrl,
      'audio_url': audioUrl,
      'version': version,
      'local_pdf_path': localPdfPath,
      'local_audio_path': localAudioPath,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory Partition.fromMap(Map<String, dynamic> map) {
    return Partition(
      id: map['id'] as int? ?? 0,
      titre: map['titre'] as String? ?? '',
      categorie: map['categorie'] as String? ?? '',
      pdfUrl: map['pdf_url'] as String? ?? '',
      audioUrl: map['audio_url'] as String? ?? '',
      version: map['version'] as int? ?? 1,
      localPdfPath: map['local_pdf_path'] as String?,
      localAudioPath: map['local_audio_path'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'categorie': categorie,
      'pdf_url': pdfUrl,
      'audio_url': audioUrl,
      'version': version,
      'is_favorite': isFavorite,
    };
  }

  @override
  String toString() {
    return 'Partition(id: $id | titre: "$titre" | favorite: $isFavorite | '
        'pdf_url: $pdfUrl | localPdf: $localPdfPath | '
        'audio_url: $audioUrl | localAudio: $localAudioPath)';
  }

  Partition copyWith({
    int? id,
    String? titre,
    String? categorie,
    String? pdfUrl,
    String? audioUrl,
    int? version,
    String? localPdfPath,
    String? localAudioPath,
    bool? isFavorite,
  }) {
    return Partition(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      categorie: categorie ?? this.categorie,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      version: version ?? this.version,
      localPdfPath: localPdfPath ?? this.localPdfPath,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}