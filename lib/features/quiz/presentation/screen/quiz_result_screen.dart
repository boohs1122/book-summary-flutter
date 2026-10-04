import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../domain/model/quiz.dart';

class QuizResultRouteArgs {
  const QuizResultRouteArgs(this.quiz, this.result);
  final Quiz quiz;
  final QuizResult result;
}

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    required this.documentId,
    required this.args,
    super.key,
  });
  final String documentId;
  final QuizResultRouteArgs? args;

  @override
  Widget build(BuildContext context) {
    final value = args;
    if (value == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('채점 결과')),
        body: const Center(child: Text('결과를 불러올 수 없습니다. 요약에서 퀴즈를 다시 시작해 주세요.')),
      );
    }
    final result = value.result;
    return Scaffold(
      appBar: AppBar(title: const Text('채점 결과')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '${result.correct} / ${result.total}',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const Text('정답'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final item in result.items)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.index + 1}. ${item.question}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (var index = 0; index < item.options.length; index++)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          index == item.answerIndex
                              ? Icons.check_circle
                              : index == item.selected
                              ? Icons.cancel
                              : Icons.circle_outlined,
                          color: index == item.answerIndex
                              ? Theme.of(context).colorScheme.primary
                              : index == item.selected
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                        title: Text(item.options[index]),
                      ),
                    Text(item.explanation),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () =>
                context.go(AppRoutes.summaryForDocument(documentId)),
            child: const Text('요약으로 돌아가기'),
          ),
          OutlinedButton(
            onPressed: () => context.push(
              AppRoutes.quizForDocument(documentId),
              extra: value.quiz,
            ),
            child: const Text('다시 풀기'),
          ),
        ],
      ),
    );
  }
}
