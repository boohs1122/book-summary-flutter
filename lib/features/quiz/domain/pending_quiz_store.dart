class PendingQuizJob {
  const PendingQuizJob({required this.documentId, required this.jobId});
  final String documentId;
  final String jobId;
}

abstract class PendingQuizStore {
  Future<PendingQuizJob?> read(String documentId);
  Future<void> put(PendingQuizJob job);
  Future<void> remove(String documentId);
}
