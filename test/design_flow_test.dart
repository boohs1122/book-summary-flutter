import 'package:booksummary/core/router/app_router.dart';
import 'package:booksummary/core/presentation/study_widgets.dart';
import 'package:booksummary/core/theme/app_theme.dart';
import 'package:booksummary/features/capture/presentation/provider/ocr_provider.dart';
import 'package:booksummary/features/capture/presentation/screen/image_selection_screen.dart';
import 'package:booksummary/features/capture/presentation/screen/text_review_screen.dart';
import 'package:booksummary/features/capture/presentation/screen/book_selection_screen.dart';
import 'package:booksummary/features/library/presentation/screen/book_list_screen.dart';
import 'package:booksummary/features/library/presentation/screen/book_detail_screen.dart';
import 'package:booksummary/features/quiz/presentation/provider/quiz_provider.dart';
import 'package:booksummary/features/quiz/presentation/screen/quiz_play_screen.dart';
import 'package:booksummary/features/quiz/presentation/screen/quiz_result_screen.dart';
import 'package:booksummary/features/summary/presentation/screen/summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/design_fixtures.dart';

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const BookListScreen()),
    GoRoute(
      path: '/books/:bookId',
      builder: (_, _) => const BookDetailScreen(bookId: 'book'),
    ),
    GoRoute(
      path: AppRoutes.capture,
      builder: (_, _) => const ImageSelectionScreen(bookId: 'book'),
    ),
    GoRoute(
      path: AppRoutes.textReview,
      builder: (_, _) => const TextReviewScreen(),
    ),
    GoRoute(
      path: AppRoutes.bookSelection,
      builder: (_, _) => const BookSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.summary,
      builder: (_, _) => const SummaryScreen(documentId: 'document'),
    ),
    GoRoute(
      path: AppRoutes.quiz,
      builder: (_, _) => const QuizPlayScreen(
        documentId: 'document',
        initialQuiz: previewQuiz,
      ),
    ),
    GoRoute(
      path: AppRoutes.quizResult,
      builder: (_, state) => QuizResultScreen(
        documentId: 'document',
        args: state.extra as QuizResultRouteArgs?,
      ),
    ),
  ],
);

void main() {
  testWidgets('small screens support large text on all content routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = previewContainer();
    final router = _router();
    addTearDown(container.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      previewApp(container: container, router: router, textScale: 2),
    );
    for (final route in [
      AppRoutes.home,
      AppRoutes.bookDetail('book'),
      AppRoutes.capture,
      AppRoutes.textReview,
      AppRoutes.bookSelection,
      AppRoutes.summary,
      AppRoutes.quiz,
      AppRoutes.quizResult,
    ]) {
      router.go(
        route,
        extra: route == AppRoutes.quizResult
            ? QuizResultRouteArgs(previewQuiz, previewResult)
            : null,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: route);
    }
  });

  testWidgets('back from book selection preserves the edited draft', (
    tester,
  ) async {
    final container = previewContainer();
    final router = _router();
    addTearDown(container.dispose);
    addTearDown(router.dispose);
    router.go(AppRoutes.textReview);
    await tester.pumpWidget(previewApp(container: container, router: router));
    await tester.pumpAndSettle();
    final edited = '$previewText 수정한 문장입니다.';
    await tester.enterText(find.byType(TextField), edited);
    await tester.tap(find.text('책 선택하기'));
    await tester.pumpAndSettle();
    expect(find.byType(BookSelectionScreen), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      edited,
    );
    expect(container.read(textDraftProvider), edited);
  });

  testWidgets(
    'quiz retry replaces result and returns to summary without stale pages',
    (tester) async {
      final container = previewContainer();
      final router = _router();
      addTearDown(container.dispose);
      addTearDown(router.dispose);
      router.go(AppRoutes.summaryForDocument('document'));
      await tester.pumpWidget(previewApp(container: container, router: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다시 풀기'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text(previewQuiz.questions[i].options[0]));
        await tester.tap(find.text(i < 2 ? '다음' : '채점하기'));
        await tester.pumpAndSettle();
      }
      expect(find.byType(QuizResultScreen), findsOneWidget);
      await tester.tap(find.text('다시 풀기'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(SummaryScreen), findsOneWidget);
      expect(find.byType(QuizResultScreen), findsNothing);
      expect(container.read(lastQuizResultProvider('document')), isNotNull);
      await tester.tap(find.text('결과 보기'));
      await tester.pumpAndSettle();
      expect(find.byType(QuizResultScreen), findsOneWidget);
    },
  );

  testWidgets(
    'processing document opens the job list without guessing its job',
    (tester) async {
      final library = PreviewLibrary()..processing = true;
      final container = previewContainer(library: library);
      final router = _router();
      addTearDown(container.dispose);
      addTearDown(router.dispose);
      router.go(AppRoutes.bookDetail('book'));
      await tester.pumpWidget(previewApp(container: container, router: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('프로세스와 문맥 교환'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('진행 중인 요약 보기'));
      await tester.pumpAndSettle();
      expect(find.byType(BookListScreen), findsOneWidget);
    },
  );

  testWidgets('emphasis preserves source text and escapes literal terms', (
    tester,
  ) async {
    const source = 'C++와 C++는 다르지 않다. PCB, 프로세스와 PCB.';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EmphasizedText(source, terms: ['C++', 'PCB', '프로세스']),
        ),
      ),
    );
    final rich = tester.widget<Text>(find.byType(Text));
    expect(rich.textSpan!.toPlainText(), source);
    final spans = (rich.textSpan as TextSpan).children!.cast<TextSpan>();
    expect(
      spans.where((span) => span.style?.fontWeight == FontWeight.w600).length,
      2,
    );
  });
}
