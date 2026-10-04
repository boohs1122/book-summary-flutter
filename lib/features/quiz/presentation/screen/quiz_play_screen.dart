import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/model/quiz.dart';
import '../provider/quiz_provider.dart';
import 'quiz_result_screen.dart';

class QuizPlayScreen extends ConsumerWidget {
  const QuizPlayScreen({required this.documentId, this.initialQuiz, super.key});
  final String documentId;
  final Quiz? initialQuiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialQuiz != null) return _QuizQuestions(quiz: initialQuiz!);
    final quiz = ref.watch(quizProvider(documentId));
    return Scaffold(
      appBar: AppBar(title: const Text('퀴즈')),
      body: quiz.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppError.message(error)),
              TextButton(
                onPressed: () => ref.invalidate(quizProvider(documentId)),
                child: const Text('다시 불러오기'),
              ),
            ],
          ),
        ),
        data: (value) => _QuizQuestions(quiz: value),
      ),
    );
  }
}

class _QuizQuestions extends ConsumerStatefulWidget {
  const _QuizQuestions({required this.quiz});
  final Quiz quiz;

  @override
  ConsumerState<_QuizQuestions> createState() => _QuizQuestionsState();
}

class _QuizQuestionsState extends ConsumerState<_QuizQuestions> {
  late final List<int?> _answers = List<int?>.filled(
    widget.quiz.questions.length,
    null,
  );
  int _current = 0;
  bool _submitting = false;
  bool _allowExit = false;

  Future<bool> _confirmExit() async {
    if (_answers.every((answer) => answer == null)) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('퀴즈를 나갈까요?'),
            content: const Text('지금 나가면 선택한 답이 저장되지 않습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('계속 풀기'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('나가기'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.quiz.questions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('퀴즈')),
        body: const Center(child: Text('퀴즈 문항이 없습니다.')),
      );
    }
    final question = questions[_current];
    return PopScope(
      canPop:
          _allowExit ||
          (!_submitting && _answers.every((answer) => answer == null)),
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop &&
            !_submitting &&
            await _confirmExit() &&
            context.mounted) {
          setState(() => _allowExit = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.pop();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('퀴즈')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${_current + 1} / ${questions.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_current + 1) / questions.length,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 28, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          question.question,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 20),
                        RadioGroup<int>(
                          groupValue: _answers[_current],
                          onChanged: (value) =>
                              setState(() => _answers[_current] = value),
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < question.options.length;
                                index++
                              )
                                Card(
                                  child: RadioListTile<int>(
                                    value: index,
                                    title: Text(question.options[index]),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (_current > 0)
                      OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _current--),
                        child: const Text('이전'),
                      ),
                    const Spacer(),
                    if (_current < questions.length - 1)
                      FilledButton(
                        onPressed: () => setState(() => _current++),
                        child: const Text('다음'),
                      )
                    else
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('채점하기'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final unanswered = _answers.where((answer) => answer == null).length;
    if (unanswered > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('답하지 않은 문항이 있어요'),
          content: Text('$unanswered개 문항은 오답으로 처리됩니다. 제출할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('계속 풀기'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('제출하기'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }
    setState(() => _submitting = true);
    try {
      final answers = widget.quiz.questions
          .asMap()
          .entries
          .map(
            (entry) => QuizAnswer(
              index: entry.value.index,
              selected: _answers[entry.key],
            ),
          )
          .toList();
      final result = await ref
          .read(quizResultProvider.notifier)
          .submit(widget.quiz.id, answers);
      if (mounted) {
        context.pushReplacement(
          AppRoutes.quizResultForDocument(widget.quiz.documentId),
          extra: QuizResultRouteArgs(widget.quiz, result),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppError.message(error))));
      }
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
