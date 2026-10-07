import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:light_reader/config/screen_size.dart';
import 'package:light_reader/feature/reader/db/book_db.dart';
import 'package:light_reader/feature/reader/model/book.dart';
import 'package:light_reader/feature/reader/provider/reader_status_vm.dart';
import 'package:light_reader/feature/reader/provider/turn_vm.dart';
import 'package:light_reader/feature/reader/provider/view_config_vm.dart';
import 'package:light_reader/feature/reader/screen/reader_view_outer.dart';
import 'package:light_reader/feature/reader/service/book_service.dart';
import 'package:provider/provider.dart';

class BookShelfPage extends StatefulWidget {
  const BookShelfPage({super.key});

  @override
  State<BookShelfPage> createState() => _BookShelfPageState();
}

class _BookShelfPageState extends State<BookShelfPage> {
  List<BookInfo> books = [];

  @override
  void initState() {
    super.initState();
    books = BookService.listBooks();
  }

  Future<void> _open(BuildContext context, String bookId) async {
    final info = await BookService.getBookInfo(bookId);
    final lastReadChapterId = await BookDb.getLastReadChapterId(info.id) ?? '0';
    if (!context.mounted) return;
    final baseTextStyle = Theme.of(context).textTheme.bodyMedium!;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => ReaderStatusVM(
                bookInfo: info,
                nowChapterId: lastReadChapterId,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => ViewConfigVM(
                contentStyle: baseTextStyle.copyWith(
                  fontSize: 16,
                  color: ViewConfigVM.textColor,
                ),
              ),
            ),
            ChangeNotifierProvider(create: (_) => TurnVM()),
          ],
          child: const ReaderViewOuter(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    const gap = 12.0;
    const pad = 16.0;
    final w = (screenSize.screenWidth - pad * 2 - gap * 2) / 3;
    return Scaffold(
      appBar: AppBar(title: const Text('书架')),
      body: Padding(
        padding: const EdgeInsets.all(pad),
        child: Wrap(
          spacing: gap,
          runSpacing: gap,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final book in books)
              SizedBox(
                width: w,
                height: 150,
                child: BookCard(
                  book: book,
                  onTap: (bookId) => _open(context, bookId),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book, required this.onTap});
  final BookInfo book;
  final Function(String bookId) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(book.id),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: getRandmoColor(),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                '${book.totalChapterCount}章',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color getRandmoColor() {
  final random = math.Random();
  return Color.fromARGB(
    255,
    random.nextInt(256),
    random.nextInt(256),
    random.nextInt(256),
  );
}
