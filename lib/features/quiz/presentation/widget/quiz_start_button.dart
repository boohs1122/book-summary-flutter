import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/model/quiz.dart';
import '../provider/quiz_provider.dart';

class QuizStartButton extends ConsumerWidget {
  const QuizStartButton({required this.documentId, super.key});
  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(quizFlowProvider);
    final loading = flow.isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: loading
              ? null
              : () async {
                  try {
                    final quiz = await ref
                        .read(quizFlowProvider.notifier)
                        .start(documentId);
                    if (context.mounted) {
                      context.push(
                        AppRoutes.quizForDocument(documentId),
                        extra: quiz,
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      final message = error is QuizGenerationFailed
                          ? _quizError(error)
                          : error is QuizAlreadyGenerating
                          ? '퀴즈를 만들고 있어요. 잠시 후 다시 시도해 주세요.'
                          : AppError.message(error);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(message)));
                    }
                  }
                },
          icon: loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.quiz_outlined),
          label: Text(loading ? '퀴즈를 준비하고 있어요' : '퀴즈 풀기'),
        ),
        if (flow.hasError && !loading) ...[
          const SizedBox(height: 8),
          Text(_errorMessage(flow.error!), textAlign: TextAlign.center),
          TextButton(
            onPressed: () => ref.invalidate(quizFlowProvider),
            child: const Text('다시 시도'),
          ),
        ],
      ],
    );
  }

  String _quizError(QuizGenerationFailed error) => switch (error.code) {
    'RATE_LIMITED' => '퀴즈 생성 요청이 많습니다. 잠시 후 다시 시도해 주세요.',
    'NOT_FOUND' => '요약 문서를 찾을 수 없습니다.',
    _ => '퀴즈를 만들지 못했습니다. 다시 시도해 주세요.',
  };

  String _errorMessage(Object error) => switch (error) {
    QuizGenerationFailed() => _quizError(error),
    QuizAlreadyGenerating() => '퀴즈를 만들고 있어요. 잠시 후 다시 시도해 주세요.',
    _ => AppError.message(error),
  };
}
