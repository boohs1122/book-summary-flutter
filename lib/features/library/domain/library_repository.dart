import 'model/book.dart';
import 'model/book_detail.dart';

abstract class LibraryRepository {
  Future<List<Book>> getBooks();
  Future<String> createBook(String title);

  Future<BookDetail> getBook(String bookId);

  Future<void> deleteBook(String bookId);
}
