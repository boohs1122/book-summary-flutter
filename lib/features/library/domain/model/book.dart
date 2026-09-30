class Book {
  const Book({
    required this.id,
    required this.title,
    required this.documentCount,
    required this.totalCharCount,
    required this.createdAt,
    this.lastStudiedAt,
    this.latestScore,
  });

  final String id;
  final String title;
  final int documentCount;
  final int totalCharCount;
  final DateTime createdAt;
  final DateTime? lastStudiedAt;
  final BookScore? latestScore;
}

class BookScore {
  const BookScore({required this.correct, required this.total});

  final int correct;
  final int total;
}
