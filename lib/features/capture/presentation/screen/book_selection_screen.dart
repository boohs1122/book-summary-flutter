import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/router/app_router.dart';
import '../../../library/domain/model/book.dart';
import '../../../library/presentation/provider/books_provider.dart';
import '../../../summary/presentation/provider/summary_submission_provider.dart';
import '../provider/ocr_provider.dart';

const _title = '책 선택';
const _newBook = '새 책 만들기';
const _filterHint = '책 이름으로 찾기';
const _empty = '일치하는 책이 없습니다.';
const _titlePrompt = '책 제목';
const _cancel = '취소';
const _create = '만들고 요약하기';
const _createError = '책 제목을 1~100자로 입력해 주세요.';

class BookSelectionScreen extends ConsumerStatefulWidget {
  const BookSelectionScreen({super.key});

  @override
  ConsumerState<BookSelectionScreen> createState() =>
      _BookSelectionScreenState();
}

class _BookSelectionScreenState extends ConsumerState<BookSelectionScreen> {
  final _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksProvider);
    final submission = ref.watch(summarySubmissionProvider);
    ref.listen(summarySubmissionProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.message(next.error!))));
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text(_title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _filterController,
              decoration: InputDecoration(
                hintText: _filterHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filter.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _filterController.clear();
                          setState(() => _filter = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _filter = value.trim()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text(_newBook),
            trailing: submission.isLoading
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: submission.isLoading ? null : _createBook,
          ),
          const Divider(height: 1),
          Expanded(
            child: books.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(booksProvider),
                  child: const Text('책 목록 다시 불러오기'),
                ),
              ),
              data: (items) {
                final filtered = items
                    .where(
                      (book) => book.title.toLowerCase().contains(
                        _filter.toLowerCase(),
                      ),
                    )
                    .toList();
                if (filtered.isEmpty) return const Center(child: Text(_empty));
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _BookOption(
                    book: filtered[index],
                    enabled: !submission.isLoading,
                    onTap: () => _submit(book: filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBook() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(_newBook),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(labelText: _titlePrompt),
          onSubmitted: (_) => Navigator.pop(dialogContext, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text(_create),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || !mounted) return;
    if (title.trim().isEmpty || title.trim().runes.length > 100) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(_createError)));
      return;
    }
    await _submit(newBookTitle: title);
  }

  Future<void> _submit({Book? book, String? newBookTitle}) async {
    final job = await ref
        .read(summarySubmissionProvider.notifier)
        .submit(
          text: ref.read(textDraftProvider),
          bookId: book?.id,
          newBookTitle: newBookTitle,
        );
    if (job != null && mounted) {
      context.go(
        AppRoutes.summaryProgressForJob(
          job.jobId,
          job.bookId,
          createdAt: job.createdAt,
        ),
      );
    }
  }
}

class _BookOption extends StatelessWidget {
  const _BookOption({
    required this.book,
    required this.enabled,
    required this.onTap,
  });

  final Book book;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    enabled: enabled,
    leading: const Icon(Icons.menu_book_outlined),
    title: Text(book.title),
    subtitle: Text('${book.documentCount}회차'),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
