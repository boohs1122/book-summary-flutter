import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/router/app_router.dart';
import '../provider/books_provider.dart';

const _retryLabel = '다시 불러오기';
const _emptyMessage = '아직 등록된 회차가 없습니다.';
const _addDocumentLabel = '회차 추가';
const _processingLabel = '생성 중';
const _failedLabel = '생성 실패';
const _doneLabel = '요약 완료';

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
      appBar: AppBar(title: Text(detail.value?.title ?? '')),
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
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
