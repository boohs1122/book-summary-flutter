import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final selectedImagesProvider =
    NotifierProvider<SelectedImagesNotifier, List<XFile>>(
      SelectedImagesNotifier.new,
    );

class SelectedImagesNotifier extends Notifier<List<XFile>> {
  @override
  List<XFile> build() => [];

  void add(List<XFile> images) {
    state = [...state, ...images].take(8).toList();
  }

  void removeAt(int index) {
    state = [...state]..removeAt(index);
  }

  void reorder(int oldIndex, int newIndex) {
    final images = [...state];
    final image = images.removeAt(oldIndex);
    images.insert(newIndex, image);
    state = images;
  }

  void clear() => state = [];
}
