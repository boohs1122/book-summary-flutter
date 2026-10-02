import 'model/book.dart';
import 'model/book_detail.dart';

abstract class LibraryRepository {
  Future<List<Book>> getBooks();

  Future<BookDetail> getBook(String bookId);

  Future<void> deleteBook(String bookId);
}
