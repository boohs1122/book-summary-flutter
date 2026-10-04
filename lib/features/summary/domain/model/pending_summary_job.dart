class PendingSummaryJob {
  const PendingSummaryJob({
    required this.jobId,
    required this.bookId,
    required this.createdAt,
  });
  final String jobId;
  final String bookId;
  final DateTime createdAt;
}
