import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/library/data/library_repository_impl.dart';
import '../../features/library/domain/library_repository.dart';
import '../network/dio_provider.dart';
import '../../features/capture/data/ocr_repository_impl.dart';
import '../../features/capture/domain/ocr_repository.dart';

final ocrRepositoryProvider = Provider<OcrRepository>(
  (ref) => OcrRepositoryImpl(),
);

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepositoryImpl(ref.watch(dioProvider));
});
