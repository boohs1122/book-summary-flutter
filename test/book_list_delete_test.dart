import 'package:booksummary/core/di/repository_providers.dart';
import 'package:booksummary/features/library/domain/library_repository.dart';
import 'package:booksummary/features/library/domain/model/book.dart';
import 'package:booksummary/features/library/domain/model/book_detail.dart';
import 'package:booksummary/features/library/presentation/screen/book_list_screen.dart';
import 'package:booksummary/features/library/presentation/widget/book_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLibraryRepository implements LibraryRepository {
  bool deleted = false;
  int deleteAttempts = 0;

  @override
  Future<List<Book>> getBooks() async => deleted
      ? []
      : [
          Book(
            id: 'book-1',
            title: '테스트 책',
            documentCount: 2,
            totalCharCount: 1000,
            createdAt: DateTime.utc(2026),
          ),
        ];

  @override
  Future<BookDetail> getBook(String bookId) => throw UnimplementedError();

  @override
  Future<void> deleteBook(String bookId) async {
    deleteAttempts++;
    if (deleteAttempts == 1) {
      throw DioException(
        requestOptions: RequestOptions(path: '/books/$bookId'),
        type: DioExceptionType.connectionError,
      );
    }
    deleted = true;
  }
}

void main() {
  testWidgets('failed deletion keeps the book and retry deletes it', (
    tester,
  ) async {
    final repository = _FakeLibraryRepository();
    await tester.pumpWidget(
      ProviderScope(
        retry: (count, error) => null,
        overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: BookListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> swipeAndConfirm() async {
      await tester.drag(find.byType(BookCard), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('2회차가 포함'), findsOneWidget);
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
    }

    await swipeAndConfirm();
    expect(repository.deleteAttempts, 1);
    expect(find.text('테스트 책'), findsOneWidget);

    await swipeAndConfirm();
    expect(repository.deleteAttempts, 2);
    expect(find.text('아직 등록된 책이 없습니다.'), findsOneWidget);
  });
}
