import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/model/book.dart';

const _neverStudied = '학습 기록 없음';
const _latestScore = '최근 점수';
const _noQuiz = '미응시';

class BookCard extends StatelessWidget {
  const BookCard({required this.book, required this.onTap, super.key});
  final Book book;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = AppSpacing.of(context);
    final date = book.lastStudiedAt?.toLocal();
    final dateText = date == null
        ? _neverStudied
        : '${date.month}월 ${date.day}일';
    final score = book.latestScore;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: gap.section),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 28,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: gap.item),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: gap.small),
                  Text(
                    '${book.documentCount}회차 · $dateText',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            SizedBox(width: gap.small),
            Semantics(
              label: score == null
                  ? _noQuiz
                  : '$_latestScore ${score.correct}/${score.total}',
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Text(
                      score == null
                          ? _noQuiz
                          : '${score.correct}/${score.total}',
                      style: score == null
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.displaySmall?.copyWith(
                              fontSize: 24,
                            ),
                    ),
                    if (score != null)
                      Text(_latestScore, style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            ),
            SizedBox(width: gap.small),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
