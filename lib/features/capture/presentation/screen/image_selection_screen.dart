import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

import '../provider/selected_images_provider.dart';

const _screenTitle = '이미지 선택';
const _cameraLabel = '사진 찍기';
const _galleryLabel = '갤러리에서 선택';
const _emptyMessage = '책 사진을 추가해 주세요.';
const _pageHint = '한 페이지씩 촬영하면 텍스트가 더 정확하게 추출됩니다.';
const _limitMessage = '사진은 최대 8장까지 추가할 수 있습니다.';
const _pickError = '사진을 불러오지 못했습니다. 다시 시도해 주세요.';
const _removeLabel = '삭제';
const _extractLabel = '텍스트 추출';

class ImageSelectionScreen extends ConsumerStatefulWidget {
  const ImageSelectionScreen({this.bookId, super.key});

  final String? bookId;

  @override
  ConsumerState<ImageSelectionScreen> createState() =>
      _ImageSelectionScreenState();
}

class _ImageSelectionScreenState extends ConsumerState<ImageSelectionScreen> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(selectedImagesProvider.notifier).clear();
    });
  }

  Future<void> _pick(ImageSource source) async {
    final count = ref.read(selectedImagesProvider).length;
    if (count >= 8) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(_limitMessage)));
      return;
    }
    try {
      final List<XFile> images;
      if (source == ImageSource.camera) {
        final image = await _picker.pickImage(source: source);
        images = image == null ? [] : [image];
      } else {
        images = await _picker.pickMultiImage(limit: 8 - count);
      }
      if (mounted) ref.read(selectedImagesProvider.notifier).add(images);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(_pickError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(selectedImagesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(_screenTitle)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: images.isEmpty
                ? null
                : () => context.push(AppRoutes.ocrForBook(widget.bookId)),
            child: const Text(_extractLabel),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_pageHint, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text(_cameraLabel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text(_galleryLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text('${images.length} / 8'),
          const Expanded(child: _SelectedImagesList()),
        ],
      ),
    );
  }
}

class _SelectedImagesList extends ConsumerWidget {
  const _SelectedImagesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(selectedImagesProvider);
    if (images.isEmpty) return const Center(child: Text(_emptyMessage));
    return ReorderableListView.builder(
      itemCount: images.length,
      onReorderItem: ref.read(selectedImagesProvider.notifier).reorder,
      itemBuilder: (context, index) {
        final image = images[index];
        return ListTile(
          key: ValueKey(image.path),
          leading: Image.file(
            File(image.path),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
          title: Text('${index + 1}번째 사진'),
          trailing: IconButton(
            tooltip: _removeLabel,
            icon: const Icon(Icons.close),
            onPressed: () =>
                ref.read(selectedImagesProvider.notifier).removeAt(index),
          ),
        );
      },
    );
  }
}
