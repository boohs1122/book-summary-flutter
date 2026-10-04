import 'package:json_annotation/json_annotation.dart';

part 'quiz_dto.g.dart';

@JsonSerializable(createToJson: false)
class QuizRequestDto {
  const QuizRequestDto({this.jobId, this.quizId});
  factory QuizRequestDto.fromJson(Map<String, dynamic> json) =>
      _$QuizRequestDtoFromJson(json);
  final String? jobId;
  final String? quizId;
}

@JsonSerializable(createToJson: false)
class QuizDto {
  const QuizDto({
    required this.quizId,
    required this.documentId,
    required this.questions,
  });
  factory QuizDto.fromJson(Map<String, dynamic> json) =>
      _$QuizDtoFromJson(json);
  final String quizId;
  final String documentId;
  final List<QuizQuestionDto> questions;
}

@JsonSerializable(createToJson: false)
class QuizQuestionDto {
  const QuizQuestionDto({
    required this.index,
    required this.question,
    required this.options,
  });
  factory QuizQuestionDto.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionDtoFromJson(json);
  final int index;
  final String question;
  final List<String> options;
}

@JsonSerializable(createToJson: false)
class QuizResultDto {
  const QuizResultDto({
    required this.resultId,
    required this.score,
    required this.items,
  });
  factory QuizResultDto.fromJson(Map<String, dynamic> json) =>
      _$QuizResultDtoFromJson(json);
  final String resultId;
  final QuizScoreDto score;
  final List<QuizResultItemDto> items;
}

@JsonSerializable(createToJson: false)
class QuizScoreDto {
  const QuizScoreDto({required this.correct, required this.total});
  factory QuizScoreDto.fromJson(Map<String, dynamic> json) =>
      _$QuizScoreDtoFromJson(json);
  final int correct;
  final int total;
}

@JsonSerializable(createToJson: false)
class QuizResultItemDto {
  const QuizResultItemDto({
    required this.index,
    required this.question,
    required this.options,
    this.selected,
    required this.answerIndex,
    required this.correct,
    required this.explanation,
  });
  factory QuizResultItemDto.fromJson(Map<String, dynamic> json) =>
      _$QuizResultItemDtoFromJson(json);
  final int index;
  final String question;
  final List<String> options;
  final int? selected;
  final int answerIndex;
  final bool correct;
  final String explanation;
}
