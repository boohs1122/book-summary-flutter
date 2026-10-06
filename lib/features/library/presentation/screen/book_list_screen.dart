import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/presentation/study_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/model/book.dart';
import '../provider/books_provider.dart';
import '../widget/book_card.dart';
import '../../../summary/presentation/provider/summary_submission_provider.dart';

const _screenTitle = '내 책';
const _emptyMessage = '아직 등록된 책이 없습니다.';
const _emptyHint = '책을 촬영해 첫 회차를 만들어 보세요.';
const _retryLabel = '다시 불러오기';
const _captureLabel = '책 사진 찍기';
const _deleteTitle = '책을 삭제할까요?';
const _deleteWarning = '이 책의 회차와 요약, 퀴즈가 모두 삭제됩니다.';
const _cancelLabel = '취소';
const _deleteLabel = '삭제';

class BookListScreen extends ConsumerWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider);
    _listenForErrors(context, ref);

    return Scaffold(
      appBar: AppBar(title: const Text(_screenTitle)),
      bottomNavigationBar: ActionFooter(
        child: FilledButton.icon(
          onPressed: () => context.push(AppRoutes.capture),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text(_captureLabel),
        ),
      ),
      body: Column(
        children: [
          const _PendingJobsBanner(),
          Expanded(
            child: books.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => ScreenMessage(
                message: AppError.message(error),
                actionLabel: _retryLabel,
                onRetry: () {
                  ref.invalidate(authenticatedUserProvider);
                  ref.invalidate(booksProvider);
                },
              ),
              data: (items) => items.isEmpty
                  ? const ScreenMessage(
                      message: _emptyMessage,
                      hint: _emptyHint,
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.of(context).page,
                        vertical: AppSpacing.of(context).small,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final book = items[index];
                        return Dismissible(
                          key: ValueKey(book.id),
                          direction: DismissDirection.endToStart,
                          background: ColoredBox(
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                              ),
                            ),
                          ),
                          confirmDismiss: (_) =>
                              _confirmAndDelete(context, ref, book),
                          child: BookCard(
                            book: book,
                            onTap: () =>
                                context.push(AppRoutes.bookDetail(book.id)),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _listenForErrors(BuildContext context, WidgetRef ref) {
    ref.listen(booksProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.message(next.error!))));
      }
    });
  }

  Future<bool> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(_deleteTitle),
        content: Text('${book.documentCount}회차가 포함되어 있습니다.\n$_deleteWarning'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(_cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(_deleteLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    try {
      ref.invalidate(deleteBookProvider(book.id));
      await ref.read(deleteBookProvider(book.id).future);
      ref.invalidate(booksProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppError.message(error))));
      }
    }
    return false;
  }
}

const _pendingLabel = '요약 생성 중';
const _pendingHint = '진행 중인 요약 확인';

class _PendingJobsBanner extends ConsumerWidget {
  const _PendingJobsBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(pendingSummaryJobsProvider);
    return jobs.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : Card(
              margin: EdgeInsets.fromLTRB(
                AppSpacing.of(context).page,
                AppSpacing.of(context).item,
                AppSpacing.of(context).page,
                0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.3,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final job in items)
                      ListTile(
                        leading: const Icon(Icons.hourglass_top),
                        title: Text(
                          ref
                                  .watch(booksProvider)
                                  .value
                                  ?.where((book) => book.id == job.bookId)
                                  .firstOrNull
                                  ?.title ??
                              _pendingLabel,
                        ),
                        subtitle: const Text(_pendingHint),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          AppRoutes.summaryProgressForJob(
                            job.jobId,
                            job.bookId,
                            createdAt: job.createdAt,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
