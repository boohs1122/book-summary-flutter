import 'package:json_annotation/json_annotation.dart';

import 'book_list_dto.dart';

part 'book_detail_dto.g.dart';

@JsonSerializable(createToJson: false)
class BookDetailDto {
  const BookDetailDto({
    required this.bookId,
    required this.title,
    required this.documentCount,
    required this.totalCharCount,
    required this.documents,
  });

  factory BookDetailDto.fromJson(Map<String, dynamic> json) =>
      _$BookDetailDtoFromJson(json);

  final String bookId;
  final String title;
  final int documentCount;
  final int totalCharCount;
  final List<BookDocumentDto> documents;
}

@JsonSerializable(createToJson: false)
class BookDocumentDto {
  const BookDocumentDto({
    required this.documentId,
    required this.sequence,
    required this.status,
    required this.charCount,
    required this.hasQuiz,
    required this.createdAt,
    this.title,
    this.preview,
    this.latestScore,
  });

  factory BookDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$BookDocumentDtoFromJson(json);

  final String documentId;
  final int sequence;
  final String status;
  final String? title;
  final String? preview;
  final int charCount;
  final bool hasQuiz;
  final BookScoreDto? latestScore;
  final DateTime createdAt;
}
