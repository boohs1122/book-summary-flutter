import 'package:booksummary/features/quiz/data/pending_quiz_store_impl.dart';
import 'package:booksummary/features/quiz/domain/pending_quiz_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Preferences extends Fake implements SharedPreferencesAsync {
  final values = <String, String>{};
  final failedWrites = <bool>[];
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    if (failedWrites.isNotEmpty) throw Exception('storage unavailable');
    values[key] = value;
  }
}

void main() {
  test('concurrent pending jobs survive a new store instance', () async {
    final preferences = _Preferences();
    final store = PendingQuizStoreImpl(preferences, () async => 'user');
    await Future.wait([
      store.put(const PendingQuizJob(documentId: 'one', jobId: 'job-one')),
      store.put(const PendingQuizJob(documentId: 'two', jobId: 'job-two')),
    ]);
    final restored = PendingQuizStoreImpl(preferences, () async => 'user');
    expect((await restored.read('one'))?.jobId, 'job-one');
    expect((await restored.read('two'))?.jobId, 'job-two');
    await Future.wait([
      store.remove('one'),
      store.put(const PendingQuizJob(documentId: 'three', jobId: 'job-three')),
    ]);
    expect(await restored.read('one'), isNull);
    expect((await restored.read('two'))?.jobId, 'job-two');
    expect((await restored.read('three'))?.jobId, 'job-three');
    final otherUser = PendingQuizStoreImpl(preferences, () async => 'other');
    expect(await otherUser.read('two'), isNull);
  });

  test('failed storage write does not block the next retry', () async {
    final preferences = _Preferences()..failedWrites.add(true);
    final store = PendingQuizStoreImpl(preferences, () async => 'user');
    const job = PendingQuizJob(documentId: 'one', jobId: 'job');
    await expectLater(store.put(job), throwsException);
    preferences.failedWrites.clear();
    await store.put(job);
    expect((await store.read('one'))?.jobId, 'job');
  });
}
