// 模拟网络请求
import 'package:light_reader/feature/reader/db/story.dart';
import 'package:light_reader/feature/reader/db/story2.dart';
import 'package:light_reader/feature/reader/db/story3.dart';
import 'package:light_reader/feature/reader/db/story4.dart';
import 'package:light_reader/feature/reader/db/story5.dart';
import 'package:light_reader/feature/reader/db/story6.dart';
import 'package:light_reader/feature/reader/model/book.dart';

class BookService {
  static final books = [
    sampleBook,
    sampleBook2,
    sampleBook3,
    sampleBook4,
    sampleBook5,
    sampleBook6,
  ];

  static Book _book(String id) => books.firstWhere((book) => book.id == id);

  static BookInfo infoOf(Book book) => BookInfo(
    id: book.id,
    title: book.title,
    author: book.author,
    totalChapterCount: book.chapters.length,
    chapterIds: book.chapters.map((chapter) => chapter.id).toList(),
    chapterTitles: book.chapters
        .map((chapter) => chapter.chapterTitle)
        .toList(),
  );

  static List<BookInfo> listBooks() => books.map(infoOf).toList();

  static Future<Chapter> getChapter(String bookId, String chapterId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final src = _book(bookId).chapters
        .firstWhere((chapter) => chapter.id == chapterId);
    return Chapter(
      id: src.id,
      chapterTitle: src.chapterTitle,
      paragraphs: src.paragraphs,
      bookName: src.bookName,
    );
  }

  static Future<BookInfo> getBookInfo(String bookId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return infoOf(_book(bookId));
  }
}
