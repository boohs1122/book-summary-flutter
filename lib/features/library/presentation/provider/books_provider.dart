import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../domain/model/book.dart';

final booksProvider = FutureProvider<List<Book>>((ref) {
  return ref.watch(libraryRepositoryProvider).getBooks();
});
