import 'model/summary_document.dart';

abstract class SummaryRepository {
  Future<String> submitText({required String bookId, required String text});
  Future<SummaryJob> getJob(String jobId);
  Future<SummaryDocument> getDocument(String documentId);
  Future<String> retryDocument(String documentId);
}
