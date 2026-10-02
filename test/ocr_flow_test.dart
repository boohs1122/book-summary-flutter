import 'dart:async';

import 'package:booksummary/core/di/repository_providers.dart';
import 'package:booksummary/core/router/app_router.dart';
import 'package:booksummary/features/capture/domain/ocr_repository.dart';
import 'package:booksummary/features/capture/presentation/provider/selected_images_provider.dart';
import 'package:booksummary/features/capture/presentation/screen/ocr_progress_screen.dart';
import 'package:booksummary/features/capture/presentation/screen/text_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class _Ocr implements OcrRepository {
  _Ocr(this.text);
  final String text;
  @override
  Future<String> recognize(String imagePath) async => text;
}

class _Images extends SelectedImagesNotifier {
  @override
  List<XFile> build() => [XFile('page.jpg')];
}

class _DelayedOcr implements OcrRepository {
  final pending = Completer<String>();
  @override
  Future<String> recognize(String imagePath) => pending.future;
}

Future<void> _mount(
  WidgetTester tester,
  String text, {
  OcrRepository? repository,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.push(AppRoutes.ocrForBook('book-1')),
            child: const Text('추출 시작'),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.ocr,
        builder: (context, state) =>
            OcrProgressScreen(bookId: state.uri.queryParameters['bookId']),
      ),
      GoRoute(
        path: AppRoutes.textReview,
        builder: (context, state) =>
            TextReviewScreen(bookId: state.uri.queryParameters['bookId']),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ocrRepositoryProvider.overrideWithValue(repository ?? _Ocr(text)),
        selectedImagesProvider.overrideWith(_Images.new),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('추출 시작'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'confirming cancellation returns to capture and ignores later OCR result',
    (tester) async {
      final repository = _DelayedOcr();
      await _mount(tester, '', repository: repository);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '취소').last);
      await tester.pumpAndSettle();
      expect(find.text('추출 시작'), findsOneWidget);
      repository.pending.complete('가' * 100);
      await tester.pumpAndSettle();
      expect(find.byType(TextReviewScreen), findsNothing);
    },
  );
  testWidgets('OCR opens editable text review and preserves target book', (
    tester,
  ) async {
    await _mount(tester, '가' * 100);
    expect(
      tester.widget<TextReviewScreen>(find.byType(TextReviewScreen)).bookId,
      'book-1',
    );
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '나' * 101);
    await tester.pump();
    expect(find.text('101자'), findsOneWidget);
  });

  testWidgets('short OCR text returns to capture with an explanation', (
    tester,
  ) async {
    await _mount(tester, '가' * 99);
    expect(find.text('추출 시작'), findsOneWidget);
    expect(find.textContaining('텍스트가 100자 미만'), findsOneWidget);
  });
}
