import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../provider/books_provider.dart';

const _selectedBook = '선택한 책';
const _adding = '회차 추가';

class BookContextHeader extends ConsumerWidget {
  const BookContextHeader({
    this.bookId,
    this.title,
    this.sequence,
    this.onTap,
    super.key,
  });
  final String? bookId;
  final String? title;
  final int? sequence;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookId == null && title == null) return const SizedBox.shrink();
    final resolved =
        title ??
        ref.watch(bookDetailProvider(bookId!)).value?.title ??
        _selectedBook;
    final text = Text(
      '$resolved  ›  ${sequence == null ? _adding : '$sequence회차'}',
      style: Theme.of(context).textTheme.bodySmall,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.of(context).section),
      child: onTap == null
          ? text
          : InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Align(alignment: Alignment.centerLeft, child: text),
              ),
            ),
    );
  }
}
