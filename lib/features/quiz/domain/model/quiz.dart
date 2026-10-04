class Quiz {
  const Quiz({
    required this.id,
    required this.documentId,
    required this.questions,
  });
  final String id;
  final String documentId;
  final List<QuizQuestion> questions;
}

class QuizQuestion {
  const QuizQuestion({
    required this.index,
    required this.question,
    required this.options,
  });
  final int index;
  final String question;
  final List<String> options;
}

class QuizAnswer {
  const QuizAnswer({required this.index, required this.selected});
  final int index;
  final int? selected;
}

class QuizResult {
  const QuizResult({
    required this.id,
    required this.correct,
    required this.total,
    required this.items,
  });
  final String id;
  final int correct;
  final int total;
  final List<QuizResultItem> items;
}

class QuizResultItem {
  const QuizResultItem({
    required this.index,
    required this.question,
    required this.options,
    required this.selected,
    required this.answerIndex,
    required this.correct,
    required this.explanation,
  });
  final int index;
  final String question;
  final List<String> options;
  final int? selected;
  final int answerIndex;
  final bool correct;
  final String explanation;
}

class QuizGenerationFailed implements Exception {
  const QuizGenerationFailed(this.code);
  final String? code;
}

class QuizAlreadyGenerating implements Exception {}
