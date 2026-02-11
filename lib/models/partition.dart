import 'package:flutter/foundation.dart'; // pour debugPrint si besoin

class Partition {
  final int id;
  final String titre;
  final String categorie;
  final String pdfUrl;        // URL distante complète (ex: http://...)
  final String audioUrl;      // URL distante complète
  final int version;

  String? localPdfPath;       // chemin local sur le téléphone
  String? localAudioPath;     // chemin local sur le téléphone

  bool isFavorite;            // vrai si en favori

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

  // Création depuis JSON API (avec baseUrl pour reconstruire les URLs complètes)
  factory Partition.fromJson(Map<String, dynamic> json, {required String baseUrl}) {
    return Partition(
      id: json['id'] as int? ?? 0,
      titre: json['titre'] as String? ?? '',
      categorie: json['categorie'] as String? ?? '',
      pdfUrl: json['pdf_url'] != null ? '$baseUrl${json['pdf_url']}' : '',
      audioUrl: json['audio_url'] != null ? '$baseUrl${json['audio_url']}' : '',
      version: json['version'] as int? ?? 1,
      isFavorite: false, // toujours false au départ depuis l'API
    );
  }

  // Pour insérer / mettre à jour dans SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'categorie': categorie,
      'pdf_url': pdfUrl,
      'audio_url': audioUrl,
      'version': version,
      'localPdfPath': localPdfPath,
      'localAudioPath': localAudioPath,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  // Création depuis la base SQLite
  factory Partition.fromMap(Map<String, dynamic> map) {
    return Partition(
      id: map['id'] as int? ?? 0,
      titre: map['titre'] as String? ?? '',
      categorie: map['categorie'] as String? ?? '',
      pdfUrl: map['pdf_url'] as String? ?? '',
      audioUrl: map['audio_url'] as String? ?? '',
      version: map['version'] as int? ?? 1,
      localPdfPath: map['localPdfPath'] as String?,
      localAudioPath: map['localAudioPath'] as String?,
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
    );
  }

  // Pour envoyer au serveur (si tu as besoin d'update distant un jour)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'categorie': categorie,
      'pdf_url': pdfUrl.replaceAll('http://192.168.88.249:8000/', ''), // enlève la base locale si besoin
      'audio_url': audioUrl.replaceAll('http://192.168.88.249:8000/', ''),
      'version': version,
      'is_favorite': isFavorite,
    };
  }

  // Pour debug / logs clairs
  @override
  String toString() {
    return 'Partition(id: $id | titre: "$titre" | favorite: $isFavorite | '
        'pdf_url: $pdfUrl | localPdf: $localPdfPath | '
        'audio_url: $audioUrl | localAudio: $localAudioPath | version: $version)';
  }

  // Copie avec modification (utile pour toggle favori sans muter l'original)
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