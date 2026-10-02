import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/ocr_provider.dart';

const _title = '텍스트 확인';
const _preview = '추출한 원문 보기';
const _hint = '인식이 잘못된 부분을 수정해 주세요.';
const _truncated = '텍스트가 길어 앞부분 10,000자만 남겼습니다.';
const _retake = '다시 찍기';

class TextReviewScreen extends ConsumerStatefulWidget {
  const TextReviewScreen({this.bookId, super.key});
  final String? bookId;

  @override
  ConsumerState<TextReviewScreen> createState() => _TextReviewScreenState();
}

class _TextReviewScreenState extends ConsumerState<TextReviewScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(textDraftProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(ocrProvider).value?.result;
    final draft = ref.watch(textDraftProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (result?.wasTruncated == true)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: const Text(_truncated),
              ),
            ),
          ExpansionTile(
            title: const Text(_preview),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(result?.text ?? ''),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 8,
            maxLines: null,
            maxLength: 10000,
            decoration: const InputDecoration(
              labelText: _hint,
              border: OutlineInputBorder(),
            ),
            onChanged: ref.read(textDraftProvider.notifier).update,
          ),
          Text('${draft.runes.length}자'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text(_retake),
          ),
        ],
      ),
    );
  }
}
