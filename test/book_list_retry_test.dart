import 'package:booksummary/core/auth/auth_provider.dart';
import 'package:booksummary/features/library/domain/model/book.dart';
import 'package:booksummary/features/library/presentation/provider/books_provider.dart';
import 'package:booksummary/features/library/presentation/screen/book_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FakeUser extends Fake implements User {}

void main() {
  testWidgets('retry re-runs authentication after login failure', (
    tester,
  ) async {
    var authAttempts = 0;

    await tester.pumpWidget(
      ProviderScope(
        retry: (count, error) => null,
        overrides: [
          authenticatedUserProvider.overrideWith((ref) async {
            authAttempts++;
            if (authAttempts == 1) {
              throw FirebaseAuthException(code: 'network-request-failed');
            }
            return _FakeUser();
          }),
          booksProvider.overrideWith((ref) async {
            await ref.read(authenticatedUserProvider.future);
            return <Book>[];
          }),
        ],
        child: const MaterialApp(home: BookListScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('다시 불러오기'), findsOneWidget);
    expect(authAttempts, 1);

    await tester.tap(find.text('다시 불러오기'));
    await tester.pumpAndSettle();
    expect(authAttempts, 2);
    expect(find.text('아직 등록된 책이 없습니다.'), findsOneWidget);
  });
}
