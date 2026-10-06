import 'package:booksummary/core/router/app_router.dart';
import 'package:booksummary/features/capture/presentation/screen/book_selection_screen.dart';
import 'package:booksummary/features/library/presentation/screen/book_list_screen.dart';
import 'package:booksummary/features/summary/domain/model/pending_summary_job.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/design_fixtures.dart';

void main() {
  testWidgets('new book dialog remains valid while closing and can reopen', (
    tester,
  ) async {
    final container = previewContainer();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const BookSelectionScreen()),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(previewApp(container: container, router: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('새 책 만들기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '새로운 책',
    );
    await tester.tap(find.text('취소'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('새 책 만들기'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      isEmpty,
    );
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'multiple pending jobs do not overflow a small large-text library',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final jobs = PreviewJobs();
      for (var i = 0; i < 5; i++) {
        await jobs.put(
          PendingSummaryJob(
            jobId: 'job-$i',
            bookId: 'book',
            createdAt: DateTime(2026, 10, 6),
          ),
        );
      }
      final container = previewContainer(jobs: jobs);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const BookListScreen(),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        previewApp(container: container, router: router, textScale: 2),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('책 사진 찍기').hitTestable(), findsOneWidget);
    },
  );
}
