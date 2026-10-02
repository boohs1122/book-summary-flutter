import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/error/app_error.dart';
import '../provider/books_provider.dart';

const _screenTitle = '내 책';
const _emptyMessage = '아직 등록된 책이 없습니다.';
const _retryLabel = '다시 불러오기';

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
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _emptyMessage,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(booksProvider),
                      child: const Text(_retryLabel),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    ListTile(title: Text(items[index].title)),
              ),
      ),
    );
  }
}
