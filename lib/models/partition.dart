import 'package:flutter/foundation.dart'; // pour debugPrint si besoin

class Partition {
  final int id;
  final String titre;
  final String categorie;
  final String pdfUrl;       // URL complète (ex: http://.../storage/pdfs/solfa1.pdf)
  final String audioUrl;     // URL complète
  final int version;

  String? localPdfPath;      // chemin local sur le téléphone
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
    return Partition(
      id: json['id'] as int? ?? 0,
      titre: json['titre'] as String? ?? '',
      categorie: json['categorie'] as String? ?? '',
      pdfUrl: json['pdf_url'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? '',
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

  // Pour debug / logs clairs
  @override
  String toString() {
    return 'Partition(id: $id | titre: $titre | favorite: $isFavorite | '
        'pdf_url: $pdfUrl | localPdf: $localPdfPath | '
        'audio_url: $audioUrl | localAudio: $localAudioPath)';
  }

  // Pour envoyer au serveur si besoin (update favorite par exemple)
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
}