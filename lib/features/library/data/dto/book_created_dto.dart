import 'package:json_annotation/json_annotation.dart';

part 'book_created_dto.g.dart';

@JsonSerializable(createToJson: false)
class BookCreatedDto {
  const BookCreatedDto({required this.bookId});
  factory BookCreatedDto.fromJson(Map<String, dynamic> json) =>
      _$BookCreatedDtoFromJson(json);
  final String bookId;
}
