import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/model/summary_document.dart';
import '../provider/summary_job_provider.dart';
import '../../../quiz/presentation/widget/quiz_start_button.dart';

const _title = '요약 보기';
const _original = '원문 보기';
const _keyPoints = '핵심 내용';
const _terms = '용어';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({required this.documentId, super.key});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(summaryDocumentProvider(documentId));
    return Scaffold(
      appBar: AppBar(title: const Text(_title)),
      body: document.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppError.message(error)),
              TextButton(
                onPressed: () =>
                    ref.invalidate(summaryDocumentProvider(documentId)),
                child: const Text('다시 불러오기'),
              ),
            ],
          ),
        ),
        data: (value) =>
            _SummaryContent(document: value, documentId: documentId),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.document, required this.documentId});

  final SummaryDocument document;
  final String documentId;

  @override
  Widget build(BuildContext context) {
    final summary = document.summary;
    if (summary == null) {
      return const Center(child: Text('아직 요약 결과가 없습니다.'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(document.bookTitle),
            subtitle: Text('${document.sequence}회차'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.bookDetail(document.bookId)),
          ),
        ),
        const SizedBox(height: 16),
        Text(summary.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        QuizStartButton(documentId: documentId),
        const SizedBox(height: 24),
        Text(_keyPoints, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final point in summary.keyPoints) _KeyPointCard(point: point),
        if (summary.terms.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(_terms, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final term in summary.terms)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      term.term,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(term.meaning),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 20),
        ExpansionTile(
          title: const Text(_original),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(document.text),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyPointCard extends StatelessWidget {
  const _KeyPointCard({required this.point});

  final SummaryKeyPoint point;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (point.type) {
      KeyPointType.definition => colors.primary,
      KeyPointType.mechanism => colors.secondary,
      KeyPointType.cause => colors.tertiary,
      KeyPointType.comparison => colors.primaryContainer,
      KeyPointType.caution => colors.error,
      KeyPointType.example => colors.secondaryContainer,
    };
    final label = switch (point.type) {
      KeyPointType.definition => '정의',
      KeyPointType.mechanism => '원리',
      KeyPointType.cause => '원인',
      KeyPointType.comparison => '비교',
      KeyPointType.caution => '주의',
      KeyPointType.example => '예시',
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            ColoredBox(color: color, child: const SizedBox(width: 5)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      label: Text(label),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: color.withValues(alpha: 0.14),
                      side: BorderSide.none,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      point.heading,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(point.detail),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
