import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/pending_quiz_store.dart';

class PendingQuizStoreImpl implements PendingQuizStore {
  const PendingQuizStoreImpl(this._preferences, this._userId);
  final SharedPreferencesAsync _preferences;
  final Future<String> Function() _userId;

  Future<String> _key() async => 'pending_quiz_jobs_${await _userId()}';

  @override
  Future<PendingQuizJob?> read(String documentId) async {
    final value = await _preferences.getString(await _key());
    if (value == null) return null;
    final jobs = jsonDecode(value) as Map<String, dynamic>;
    final job = jobs[documentId];
    if (job is! String) return null;
    return PendingQuizJob(documentId: documentId, jobId: job);
  }

  @override
  Future<void> put(PendingQuizJob job) async {
    final key = await _key();
    final value = await _preferences.getString(key);
    final jobs = value == null
        ? <String, dynamic>{}
        : jsonDecode(value) as Map<String, dynamic>;
    jobs[job.documentId] = job.jobId;
    await _preferences.setString(key, jsonEncode(jobs));
  }

  @override
  Future<void> remove(String documentId) async {
    final key = await _key();
    final value = await _preferences.getString(key);
    if (value == null) return;
    final jobs = jsonDecode(value) as Map<String, dynamic>;
    jobs.remove(documentId);
    await _preferences.setString(key, jsonEncode(jobs));
  }
}
