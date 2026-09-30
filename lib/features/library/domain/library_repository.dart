import 'model/book.dart';

abstract class LibraryRepository {
  Future<List<Book>> getBooks();
}
