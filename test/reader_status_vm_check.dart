import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_reader/feature/reader/model/book.dart';
import 'package:light_reader/feature/reader/provider/reader_status_vm.dart';
import 'package:light_reader/feature/reader/provider/view_config_vm.dart';

PageText _page(String chapterId, int index) => PageText(
  text: '$chapterId-$index',
  height: 1,
  chapterTitle: chapterId,
  chapterTitleHeight: 0,
  chapterIndex: chapterId,
  index: index,
  fontSize: 16,
  titleFontSize: 19.2,
  bookName: 't',
);

Chapter _chapter(String id, int pages) {
  final chapter = Chapter(
    id: id,
    chapterTitle: id,
    paragraphs: const [],
    bookName: 't',
  );
  for (var i = 0; i < pages; i++) {
    chapter.pageTexts.add(_page(id, i));
  }
  return chapter;
}

void main() {
  test('flatIndex stays aligned with pageIndex in the 3-chapter window', () {
    final session = ReaderStatusVM(
      bookInfo: const BookInfo(
        id: 'b',
        title: 't',
        author: 'a',
        totalChapterCount: 3,
        chapterIds: ['c0', 'c1', 'c2'],
        chapterTitles: ['0', '1', '2'],
      ),
      nowChapterId: 'c1',
      nowPageIndex: 1,
    );
    session.adopt([
      _chapter('c0', 2),
      _chapter('c1', 3),
      _chapter('c2', 1),
    ]);
    session.setProgress('c1', 1);
    expect(session.nowFlatIndex, 3);
    session.toNearPage(1);
    session.toNearPage(1);
    expect(session.nowChapterId, 'c2');
    expect(session.nowPageIndex, 0);
    expect(session.nowFlatIndex, 5);
    session.toNearPage(-1);
    expect(session.nowChapterId, 'c1');
    expect(session.nowPageIndex, 2);
    expect(session.nowFlatIndex, 4);
  });

  test('one-page chapter at window edge is not book start/end', () {
    final session = ReaderStatusVM(
      bookInfo: const BookInfo(
        id: 'b',
        title: 't',
        author: 'a',
        totalChapterCount: 3,
        chapterIds: ['c0', 'c1', 'c2'],
        chapterTitles: ['0', '1', '2'],
      ),
      nowChapterId: 'c1',
    );
    final mid = _chapter('c1', 1);
    session.adopt([_chapter('c0', 2), mid, null]);
    session.setProgress('c1', 0);
    expect(session.nowFlatIndex, 2);
    expect(session.hasNextPage, isTrue);
    expect(session.atBookEnd, isFalse);
    session.adopt([null, mid, null]);
    session.setProgress('c1', 0);
    expect(session.nowFlatIndex, 0);
    expect(session.hasPrevPage, isTrue);
    expect(session.atBookStart, isFalse);
    // 窗口还没摆上上一章时，往前 peek 必须是 null，不能 RangeError。
    expect(session.pageNear(-1), isNull);
  });

  test('last chapter last page is book end', () {
    final session = ReaderStatusVM(
      bookInfo: const BookInfo(
        id: 'b',
        title: 't',
        author: 'a',
        totalChapterCount: 2,
        chapterIds: ['c0', 'c1'],
        chapterTitles: ['0', '1'],
      ),
      nowChapterId: 'c1',
    );
    session.adopt([_chapter('c0', 1), _chapter('c1', 1), null]);
    session.setProgress('c1', 0);
    expect(session.hasNextPage, isFalse);
    expect(session.atBookEnd, isTrue);
    session.setProgress('c0', 0);
    expect(session.hasPrevPage, isFalse);
    expect(session.atBookStart, isTrue);
  });

  test('ensureChapters marks screenReady even while flipping', () async {
    final viewConfig = ViewConfigVM(
      contentStyle: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
    );
    final session = ReaderStatusVM(
      bookInfo: const BookInfo(
        id: 'b',
        title: 't',
        author: 'a',
        totalChapterCount: 3,
        chapterIds: ['c0', 'c1', 'c2'],
        chapterTitles: ['0', '1', '2'],
      ),
      nowChapterId: 'c1',
    );
    session.adopt([
      _chapter('c0', 1),
      _chapter('c1', 1),
      _chapter('c2', 1),
    ]);
    await session.ensureChapters(viewConfig, isFlipping: () => false);
    expect(session.screenReady, isTrue);
    session.toNearPage(1);
    expect(session.nowChapterId, 'c2');
    expect(session.screenReady, isFalse);
    // 连滑时 isFlipping 仍为 true；若不标 screenReady，listener 会打转 ensure。
    await session.ensureChapters(viewConfig, isFlipping: () => true);
    expect(session.screenReady, isTrue);
    expect(session.nowFlatIndex, 1);
  });
}
