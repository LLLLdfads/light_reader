import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_reader/feature/book_shelf/book_shelf_page.dart';
import 'package:light_reader/feature/reader/service/book_service.dart';

void main() {
  testWidgets('shelf shows title author and chapter count', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: BookShelfPage()));
    final book = BookService.listBooks().first;
    expect(find.text('书架'), findsOneWidget);
    expect(find.text(book.title), findsOneWidget);
    expect(find.text(book.author), findsOneWidget);
    expect(find.text('${book.totalChapterCount}章'), findsOneWidget);
  });
}
