import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_error.dart';
import '../provider/book_title_provider.dart';

const _title = '책 제목 수정';
const _label = '책 제목';
const _invalidTitle = '앞뒤 공백을 제외한 책 제목을 1~100자로 입력해 주세요.';
const _cancel = '취소';
const _save = '저장';

class BookTitleDialog extends ConsumerStatefulWidget {
  const BookTitleDialog({required this.bookId, required this.title, super.key});
  final String bookId;
  final String title;

  @override
  ConsumerState<BookTitleDialog> createState() => _BookTitleDialogState();
}

class _BookTitleDialogState extends ConsumerState<BookTitleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.title);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveTitle() async {
    if (!_formKey.currentState!.validate()) return;
    final saved = await ref
        .read(bookTitleProvider.notifier)
        .rename(widget.bookId, _controller.text);
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, true);
    } else {
      final error = ref.read(bookTitleProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppError.message(error ?? Exception()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(bookTitleProvider).isLoading;
    return PopScope(
      canPop: !saving,
      child: AlertDialog(
        title: const Text(_title),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            enabled: !saving,
            maxLength: 100,
            decoration: const InputDecoration(labelText: _label),
            validator: (value) =>
                (value ?? '').trim().isNotEmpty &&
                    (value ?? '').trim().length <= 100
                ? null
                : _invalidTitle,
            onFieldSubmitted: saving ? null : (_) => _saveTitle(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context, false),
            child: const Text(_cancel),
          ),
          FilledButton(
            onPressed: saving ? null : _saveTitle,
            child: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(_save),
          ),
        ],
      ),
    );
  }
}
