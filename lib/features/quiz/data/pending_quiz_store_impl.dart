import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/pending_quiz_store.dart';

class PendingQuizStoreImpl implements PendingQuizStore {
  PendingQuizStoreImpl(this._preferences, this._userId);
  final SharedPreferencesAsync _preferences;
  final Future<String> Function() _userId;
  Future<void> _mutation = Future.value();

  Future<String> _key() async => 'pending_quiz_jobs_${await _userId()}';

  @override
  Future<PendingQuizJob?> read(String documentId) async {
    await _mutation;
    final value = await _preferences.getString(await _key());
    if (value == null) return null;
    final jobs = jsonDecode(value) as Map<String, dynamic>;
    final job = jobs[documentId];
    if (job is! String) return null;
    return PendingQuizJob(documentId: documentId, jobId: job);
  }

  Future<void> _update(void Function(Map<String, dynamic>) update) {
    final operation = _mutation.then((_) async {
      final key = await _key();
      final value = await _preferences.getString(key);
      final jobs = value == null
          ? <String, dynamic>{}
          : jsonDecode(value) as Map<String, dynamic>;
      update(jobs);
      await _preferences.setString(key, jsonEncode(jobs));
    });
    _mutation = operation.catchError((Object _) {});
    return operation;
  }

  @override
  Future<void> put(PendingQuizJob job) => _update((jobs) {
    jobs[job.documentId] = job.jobId;
  });

  @override
  Future<void> remove(String documentId) => _update((jobs) {
    jobs.remove(documentId);
  });
}
