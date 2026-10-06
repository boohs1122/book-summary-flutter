import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/presentation/study_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../library/presentation/widget/book_context_header.dart';
import '../provider/selected_images_provider.dart';

const _screenTitle = '사진 선택';
const _cameraLabel = '사진 찍기';
const _galleryLabel = '갤러리';
const _emptyMessage = '책 사진을 추가해 주세요.';
const _pageHint = '한 페이지씩 촬영하면 더 정확해요.';
const _heading = '학습할 페이지를 선택하세요';
const _selected = '선택한 사진';
const _reorder = '길게 눌러 순서를 바꿀 수 있어요.';
const _limitMessage = '사진은 최대 8장까지 추가할 수 있습니다.';
const _pickError = '사진을 불러오지 못했습니다. 다시 시도해 주세요.';
const _permissionTitle = '사진 접근 권한이 필요해요';
const _permissionHint = '기기 설정에서 이 앱의 카메라 또는 사진 접근을 허용한 뒤 다시 시도해 주세요.';
const _confirm = '확인';
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
      _notify(_limitMessage);
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
    } on PlatformException catch (error) {
      if (!mounted) return;
      if (const {
        'camera_access_denied',
        'photo_access_denied',
        'camera_access_restricted',
        'photo_access_restricted',
      }.contains(error.code)) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(_permissionTitle),
            content: const Text(_permissionHint),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(_confirm),
              ),
            ],
          ),
        );
      } else {
        _notify(_pickError);
      }
    } catch (_) {
      _notify(_pickError);
    }
  }

  void _notify(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(selectedImagesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(_screenTitle)),
      bottomNavigationBar: ActionFooter(
        child: FilledButton(
          onPressed: images.isEmpty
              ? null
              : () => context.push(AppRoutes.ocrForBook(widget.bookId)),
          child: const Text(_extractLabel),
        ),
      ),
      body: _CaptureContent(bookId: widget.bookId, onPick: _pick),
    );
  }
}

class _CaptureContent extends ConsumerWidget {
  const _CaptureContent({required this.bookId, required this.onPick});
  final String? bookId;
  final void Function(ImageSource source) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gap = AppSpacing.of(context);
    final images = ref.watch(selectedImagesProvider);
    return ListView(
      padding: EdgeInsets.all(gap.page),
      children: [
        BookContextHeader(bookId: bookId),
        Text(_heading, style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: gap.small),
        Text(_pageHint, style: Theme.of(context).textTheme.bodySmall),
        SizedBox(height: gap.section),
        _PhotoActions(onPick: onPick),
        SizedBox(height: gap.section),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: gap.item,
          children: [
            Text(_selected, style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${images.length} / 8장',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        SizedBox(height: gap.item),
        const _SelectedImagesList(),
        SizedBox(height: gap.item),
        Text(_reorder, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _PhotoActions extends StatelessWidget {
  const _PhotoActions({required this.onPick});
  final void Function(ImageSource source) onPick;
  @override
  Widget build(BuildContext context) {
    final gap = AppSpacing.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final large = MediaQuery.textScalerOf(context).scale(15) > 22;
        final width = large
            ? constraints.maxWidth
            : (constraints.maxWidth - gap.small) / 2;
        return Wrap(
          spacing: gap.small,
          runSpacing: gap.small,
          children: [
            SizedBox(
              width: width,
              child: OutlinedButton.icon(
                onPressed: () => onPick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text(_cameraLabel),
              ),
            ),
            SizedBox(
              width: width,
              child: OutlinedButton.icon(
                onPressed: () => onPick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text(_galleryLabel),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SelectedImagesList extends ConsumerWidget {
  const _SelectedImagesList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(selectedImagesProvider);
    final gap = AppSpacing.of(context);
    if (images.isEmpty) return const ScreenMessage(message: _emptyMessage);
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      onReorderItem: ref.read(selectedImagesProvider.notifier).reorder,
      itemBuilder: (context, index) {
        final image = images[index];
        return Padding(
          key: ValueKey(image.path),
          padding: EdgeInsets.only(bottom: gap.item),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AspectRatio(
                  aspectRatio: 1.8,
                  child: Image.file(
                    File(image.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
              Positioned(
                left: gap.small,
                top: gap.small,
                child: Chip(label: Text('${index + 1}')),
              ),
              Positioned(
                right: gap.small,
                top: gap.small,
                child: IconButton.filledTonal(
                  tooltip: '${index + 1}번째 사진 $_removeLabel',
                  onPressed: () =>
                      ref.read(selectedImagesProvider.notifier).removeAt(index),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
