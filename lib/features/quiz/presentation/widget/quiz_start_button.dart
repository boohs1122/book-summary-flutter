import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/model/quiz.dart';
import '../provider/quiz_provider.dart';

const _preparing = '퀴즈를 준비하고 있어요';
const _again = '다시 풀기';
const _startLabel = '퀴즈 풀기';
const _retry = '다시 시도';
const _rateLimited = '퀴즈 생성 요청이 많습니다. 잠시 후 다시 시도해 주세요.';
const _missingDocument = '요약 문서를 찾을 수 없습니다.';
const _failed = '퀴즈를 만들지 못했습니다. 다시 시도해 주세요.';
const _pending = '퀴즈를 만들고 있어요. 잠시 후 다시 시도해 주세요.';

class QuizStartButton extends ConsumerWidget {
  const QuizStartButton({
    required this.documentId,
    this.hasAttempt = false,
    super.key,
  });
  final String documentId;
  final bool hasAttempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(quizFlowProvider);
    final loading = flow.isLoading;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: loading ? null : () => _start(context, ref),
          icon: loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.quiz_outlined),
          label: Text(
            loading
                ? _preparing
                : hasAttempt
                ? _again
                : _startLabel,
          ),
        ),
        if (flow.hasError && !loading) ...[
          SizedBox(height: AppSpacing.of(context).small),
          Text(_errorMessage(flow.error!), textAlign: TextAlign.center),
          TextButton(
            onPressed: () => _start(context, ref),
            child: const Text(_retry),
          ),
        ],
      ],
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    try {
      final quiz = await ref.read(quizFlowProvider.notifier).start(documentId);
      if (context.mounted) {
        context.push(AppRoutes.quizForDocument(documentId), extra: quiz);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      }
    }
  }

  String _quizError(QuizGenerationFailed error) => switch (error.code) {
    'RATE_LIMITED' => _rateLimited,
    'NOT_FOUND' => _missingDocument,
    _ => _failed,
  };

  String _errorMessage(Object error) => switch (error) {
    QuizGenerationFailed() => _quizError(error),
    QuizAlreadyGenerating() => _pending,
    _ => AppError.message(error),
  };
}
