import 'package:json_annotation/json_annotation.dart';

part 'summary_dto.g.dart';

@JsonSerializable(createToJson: false)
class JobAcceptedDto {
  const JobAcceptedDto({required this.jobId});
  factory JobAcceptedDto.fromJson(Map<String, dynamic> json) =>
      _$JobAcceptedDtoFromJson(json);
  final String jobId;
}

@JsonSerializable(createToJson: false)
class SummaryJobDto {
  const SummaryJobDto({
    required this.jobId,
    required this.status,
    this.documentId,
    this.createdAt,
    this.error,
  });
  factory SummaryJobDto.fromJson(Map<String, dynamic> json) =>
      _$SummaryJobDtoFromJson(json);
  final String jobId;
  final String status;
  final String? documentId;
  final DateTime? createdAt;
  final JobErrorDto? error;
}

@JsonSerializable(createToJson: false)
class JobErrorDto {
  const JobErrorDto({required this.code});
  factory JobErrorDto.fromJson(Map<String, dynamic> json) =>
      _$JobErrorDtoFromJson(json);
  final String code;
}

@JsonSerializable(createToJson: false)
class SummaryDocumentDto {
  const SummaryDocumentDto({
    required this.documentId,
    required this.bookId,
    required this.bookTitle,
    required this.sequence,
    required this.extractedText,
    required this.status,
    this.summary,
    this.quiz,
  });
  factory SummaryDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$SummaryDocumentDtoFromJson(json);
  final String documentId;
  final String bookId;
  final String bookTitle;
  final int sequence;
  final String extractedText;
  final String status;
  final SummaryContentDto? summary;
  final SummaryQuizDto? quiz;
}

@JsonSerializable(createToJson: false)
class SummaryQuizDto {
  const SummaryQuizDto({required this.exists, this.latestScore});
  factory SummaryQuizDto.fromJson(Map<String, dynamic> json) =>
      _$SummaryQuizDtoFromJson(json);
  final bool exists;
  final SummaryScoreDto? latestScore;
}

@JsonSerializable(createToJson: false)
class SummaryScoreDto {
  const SummaryScoreDto({required this.correct, required this.total});
  factory SummaryScoreDto.fromJson(Map<String, dynamic> json) =>
      _$SummaryScoreDtoFromJson(json);
  final int correct;
  final int total;
}

@JsonSerializable(createToJson: false)
class SummaryContentDto {
  const SummaryContentDto({
    required this.title,
    required this.keyPoints,
    required this.terms,
  });
  factory SummaryContentDto.fromJson(Map<String, dynamic> json) =>
      _$SummaryContentDtoFromJson(json);
  final String title;
  final List<KeyPointDto> keyPoints;
  final List<TermDto> terms;
}

@JsonSerializable(createToJson: false)
class KeyPointDto {
  const KeyPointDto({
    required this.type,
    required this.heading,
    required this.detail,
  });
  factory KeyPointDto.fromJson(Map<String, dynamic> json) =>
      _$KeyPointDtoFromJson(json);
  final String type;
  final String heading;
  final String detail;
}

@JsonSerializable(createToJson: false)
class TermDto {
  const TermDto({required this.term, required this.meaning});
  factory TermDto.fromJson(Map<String, dynamic> json) =>
      _$TermDtoFromJson(json);
  final String term;
  final String meaning;
}
