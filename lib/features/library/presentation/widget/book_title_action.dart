import 'package:flutter/material.dart';

import 'book_title_dialog.dart';

const _editTitle = '제목 수정';
const _titleSaved = '책 제목을 수정했습니다.';

class BookTitleAction extends StatelessWidget {
  const BookTitleAction({required this.bookId, required this.title, super.key});
  final String bookId;
  final String title;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _editTitle,
    icon: const Icon(Icons.edit_outlined),
    onPressed: () async {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => BookTitleDialog(bookId: bookId, title: title),
      );
      if (saved == true && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(_titleSaved)));
      }
    },
  );
}
