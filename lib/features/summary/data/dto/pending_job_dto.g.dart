// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_job_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingJobDto _$PendingJobDtoFromJson(Map<String, dynamic> json) =>
    PendingJobDto(
      jobId: json['jobId'] as String,
      bookId: json['bookId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PendingJobDtoToJson(PendingJobDto instance) =>
    <String, dynamic>{
      'jobId': instance.jobId,
      'bookId': instance.bookId,
      'createdAt': instance.createdAt.toIso8601String(),
    };
