import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/presentation/study_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../library/domain/model/book.dart';
import '../../../library/presentation/provider/books_provider.dart';
import '../../../summary/presentation/provider/summary_submission_provider.dart';
import '../provider/ocr_provider.dart';

const _instruction = '요약을 저장할 책을 선택하세요.';
const _noBooks = '아직 등록된 책이 없습니다.';
const _firstSession = '새 책에 첫 회차를 저장해 보세요.';
const _clearFilter = '필터 지우기';
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

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submission = ref.watch(summarySubmissionProvider);
    ref.listen(summarySubmissionProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.message(next.error!))));
      }
    });
    final gap = AppSpacing.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(_title)),
      body: Padding(
        padding: EdgeInsets.all(gap.page),
        child: ListView(
          children: [
            Text(_instruction, style: Theme.of(context).textTheme.bodySmall),
            SizedBox(height: gap.section),
            OutlinedButton.icon(
              onPressed: submission.isLoading ? null : _createBook,
              icon: submission.isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text(_newBook),
            ),
            SizedBox(height: gap.item),
            TextField(
              controller: _filterController,
              decoration: const InputDecoration(
                hintText: _filterHint,
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: gap.item),
            _BookSelectionList(
              controller: _filterController,
              enabled: !submission.isLoading,
              onCreate: _createBook,
              onSelect: (book) => _submit(book: book),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBook() async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const _NewBookDialog(),
    );
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
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.symmetric(
          vertical: AppSpacing.of(context).item,
        ),
        enabled: enabled,
        leading: const Icon(Icons.menu_book_outlined),
        title: Text(book.title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text('${book.documentCount}회차'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
      const Divider(),
    ],
  );
}

class _BookSelectionList extends ConsumerWidget {
  const _BookSelectionList({
    required this.controller,
    required this.enabled,
    required this.onCreate,
    required this.onSelect,
  });
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onCreate;
  final void Function(Book book) onSelect;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => books.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ScreenMessage(
          message: AppError.message(error),
          onRetry: () {
            ref.invalidate(authenticatedUserProvider);
            ref.invalidate(booksProvider);
          },
        ),
        data: (items) {
          final filtered = items
              .where(
                (book) => book.title.toLowerCase().contains(
                  value.text.trim().toLowerCase(),
                ),
              )
              .toList();
          if (items.isEmpty) {
            return ScreenMessage(
              message: _noBooks,
              hint: _firstSession,
              onRetry: enabled ? onCreate : null,
              actionLabel: _newBook,
            );
          }
          if (filtered.isEmpty) {
            return ScreenMessage(
              message: _empty,
              onRetry: controller.clear,
              actionLabel: _clearFilter,
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _BookOption(
              book: filtered[index],
              enabled: enabled,
              onTap: () => onSelect(filtered[index]),
            ),
          );
        },
      ),
    );
  }
}

class _NewBookDialog extends StatefulWidget {
  const _NewBookDialog();
  @override
  State<_NewBookDialog> createState() => _NewBookDialogState();
}

class _NewBookDialogState extends State<_NewBookDialog> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_controller.text.trim().isNotEmpty) {
      Navigator.pop(context, _controller.text);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(_newBook),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 100,
      decoration: const InputDecoration(labelText: _titlePrompt),
      onSubmitted: (_) => _confirm(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(_cancel),
      ),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (_, value, _) => FilledButton(
          onPressed: value.text.trim().isEmpty ? null : _confirm,
          child: const Text(_create),
        ),
      ),
    ],
  );
}
