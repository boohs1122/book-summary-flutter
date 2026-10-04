import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../library/presentation/provider/books_provider.dart';
import '../../domain/model/pending_summary_job.dart';
import '../../domain/model/summary_document.dart';

final pendingSummaryJobsProvider = FutureProvider<List<PendingSummaryJob>>(
  (ref) => ref.watch(pendingJobStoreProvider).read(),
);

final summarySubmissionProvider =
    AsyncNotifierProvider<SummarySubmissionNotifier, PendingSummaryJob?>(
      SummarySubmissionNotifier.new,
    );

class SummarySubmissionNotifier extends AsyncNotifier<PendingSummaryJob?> {
  String? _requestKey;
  String? _createdBookId;
  PendingSummaryJob? _acceptedJob;

  @override
  PendingSummaryJob? build() => null;

  Future<PendingSummaryJob?> submit({
    required String text,
    String? bookId,
    String? newBookTitle,
  }) async {
    if (state.isLoading) return null;
    final input = text.trim();
    final title = newBookTitle?.trim();
    if (input.runes.length < 100 ||
        input.runes.length > 10000 ||
        (bookId == null &&
            (title == null || title.isEmpty || title.runes.length > 100))) {
      state = AsyncError(InvalidSummaryText(), StackTrace.current);
      return null;
    }
    final key = '$bookId\u0000$title\u0000$input';
    if (_requestKey != key) {
      _requestKey = key;
      _createdBookId = null;
      _acceptedJob = null;
    }
    state = const AsyncLoading();
    try {
      final targetBookId =
          bookId ??
          (_createdBookId ??= await ref
              .read(libraryRepositoryProvider)
              .createBook(title!));
      final job = _acceptedJob ??= PendingSummaryJob(
        jobId: await ref
            .read(summaryRepositoryProvider)
            .submitText(bookId: targetBookId, text: input),
        bookId: targetBookId,
        createdAt: DateTime.now().toUtc(),
      );
      await ref.read(pendingJobStoreProvider).put(job);
      ref.invalidate(pendingSummaryJobsProvider);
      ref.invalidate(booksProvider);
      ref.invalidate(bookDetailProvider(targetBookId));
      state = AsyncData(job);
      return job;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<PendingSummaryJob?> retry({
    required String documentId,
    required String bookId,
    String? previousJobId,
  }) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final jobId = await ref
          .read(summaryRepositoryProvider)
          .retryDocument(documentId);
      final job = PendingSummaryJob(
        jobId: jobId,
        bookId: bookId,
        createdAt: DateTime.now().toUtc(),
      );
      await ref.read(pendingJobStoreProvider).put(job);
      if (previousJobId != null) {
        await ref.read(pendingJobStoreProvider).remove(previousJobId);
      }
      ref.invalidate(pendingSummaryJobsProvider);
      state = AsyncData(job);
      return job;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  void clearCompletedRequest() {
    _requestKey = null;
    _createdBookId = null;
    _acceptedJob = null;
    state = const AsyncData(null);
  }
}
