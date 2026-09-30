import 'package:go_router/go_router.dart';

import '../../features/library/presentation/screen/book_list_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
}

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const BookListScreen(),
    ),
  ],
);
