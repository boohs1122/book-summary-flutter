import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';

import '../domain/ocr_repository.dart';

Uint8List prepareOcrImage(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unsupported image');
  final oriented = image.bakeOrientation(decoded);
  final resized = oriented.width > 1600 || oriented.height > 1600
      ? image.copyResize(
          oriented,
          width: oriented.width >= oriented.height ? 1600 : null,
          height: oriented.height > oriented.width ? 1600 : null,
        )
      : oriented;
  return Uint8List.fromList(image.encodeJpg(resized, quality: 90));
}

class OcrRepositoryImpl implements OcrRepository {
  @override
  Future<String> recognize(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final resized = await compute(prepareOcrImage, bytes);
    final directory = await Directory((await getTemporaryDirectory()).path)
        .createTemp('ocr-');
    final file = File('${directory.path}/page.jpg');
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
    try {
      await file.writeAsBytes(resized);
      final result = await recognizer.processImage(
        InputImage.fromFilePath(file.path),
      );
      return result.text;
    } finally {
      await recognizer.close();
      await directory.delete(recursive: true);
    }
  }
}
