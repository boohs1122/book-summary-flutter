// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookListDto _$BookListDtoFromJson(Map<String, dynamic> json) => BookListDto(
  items: (json['items'] as List<dynamic>)
      .map((e) => BookDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['nextCursor'] as String?,
);

BookDto _$BookDtoFromJson(Map<String, dynamic> json) => BookDto(
  bookId: json['bookId'] as String,
  title: json['title'] as String,
  documentCount: (json['documentCount'] as num).toInt(),
  totalCharCount: (json['totalCharCount'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  lastStudiedAt: json['lastStudiedAt'] == null
      ? null
      : DateTime.parse(json['lastStudiedAt'] as String),
  latestScore: json['latestScore'] == null
      ? null
      : BookScoreDto.fromJson(json['latestScore'] as Map<String, dynamic>),
);

BookScoreDto _$BookScoreDtoFromJson(Map<String, dynamic> json) => BookScoreDto(
  correct: (json['correct'] as num).toInt(),
  total: (json['total'] as num).toInt(),
);
