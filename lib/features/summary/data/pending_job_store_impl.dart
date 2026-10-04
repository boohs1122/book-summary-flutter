import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/model/pending_summary_job.dart';
import '../domain/pending_job_store.dart';
import 'dto/pending_job_dto.dart';

class PendingJobStoreImpl implements PendingJobStore {
  PendingJobStoreImpl(this._preferences, this._userId);
  final SharedPreferencesAsync _preferences;
  final Future<String> Function() _userId;
  Future<void> _mutation = Future.value();

  Future<String> _key() async => 'pending_summary_jobs_${await _userId()}';

  @override
  Future<List<PendingSummaryJob>> read() async {
    final value = await _preferences.getString(await _key());
    if (value == null) return [];
    final entries = jsonDecode(value) as List<dynamic>;
    return entries.map((entry) {
      final dto = PendingJobDto.fromJson(entry as Map<String, dynamic>);
      return PendingSummaryJob(
        jobId: dto.jobId,
        bookId: dto.bookId,
        createdAt: dto.createdAt,
      );
    }).toList();
  }

  Future<void> _update(
    List<PendingSummaryJob> Function(List<PendingSummaryJob>) update,
  ) {
    final operation = _mutation.then((_) async {
      final key = await _key();
      final value = await _preferences.getString(key);
      final jobs = value == null
          ? <PendingSummaryJob>[]
          : (jsonDecode(value) as List<dynamic>).map((entry) {
              final dto = PendingJobDto.fromJson(entry as Map<String, dynamic>);
              return PendingSummaryJob(
                jobId: dto.jobId,
                bookId: dto.bookId,
                createdAt: dto.createdAt,
              );
            }).toList();
      await _preferences.setString(
        key,
        jsonEncode(
          update(jobs)
              .map(
                (job) => PendingJobDto(
                  jobId: job.jobId,
                  bookId: job.bookId,
                  createdAt: job.createdAt,
                ).toJson(),
              )
              .toList(),
        ),
      );
    });
    _mutation = operation.catchError((Object _) {});
    return operation;
  }

  @override
  Future<void> put(PendingSummaryJob job) => _update(
    (jobs) => [...jobs.where((value) => value.jobId != job.jobId), job],
  );

  @override
  Future<void> remove(String jobId) =>
      _update((jobs) => jobs.where((job) => job.jobId != jobId).toList());
}
