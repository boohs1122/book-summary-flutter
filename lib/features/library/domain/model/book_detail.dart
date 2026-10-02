import 'book.dart';

class BookDetail {
  const BookDetail({
    required this.id,
    required this.title,
    required this.documentCount,
    required this.totalCharCount,
    required this.documents,
  });

  final String id;
  final String title;
  final int documentCount;
  final int totalCharCount;
  final List<BookDocument> documents;
}

class BookDocument {
  const BookDocument({
    required this.id,
    required this.sequence,
    required this.status,
    required this.charCount,
    required this.hasQuiz,
    required this.createdAt,
    this.title,
    this.preview,
    this.latestScore,
  });

  final String id;
  final int sequence;
  final String status;
  final String? title;
  final String? preview;
  final int charCount;
  final bool hasQuiz;
  final BookScore? latestScore;
  final DateTime createdAt;
}
