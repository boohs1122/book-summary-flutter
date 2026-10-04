import 'model/pending_summary_job.dart';

abstract class PendingJobStore {
  Future<List<PendingSummaryJob>> read();
  Future<void> put(PendingSummaryJob job);
  Future<void> remove(String jobId);
}
