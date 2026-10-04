import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../summary/presentation/provider/summary_job_provider.dart';
import 'books_provider.dart';

final bookTitleProvider = AsyncNotifierProvider<BookTitleController, void>(
  BookTitleController.new,
);

class BookTitleController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> rename(String bookId, String title) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () =>
          ref.read(libraryRepositoryProvider).renameBook(bookId, title.trim()),
    );
    if (state.hasError) return false;
    ref.invalidate(booksProvider);
    ref.invalidate(bookDetailProvider(bookId));
    ref.invalidate(summaryDocumentProvider);
    return true;
  }
}
