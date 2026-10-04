import 'package:booksummary/core/di/repository_providers.dart';
import 'package:booksummary/features/library/domain/library_repository.dart';
import 'package:booksummary/features/library/domain/model/book.dart';
import 'package:booksummary/features/library/domain/model/book_detail.dart';
import 'package:booksummary/features/library/presentation/provider/book_title_provider.dart';
import 'package:booksummary/features/library/presentation/provider/books_provider.dart';
import 'package:booksummary/features/library/presentation/widget/book_title_dialog.dart';
import 'package:booksummary/features/summary/domain/model/summary_document.dart';
import 'package:booksummary/features/summary/presentation/provider/summary_job_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Library extends Fake implements LibraryRepository {
  String title = '기존 제목';
  int attempts = 0;
  bool fail = false;

  @override
  Future<void> renameBook(String bookId, String title) async {
    attempts++;
    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(path: '/books/$bookId'),
        type: DioExceptionType.connectionError,
      );
    }
    this.title = title;
  }

  @override
  Future<List<Book>> getBooks() async => [
    Book(
      id: 'book',
      title: title,
      documentCount: 1,
      totalCharCount: 300,
      createdAt: DateTime.utc(2026),
    ),
  ];

  @override
  Future<BookDetail> getBook(String bookId) async => BookDetail(
    id: bookId,
    title: title,
    documentCount: 1,
    totalCharCount: 300,
    documents: [],
  );
}

void main() {
  test(
    'successful rename refreshes book list, detail and cached summary title',
    () async {
      final library = _Library();
      final container = ProviderContainer(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(library),
          summaryDocumentProvider.overrideWith(
            (ref, documentId) async => SummaryDocument(
              id: documentId,
              bookId: 'book',
              bookTitle: library.title,
              sequence: 1,
              text: '원문',
              status: SummaryJobStatus.done,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        (await container.read(booksProvider.future)).single.title,
        '기존 제목',
      );
      expect(
        (await container.read(bookDetailProvider('book').future)).title,
        '기존 제목',
      );
      expect(
        (await container.read(summaryDocumentProvider('document').future))
            .bookTitle,
        '기존 제목',
      );
      expect(
        await container
            .read(bookTitleProvider.notifier)
            .rename('book', '  수정 제목  '),
        isTrue,
      );
      expect(
        (await container.read(booksProvider.future)).single.title,
        '수정 제목',
      );
      expect(
        (await container.read(bookDetailProvider('book').future)).title,
        '수정 제목',
      );
      expect(
        (await container.read(summaryDocumentProvider('document').future))
            .bookTitle,
        '수정 제목',
      );
    },
  );

  testWidgets(
    'invalid title makes no request and failed save retains input for retry',
    (tester) async {
      final library = _Library()..fail = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [libraryRepositoryProvider.overrideWithValue(library)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) =>
                        const BookTitleDialog(bookId: 'book', title: '기존 제목'),
                  ),
                  child: const Text('수정'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('수정'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(library.attempts, 0);
      expect(find.text('앞뒤 공백을 제외한 책 제목을 1~100자로 입력해 주세요.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '수정 제목');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(library.attempts, 1);
      expect(find.text('수정 제목'), findsOneWidget);
      expect(library.title, '기존 제목');
      library.fail = false;
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(library.attempts, 2);
      expect(library.title, '수정 제목');
      expect(find.byType(BookTitleDialog), findsNothing);
    },
  );
}
