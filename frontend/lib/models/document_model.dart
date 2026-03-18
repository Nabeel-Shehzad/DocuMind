class DocumentModel {
  final String documentId;
  final String filename;
  final String fileType;
  final int pageCount;
  final int chunkCount;
  final DateTime uploadedAt;

  const DocumentModel({
    required this.documentId,
    required this.filename,
    required this.fileType,
    required this.pageCount,
    required this.chunkCount,
    required this.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
    documentId: json['document_id'] as String,
    filename:   json['filename']    as String,
    fileType:   json['file_type']   as String,
    pageCount:  json['page_count']  as int,
    chunkCount: json['chunk_count'] as int,
    uploadedAt: DateTime.parse(json['uploaded_at'] as String),
  );

  // File type icon helper
  String get typeIcon {
    switch (fileType.toLowerCase()) {
      case 'pdf':      return '📄';
      case 'png':
      case 'jpg':
      case 'jpeg':     return '🖼️';
      default:         return '📁';
    }
  }

  // Short display name
  String get shortName =>
      filename.length > 28 ? '${filename.substring(0, 25)}...' : filename;
}
