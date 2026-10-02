import 'dart:async';

import 'package:booksummary/core/di/repository_providers.dart';
import 'package:booksummary/features/capture/data/ocr_repository_impl.dart';
import 'package:booksummary/features/capture/domain/model/ocr_result.dart';
import 'package:booksummary/features/capture/domain/ocr_repository.dart';
import 'package:booksummary/features/capture/presentation/provider/ocr_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

class _FakeOcr implements OcrRepository {
  _FakeOcr(this.callback);
  final Future<String> Function(String) callback;
  @override
  Future<String> recognize(String path) => callback(path);
}

void main() {
  test('OCR minimum and truncation boundaries', () {
    expect(
      () => OcrResult.fromPages(['가' * 99]),
      throwsA(isA<OcrTextTooShort>()),
    );
    expect(OcrResult.fromPages(['가' * 100]).text.length, 100);
    expect(OcrResult.fromPages(['가' * 10000]).wasTruncated, isFalse);
    final result = OcrResult.fromPages(['가' * 10001]);
    expect(result.text.length, 10000);
    expect(result.wasTruncated, isTrue);
  });

  test('pages are merged in selected order', () {
    expect(
      OcrResult.fromPages([' 가' * 100, '나 ']).text,
      '${(' 가' * 100).trim()}\n\n나',
    );
  });

  test('long image edge is resized to 1600 while retaining proportions', () {
    final bytes = image.encodePng(image.Image(width: 2000, height: 1000));
    final resized = image.decodeJpg(prepareOcrImage(bytes))!;
    expect(resized.width, 1600);
    expect(resized.height, 800);
  });

  test(
    'cancellation discards an in-flight page and skips remaining pages',
    () async {
      final pending = Completer<String>();
      final calls = <String>[];
      final container = ProviderContainer(
        overrides: [
          ocrRepositoryProvider.overrideWithValue(
            _FakeOcr((path) {
              calls.add(path);
              return pending.future;
            }),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(ocrProvider.future);
      final notifier = container.read(ocrProvider.notifier);
      final task = notifier.start(['first', 'second']);
      notifier.cancel();
      pending.complete('가' * 100);
      await task;
      expect(calls, ['first']);
      expect(container.read(ocrProvider).requireValue.result, isNull);
      expect(container.read(textDraftProvider), isEmpty);
    },
  );

  test('retry invokes OCR again after failure', () async {
    var calls = 0;
    final container = ProviderContainer(
      overrides: [
        ocrRepositoryProvider.overrideWithValue(
          _FakeOcr((path) async {
            if (++calls == 1) throw StateError('native recognition failed');
            return '가' * 100;
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(ocrProvider.future);
    await container.read(ocrProvider.notifier).start(['first']);
    expect(container.read(ocrProvider).hasError, isTrue);
    await container.read(ocrProvider.notifier).start(['first']);
    expect(calls, 2);
    expect(container.read(textDraftProvider), '가' * 100);
  });
}
