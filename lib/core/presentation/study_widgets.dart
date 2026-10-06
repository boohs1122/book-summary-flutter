import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const _retry = '다시 불러오기';
const _memoryLabel = '기억할 핵심';

class ActionFooter extends StatelessWidget {
  const ActionFooter({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final gap = AppSpacing.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(gap.page, gap.item, gap.page, gap.item),
          child: child,
        ),
      ),
    );
  }
}

class ScreenMessage extends StatelessWidget {
  const ScreenMessage({
    required this.message,
    this.hint,
    this.onRetry,
    this.actionLabel = _retry,
    super.key,
  });
  final String message;
  final String? hint;
  final VoidCallback? onRetry;
  final String actionLabel;
  @override
  Widget build(BuildContext context) {
    final gap = AppSpacing.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(gap.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (hint != null)
              Padding(
                padding: EdgeInsets.only(top: gap.small),
                child: Text(
                  hint!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (onRetry != null)
              Padding(
                padding: EdgeInsets.only(top: gap.item),
                child: TextButton(onPressed: onRetry, child: Text(actionLabel)),
              ),
          ],
        ),
      ),
    );
  }
}

class MemoryCallout extends StatelessWidget {
  const MemoryCallout({
    required this.child,
    this.label = _memoryLabel,
    super.key,
  });
  final Widget child;
  final String label;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final gap = AppSpacing.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(gap.item),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(left: BorderSide(color: colors.onSurface)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: gap.small),
          child,
        ],
      ),
    );
  }
}

class EmphasizedText extends StatelessWidget {
  const EmphasizedText(this.text, {this.terms = const [], super.key});
  final String text;
  final List<String> terms;
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyLarge!;
    final patternTerms =
        terms.where((term) => term.trim().isNotEmpty).toSet().toList()
          ..sort((a, b) => b.length.compareTo(a.length));
    if (patternTerms.isEmpty) return Text(text, style: base);
    final pattern = RegExp(patternTerms.map(RegExp.escape).join('|'));
    final spans = <TextSpan>[];
    var cursor = 0;
    // Keep emphasis sparse: at most two occurrences per paragraph.
    for (final match in pattern.allMatches(text).take(2)) {
      spans.add(TextSpan(text: text.substring(cursor, match.start)));
      spans.add(
        TextSpan(
          text: match.group(0),
          style: base.copyWith(
            fontWeight: FontWeight.w600,
            fontVariations: const [FontVariation('wght', 600)],
          ),
        ),
      );
      cursor = match.end;
    }
    spans.add(TextSpan(text: text.substring(cursor)));
    return Text.rich(TextSpan(children: spans), style: base);
  }
}
