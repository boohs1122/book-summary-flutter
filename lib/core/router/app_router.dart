import 'package:go_router/go_router.dart';

import '../../features/library/presentation/screen/book_list_screen.dart';
import '../../features/library/presentation/screen/book_detail_screen.dart';
import '../../features/capture/presentation/screen/image_selection_screen.dart';
import '../../features/capture/presentation/screen/ocr_progress_screen.dart';
import '../../features/capture/presentation/screen/text_review_screen.dart';
import '../../features/capture/presentation/screen/book_selection_screen.dart';
import '../../features/summary/presentation/screen/summary_progress_screen.dart';
import '../../features/summary/presentation/screen/summary_screen.dart';
import '../../features/quiz/presentation/screen/quiz_play_screen.dart';
import '../../features/quiz/presentation/screen/quiz_result_screen.dart';
import '../../features/quiz/domain/model/quiz.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const capture = '/capture';
  static const ocr = '/capture/ocr';
  static const textReview = '/capture/text';
  static const bookSelection = '/capture/books';
  static const summaryProgress = '/summary/progress';
  static const summary = '/summary';
  static const quiz = '/quiz';
  static const quizResult = '/quiz/result';

  static String ocrForBook(String? bookId) => Uri(
    path: ocr,
    queryParameters: bookId == null ? null : {'bookId': bookId},
  ).toString();
  static String textReviewForBook(String? bookId) => Uri(
    path: textReview,
    queryParameters: bookId == null ? null : {'bookId': bookId},
  ).toString();

  static String bookDetail(String bookId) =>
      '/books/${Uri.encodeComponent(bookId)}';

  static String captureForBook(String bookId) =>
      '/capture?bookId=${Uri.encodeQueryComponent(bookId)}';

  static String summaryProgressForJob(
    String jobId,
    String bookId, {
    DateTime? createdAt,
  }) => Uri(
    path: summaryProgress,
    queryParameters: {
      'jobId': jobId,
      'bookId': bookId,
      if (createdAt != null) 'createdAt': createdAt.toIso8601String(),
    },
  ).toString();

  static String summaryForDocument(String documentId) => Uri(
    path: summary,
    queryParameters: {'documentId': documentId},
  ).toString();

  static String quizForDocument(String documentId) =>
      Uri(path: quiz, queryParameters: {'documentId': documentId}).toString();

  static String quizResultForDocument(String documentId) => Uri(
    path: quizResult,
    queryParameters: {'documentId': documentId},
  ).toString();
}

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: AppRoutes.ocr,
      builder: (context, state) =>
          OcrProgressScreen(bookId: state.uri.queryParameters['bookId']),
    ),
    GoRoute(
      path: AppRoutes.textReview,
      builder: (context, state) =>
          TextReviewScreen(bookId: state.uri.queryParameters['bookId']),
    ),
    GoRoute(
      path: AppRoutes.bookSelection,
      builder: (context, state) => const BookSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.summaryProgress,
      builder: (context, state) => SummaryProgressScreen(
        jobId: state.uri.queryParameters['jobId']!,
        bookId: state.uri.queryParameters['bookId']!,
        createdAt: DateTime.tryParse(
          state.uri.queryParameters['createdAt'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.summary,
      builder: (context, state) =>
          SummaryScreen(documentId: state.uri.queryParameters['documentId']!),
    ),
    GoRoute(
      path: AppRoutes.quiz,
      builder: (context, state) => QuizPlayScreen(
        documentId: state.uri.queryParameters['documentId']!,
        initialQuiz: state.extra is Quiz ? state.extra! as Quiz : null,
      ),
    ),
    GoRoute(
      path: AppRoutes.quizResult,
      builder: (context, state) => QuizResultScreen(
        documentId: state.uri.queryParameters['documentId']!,
        args: state.extra is QuizResultRouteArgs
            ? state.extra! as QuizResultRouteArgs
            : null,
      ),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const BookListScreen(),
    ),
    GoRoute(
      path: '/books/:bookId',
      builder: (context, state) =>
          BookDetailScreen(bookId: state.pathParameters['bookId']!),
    ),
    GoRoute(
      path: AppRoutes.capture,
      builder: (context, state) =>
          ImageSelectionScreen(bookId: state.uri.queryParameters['bookId']),
    ),
  ],
);
