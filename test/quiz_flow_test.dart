import 'package:booksummary/core/di/repository_providers.dart';
import 'package:booksummary/core/router/app_router.dart';
import 'package:booksummary/features/quiz/domain/model/quiz.dart';
import 'package:booksummary/features/quiz/domain/pending_quiz_store.dart';
import 'package:booksummary/features/quiz/domain/quiz_repository.dart';
import 'package:booksummary/features/quiz/presentation/provider/quiz_provider.dart';
import 'package:booksummary/features/quiz/presentation/screen/quiz_play_screen.dart';
import 'package:booksummary/features/quiz/presentation/screen/quiz_result_screen.dart';
import 'package:booksummary/features/summary/domain/model/summary_document.dart';
import 'package:booksummary/features/summary/domain/summary_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _quiz = Quiz(
  id: 'quiz',
  documentId: 'document',
  questions: [
    QuizQuestion(
      index: 0,
      question: '첫 번째 문제',
      options: ['선택 A', '선택 B', '선택 C', '선택 D'],
    ),
    QuizQuestion(
      index: 1,
      question: '두 번째 문제',
      options: ['선택 E', '선택 F', '선택 G', '선택 H'],
    ),
  ],
);

class _Quizzes extends Fake implements QuizRepository {
  int requests = 0;
  bool submissionFails = false;
  List<QuizAnswer>? answers;

  @override
  Future<QuizRequest> requestQuiz(String documentId) async {
    requests++;
    return const QuizRequest.accepted('job');
  }

  @override
  Future<Quiz> getQuiz(String documentId) async => _quiz;

  @override
  Future<QuizResult> submitResult(
    String quizId,
    List<QuizAnswer> answers,
  ) async {
    this.answers = answers;
    if (submissionFails) {
      throw DioException(
        requestOptions: RequestOptions(path: '/results'),
        type: DioExceptionType.connectionError,
      );
    }
    return const QuizResult(id: 'result', correct: 1, total: 2, items: []);
  }
}

class _Jobs extends Fake implements SummaryRepository {
  Object? error;
  SummaryJobStatus status = SummaryJobStatus.done;
  int polls = 0;

  @override
  Future<SummaryJob> getJob(String jobId) async {
    polls++;
    if (error != null) throw error!;
    return SummaryJob(id: jobId, status: status, errorCode: 'LLM_ERROR');
  }
}

class _Store implements PendingQuizStore {
  final jobs = <String, PendingQuizJob>{};
  @override
  Future<PendingQuizJob?> read(String documentId) async => jobs[documentId];
  @override
  Future<void> put(PendingQuizJob job) async => jobs[job.documentId] = job;
  @override
  Future<void> remove(String documentId) async => jobs.remove(documentId);
}

void main() {
  test(
    'offline polling retry resumes the saved job without generating twice',
    () async {
      final quizzes = _Quizzes();
      final jobs = _Jobs()..error = Exception('offline');
      final store = _Store();
      final container = ProviderContainer(
        retry: (count, error) => null,
        overrides: [
          quizRepositoryProvider.overrideWithValue(quizzes),
          summaryRepositoryProvider.overrideWithValue(jobs),
          pendingQuizStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      await container.read(quizFlowProvider.future);
      final flow = container.read(quizFlowProvider.notifier);
      await expectLater(flow.start('document'), throwsException);
      expect(store.jobs['document']?.jobId, 'job');
      jobs.error = null;
      expect((await flow.start('document')).id, 'quiz');
      expect(quizzes.requests, 1);
      expect(jobs.polls, 2);
      expect(store.jobs, isEmpty);
    },
  );

  test('failed generation discards the job and allows a new request', () async {
    final quizzes = _Quizzes();
    final jobs = _Jobs()..status = SummaryJobStatus.failed;
    final store = _Store();
    final container = ProviderContainer(
      retry: (count, error) => null,
      overrides: [
        quizRepositoryProvider.overrideWithValue(quizzes),
        summaryRepositoryProvider.overrideWithValue(jobs),
        pendingQuizStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    await container.read(quizFlowProvider.future);
    final flow = container.read(quizFlowProvider.notifier);
    await expectLater(
      flow.start('document'),
      throwsA(isA<QuizGenerationFailed>()),
    );
    expect(store.jobs, isEmpty);
    jobs.status = SummaryJobStatus.done;
    await flow.start('document');
    expect(quizzes.requests, 2);
  });

  testWidgets(
    'unanswered confirmation sends null and submission retry preserves selections',
    (tester) async {
      final quizzes = _Quizzes()..submissionFails = true;
      final router = GoRouter(
        initialLocation: '/quiz',
        routes: [
          GoRoute(
            path: '/quiz',
            builder: (context, state) => const QuizPlayScreen(
              documentId: 'document',
              initialQuiz: _quiz,
            ),
          ),
          GoRoute(
            path: AppRoutes.quizResult,
            builder: (context, state) => QuizResultScreen(
              documentId: 'document',
              args: state.extra! as QuizResultRouteArgs,
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [quizRepositoryProvider.overrideWithValue(quizzes)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('선택 F'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('채점하기'));
      await tester.pumpAndSettle();
      expect(find.text('1개 문항은 오답으로 처리됩니다. 제출할까요?'), findsOneWidget);
      await tester.tap(find.text('제출하기'));
      await tester.pumpAndSettle();
      expect(find.text('서버에 연결할 수 없습니다. 연결 상태를 확인해 주세요.'), findsOneWidget);
      expect(quizzes.answers!.map((answer) => answer.selected), [null, 1]);
      quizzes.submissionFails = false;
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('채점하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('제출하기'));
      await tester.pumpAndSettle();
      expect(find.text('채점 결과'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(quizzes.answers!.map((answer) => answer.selected), [null, 1]);
    },
  );
}
