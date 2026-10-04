import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../summary/domain/model/summary_document.dart';
import '../../domain/model/quiz.dart';
import '../../domain/pending_quiz_store.dart';

final quizPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 2),
);

final quizProvider = FutureProvider.family<Quiz, String>(
  (ref, documentId) => ref.watch(quizRepositoryProvider).getQuiz(documentId),
);

final quizFlowProvider = AsyncNotifierProvider<QuizFlowController, Quiz?>(
  QuizFlowController.new,
);

class QuizFlowController extends AsyncNotifier<Quiz?> {
  @override
  Future<Quiz?> build() async => null;

  Future<Quiz> start(String documentId) async {
    state = const AsyncLoading();
    try {
      final store = ref.read(pendingQuizStoreProvider);
      final repository = ref.read(quizRepositoryProvider);
      final pending = await store.read(documentId);
      String? jobId = pending?.jobId;
      if (jobId == null) {
        final request = await repository.requestQuiz(documentId);
        jobId = request.jobId;
        if (jobId != null) {
          await store.put(PendingQuizJob(documentId: documentId, jobId: jobId));
        }
      }
      if (jobId != null) {
        while (true) {
          final job = await ref.read(summaryRepositoryProvider).getJob(jobId);
          if (job.status == SummaryJobStatus.done) break;
          if (job.status == SummaryJobStatus.failed) {
            await store.remove(documentId);
            throw QuizGenerationFailed(job.errorCode);
          }
          await Future<void>.delayed(ref.read(quizPollIntervalProvider));
        }
      }
      final quiz = await repository.getQuiz(documentId);
      await store.remove(documentId);
      state = AsyncData(quiz);
      return quiz;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final quizResultProvider =
    AsyncNotifierProvider<QuizResultController, QuizResult?>(
      QuizResultController.new,
    );

class QuizResultController extends AsyncNotifier<QuizResult?> {
  @override
  Future<QuizResult?> build() async => null;

  Future<QuizResult> submit(String quizId, List<QuizAnswer> answers) async {
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(quizRepositoryProvider)
          .submitResult(quizId, answers);
      state = AsyncData(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
