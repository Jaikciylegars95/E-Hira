class Partition {
  final int id;
  final String titre;
  final String categorie;
  final String pdfUrl;
  final String audioUrl;
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

  factory Partition.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    String formatUrl(String? rawUrl) {
      if (rawUrl == null || rawUrl.isEmpty) return '';
      if (rawUrl.startsWith('http')) return rawUrl;

      // Nettoyage du chemin (évite les doubles slashs)
      String cleanPath = rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl;
      return baseUrl != null ? '$baseUrl$cleanPath' : '';
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
      id: map['id'] as int,
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

  // Pour debug / logs
  @override
  String toString() {
    return 'Partition(id: $id, titre: $titre, categorie: $categorie, favorite: $isFavorite, pdf: $localPdfPath != null)';
  }
}