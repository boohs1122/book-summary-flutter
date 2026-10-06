import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/ocr_provider.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/presentation/study_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../library/presentation/widget/book_context_header.dart';
import '../../../summary/presentation/provider/summary_submission_provider.dart';

const _title = '텍스트 확인';
const _preview = '추출한 원문 보기';
const _heading = '인식된 텍스트';
const _hint = '잘못 인식된 글자를 수정해 주세요.';
const _truncated = '텍스트가 길어 앞부분 10,000자만 남겼습니다.';
const _retake = '다시 찍기';
const _submit = '요약하기';
const _choose = '책 선택하기';
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

  Future<void> _submitDraft() async {
    FocusScope.of(context).unfocus();
    if (widget.bookId == null) {
      context.push(AppRoutes.bookSelection);
      return;
    }
    final job = await ref
        .read(summarySubmissionProvider.notifier)
        .submit(text: ref.read(textDraftProvider), bookId: widget.bookId);
    if (job != null && mounted) {
      context.go(
        AppRoutes.summaryProgressForJob(
          job.jobId,
          job.bookId,
          createdAt: job.createdAt,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gap = AppSpacing.of(context);
    final draft = ref.watch(textDraftProvider);
    final submission = ref.watch(summarySubmissionProvider);
    final enabled =
        draft.trim().runes.length >= 100 &&
        draft.runes.length <= 10000 &&
        !submission.isLoading;
    ref.listen(summarySubmissionProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.message(next.error!))));
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text(_title)),
      bottomNavigationBar: ActionFooter(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: submission.isLoading ? null : () => context.pop(),
                child: const Text(_retake),
              ),
            ),
            SizedBox(width: gap.small),
            Expanded(
              child: FilledButton(
                onPressed: enabled ? _submitDraft : null,
                child: submission.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.bookId == null ? _choose : _submit),
              ),
            ),
          ],
        ),
      ),
      body: _TextEditor(
        bookId: widget.bookId,
        controller: _controller,
        enabled: !submission.isLoading,
      ),
    );
  }
}

class _TextEditor extends ConsumerWidget {
  const _TextEditor({
    required this.bookId,
    required this.controller,
    required this.enabled,
  });
  final String? bookId;
  final TextEditingController controller;
  final bool enabled;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gap = AppSpacing.of(context);
    final result = ref.watch(ocrProvider).value?.result;
    final draft = ref.watch(textDraftProvider);
    return ListView(
      padding: EdgeInsets.all(gap.page),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        BookContextHeader(bookId: bookId),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: gap.item,
          children: [
            Text(_heading, style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${draft.runes.length} / 10,000자',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        SizedBox(height: gap.item),
        if (result?.wasTruncated == true) ...[
          const MemoryCallout(label: _truncated, child: SizedBox.shrink()),
          SizedBox(height: gap.item),
        ],
        TextField(
          controller: controller,
          enabled: enabled,
          minLines: 10,
          maxLines: null,
          maxLength: 10000,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: const InputDecoration(hintText: _hint, counterText: ''),
          onChanged: ref.read(textDraftProvider.notifier).update,
        ),
        SizedBox(height: gap.small),
        Text(
          draft.trim().runes.length < 100 ? _minimumText : _hint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(height: gap.section),
        ExpansionTile(
          title: const Text(_preview),
          children: [
            SelectableText(
              result?.text ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ],
    );
  }
}
