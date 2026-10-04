import 'package:json_annotation/json_annotation.dart';

part 'pending_job_dto.g.dart';

@JsonSerializable()
class PendingJobDto {
  const PendingJobDto({
    required this.jobId,
    required this.bookId,
    required this.createdAt,
  });
  factory PendingJobDto.fromJson(Map<String, dynamic> json) =>
      _$PendingJobDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PendingJobDtoToJson(this);
  final String jobId;
  final String bookId;
  final DateTime createdAt;
}
