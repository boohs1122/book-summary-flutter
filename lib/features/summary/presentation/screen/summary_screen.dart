import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/presentation/study_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../library/presentation/widget/book_context_header.dart';
import '../../domain/model/summary_document.dart';
import '../provider/summary_job_provider.dart';
import '../../../quiz/presentation/widget/quiz_start_button.dart';
import '../../../quiz/presentation/provider/quiz_provider.dart';
import '../../../quiz/domain/model/quiz.dart';

const _title = '요약 보기';
const _original = '원문 보기';
const _keyPoints = '핵심 내용';
const _terms = '용어';
const _noSummary = '아직 요약 결과가 없습니다.';
const _returnBook = '회차 목록으로';
const _latest = '최근 점수';
const _viewResult = '결과 보기';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({required this.documentId, super.key});
  final String documentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(summaryDocumentProvider(documentId));
    return Scaffold(
      appBar: AppBar(
        title: const Text(_title),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                document.value == null
                    ? AppRoutes.home
                    : AppRoutes.bookDetail(document.value!.bookId),
              );
            }
          },
        ),
      ),
      bottomNavigationBar: document.value?.summary == null
          ? null
          : ActionFooter(
              child: QuizStartButton(
                documentId: documentId,
                hasAttempt:
                    document.value!.latestCorrect != null ||
                    ref.watch(lastQuizResultProvider(documentId)) != null,
              ),
            ),
      body: document.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ScreenMessage(
          message: AppError.message(error),
          onRetry: () => ref.invalidate(summaryDocumentProvider(documentId)),
        ),
        data: (value) => value.summary == null
            ? ScreenMessage(
                message: _noSummary,
                onRetry: () => context.go(AppRoutes.bookDetail(value.bookId)),
                actionLabel: _returnBook,
              )
            : _SummaryContent(document: value),
      ),
    );
  }
}

class _SummaryContent extends ConsumerWidget {
  const _SummaryContent({required this.document});
  final SummaryDocument document;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = document.summary!;
    final gap = AppSpacing.of(context);
    final theme = Theme.of(context);
    final lastResult = ref.watch(lastQuizResultProvider(document.id));
    return ListView(
      padding: EdgeInsets.all(gap.page),
      children: [
        BookContextHeader(
          title: document.bookTitle,
          sequence: document.sequence,
          onTap: () => context.go(AppRoutes.bookDetail(document.bookId)),
        ),
        Text(summary.title, style: theme.textTheme.headlineSmall),
        SizedBox(height: gap.section),
        if (document.latestCorrect != null || lastResult != null) ...[
          const Divider(),
          _LatestScore(document: document, lastResult: lastResult),
          const Divider(),
          SizedBox(height: gap.section),
        ],
        Text(_keyPoints, style: theme.textTheme.titleLarge),
        SizedBox(height: gap.item),
        for (var i = 0; i < summary.keyPoints.length; i++)
          _KeyPointSection(
            point: summary.keyPoints[i],
            index: i,
            terms: summary.terms.map((term) => term.term).toList(),
          ),
        if (summary.terms.isNotEmpty) ...[
          SizedBox(height: gap.section),
          Text(_terms, style: theme.textTheme.titleLarge),
          for (final term in summary.terms)
            Padding(
              padding: EdgeInsets.symmetric(vertical: gap.item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(term.term, style: theme.textTheme.titleMedium),
                  SizedBox(height: gap.small),
                  Text(term.meaning, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
        ],
        SizedBox(height: gap.section),
        ExpansionTile(
          title: const Text(_original),
          children: [
            SelectableText(document.text, style: theme.textTheme.bodyLarge),
          ],
        ),
      ],
    );
  }
}

class _KeyPointSection extends StatelessWidget {
  const _KeyPointSection({
    required this.point,
    required this.index,
    required this.terms,
  });
  final SummaryKeyPoint point;
  final int index;
  final List<String> terms;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = AppSpacing.of(context);
    final label = switch (point.type) {
      KeyPointType.definition => '정의',
      KeyPointType.mechanism => '원리',
      KeyPointType.cause => '원인',
      KeyPointType.comparison => '비교',
      KeyPointType.caution => '주의',
      KeyPointType.example => '예시',
    };
    return Padding(
      padding: EdgeInsets.only(bottom: gap.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (index + 1).toString().padLeft(2, '0'),
                style: theme.textTheme.bodySmall,
              ),
              SizedBox(width: gap.item),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.labelSmall),
                    SizedBox(height: gap.small),
                    Text(point.heading, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: gap.item),
          if (point.type == KeyPointType.mechanism ||
              point.type == KeyPointType.comparison ||
              point.type == KeyPointType.caution)
            MemoryCallout(child: EmphasizedText(point.detail, terms: terms))
          else
            EmphasizedText(point.detail, terms: terms),
          SizedBox(height: gap.section),
          const Divider(),
        ],
      ),
    );
  }
}

class _LatestScore extends StatelessWidget {
  const _LatestScore({required this.document, required this.lastResult});
  final SummaryDocument document;
  final QuizResultRouteArgs? lastResult;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = AppSpacing.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: gap.small),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: gap.item,
        children: [
          Text(_latest, style: theme.textTheme.bodySmall),
          Text(
            '${lastResult?.result.correct ?? document.latestCorrect}/${lastResult?.result.total ?? document.latestTotal}',
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 24),
          ),
          if (lastResult != null)
            TextButton(
              onPressed: () => context.push(
                AppRoutes.quizResultForDocument(document.id),
                extra: lastResult,
              ),
              child: const Text(_viewResult),
            ),
        ],
      ),
    );
  }
}
