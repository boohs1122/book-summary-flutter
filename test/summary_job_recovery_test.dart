import 'dart:async';

import 'package:booksummary/core/di/repository_providers.dart';
import 'package:booksummary/features/summary/domain/model/summary_document.dart';
import 'package:booksummary/features/summary/domain/summary_repository.dart';
import 'package:booksummary/features/summary/presentation/provider/summary_job_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Jobs extends Fake implements SummaryRepository {
  bool offline = true;
  int polls = 0;
  @override
  Future<SummaryJob> getJob(String jobId) async {
    polls++;
    if (offline) throw Exception('offline');
    return SummaryJob(id: jobId, status: SummaryJobStatus.done);
  }
}

void main() {
  test('summary polling recovers after a connection failure', () async {
    final jobs = _Jobs();
    final container = ProviderContainer(
      overrides: [
        summaryRepositoryProvider.overrideWithValue(jobs),
        summaryPollIntervalProvider.overrideWithValue(
          const Duration(milliseconds: 10),
        ),
      ],
    );
    addTearDown(container.dispose);
    final recovered = Completer<SummaryJob>();
    var errors = 0;
    final subscription = container.listen(summaryJobProvider('job'), (_, next) {
      if (next.hasError) {
        errors++;
        jobs.offline = false;
      }
      if (next.value?.status == SummaryJobStatus.done) {
        recovered.complete(next.value!);
      }
    });
    addTearDown(subscription.close);
    expect((await recovered.future).id, 'job');
    expect(errors, 1);
    expect(jobs.polls, 2);
  });

  test('leaving stops polling and reentry resumes the same job', () async {
    final jobs = _Jobs();
    final container = ProviderContainer(
      overrides: [
        summaryRepositoryProvider.overrideWithValue(jobs),
        summaryPollIntervalProvider.overrideWithValue(
          const Duration(milliseconds: 10),
        ),
      ],
    );
    addTearDown(container.dispose);
    final failed = Completer<void>();
    final first = container.listen(summaryJobProvider('job'), (_, next) {
      if (next.hasError && !failed.isCompleted) failed.complete();
    });
    await failed.future;
    first.close();
    await container.pump();
    final stoppedAt = jobs.polls;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(jobs.polls, stoppedAt);
    jobs.offline = false;
    final resumed = Completer<SummaryJob>();
    final second = container.listen(summaryJobProvider('job'), (_, next) {
      if (next.value?.status == SummaryJobStatus.done) {
        resumed.complete(next.value!);
      }
    });
    addTearDown(second.close);
    expect((await resumed.future).id, 'job');
    expect(jobs.polls, stoppedAt + 1);
  });
}
