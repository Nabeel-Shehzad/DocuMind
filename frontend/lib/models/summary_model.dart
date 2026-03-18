class SummaryModel {
  final String documentId;
  final String summaryType;
  final String summary;
  final Map<String, dynamic>? structuredData;

  const SummaryModel({
    required this.documentId,
    required this.summaryType,
    required this.summary,
    this.structuredData,
  });

  factory SummaryModel.fromJson(Map<String, dynamic> json) => SummaryModel(
    documentId:     json['document_id']   as String,
    summaryType:    json['summary_type']  as String,
    summary:        json['summary']       as String,
    structuredData: json['structured_data'] as Map<String, dynamic>?,
  );
}

// Summary type options shown in UI
class SummaryType {
  final String value;
  final String label;
  final String icon;
  final String description;

  const SummaryType({
    required this.value,
    required this.label,
    required this.icon,
    required this.description,
  });

  static const List<SummaryType> all = [
    SummaryType(
      value:       'general',
      label:       'General Summary',
      icon:        '📝',
      description: 'Overview of the document',
    ),
    SummaryType(
      value:       'key_points',
      label:       'Key Points',
      icon:        '🎯',
      description: 'Top 5-10 bullet points',
    ),
    SummaryType(
      value:       'invoice',
      label:       'Invoice Extractor',
      icon:        '🧾',
      description: 'Structured invoice data',
    ),
    SummaryType(
      value:       'contract',
      label:       'Contract Analysis',
      icon:        '⚖️',
      description: 'Parties, terms, risks',
    ),
  ];
}
