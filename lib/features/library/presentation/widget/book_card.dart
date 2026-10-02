import 'package:flutter/material.dart';

import '../../domain/model/book.dart';

const _lastStudiedLabel = '마지막 학습';
const _neverStudiedLabel = '학습 기록 없음';
const _latestScoreLabel = '최근 점수';

class BookCard extends StatelessWidget {
  const BookCard({required this.book, required this.onTap, super.key});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = book.lastStudiedAt?.toLocal();
    final dateText = date == null
        ? _neverStudiedLabel
        : '$_lastStudiedLabel ${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final score = book.latestScore;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text('${book.documentCount}회차'),
                  Text(dateText),
                  if (score != null)
                    Text('$_latestScoreLabel ${score.correct}/${score.total}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
