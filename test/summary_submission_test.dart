import 'package:booksummary/core/di/repository_providers.dart';
import 'package:booksummary/features/library/domain/library_repository.dart';
import 'package:booksummary/features/library/domain/model/book.dart';
import 'package:booksummary/features/library/domain/model/book_detail.dart';
import 'package:booksummary/features/summary/domain/model/pending_summary_job.dart';
import 'package:booksummary/features/summary/domain/model/summary_document.dart';
import 'package:booksummary/features/summary/domain/pending_job_store.dart';
import 'package:booksummary/features/summary/domain/summary_repository.dart';
import 'package:booksummary/features/summary/presentation/provider/summary_submission_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Library implements LibraryRepository {
  @override
  Future<void> renameBook(String bookId, String title) =>
      throw UnimplementedError();
  int creations = 0;
  @override
  Future<String> createBook(String title) async {
    creations++;
    return 'book';
  }

  @override
  Future<List<Book>> getBooks() async => [];
  @override
  Future<BookDetail> getBook(String bookId) => throw UnimplementedError();
  @override
  Future<void> deleteBook(String bookId) => throw UnimplementedError();
}

class _Summary implements SummaryRepository {
  int submissions = 0;
  bool fail = false;
  @override
  Future<String> submitText({
    required String bookId,
    required String text,
  }) async {
    submissions++;
    if (fail) throw Exception('offline');
    return 'job';
  }

  @override
  Future<SummaryJob> getJob(String jobId) => throw UnimplementedError();
  @override
  Future<SummaryDocument> getDocument(String documentId) =>
      throw UnimplementedError();
  @override
  Future<String> retryDocument(String documentId) => throw UnimplementedError();
}

class _Store implements PendingJobStore {
  bool fail = false;
  final jobs = <PendingSummaryJob>[];
  @override
  Future<List<PendingSummaryJob>> read() async => jobs;
  @override
  Future<void> put(PendingSummaryJob job) async {
    if (fail) throw Exception('storage unavailable');
    jobs.add(job);
  }

  @override
  Future<void> remove(String jobId) async =>
      jobs.removeWhere((job) => job.jobId == jobId);
}

void main() {
  late _Library library;
  late _Summary summary;
  late _Store store;
  late ProviderContainer container;
  setUp(() {
    library = _Library();
    summary = _Summary();
    store = _Store();
    container = ProviderContainer(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(library),
        summaryRepositoryProvider.overrideWithValue(summary),
        pendingJobStoreProvider.overrideWithValue(store),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('document retry reuses a successfully created book', () async {
    final notifier = container.read(summarySubmissionProvider.notifier);
    summary.fail = true;
    expect(await notifier.submit(text: '가' * 100, newBookTitle: '책'), isNull);
    summary.fail = false;
    expect(
      await notifier.submit(text: '가' * 100, newBookTitle: '책'),
      isNotNull,
    );
    expect(library.creations, 1);
    expect(summary.submissions, 2);
  });

  test(
    'storage retry saves the accepted job without resubmitting text',
    () async {
      final notifier = container.read(summarySubmissionProvider.notifier);
      store.fail = true;
      expect(await notifier.submit(text: '가' * 100, bookId: 'book'), isNull);
      store.fail = false;
      expect(await notifier.submit(text: '가' * 100, bookId: 'book'), isNotNull);
      expect(summary.submissions, 1);
      expect(store.jobs.single.jobId, 'job');
    },
  );

  test('invalid text does not create a book or submit a document', () async {
    final notifier = container.read(summarySubmissionProvider.notifier);
    expect(await notifier.submit(text: '가' * 99, newBookTitle: '책'), isNull);
    expect(library.creations, 0);
    expect(summary.submissions, 0);
  });
}
