import 'package:go_router/go_router.dart';

import '../../features/library/presentation/screen/book_list_screen.dart';
import '../../features/library/presentation/screen/book_detail_screen.dart';
import '../../features/capture/presentation/screen/image_selection_screen.dart';
import '../../features/capture/presentation/screen/ocr_progress_screen.dart';
import '../../features/capture/presentation/screen/text_review_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const capture = '/capture';
  static const ocr = '/capture/ocr';
  static const textReview = '/capture/text';

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
