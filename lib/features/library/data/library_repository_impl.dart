import 'package:dio/dio.dart';

import '../domain/library_repository.dart';
import '../domain/model/book.dart';
import 'dto/book_list_dto.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Book>> getBooks() async {
    final response = await _dio.get<Map<String, dynamic>>('/books');
    final dto = BookListDto.fromJson(response.data!);
    return dto.items.map((item) {
      final score = item.latestScore;
      return Book(
        id: item.bookId,
        title: item.title,
        documentCount: item.documentCount,
        totalCharCount: item.totalCharCount,
        createdAt: item.createdAt,
        lastStudiedAt: item.lastStudiedAt,
        latestScore: score == null
            ? null
            : BookScore(correct: score.correct, total: score.total),
      );
    }).toList();
  }
}
