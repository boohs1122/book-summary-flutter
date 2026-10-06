import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/presentation/study_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/model/book_detail.dart';
import '../../../summary/presentation/provider/summary_submission_provider.dart';
import '../provider/books_provider.dart';
import '../widget/book_title_action.dart';

const _title = '책 상세';
const _viewPending = '진행 중인 요약 보기';
const _cancel = '취소';
const _choosePending = '홈의 진행 중인 요약에서 작업을 선택해 주세요.';
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
        title: const Text(_title),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          if (detail.hasValue)
            BookTitleAction(bookId: bookId, title: detail.value!.title),
        ],
      ),
      bottomNavigationBar: ActionFooter(
        child: FilledButton.icon(
          onPressed: () => context.push(AppRoutes.captureForBook(bookId)),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text(_addDocumentLabel),
        ),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ScreenMessage(
          message: AppError.message(error),
          onRetry: () => ref.invalidate(bookDetailProvider(bookId)),
          actionLabel: _retryLabel,
        ),
        data: (book) => _DocumentList(book: book),
      ),
    );
  }
}

class _DocumentList extends ConsumerWidget {
  const _DocumentList({required this.book});
  final BookDetail book;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gap = AppSpacing.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: EdgeInsets.all(gap.page),
      children: [
        Text(book.title, style: theme.textTheme.headlineSmall),
        SizedBox(height: gap.small),
        Text(
          '${book.documentCount}회차 · 총 ${book.totalCharCount}자',
          style: theme.textTheme.bodySmall,
        ),
        SizedBox(height: gap.item),
        if (book.documents.isEmpty)
          const ScreenMessage(message: _emptyMessage)
        else
          for (final document in book.documents)
            _DocumentRow(
              document: document,
              onTap: () => _openDocument(context, ref, book.id, document),
            ),
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.document, required this.onTap});
  final BookDocument document;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = switch (document.status) {
      'DONE' => _doneLabel,
      'FAILED' => _failedLabel,
      _ => _processingLabel,
    };
    final date = document.createdAt.toLocal();
    final score = document.latestScore;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.of(context).item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${document.sequence}회차', style: theme.textTheme.bodySmall),
            SizedBox(height: AppSpacing.of(context).small),
            Text(
              document.title ?? document.preview ?? status,
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: AppSpacing.of(context).small),
            Wrap(
              spacing: AppSpacing.of(context).item,
              runSpacing: AppSpacing.of(context).small,
              children: [
                Text(
                  '$status · ${date.month}/${date.day}',
                  style: theme.textTheme.bodySmall,
                ),
                if (score != null)
                  Text(
                    '${score.correct}/${score.total}',
                    style: theme.textTheme.bodyMedium,
                  )
                else if (document.hasQuiz)
                  const Text(_quizReady),
              ],
            ),
            SizedBox(height: AppSpacing.of(context).item),
            const Divider(),
          ],
        ),
      ),
    );
  }
}

const _quizReady = '퀴즈 준비됨';

Future<void> _openDocument(
  BuildContext context,
  WidgetRef ref,
  String bookId,
  BookDocument document,
) async {
  if (document.status == 'DONE') {
    context.push(AppRoutes.summaryForDocument(document.id));
    return;
  }
  if (document.status == 'PROCESSING') {
    final openJobs = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(_processingLabel),
        content: const Text(_choosePending),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(_viewPending),
          ),
        ],
      ),
    );
    if (openJobs == true && context.mounted) context.go(AppRoutes.home);
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
          child: const Text(_cancel),
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
