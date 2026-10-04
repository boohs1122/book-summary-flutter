// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JobAcceptedDto _$JobAcceptedDtoFromJson(Map<String, dynamic> json) =>
    JobAcceptedDto(jobId: json['jobId'] as String);

SummaryJobDto _$SummaryJobDtoFromJson(Map<String, dynamic> json) =>
    SummaryJobDto(
      jobId: json['jobId'] as String,
      status: json['status'] as String,
      documentId: json['documentId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      error: json['error'] == null
          ? null
          : JobErrorDto.fromJson(json['error'] as Map<String, dynamic>),
    );

JobErrorDto _$JobErrorDtoFromJson(Map<String, dynamic> json) =>
    JobErrorDto(code: json['code'] as String);

SummaryDocumentDto _$SummaryDocumentDtoFromJson(Map<String, dynamic> json) =>
    SummaryDocumentDto(
      documentId: json['documentId'] as String,
      bookId: json['bookId'] as String,
      bookTitle: json['bookTitle'] as String,
      sequence: (json['sequence'] as num).toInt(),
      extractedText: json['extractedText'] as String,
      status: json['status'] as String,
      summary: json['summary'] == null
          ? null
          : SummaryContentDto.fromJson(json['summary'] as Map<String, dynamic>),
    );

SummaryContentDto _$SummaryContentDtoFromJson(Map<String, dynamic> json) =>
    SummaryContentDto(
      title: json['title'] as String,
      keyPoints: (json['keyPoints'] as List<dynamic>)
          .map((e) => KeyPointDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      terms: (json['terms'] as List<dynamic>)
          .map((e) => TermDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

KeyPointDto _$KeyPointDtoFromJson(Map<String, dynamic> json) => KeyPointDto(
  type: json['type'] as String,
  heading: json['heading'] as String,
  detail: json['detail'] as String,
);

TermDto _$TermDtoFromJson(Map<String, dynamic> json) =>
    TermDto(term: json['term'] as String, meaning: json['meaning'] as String);
