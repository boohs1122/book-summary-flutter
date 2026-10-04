enum SummaryJobStatus { processing, done, failed }

enum KeyPointType { definition, mechanism, cause, comparison, caution, example }

class SummaryJob {
  const SummaryJob({
    required this.id,
    required this.status,
    this.documentId,
    this.createdAt,
    this.errorCode,
  });
  final String id;
  final SummaryJobStatus status;
  final String? documentId;
  final DateTime? createdAt;
  final String? errorCode;
}

class SummaryDocument {
  const SummaryDocument({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.sequence,
    required this.text,
    required this.status,
    this.summary,
  });
  final String id;
  final String bookId;
  final String bookTitle;
  final int sequence;
  final String text;
  final SummaryJobStatus status;
  final SummaryContent? summary;
}

class SummaryContent {
  const SummaryContent({
    required this.title,
    required this.keyPoints,
    required this.terms,
  });
  final String title;
  final List<SummaryKeyPoint> keyPoints;
  final List<SummaryTerm> terms;
}

class SummaryKeyPoint {
  const SummaryKeyPoint({
    required this.type,
    required this.heading,
    required this.detail,
  });
  final KeyPointType type;
  final String heading;
  final String detail;
}

class SummaryTerm {
  const SummaryTerm({required this.term, required this.meaning});
  final String term;
  final String meaning;
}

class InvalidSummaryText implements Exception {}

class SummaryJobExpired implements Exception {}
