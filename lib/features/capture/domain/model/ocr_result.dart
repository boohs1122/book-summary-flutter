class OcrTextTooShort implements Exception {}

class OcrResult {
  const OcrResult({required this.text, required this.wasTruncated});

  static const minimumLength = 100;
  static const maximumLength = 10000;

  factory OcrResult.fromPages(List<String> pages) {
    final merged = pages
        .map((page) => page.trim())
        .where((page) => page.isNotEmpty)
        .join('\n\n');
    final characters = merged.runes.toList();
    if (characters.length < minimumLength) throw OcrTextTooShort();
    return OcrResult(
      text: String.fromCharCodes(characters.take(maximumLength)),
      wasTruncated: characters.length > maximumLength,
    );
  }

  final String text;
  final bool wasTruncated;
}
