import 'package:dio/dio.dart';

import '../domain/model/quiz.dart';
import '../domain/quiz_repository.dart';
import 'dto/quiz_dto.dart';

class QuizRepositoryImpl implements QuizRepository {
  const QuizRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<QuizRequest> requestQuiz(String documentId) async {
    Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        '/documents/${Uri.encodeComponent(documentId)}/quiz',
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      final body = data is Map ? data['error'] : null;
      if (error.response?.statusCode == 409 &&
          body is Map &&
          body['code'] == 'JOB_IN_PROGRESS') {
        throw QuizAlreadyGenerating();
      }
      rethrow;
    }
    final dto = QuizRequestDto.fromJson(response.data!);
    return dto.jobId == null
        ? const QuizRequest.existing()
        : QuizRequest.accepted(dto.jobId!);
  }

  @override
  Future<Quiz> getQuiz(String documentId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/documents/${Uri.encodeComponent(documentId)}/quiz',
    );
    final dto = QuizDto.fromJson(response.data!);
    return Quiz(
      id: dto.quizId,
      documentId: dto.documentId,
      questions: dto.questions
          .map(
            (question) => QuizQuestion(
              index: question.index,
              question: question.question,
              options: question.options,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<QuizResult> submitResult(
    String quizId,
    List<QuizAnswer> answers,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/quizzes/${Uri.encodeComponent(quizId)}/results',
      data: {
        'answers': answers
            .map(
              (answer) => {'index': answer.index, 'selected': answer.selected},
            )
            .toList(),
      },
    );
    final dto = QuizResultDto.fromJson(response.data!);
    return QuizResult(
      id: dto.resultId,
      correct: dto.score.correct,
      total: dto.score.total,
      items: dto.items
          .map(
            (item) => QuizResultItem(
              index: item.index,
              question: item.question,
              options: item.options,
              selected: item.selected,
              answerIndex: item.answerIndex,
              correct: item.correct,
              explanation: item.explanation,
            ),
          )
          .toList(),
    );
  }
}
