import 'package:booksummary/core/auth/auth_provider.dart';
import 'package:booksummary/core/di/repository_providers.dart';
import 'package:booksummary/core/network/dio_provider.dart';
import 'package:booksummary/features/summary/domain/model/summary_document.dart';
import 'package:booksummary/firebase_options.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _runLiveApi = bool.fromEnvironment('RUN_LIVE_API');
const _text =
    '광합성은 식물과 조류가 빛 에너지를 이용하여 이산화탄소와 물로부터 '
    '유기물을 합성하는 과정이다. 산소는 이 과정의 부산물로 방출된다. '
    '엽록체의 틸라코이드 막에서 명반응이 일어나며, 빛 에너지를 화학 에너지로 '
    '전환하여 ATP와 NADPH를 만든다. 스트로마에서 진행되는 캘빈 회로는 '
    'ATP와 NADPH를 사용하여 이산화탄소를 고정한다. 광합성 속도는 빛의 세기, '
    '이산화탄소 농도와 온도의 영향을 받는다. 빛이 충분해도 이산화탄소가 '
    '부족하면 광합성 속도는 더 이상 증가하지 않는다.';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Firebase anonymous token authenticates the live summary flow',
    (tester) async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Use a fresh anonymous session so SDK sign-in is exercised on every run.
      await FirebaseAuth.instance.signOut();
      final container = ProviderContainer(retry: (count, error) => null);
      addTearDown(container.dispose);
      final user = await container.read(authenticatedUserProvider.future);
      expect(user.isAnonymous, isTrue);
      debugPrint('LIVE_API Firebase SDK anonymous login: PASS');

      final statuses = <String, int?>{};
      final dio = container.read(dioProvider);
      dio.interceptors.add(
        InterceptorsWrapper(
          onResponse: (response, handler) {
            final request = response.requestOptions;
            statuses['${request.method} ${request.path}'] = response.statusCode;
            // Never log request headers, tokens, Firebase config or exceptions.
            debugPrint(
              'LIVE_API ${request.method} ${request.path}: '
              '${response.statusCode}',
            );
            handler.next(response);
          },
          onError: (error, handler) {
            final code = error.response?.data;
            final body = code is Map ? code['error'] : null;
            final safeCode = body is Map ? body['code'] : null;
            handler.reject(
              DioException(
                requestOptions: RequestOptions(path: '/live-api'),
                error: 'HTTP ${error.response?.statusCode}; code=$safeCode',
              ),
            );
          },
        ),
      );
      final library = container.read(libraryRepositoryProvider);
      final summaries = container.read(summaryRepositoryProvider);
      final bookId = await library.createBook('연동 테스트');
      expect(statuses['POST /books'], 201);
      final books = await library.getBooks();
      expect(books.any((book) => book.id == bookId), isTrue);

      final jobId = await summaries.submitText(bookId: bookId, text: _text);
      expect(statuses['POST /documents'], 202);
      debugPrint('LIVE_API bookId=$bookId jobId=$jobId');
      final deadline = DateTime.now().add(const Duration(minutes: 4));
      var job = await summaries.getJob(jobId);
      while (job.status == SummaryJobStatus.processing &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(seconds: 2));
        job = await summaries.getJob(jobId);
      }
      expect(
        job.status,
        SummaryJobStatus.done,
        reason: 'Job status=${job.status.name}; error.code=${job.errorCode}',
      );
      expect(job.documentId, isNotNull);
      final document = await summaries.getDocument(job.documentId!);
      expect(document.text, _text);
      expect(document.summary?.title, isNotEmpty);
      expect(document.summary?.keyPoints, isNotEmpty);
      debugPrint(
        'LIVE_API documentId=${document.id}; '
        'summary=${document.summary!.title}; '
        'keyPoints=${document.summary!.keyPoints.length}; '
        'terms=${document.summary!.terms.length}',
      );

      final detail = await library.getBook(bookId);
      expect(detail.documents, hasLength(1));
      expect(detail.documents.single.id, document.id);
      expect(detail.documents.single.sequence, 1);
      expect(detail.documents.single.status, 'DONE');
      expect(detail.documents.single.charCount, _text.runes.length);
      expect(detail.documentCount, 1);
      expect(detail.totalCharCount, _text.runes.length);
      debugPrint(
        'LIVE_API original, sequence and aggregate: PASS '
        '(${_text.runes.length} characters)',
      );
    },
    skip: !_runLiveApi,
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
