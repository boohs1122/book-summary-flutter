import 'package:booksummary/features/capture/presentation/provider/selected_images_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('keeps at most eight images and preserves reordered page order', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final images = List.generate(9, (index) => XFile('page-$index.jpg'));

    container.read(selectedImagesProvider.notifier).add(images);
    expect(container.read(selectedImagesProvider), hasLength(8));

    container.read(selectedImagesProvider.notifier).reorder(0, 7);
    expect(container.read(selectedImagesProvider).map((image) => image.path), [
      'page-1.jpg',
      'page-2.jpg',
      'page-3.jpg',
      'page-4.jpg',
      'page-5.jpg',
      'page-6.jpg',
      'page-7.jpg',
      'page-0.jpg',
    ]);
  });
}
