import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../summary/domain/model/summary_document.dart';
import '../../../summary/presentation/provider/summary_job_provider.dart';
import '../../domain/model/quiz.dart';
import '../../domain/pending_quiz_store.dart';

final quizProvider = FutureProvider.family<Quiz, String>(
  (ref, documentId) => ref.watch(quizRepositoryProvider).getQuiz(documentId),
);

final quizFlowProvider = AsyncNotifierProvider<QuizFlowController, Quiz?>(
  QuizFlowController.new,
);

class QuizFlowController extends AsyncNotifier<Quiz?> {
  final _acceptedJobs = <String, PendingQuizJob>{};
  final _requests = <String, Future<Quiz>>{};

  @override
  Future<Quiz?> build() async => null;

  Future<Quiz> start(String documentId) =>
      _requests[documentId] ??= _start(documentId).whenComplete(() {
        _requests.remove(documentId);
      });

  Future<Quiz> _start(String documentId) async {
    state = const AsyncLoading();
    final store = ref.read(pendingQuizStoreProvider);
    try {
      final repository = ref.read(quizRepositoryProvider);
      var pending = _acceptedJobs[documentId] ?? await store.read(documentId);
      if (pending == null) {
        final request = await repository.requestQuiz(documentId);
        final jobId = request.jobId;
        if (jobId != null) {
          pending = PendingQuizJob(documentId: documentId, jobId: jobId);
        }
      }
      if (pending != null) {
        _acceptedJobs[documentId] = pending;
        await store.put(pending);
        final job = await _waitForJob(pending.jobId);
        if (job.status == SummaryJobStatus.failed) {
          throw QuizGenerationFailed(job.errorCode);
        }
      }
      final quiz = await repository.getQuiz(documentId);
      await store.remove(documentId);
      _acceptedJobs.remove(documentId);
      state = AsyncData(quiz);
      return quiz;
    } catch (error, stackTrace) {
      if (!ref.mounted) rethrow;
      state = AsyncError(error, stackTrace);
      if (error is SummaryJobExpired || error is QuizGenerationFailed) {
        await store.remove(documentId);
        _acceptedJobs.remove(documentId);
      }
      rethrow;
    }
  }

  Future<SummaryJob> _waitForJob(String jobId) async {
    final completed = Completer<SummaryJob>();

    ref.invalidate(summaryJobProvider(jobId));
    final subscription = ref.container.listen(summaryJobProvider(jobId), (
      _,
      next,
    ) {
      if (completed.isCompleted || next.isLoading) return;
      if (next.hasError) {
        completed.completeError(next.error!, next.stackTrace);
      } else {
        final job = next.value;
        if (job != null && job.status != SummaryJobStatus.processing) {
          completed.complete(job);
        }
      }
    }, fireImmediately: true);
    final removeDisposeListener = ref.onDispose(() {
      subscription.close();
      if (!completed.isCompleted) {
        completed.completeError(StateError('Quiz polling was disposed'));
      }
    });
    try {
      return await completed.future;
    } finally {
      removeDisposeListener();
      subscription.close();
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

final sessionQuizResultsProvider =
    NotifierProvider<SessionQuizResults, Map<String, QuizResultRouteArgs>>(
      SessionQuizResults.new,
    );

class SessionQuizResults extends Notifier<Map<String, QuizResultRouteArgs>> {
  @override
  Map<String, QuizResultRouteArgs> build() => {};
  void save(Quiz quiz, QuizResult result) {
    state = {...state, quiz.documentId: QuizResultRouteArgs(quiz, result)};
  }
}

final lastQuizResultProvider = Provider.family<QuizResultRouteArgs?, String>(
  (ref, documentId) => ref.watch(sessionQuizResultsProvider)[documentId],
);

class QuizSession {
  const QuizSession({
    required this.answers,
    this.current = 0,
    this.allowExit = false,
  });
  final List<int?> answers;
  final int current;
  final bool allowExit;
}

final quizSessionProvider = NotifierProvider.autoDispose
    .family<QuizSessionController, QuizSession, Quiz>(
      QuizSessionController.new,
    );

class QuizSessionController extends Notifier<QuizSession> {
  QuizSessionController(this.quiz);
  final Quiz quiz;
  @override
  QuizSession build() =>
      QuizSession(answers: List<int?>.filled(quiz.questions.length, null));
  void select(int? value) {
    final answers = [...state.answers];
    answers[state.current] = value;
    state = QuizSession(answers: answers, current: state.current);
  }

  void move(int index) =>
      state = QuizSession(answers: state.answers, current: index);
  void allowExit() => state = QuizSession(
    answers: state.answers,
    current: state.current,
    allowExit: true,
  );
}
