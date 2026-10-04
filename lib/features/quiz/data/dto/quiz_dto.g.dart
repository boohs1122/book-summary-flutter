// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizRequestDto _$QuizRequestDtoFromJson(Map<String, dynamic> json) =>
    QuizRequestDto(
      jobId: json['jobId'] as String?,
      quizId: json['quizId'] as String?,
    );

QuizDto _$QuizDtoFromJson(Map<String, dynamic> json) => QuizDto(
  quizId: json['quizId'] as String,
  documentId: json['documentId'] as String,
  questions: (json['questions'] as List<dynamic>)
      .map((e) => QuizQuestionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

QuizQuestionDto _$QuizQuestionDtoFromJson(Map<String, dynamic> json) =>
    QuizQuestionDto(
      index: (json['index'] as num).toInt(),
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

QuizResultDto _$QuizResultDtoFromJson(Map<String, dynamic> json) =>
    QuizResultDto(
      resultId: json['resultId'] as String,
      score: QuizScoreDto.fromJson(json['score'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>)
          .map((e) => QuizResultItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

QuizScoreDto _$QuizScoreDtoFromJson(Map<String, dynamic> json) => QuizScoreDto(
  correct: (json['correct'] as num).toInt(),
  total: (json['total'] as num).toInt(),
);

QuizResultItemDto _$QuizResultItemDtoFromJson(Map<String, dynamic> json) =>
    QuizResultItemDto(
      index: (json['index'] as num).toInt(),
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      selected: (json['selected'] as num?)?.toInt(),
      answerIndex: (json['answerIndex'] as num).toInt(),
      correct: json['correct'] as bool,
      explanation: json['explanation'] as String,
    );
