// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_detail_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookDetailDto _$BookDetailDtoFromJson(Map<String, dynamic> json) =>
    BookDetailDto(
      bookId: json['bookId'] as String,
      title: json['title'] as String,
      documentCount: (json['documentCount'] as num).toInt(),
      totalCharCount: (json['totalCharCount'] as num).toInt(),
      documents: (json['documents'] as List<dynamic>)
          .map((e) => BookDocumentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

BookDocumentDto _$BookDocumentDtoFromJson(Map<String, dynamic> json) =>
    BookDocumentDto(
      documentId: json['documentId'] as String,
      sequence: (json['sequence'] as num).toInt(),
      status: json['status'] as String,
      charCount: (json['charCount'] as num).toInt(),
      hasQuiz: json['hasQuiz'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      title: json['title'] as String?,
      preview: json['preview'] as String?,
      latestScore: json['latestScore'] == null
          ? null
          : BookScoreDto.fromJson(json['latestScore'] as Map<String, dynamic>),
    );
