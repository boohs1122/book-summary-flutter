import 'dart:async';

import 'package:booksummary/core/di/repository_providers.dart';
import 'package:booksummary/core/theme/app_theme.dart';
import 'package:booksummary/features/capture/domain/ocr_repository.dart';
import 'package:booksummary/features/capture/presentation/provider/ocr_provider.dart';
import 'package:booksummary/features/library/domain/library_repository.dart';
import 'package:booksummary/features/library/domain/model/book.dart';
import 'package:booksummary/features/library/domain/model/book_detail.dart';
import 'package:booksummary/features/summary/domain/summary_repository.dart';
import 'package:booksummary/features/summary/domain/model/summary_document.dart';
import 'package:booksummary/features/summary/domain/model/pending_summary_job.dart';
import 'package:booksummary/features/summary/domain/pending_job_store.dart';
import 'package:booksummary/features/quiz/domain/model/quiz.dart';
import 'package:booksummary/features/quiz/domain/quiz_repository.dart';
import 'package:booksummary/features/quiz/domain/pending_quiz_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const previewText =
    '프로세스는 실행 중인 프로그램이다. 운영체제는 각 프로세스의 정보를 PCB에 저장하고 CPU 스케줄러를 통해 실행 순서를 정한다. 문맥 교환은 현재 실행 중인 프로세스의 상태를 저장하고 다음 프로세스의 상태를 복원하는 과정이다.';
const previewDocument = SummaryDocument(
  id: 'document',
  bookId: 'book',
  bookTitle: '운영체제',
  sequence: 3,
  text: previewText,
  status: SummaryJobStatus.done,
  quizExists: true,
  latestCorrect: 2,
  latestTotal: 3,
  summary: SummaryContent(
    title: '프로세스와 문맥 교환',
    keyPoints: [
      SummaryKeyPoint(
        type: KeyPointType.definition,
        heading: '실행 중인 프로그램',
        detail: '프로세스는 실행 중인 프로그램이다. 운영체제는 프로세스의 상태와 자원을 관리한다.',
      ),
      SummaryKeyPoint(
        type: KeyPointType.mechanism,
        heading: '문맥 교환의 과정',
        detail: '현재 프로세스의 상태를 PCB에 저장하고 다음 프로세스의 상태를 복원한다.',
      ),
      SummaryKeyPoint(
        type: KeyPointType.caution,
        heading: '전환 비용',
        detail: '문맥 교환 중에는 CPU가 사용자 프로그램을 실행하지 못하므로 전환 비용이 발생한다.',
      ),
    ],
    terms: [
      SummaryTerm(term: '프로세스', meaning: '실행 중인 프로그램'),
      SummaryTerm(term: 'PCB', meaning: '프로세스의 상태와 실행 정보를 저장하는 자료구조'),
      SummaryTerm(term: 'CPU', meaning: '프로그램의 명령을 실행하는 처리 장치'),
    ],
  ),
);
const previewQuiz = Quiz(
  id: 'quiz',
  documentId: 'document',
  questions: [
    QuizQuestion(
      index: 0,
      question: '프로세스를 가장 잘 설명한 것은 무엇인가요?',
      options: ['실행 중인 프로그램', '디스크에 저장된 파일', '컴퓨터의 입력 장치', '운영체제의 설치 과정'],
    ),
    QuizQuestion(
      index: 1,
      question: '프로세스의 상태와 실행 정보를 저장하는 곳은?',
      options: ['캐시', 'PCB', '입출력 장치', '파일 시스템'],
    ),
    QuizQuestion(
      index: 2,
      question: '문맥 교환 중 발생하는 전환 비용의 이유는?',
      options: [
        '디스크를 포맷하기 때문',
        '네트워크를 연결하기 때문',
        '사용자 프로그램의 실행이 멈추기 때문',
        '모든 파일을 삭제하기 때문',
      ],
    ),
  ],
);
final previewResult = QuizResult(
  id: 'result',
  correct: 2,
  total: 3,
  items: [
    for (final question in previewQuiz.questions)
      QuizResultItem(
        index: question.index,
        question: question.question,
        options: question.options,
        selected: question.index == 1
            ? 0
            : question.index == 0
            ? 0
            : 2,
        answerIndex: question.index == 0
            ? 0
            : question.index == 1
            ? 1
            : 2,
        correct: question.index != 1,
        explanation: question.index == 1
            ? 'PCB는 프로세스의 상태와 실행 정보를 보관한다. 캐시와 구분해 기억하자.'
            : '프로세스의 정의와 문맥 교환 과정을 확인해 보세요.',
      ),
  ],
);

class PreviewLibrary extends Fake implements LibraryRepository {
  bool empty = false;
  bool fails = false;
  bool processing = false;
  @override
  Future<List<Book>> getBooks() async {
    if (fails) throw Exception('offline');
    if (empty) return [];
    return [
      Book(
        id: 'book',
        title: '운영체제',
        documentCount: 3,
        totalCharCount: 2100,
        createdAt: DateTime(2026, 10, 1),
        lastStudiedAt: DateTime(2026, 10, 6),
        latestScore: const BookScore(correct: 2, total: 3),
      ),
      Book(
        id: 'other',
        title: '생각의 탄생',
        documentCount: 2,
        totalCharCount: 1500,
        createdAt: DateTime(2026, 10, 2),
      ),
    ];
  }

  @override
  Future<BookDetail> getBook(String bookId) async => BookDetail(
    id: bookId,
    title: '운영체제',
    documentCount: 3,
    totalCharCount: 2100,
    documents: [
      for (var i = 3; i > 0; i--)
        BookDocument(
          id: i == 3 ? 'document' : 'document-$i',
          sequence: i,
          status: processing ? 'PROCESSING' : 'DONE',
          charCount: 700,
          hasQuiz: i == 3,
          createdAt: DateTime(2026, 10, i),
          title: i == 3
              ? '프로세스와 문맥 교환'
              : i == 2
              ? '메모리 관리'
              : '운영체제의 역할',
          latestScore: i == 3 ? const BookScore(correct: 2, total: 3) : null,
        ),
    ],
  );
  @override
  Future<String> createBook(String title) async => 'book';
}

class PreviewSummary extends Fake implements SummaryRepository {
  @override
  Future<SummaryDocument> getDocument(String documentId) async =>
      previewDocument;
  @override
  Future<SummaryJob> getJob(String jobId) async =>
      SummaryJob(id: jobId, status: SummaryJobStatus.processing);
  @override
  Future<String> submitText({
    required String bookId,
    required String text,
  }) async => 'job';
}

class PreviewQuizRepository extends Fake implements QuizRepository {
  @override
  Future<Quiz> getQuiz(String documentId) async => previewQuiz;
  @override
  Future<QuizRequest> requestQuiz(String documentId) async =>
      const QuizRequest.existing();
  @override
  Future<QuizResult> submitResult(
    String quizId,
    List<QuizAnswer> answers,
  ) async => previewResult;
}

class PreviewJobs implements PendingJobStore {
  final jobs = <String, PendingSummaryJob>{};
  @override
  Future<List<PendingSummaryJob>> read() async => jobs.values.toList();
  @override
  Future<void> put(PendingSummaryJob job) async {
    jobs[job.jobId] = job;
  }

  @override
  Future<void> remove(String jobId) async {
    jobs.remove(jobId);
  }
}

class PreviewQuizzes implements PendingQuizStore {
  @override
  Future<PendingQuizJob?> read(String documentId) async => null;
  @override
  Future<void> put(PendingQuizJob job) async {}
  @override
  Future<void> remove(String documentId) async {}
}

class PreviewOcr extends Fake implements OcrRepository {
  final response = Completer<String>();
  @override
  Future<String> recognize(String path) => response.future;
}

ProviderContainer previewContainer({PreviewLibrary? library}) {
  final container = ProviderContainer(
    overrides: [
      libraryRepositoryProvider.overrideWithValue(library ?? PreviewLibrary()),
      summaryRepositoryProvider.overrideWithValue(PreviewSummary()),
      quizRepositoryProvider.overrideWithValue(PreviewQuizRepository()),
      pendingJobStoreProvider.overrideWithValue(PreviewJobs()),
      pendingQuizStoreProvider.overrideWithValue(PreviewQuizzes()),
      ocrRepositoryProvider.overrideWithValue(PreviewOcr()),
    ],
  );
  container.read(textDraftProvider.notifier).update(previewText);
  return container;
}

Widget previewApp({
  required ProviderContainer container,
  required GoRouter router,
  bool dark = false,
  double textScale = 1,
}) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    routerConfig: router,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
  ),
);
