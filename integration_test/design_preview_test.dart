import 'package:booksummary/core/router/app_router.dart';
import 'package:booksummary/core/di/repository_providers.dart';
import 'package:booksummary/features/capture/presentation/provider/selected_images_provider.dart';
import 'package:booksummary/features/quiz/domain/model/quiz.dart';
import 'package:booksummary/features/quiz/presentation/provider/quiz_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:booksummary/features/library/presentation/provider/books_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/design_fixtures.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('v6 actual screens in light, dark and large text', (
    tester,
  ) async {
    final library = PreviewLibrary();
    final container = previewContainer(library: library);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      previewApp(container: container, router: appRouter),
    );
    await tester.pump(const Duration(seconds: 1));
    await container.read(quizFlowProvider.future);
    await binding.convertFlutterSurfaceToImage();

    Future<void> capture(String name, String location, {Object? extra}) async {
      appRouter.go(location, extra: extra);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull, reason: name);
      await binding.takeScreenshot(name);
    }

    await capture('01-book-list-light', AppRoutes.home);
    await capture('02-book-detail-light', AppRoutes.bookDetail('book'));
    await capture('03-image-selection-light', AppRoutes.captureForBook('book'));
    container.read(selectedImagesProvider.notifier).add([
      XFile('preview-page'),
    ]);
    await capture('04-ocr-progress-light', AppRoutes.ocrForBook('book'));
    (container.read(ocrRepositoryProvider) as PreviewOcr).response.complete(
      previewText,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await capture('05-text-review-light', AppRoutes.textReviewForBook('book'));
    await capture('06-book-selection-light', AppRoutes.bookSelection);
    await capture(
      '07-summary-progress-light',
      AppRoutes.summaryProgressForJob('job', 'book'),
    );
    await capture('08-summary-light', AppRoutes.summaryForDocument('document'));
    await capture(
      '09-quiz-light',
      AppRoutes.quizForDocument('document'),
      extra: previewQuiz,
    );
    await capture(
      '10-result-light',
      AppRoutes.quizResultForDocument('document'),
      extra: QuizResultRouteArgs(previewQuiz, previewResult),
    );

    await tester.pumpWidget(
      previewApp(container: container, router: appRouter, dark: true),
    );
    await capture('11-summary-dark', AppRoutes.summaryForDocument('document'));
    await capture(
      '12-result-dark',
      AppRoutes.quizResultForDocument('document'),
      extra: QuizResultRouteArgs(previewQuiz, previewResult),
    );
    await capture('13-book-list-dark', AppRoutes.home);

    library.empty = true;
    // Re-read through the same fake to exercise the actual empty state.
    container.invalidate(booksProvider);
    await capture('14-library-empty-dark', AppRoutes.home);
    library.empty = false;
    library.fails = true;
    container.invalidate(booksProvider);
    await capture('15-library-error-dark', AppRoutes.home);
    library.fails = false;
    container.invalidate(booksProvider);
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
        .clearSnackBars();

    await tester.pumpWidget(
      previewApp(container: container, router: appRouter, textScale: 2),
    );
    await capture(
      '16-summary-large-text',
      AppRoutes.summaryForDocument('document'),
    );
    await capture('17-capture-large-text', AppRoutes.captureForBook('book'));
    await capture(
      '18-text-review-large-text',
      AppRoutes.textReviewForBook('book'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
