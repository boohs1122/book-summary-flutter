import 'package:go_router/go_router.dart';

import '../../features/library/presentation/screen/book_list_screen.dart';
import '../../features/library/presentation/screen/book_detail_screen.dart';
import '../../features/capture/presentation/screen/image_selection_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const capture = '/capture';

  static String bookDetail(String bookId) =>
      '/books/${Uri.encodeComponent(bookId)}';

  static String captureForBook(String bookId) =>
      '/capture?bookId=${Uri.encodeQueryComponent(bookId)}';
}

final appRouter = GoRouter(
  routes: [
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
