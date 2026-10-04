import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/model/book_detail.dart';
import '../../../summary/presentation/provider/summary_submission_provider.dart';
import '../provider/books_provider.dart';
import '../widget/book_title_action.dart';

const _retryLabel = '다시 불러오기';
const _emptyMessage = '아직 등록된 회차가 없습니다.';
const _addDocumentLabel = '회차 추가';
const _processingLabel = '생성 중';
const _failedLabel = '생성 실패';
const _doneLabel = '요약 완료';
const _retrySummary = '요약을 다시 만들까요?';
const _retryDescription = '저장된 원문으로 서버에 다시 요청합니다.';
const _retryAction = '다시 만들기';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({required this.bookId, super.key});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(bookDetailProvider(bookId));
    ref.listen(bookDetailProvider(bookId), (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.message(next.error!))));
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(detail.value?.title ?? ''),
        actions: [
          if (detail.hasValue)
            BookTitleAction(bookId: bookId, title: detail.value!.title),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.captureForBook(bookId)),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text(_addDocumentLabel),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(bookDetailProvider(bookId)),
            child: const Text(_retryLabel),
          ),
        ),
        data: (book) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Text(book.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('${book.documentCount}회차 · ${book.totalCharCount}자'),
            const SizedBox(height: 16),
            if (book.documents.isEmpty)
              const Center(child: Text(_emptyMessage))
            else
              for (final document in book.documents)
                Card(
                  child: ListTile(
                    title: Text(
                      '${document.sequence}회차 · ${document.title ?? document.preview ?? ''}',
                    ),
                    subtitle: Text(switch (document.status) {
                      'DONE' => _doneLabel,
                      'FAILED' => _failedLabel,
                      _ => _processingLabel,
                    }),
                    trailing: document.latestScore == null
                        ? null
                        : Text(
                            '${document.latestScore!.correct}/${document.latestScore!.total}',
                          ),
                    onTap: () => _openDocument(context, ref, book.id, document),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openDocument(
  BuildContext context,
  WidgetRef ref,
  String bookId,
  BookDocument document,
) async {
  if (document.status == 'DONE') {
    context.go(AppRoutes.summaryForDocument(document.id));
    return;
  }
  if (document.status == 'PROCESSING') {
    try {
      final jobs = await ref.read(pendingSummaryJobsProvider.future);
      final job = jobs.where((entry) => entry.bookId == bookId).firstOrNull;
      if (job != null && context.mounted) {
        context.go(
          AppRoutes.summaryProgressForJob(
            job.jobId,
            bookId,
            createdAt: job.createdAt,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('홈 화면의 진행 중인 요약에서 다시 열 수 있습니다.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppError.message(error))));
      }
    }
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(_retrySummary),
      content: const Text(_retryDescription),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text(_retryAction),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final job = await ref
      .read(summarySubmissionProvider.notifier)
      .retry(documentId: document.id, bookId: bookId);
  if (job != null && context.mounted) {
    context.go(
      AppRoutes.summaryProgressForJob(
        job.jobId,
        bookId,
        createdAt: job.createdAt,
      ),
    );
  } else if (context.mounted) {
    final error = ref.read(summarySubmissionProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppError.message(error ?? Exception()))),
    );
  }
}
