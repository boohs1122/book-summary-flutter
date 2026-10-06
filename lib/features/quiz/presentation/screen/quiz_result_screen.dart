import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/presentation/study_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../library/presentation/widget/book_context_header.dart';
import '../../../summary/presentation/provider/summary_job_provider.dart';
import '../../domain/model/quiz.dart';

export '../../domain/model/quiz.dart' show QuizResultRouteArgs;

const _title = '채점 결과';
const _missing = '결과를 불러올 수 없습니다. 요약에서 퀴즈를 다시 시작해 주세요.';
const _return = '요약으로 돌아가기';
const _again = '다시 풀기';
const _answers = '답과 해설';
const _correct = '정답';
const _review = '다시 확인';
const _selected = '선택한 답';
const _unanswered = '미응답';
const _explanation = '해설';
const _memory = '다시 기억할 핵심';

const _allCorrect = '모두 기억했어요. 잘했어요.';
const _tryAgain = '괜찮아요. 해설을 읽고 다시 기억해요.';
const _encourage = '좋아요. 틀린 문제만 다시 기억해요.';

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({
    required this.documentId,
    required this.args,
    super.key,
  });
  final String documentId;
  final QuizResultRouteArgs? args;

  void _returnToSummary(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.summaryForDocument(documentId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = args;
    final gap = AppSpacing.of(context);
    final document = ref.watch(summaryDocumentProvider(documentId)).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text(_title),
        leading: BackButton(onPressed: () => _returnToSummary(context)),
      ),
      bottomNavigationBar: ActionFooter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (value != null)
              FilledButton(
                onPressed: () => context.pushReplacement(
                  AppRoutes.quizForDocument(documentId),
                  extra: value.quiz,
                ),
                child: const Text(_again),
              ),
            TextButton(
              onPressed: () => _returnToSummary(context),
              child: const Text(_return),
            ),
          ],
        ),
      ),
      body: value == null
          ? const ScreenMessage(message: _missing)
          : ListView(
              padding: EdgeInsets.all(gap.page),
              children: [
                if (document != null)
                  BookContextHeader(
                    title: document.bookTitle,
                    sequence: document.sequence,
                  ),
                _ScoreHeader(result: value.result),
                SizedBox(height: gap.section),
                const Divider(),
                SizedBox(height: gap.section),
                Text(_answers, style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: gap.item),
                for (final item in value.result.items)
                  _ResultItem(
                    item: item,
                    terms:
                        document?.summary?.terms
                            .map((term) => term.term)
                            .toList() ??
                        const [],
                  ),
              ],
            ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.result});
  final QuizResult result;
  @override
  Widget build(BuildContext context) {
    final gap = AppSpacing.of(context);
    final encouragement = result.correct == result.total && result.total > 0
        ? _allCorrect
        : result.correct == 0
        ? _tryAgain
        : _encourage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${result.correct} / ${result.total}',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        SizedBox(height: gap.small),
        Text(
          '${result.total}문제 중 ${result.correct}문제 정답',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: gap.item),
        Text(encouragement, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ResultItem extends StatelessWidget {
  const _ResultItem({required this.item, required this.terms});
  final QuizResultItem item;
  final List<String> terms;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = AppSpacing.of(context);
    return ExpansionTile(
      key: PageStorageKey('result-${item.index}'),
      initiallyExpanded: !item.correct,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      expandedAlignment: Alignment.centerLeft,
      leading: Icon(
        item.correct ? Icons.check_circle_outline : Icons.cancel_outlined,
        semanticLabel: item.correct ? _correct : _review,
      ),
      title: Text(
        '${(item.index + 1).toString().padLeft(2, '0')} · ${item.correct ? _correct : _review}',
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(item.question, style: theme.textTheme.bodyMedium),
      children: [
        _AnswerRow(
          label: _selected,
          answer: item.selected == null
              ? _unanswered
              : item.options[item.selected!],
        ),
        SizedBox(height: gap.small),
        _AnswerRow(label: _correct, answer: item.options[item.answerIndex]),
        SizedBox(height: gap.item),
        Text(_explanation, style: theme.textTheme.bodySmall),
        SizedBox(height: gap.small),
        EmphasizedText(item.explanation, terms: terms),
        if (!item.correct) ...[
          SizedBox(height: gap.item),
          MemoryCallout(
            label: _memory,
            child: EmphasizedText(item.options[item.answerIndex], terms: terms),
          ),
        ],
      ],
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({required this.label, required this.answer});
  final String label;
  final String answer;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(answer, style: Theme.of(context).textTheme.bodyLarge),
    ],
  );
}
