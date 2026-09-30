import 'package:json_annotation/json_annotation.dart';

part 'book_list_dto.g.dart';

@JsonSerializable(createToJson: false)
class BookListDto {
  const BookListDto({required this.items, this.nextCursor});

  factory BookListDto.fromJson(Map<String, dynamic> json) =>
      _$BookListDtoFromJson(json);

  final List<BookDto> items;
  final String? nextCursor;
}

@JsonSerializable(createToJson: false)
class BookDto {
  const BookDto({
    required this.bookId,
    required this.title,
    required this.documentCount,
    required this.totalCharCount,
    required this.createdAt,
    this.lastStudiedAt,
    this.latestScore,
  });

  factory BookDto.fromJson(Map<String, dynamic> json) =>
      _$BookDtoFromJson(json);

  final String bookId;
  final String title;
  final int documentCount;
  final int totalCharCount;
  final DateTime createdAt;
  final DateTime? lastStudiedAt;
  final BookScoreDto? latestScore;
}

@JsonSerializable(createToJson: false)
class BookScoreDto {
  const BookScoreDto({required this.correct, required this.total});

  factory BookScoreDto.fromJson(Map<String, dynamic> json) =>
      _$BookScoreDtoFromJson(json);

  final int correct;
  final int total;
}
