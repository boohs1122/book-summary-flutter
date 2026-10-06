import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/presentation/study_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../library/presentation/widget/book_context_header.dart';
import '../../../library/presentation/provider/books_provider.dart';
import '../../domain/model/summary_document.dart';
import '../provider/summary_job_provider.dart';
import '../provider/summary_submission_provider.dart';

const _reconnect = '다시 연결';
const _title = '요약 생성';
const _waiting = '핵심 내용을 정리하고 있어요';
const _slow = '예상보다 오래 걸리고 있습니다. 계속 기다리는 중입니다.';
const _cancel = '나중에 보기';
const _leaveTitle = '요약 생성은 계속됩니다';
const _leaveMessage = '이 화면을 닫아도 서버에서 요약을 만들고 있습니다. 홈에서 진행 상황을 다시 열 수 있습니다.';
const _leaveConfirm = '회차 목록으로';
const _retryLabel = '요약 다시 만들기';
const _failed = '요약을 만들지 못했습니다.';
const _missingDocument = '실패한 회차 정보를 찾지 못했습니다. 책 목록에서 확인해 주세요.';

class SummaryProgressScreen extends ConsumerStatefulWidget {
  const SummaryProgressScreen({
    required this.jobId,
    required this.bookId,
    this.createdAt,
    super.key,
  });

  final String jobId;
  final String bookId;
  final DateTime? createdAt;

  @override
  ConsumerState<SummaryProgressScreen> createState() =>
      _SummaryProgressScreenState();
}

class _SummaryProgressScreenState extends ConsumerState<SummaryProgressScreen>
    with WidgetsBindingObserver {
  Timer? _clock;
  late DateTime _started;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _started = widget.createdAt ?? DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(summaryJobProvider(widget.jobId));
    }
  }

  Future<void> _leave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(_leaveTitle),
        content: const Text(_leaveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('계속 기다리기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(_leaveConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.go(AppRoutes.bookDetail(widget.bookId));
    }
  }

  Future<void> _openDocument(String documentId) async {
    if (_opening) return;
    _opening = true;
    try {
      await ref.read(summaryDocumentProvider(documentId).future);
      await ref.read(pendingJobStoreProvider).remove(widget.jobId);
      ref.invalidate(pendingSummaryJobsProvider);
      ref.invalidate(bookDetailProvider(widget.bookId));
      ref.invalidate(booksProvider);
      if (mounted) context.go(AppRoutes.summaryForDocument(documentId));
    } catch (error) {
      _opening = false;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppError.message(error))));
      }
    }
  }

  Future<void> _retry(SummaryJob job) async {
    final documentId = job.documentId;
    if (documentId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(_missingDocument)));
      return;
    }
    final next = await ref
        .read(summarySubmissionProvider.notifier)
        .retry(
          documentId: documentId,
          bookId: widget.bookId,
          previousJobId: widget.jobId,
        );
    if (next != null && mounted) {
      context.go(
        AppRoutes.summaryProgressForJob(
          next.jobId,
          next.bookId,
          createdAt: next.createdAt,
        ),
      );
    } else if (mounted) {
      final error = ref.read(summarySubmissionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppError.message(error ?? Exception()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(summaryJobProvider(widget.jobId));
    ref.listen(summaryJobProvider(widget.jobId), (previous, next) {
      final value = next.value;
      if (value?.status == SummaryJobStatus.done && value?.documentId != null) {
        _openDocument(value!.documentId!);
      }
    });
    final seconds = DateTime.now().difference(_started).inSeconds;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(_title),
          leading: IconButton(
            tooltip: _cancel,
            onPressed: _leave,
            icon: const Icon(Icons.close),
          ),
        ),
        bottomNavigationBar: ActionFooter(
          child: OutlinedButton(onPressed: _leave, child: const Text(_cancel)),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.of(context).page),
              child: BookContextHeader(bookId: widget.bookId),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.of(context).page),
                  child: job.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stackTrace) => ScreenMessage(
                      message: AppError.message(error),
                      onRetry: () =>
                          ref.invalidate(summaryJobProvider(widget.jobId)),
                      actionLabel: _reconnect,
                    ),
                    data: (value) => switch (value.status) {
                      SummaryJobStatus.processing => _ProcessingJob(
                        seconds: seconds,
                      ),
                      SummaryJobStatus.done => _DoneJob(
                        onOpen: value.documentId == null
                            ? null
                            : () => _openDocument(value.documentId!),
                      ),
                      SummaryJobStatus.failed => ScreenMessage(
                        message: _failed,
                        hint: value.errorCode == null
                            ? null
                            : _friendlyJobError(value.errorCode!),
                        onRetry: () => _retry(value),
                        actionLabel: _retryLabel,
                      ),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _friendlyJobError(String code) => switch (code) {
  'RATE_LIMITED' => '요청이 많아 잠시 후 다시 시도해 주세요.',
  'LLM_FAILED' || 'LLM_INVALID_RESPONSE' => '요약 서비스에 일시적인 문제가 있습니다.',
  _ => '잠시 후 다시 시도해 주세요.',
};

class _DoneJob extends StatelessWidget {
  const _DoneJob({required this.onOpen});

  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.check_circle_outline, size: 52),
      const SizedBox(height: 12),
      const Text('요약이 완성됐습니다.'),
      const SizedBox(height: 16),
      FilledButton(onPressed: onOpen, child: const Text('요약 보기')),
    ],
  );
}

class _ProcessingJob extends StatelessWidget {
  const _ProcessingJob({required this.seconds});
  final int seconds;
  @override
  Widget build(BuildContext context) {
    final gap = AppSpacing.of(context);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        SizedBox(height: gap.section),
        Text(
          seconds >= 60 ? _slow : _waiting,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        SizedBox(height: gap.small),
        Text(
          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
          style: theme.textTheme.displaySmall?.copyWith(fontSize: 28),
        ),
        SizedBox(height: gap.section),
        Text(
          _leaveMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
