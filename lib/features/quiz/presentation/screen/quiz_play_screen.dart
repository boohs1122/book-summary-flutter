import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/presentation/study_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../library/presentation/provider/books_provider.dart';
import '../../../library/presentation/widget/book_context_header.dart';
import '../../../summary/presentation/provider/summary_job_provider.dart';
import '../../domain/model/quiz.dart';
import '../provider/quiz_provider.dart';

const _title = '퀴즈 풀이';
const _empty = '퀴즈 문항이 없습니다.';
const _back = '요약으로 돌아가기';
const _previous = '이전';
const _next = '다음';
const _submit = '채점하기';
const _exitTitle = '퀴즈를 나갈까요?';
const _exitHint = '지금 나가면 선택한 답이 저장되지 않습니다.';
const _continue = '계속 풀기';
const _exit = '나가기';
const _unanswered = '답하지 않은 문항이 있어요';
const _confirmSubmit = '제출하기';

class QuizPlayScreen extends ConsumerWidget {
  const QuizPlayScreen({required this.documentId, this.initialQuiz, super.key});
  final String documentId;
  final Quiz? initialQuiz;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialQuiz != null) return _QuizQuestions(quiz: initialQuiz!);
    final quiz = ref.watch(quizProvider(documentId));
    return quiz.when(
      data: (value) => _QuizQuestions(quiz: value),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: ScreenMessage(
          message: AppError.message(error),
          onRetry: () => ref.invalidate(quizProvider(documentId)),
        ),
      ),
    );
  }
}

class _QuizQuestions extends ConsumerWidget {
  const _QuizQuestions({required this.quiz});
  final Quiz quiz;

  void _return(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.summaryForDocument(quiz.documentId));
    }
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    if (ref.read(quizResultProvider).isLoading) return;
    final session = ref.read(quizSessionProvider(quiz));
    final confirmed =
        session.answers.every((answer) => answer == null) ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text(_exitTitle),
                content: const Text(_exitHint),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(_continue),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(_exit),
                  ),
                ],
              ),
            ) ==
            true;
    if (confirmed && context.mounted) {
      ref.read(quizSessionProvider(quiz).notifier).allowExit();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _return(context);
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gap = AppSpacing.of(context);
    final session = ref.watch(quizSessionProvider(quiz));
    final submitting = ref.watch(quizResultProvider).isLoading;
    if (quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: ScreenMessage(
          message: _empty,
          onRetry: () => _return(context),
          actionLabel: _back,
        ),
      );
    }
    final notifier = ref.read(quizSessionProvider(quiz).notifier);
    return PopScope(
      canPop: session.allowExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(context, ref);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(_title),
          leading: BackButton(
            onPressed: submitting ? null : () => _leave(context, ref),
          ),
        ),
        bottomNavigationBar: ActionFooter(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: submitting || session.current == 0
                      ? null
                      : () => notifier.move(session.current - 1),
                  child: const Text(_previous),
                ),
              ),
              SizedBox(width: gap.small),
              Expanded(
                child: FilledButton(
                  onPressed: submitting
                      ? null
                      : () {
                          if (session.current < quiz.questions.length - 1) {
                            notifier.move(session.current + 1);
                          } else {
                            _submitAnswers(context, ref);
                          }
                        },
                  child: submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          session.current < quiz.questions.length - 1
                              ? _next
                              : _submit,
                        ),
                ),
              ),
            ],
          ),
        ),
        body: _QuestionBody(quiz: quiz, session: session, enabled: !submitting),
      ),
    );
  }

  Future<void> _submitAnswers(BuildContext context, WidgetRef ref) async {
    final session = ref.read(quizSessionProvider(quiz));
    final unanswered = session.answers.where((answer) => answer == null).length;
    if (unanswered > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(_unanswered),
          content: Text('$unanswered개 문항은 오답으로 처리됩니다. 제출할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(_continue),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(_confirmSubmit),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    try {
      final answers = quiz.questions
          .asMap()
          .entries
          .map(
            (entry) => QuizAnswer(
              index: entry.value.index,
              selected: session.answers[entry.key],
            ),
          )
          .toList();
      final result = await ref
          .read(quizResultProvider.notifier)
          .submit(quiz.id, answers);
      ref.read(sessionQuizResultsProvider.notifier).save(quiz, result);
      final bookId = ref
          .read(summaryDocumentProvider(quiz.documentId))
          .value
          ?.bookId;
      ref.invalidate(booksProvider);
      if (bookId != null) ref.invalidate(bookDetailProvider(bookId));
      ref.invalidate(summaryDocumentProvider(quiz.documentId));
      if (context.mounted) {
        context.pushReplacement(
          AppRoutes.quizResultForDocument(quiz.documentId),
          extra: QuizResultRouteArgs(quiz, result),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppError.message(error))));
      }
    }
  }
}

class _QuestionBody extends ConsumerWidget {
  const _QuestionBody({
    required this.quiz,
    required this.session,
    required this.enabled,
  });
  final Quiz quiz;
  final QuizSession session;
  final bool enabled;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gap = AppSpacing.of(context);
    final theme = Theme.of(context);
    final document = ref.watch(summaryDocumentProvider(quiz.documentId)).value;
    final question = quiz.questions[session.current];
    return ListView(
      padding: EdgeInsets.all(gap.page),
      children: [
        if (document != null)
          BookContextHeader(
            title: document.bookTitle,
            sequence: document.sequence,
          ),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: (session.current + 1) / quiz.questions.length,
              ),
            ),
            SizedBox(width: gap.item),
            Text(
              '${session.current + 1} / ${quiz.questions.length}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        SizedBox(height: gap.section),
        Text(question.question, style: theme.textTheme.titleLarge),
        SizedBox(height: gap.section),
        RadioGroup<int>(
          groupValue: session.answers[session.current],
          onChanged: (value) {
            if (enabled) {
              ref.read(quizSessionProvider(quiz).notifier).select(value);
            }
          },
          child: Column(
            children: [
              for (var i = 0; i < question.options.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: gap.item),
                  child: Material(
                    color: session.answers[session.current] == i
                        ? theme.colorScheme.surfaceContainerLow
                        : theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: session.answers[session.current] == i
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: RadioListTile<int>(
                      value: i,
                      enabled: enabled,
                      title: Text(
                        question.options[i],
                        style: theme.textTheme.bodyLarge,
                      ),
                      contentPadding: EdgeInsets.all(gap.small),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
