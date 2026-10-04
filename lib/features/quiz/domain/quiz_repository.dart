import 'model/quiz.dart';

abstract class QuizRepository {
  Future<QuizRequest> requestQuiz(String documentId);
  Future<Quiz> getQuiz(String documentId);
  Future<QuizResult> submitResult(String quizId, List<QuizAnswer> answers);
}

class QuizRequest {
  const QuizRequest.existing() : jobId = null;
  const QuizRequest.accepted(this.jobId);
  final String? jobId;
}
