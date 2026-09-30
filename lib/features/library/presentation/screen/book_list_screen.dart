import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _screenTitle = '내 책';
const _appName = 'BookSummary';

class BookListScreen extends ConsumerWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;

    return Scaffold(
      appBar: AppBar(title: const Text(_screenTitle)),
      body: Center(child: Text(_appName, style: textStyle)),
    );
  }
}
