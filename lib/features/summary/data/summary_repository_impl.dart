import 'package:dio/dio.dart';

import '../domain/model/summary_document.dart';
import '../domain/summary_repository.dart';
import 'dto/summary_dto.dart';

SummaryJobStatus _status(String status) => switch (status) {
  'PROCESSING' => SummaryJobStatus.processing,
  'DONE' => SummaryJobStatus.done,
  'FAILED' => SummaryJobStatus.failed,
  _ => throw const FormatException('Unknown summary status'),
};

class SummaryRepositoryImpl implements SummaryRepository {
  const SummaryRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<String> submitText({
    required String bookId,
    required String text,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/documents',
      data: {'bookId': bookId, 'text': text},
    );
    return JobAcceptedDto.fromJson(response.data!).jobId;
  }

  @override
  Future<SummaryJob> getJob(String jobId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/jobs/${Uri.encodeComponent(jobId)}',
      );
      final dto = SummaryJobDto.fromJson(response.data!);
      return SummaryJob(
        id: dto.jobId,
        status: _status(dto.status),
        documentId: dto.documentId,
        createdAt: dto.createdAt,
        errorCode: dto.error?.code,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) throw SummaryJobExpired();
      rethrow;
    }
  }

  @override
  Future<SummaryDocument> getDocument(String documentId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/documents/${Uri.encodeComponent(documentId)}',
    );
    final dto = SummaryDocumentDto.fromJson(response.data!);
    final summary = dto.summary;
    return SummaryDocument(
      id: dto.documentId,
      bookId: dto.bookId,
      bookTitle: dto.bookTitle,
      sequence: dto.sequence,
      text: dto.extractedText,
      status: _status(dto.status),
      summary: summary == null
          ? null
          : SummaryContent(
              title: summary.title,
              keyPoints: summary.keyPoints
                  .map(
                    (point) => SummaryKeyPoint(
                      type: KeyPointType.values.firstWhere(
                        (value) => value.name == point.type,
                        orElse: () => KeyPointType.definition,
                      ),
                      heading: point.heading,
                      detail: point.detail,
                    ),
                  )
                  .toList(),
              terms: summary.terms
                  .map(
                    (term) =>
                        SummaryTerm(term: term.term, meaning: term.meaning),
                  )
                  .toList(),
            ),
    );
  }

  @override
  Future<String> retryDocument(String documentId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/documents/${Uri.encodeComponent(documentId)}/retry',
    );
    return JobAcceptedDto.fromJson(response.data!).jobId;
  }
}
