import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../domain/model/summary_document.dart';

final summaryPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 2),
);

final summaryDocumentProvider = FutureProvider.family<SummaryDocument, String>(
  (ref, documentId) =>
      ref.watch(summaryRepositoryProvider).getDocument(documentId),
);

final summaryJobProvider = StreamProvider.autoDispose
    .family<SummaryJob, String>((ref, jobId) {
      final repository = ref.watch(summaryRepositoryProvider);
      final interval = ref.watch(summaryPollIntervalProvider);
      final controller = StreamController<SummaryJob>();
      Timer? timer;
      var disposed = false;

      Future<void> poll() async {
        var terminal = false;
        try {
          final job = await repository.getJob(jobId);
          if (disposed) return;
          controller.add(job);
          terminal = job.status != SummaryJobStatus.processing;
        } catch (error, stackTrace) {
          if (disposed) return;
          controller.addError(error, stackTrace);
          terminal = error is SummaryJobExpired;
        }
        if (terminal) {
          await controller.close();
        } else if (!disposed) {
          timer = Timer(interval, poll);
        }
      }

      ref.onDispose(() {
        disposed = true;
        timer?.cancel();
        unawaited(controller.close());
      });
      unawaited(poll());
      return controller.stream;
    }, retry: (count, error) => null);
