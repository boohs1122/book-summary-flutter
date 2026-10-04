import 'package:dio/dio.dart';

import '../domain/library_repository.dart';
import '../domain/model/book.dart';
import '../domain/model/book_detail.dart';
import 'dto/book_detail_dto.dart';
import 'dto/book_list_dto.dart';
import 'dto/book_created_dto.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<String> createBook(String title) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/books',
      data: {'title': title},
    );
    return BookCreatedDto.fromJson(response.data!).bookId;
  }

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

  @override
  Future<void> deleteBook(String bookId) async {
    await _dio.delete<void>('/books/${Uri.encodeComponent(bookId)}');
  }

  @override
  Future<BookDetail> getBook(String bookId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/books/${Uri.encodeComponent(bookId)}',
    );
    final dto = BookDetailDto.fromJson(response.data!);
    return BookDetail(
      id: dto.bookId,
      title: dto.title,
      documentCount: dto.documentCount,
      totalCharCount: dto.totalCharCount,
      documents: dto.documents.map((document) {
        final score = document.latestScore;
        return BookDocument(
          id: document.documentId,
          sequence: document.sequence,
          status: document.status,
          title: document.title,
          preview: document.preview,
          charCount: document.charCount,
          hasQuiz: document.hasQuiz,
          createdAt: document.createdAt,
          latestScore: score == null
              ? null
              : BookScore(correct: score.correct, total: score.total),
        );
      }).toList(),
    );
  }
}
