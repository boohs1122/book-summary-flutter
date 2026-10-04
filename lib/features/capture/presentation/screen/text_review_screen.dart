import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/ocr_provider.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/router/app_router.dart';
import '../../../summary/presentation/provider/summary_submission_provider.dart';

const _title = '텍스트 확인';
const _preview = '추출한 원문 보기';
const _hint = '인식이 잘못된 부분을 수정해 주세요.';
const _truncated = '텍스트가 길어 앞부분 10,000자만 남겼습니다.';
const _retake = '다시 찍기';
const _submit = '요약하기';
const _minimumText = '요약하려면 텍스트가 100자 이상이어야 합니다.';

class TextReviewScreen extends ConsumerStatefulWidget {
  const TextReviewScreen({this.bookId, super.key});
  final String? bookId;

  @override
  ConsumerState<TextReviewScreen> createState() => _TextReviewScreenState();
}

class _TextReviewScreenState extends ConsumerState<TextReviewScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(textDraftProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(ocrProvider).value?.result;
    final draft = ref.watch(textDraftProvider);
    final submission = ref.watch(summarySubmissionProvider);
    ref.listen(summarySubmissionProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.message(next.error!))));
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text(_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (result?.wasTruncated == true)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: const Text(_truncated),
              ),
            ),
          ExpansionTile(
            title: const Text(_preview),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(result?.text ?? ''),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 8,
            maxLines: null,
            maxLength: 10000,
            decoration: const InputDecoration(
              labelText: _hint,
              border: OutlineInputBorder(),
            ),
            onChanged: ref.read(textDraftProvider.notifier).update,
          ),
          Text('${draft.runes.length}자'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text(_retake),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed:
                draft.trim().runes.length < 100 ||
                    draft.runes.length > 10000 ||
                    submission.isLoading
                ? null
                : () async {
                    if (widget.bookId == null) {
                      context.push(AppRoutes.bookSelection);
                      return;
                    }
                    final job = await ref
                        .read(summarySubmissionProvider.notifier)
                        .submit(text: draft, bookId: widget.bookId);
                    if (job != null && context.mounted) {
                      context.go(
                        AppRoutes.summaryProgressForJob(
                          job.jobId,
                          job.bookId,
                          createdAt: job.createdAt,
                        ),
                      );
                    }
                  },
            icon: submission.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: const Text(_submit),
          ),
          if (draft.trim().runes.length < 100)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(_minimumText),
            ),
        ],
      ),
    );
  }
}
