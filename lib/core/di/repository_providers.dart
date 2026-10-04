import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_provider.dart';
import '../../features/summary/data/summary_repository_impl.dart';
import '../../features/summary/domain/summary_repository.dart';
import '../../features/summary/data/pending_job_store_impl.dart';
import '../../features/summary/domain/pending_job_store.dart';

import '../../features/library/data/library_repository_impl.dart';
import '../../features/library/domain/library_repository.dart';
import '../network/dio_provider.dart';
import '../../features/capture/data/ocr_repository_impl.dart';
import '../../features/capture/domain/ocr_repository.dart';
import '../../features/quiz/data/quiz_repository_impl.dart';
import '../../features/quiz/domain/quiz_repository.dart';
import '../../features/quiz/data/pending_quiz_store_impl.dart';
import '../../features/quiz/domain/pending_quiz_store.dart';

final summaryRepositoryProvider = Provider<SummaryRepository>(
  (ref) => SummaryRepositoryImpl(ref.watch(dioProvider)),
);
final pendingJobStoreProvider = Provider<PendingJobStore>(
  (ref) => PendingJobStoreImpl(
    SharedPreferencesAsync(),
    () async => (await ref.read(authenticatedUserProvider.future)).uid,
  ),
);

final ocrRepositoryProvider = Provider<OcrRepository>(
  (ref) => OcrRepositoryImpl(),
);

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepositoryImpl(ref.watch(dioProvider));
});

final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => QuizRepositoryImpl(ref.watch(dioProvider)),
);
final pendingQuizStoreProvider = Provider<PendingQuizStore>(
  (ref) => PendingQuizStoreImpl(
    SharedPreferencesAsync(),
    () async => (await ref.read(authenticatedUserProvider.future)).uid,
  ),
);
