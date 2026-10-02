import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../domain/model/ocr_result.dart';
import '../provider/ocr_provider.dart';
import '../provider/selected_images_provider.dart';

const _title = '텍스트 추출';
const _shortText = '텍스트가 100자 미만입니다. 더 선명한 사진으로 다시 촬영해 주세요.';
const _failed = '텍스트를 추출하지 못했습니다. 다시 시도해 주세요.';
const _retry = '다시 추출하기';
const _cancel = '취소';
const _cancelTitle = '텍스트 추출을 취소할까요?';
const _cancelHint = '지금까지 추출한 텍스트는 삭제됩니다.';
const _continue = '계속 추출';

class OcrProgressScreen extends ConsumerStatefulWidget {
  const OcrProgressScreen({this.bookId, super.key});
  final String? bookId;

  @override
  ConsumerState<OcrProgressScreen> createState() => _OcrProgressScreenState();
}

class _OcrProgressScreenState extends ConsumerState<OcrProgressScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_start);
  }

  void _start() {
    if (!mounted) return;
    ref
        .read(ocrProvider.notifier)
        .start(
          ref.read(selectedImagesProvider).map((file) => file.path).toList(),
        );
  }

  Future<void> _cancelExtraction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(_cancelTitle),
        content: const Text(_cancelHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(_continue),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(_cancel),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(ocrProvider.notifier).cancel();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(ocrProvider);
    ref.listen(ocrProvider, (previous, next) {
      if (next.value?.result != null) {
        context.pushReplacement(AppRoutes.textReviewForBook(widget.bookId));
      } else if (next.error is OcrTextTooShort) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(_shortText)));
        context.pop();
      }
    });
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _cancelExtraction();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(_title),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: progress.when(
            loading: () => const CircularProgressIndicator(),
            error: (error, stackTrace) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(_failed),
                TextButton(onPressed: _start, child: const Text(_retry)),
                TextButton(
                  onPressed: _cancelExtraction,
                  child: const Text(_cancel),
                ),
              ],
            ),
            data: (value) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  value: value.total == 0
                      ? null
                      : value.processed / value.total,
                ),
                const SizedBox(height: 16),
                Text('${value.processed} / ${value.total} 장 처리 중'),
                TextButton(
                  onPressed: _cancelExtraction,
                  child: const Text(_cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
