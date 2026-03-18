class DocumentModel {
  final String documentId;
  final String filename;
  final String fileType;
  final int chunkCount;
  final int fileSizeBytes;
  final DateTime uploadedAt;

  const DocumentModel({
    required this.documentId,
    required this.filename,
    required this.fileType,
    required this.chunkCount,
    required this.fileSizeBytes,
    required this.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
    documentId:    json['document_id']      as String,
    filename:      json['filename']         as String,
    fileType:      json['file_type']        as String,
    chunkCount:    json['chunk_count']      as int,
    fileSizeBytes: (json['file_size_bytes'] as int?) ?? 0,
    uploadedAt:    DateTime.parse(json['uploaded_at'] as String),
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

  // Human-readable file size (e.g. "1.2 MB")
  String get fileSizeLabel {
    if (fileSizeBytes <= 0)           return '';
    if (fileSizeBytes < 1024)         return '${fileSizeBytes} B';
    if (fileSizeBytes < 1024 * 1024)  return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Short display name
  String get shortName =>
      filename.length > 28 ? '${filename.substring(0, 25)}...' : filename;
}
