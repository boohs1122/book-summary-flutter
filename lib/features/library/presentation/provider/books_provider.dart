import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../domain/model/book.dart';
import '../../domain/model/book_detail.dart';

final booksProvider = FutureProvider<List<Book>>((ref) {
  return ref.watch(libraryRepositoryProvider).getBooks();
});

final bookDetailProvider = FutureProvider.family<BookDetail, String>((
  ref,
  bookId,
) {
  return ref.watch(libraryRepositoryProvider).getBook(bookId);
});
