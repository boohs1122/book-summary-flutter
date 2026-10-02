import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/model/book.dart';
import '../provider/books_provider.dart';
import '../widget/book_card.dart';

const _screenTitle = '내 책';
const _emptyMessage = '아직 등록된 책이 없습니다.';
const _emptyHint = '책을 촬영해 첫 회차를 만들어 보세요.';
const _retryLabel = '다시 불러오기';
const _captureLabel = '바로 찍기';
const _deleteTitle = '책을 삭제할까요?';
const _deleteWarning = '이 책의 회차와 요약, 퀴즈가 모두 삭제됩니다.';
const _cancelLabel = '취소';
const _deleteLabel = '삭제';

class BookListScreen extends ConsumerWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider);
    ref.listen(booksProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.message(next.error!))));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(_screenTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.capture),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text(_captureLabel),
      ),
      body: books.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: TextButton(
            onPressed: () {
              ref.invalidate(authenticatedUserProvider);
              ref.invalidate(booksProvider);
            },
            child: const Text(_retryLabel),
          ),
        ),
        data: (items) => items.isEmpty
            ? _EmptyLibrary(onCapture: () => context.push(AppRoutes.capture))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      onTap: () => context.push(AppRoutes.bookDetail(book.id)),
                    ),
                  );
                },
              ),
      ),
    );
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

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onCapture});

  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(_emptyMessage, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_emptyHint, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          FilledButton(onPressed: onCapture, child: const Text(_captureLabel)),
        ],
      ),
    );
  }
}
