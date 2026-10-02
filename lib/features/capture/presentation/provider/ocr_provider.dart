import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../domain/model/ocr_result.dart';

class OcrProgress {
  const OcrProgress({required this.total, this.processed = 0, this.result});

  final int total;
  final int processed;
  final OcrResult? result;
}

final ocrProvider = AsyncNotifierProvider<OcrNotifier, OcrProgress>(
  OcrNotifier.new,
);

class OcrNotifier extends AsyncNotifier<OcrProgress> {
  int _generation = 0;

  @override
  FutureOr<OcrProgress> build() => const OcrProgress(total: 0);

  Future<void> start(List<String> paths) async {
    final generation = ++_generation;
    final pages = <String>[];
    ref.read(textDraftProvider.notifier).update('');
    state = AsyncData(OcrProgress(total: paths.length));
    try {
      for (final path in paths) {
        final text = await ref.read(ocrRepositoryProvider).recognize(path);
        if (!ref.mounted || generation != _generation) return;
        pages.add(text);
        state = AsyncData(
          OcrProgress(total: paths.length, processed: pages.length),
        );
      }
      final result = OcrResult.fromPages(pages);
      ref.read(textDraftProvider.notifier).update(result.text);
      state = AsyncData(
        OcrProgress(
          total: paths.length,
          processed: pages.length,
          result: result,
        ),
      );
    } catch (error, stackTrace) {
      if (ref.mounted && generation == _generation) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  void cancel() {
    _generation++;
    state = const AsyncData(OcrProgress(total: 0));
  }
}

final textDraftProvider = NotifierProvider<TextDraftNotifier, String>(
  TextDraftNotifier.new,
);

class TextDraftNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String text) => state = text;
}
