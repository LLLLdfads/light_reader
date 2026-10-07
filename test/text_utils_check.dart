import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_reader/config/screen_size.dart';
import 'package:light_reader/feature/reader/db/story.dart';
import 'package:light_reader/feature/reader/db/story6.dart';
import 'package:light_reader/feature/reader/model/book.dart';
import 'package:light_reader/feature/reader/provider/view_config_vm.dart';
import 'package:light_reader/feature/utils/text_utils.dart';

void _screen({double width = 360, double height = 640}) {
  screenSize
    ..screenWidth = width
    ..screenHeight = height
    ..screenTopInset = 24
    ..screenBottomInset = 16;
}

ViewConfigVM _config({double fontSize = 16, double height = 1.5}) {
  return ViewConfigVM(
    contentStyle: TextStyle(fontSize: fontSize, height: height),
  );
}

Chapter _ch(String title, List<String> paragraphs, {String id = 'c'}) {
  return Chapter(
    id: id,
    chapterTitle: title,
    bookName: 'b',
    paragraphs: paragraphs,
  );
}

double _contentBottom(String text, ViewConfigVM config) {
  if (text.isEmpty) return 0;
  final painter = TextPainter(
    text: TextSpan(text: text, style: config.contentStyle),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: config.bodyMaxWidth);
  final metrics = painter.computeLineMetrics();
  painter.dispose();
  if (metrics.isEmpty) return 0;
  var last = metrics.last;
  if (last.width == 0 && metrics.length > 1) {
    last = metrics[metrics.length - 2];
  }
  return last.baseline + last.descent;
}

void _assertPaging(ViewConfigVM config, Chapter chapter) {
  final pages = TextUtils.getPageTextList(config, chapter);
  expect(pages, isNotEmpty);
  expect(pages.map((p) => p.index).toList(), List.generate(pages.length, (i) => i));
  expect(pages.every((p) => p.pageCount == pages.length), isTrue);
  if (chapter.content.isEmpty) {
    expect(pages, hasLength(1));
    expect(pages.single.text, isEmpty);
    return;
  }
  expect(pages.every((p) => p.text.isNotEmpty), isTrue);
  expect(pages.map((p) => p.text).join(), chapter.content);
  if (chapter.chapterTitle.isNotEmpty) {
    expect(pages.first.chapterTitleHeight, greaterThan(0));
  }
  for (var i = 1; i < pages.length; i++) {
    expect(pages[i].chapterTitleHeight, 0);
  }
  final firstMax = config.bodyMaxHeight(pages.first.chapterTitleHeight);
  final laterMax = config.bodyMaxHeight(0);
  expect(_contentBottom(pages.first.text, config), lessThanOrEqualTo(firstMax + 1));
  for (var i = 1; i < pages.length; i++) {
    expect(_contentBottom(pages[i].text, config), lessThanOrEqualTo(laterMax + 1));
  }
}

void main() {
  setUp(_screen);

  group('正文形态', () {
    test('空章一页空文', () {
      _assertPaging(_config(), _ch('空', []));
    });

    test('一段短文只占一页', () {
      final pages = TextUtils.getPageTextList(_config(), _ch('短', ['只有一句。']));
      expect(pages, hasLength(1));
      _assertPaging(_config(), _ch('短', ['只有一句。']));
    });

    test('单字', () {
      _assertPaging(_config(), _ch('一', ['字']));
    });

    test('纯中文长段', () {
      _assertPaging(
        _config(),
        _ch('第一回', List.filled(40, '一段用来分页的正文，' * 8)),
      );
    });

    test('多段与空行、Windows 换行会被收成段', () {
      final chapter = _ch('段', [
        '第一段\r\n\r\n第二段',
        '',
        '   ',
        '第三段',
      ]);
      expect(chapter.content, '　　第一段\n　　第二段\n　　第三段');
      _assertPaging(_config(), chapter);
    });

    test('段首缩进保留在切页拼接里', () {
      final chapter = _ch('缩进', ['甲。' * 80, '乙。' * 80]);
      final pages = TextUtils.getPageTextList(_config(), chapter);
      expect(pages.first.text.startsWith('　　'), isTrue);
      expect(chapter.content.split('\n').every((p) => p.startsWith('　　')), isTrue);
      _assertPaging(_config(), chapter);
    });
  });

  group('中英混排与标点', () {
    test('中英夹杂、长 token、数字', () {
      _assertPaging(
        _config(),
        _ch('Chapter 1 混合', [
          'Hello 世界，this is a mixed paragraph with English words and 中文夹杂，'
              'including a long token ABCDEFGHIJKLMNOPQRSTUVWXYZ and 标点。',
          'Next line: The Mole said “Bother!” 然后他跑出去了，spring-cleaning his little home.',
          'URL-like fooBarBazQux 以及数字 1234567890 混在 汉字中间 wrappingTest.',
          ('一段中文后面突然插入 many English words that should wrap on spaces, '
              'then 又回到中文继续排，反复几次。') *
              12,
        ]),
      );
    });

    test('英文词边界 Wind in the Willows', () {
      _assertPaging(_config(), sampleBook6.chapters.first);
    });

    test('连字符、省略号、撇号', () {
      _assertPaging(
        _config(),
        _ch('Punc', [
          "It's a well-known state-of-the-art test... wait—em dash—and "
              'so-called “quotes” with 中文破折号——还有省略号……夹在 English 里。' *
              20,
        ]),
      );
    });

    test('中文标点贴行尾', () {
      _assertPaging(
        _config(),
        _ch('标点', [
          '他说：“你好！”然后问：这是谁？啊！嗯……走吧、停一下；继续。' * 40,
        ]),
      );
    });

    test('书名号引号与数字千分位', () {
      _assertPaging(
        _config(),
        _ch('符号', [
          '《石头记》又名「红楼梦」，见『第一回』。价格 1,234.56 美元 vs １２３全角数字。' *
              25,
        ]),
      );
    });

    test('URL 与邮箱不按旧算法切错', () {
      _assertPaging(
        _config(),
        _ch('Link', [
          'See https://example.com/path/to/very/long/resource?q=中文&x=1 '
              'or mail foo.bar+tag@example.co.uk 然后回到中文叙述。' *
              15,
        ]),
      );
    });

    test('超长无空格英文夹中文', () {
      _assertPaging(
        _config(),
        _ch('Long', [
          '中文Supercalifragilisticexpialidocious中文'
              'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789中文' *
              8,
        ]),
      );
    });
  });

  group('标题与版式', () {
    test('空标题', () {
      _assertPaging(_config(), _ch('', ['正文若干。' * 50]));
    });

    test('超长标题换行后第一页正文更少', () {
      final shortTitle = _ch('短', List.filled(20, '正文，' * 30));
      final longTitle = _ch(
        '这是一个非常非常长的章节标题需要换很多行才能显示完而且还混了 English Title Words',
        List.filled(20, '正文，' * 30),
      );
      final shortPages = TextUtils.getPageTextList(_config(), shortTitle);
      final longPages = TextUtils.getPageTextList(_config(), longTitle);
      expect(longPages.first.chapterTitleHeight, greaterThan(shortPages.first.chapterTitleHeight));
      expect(longPages.first.text.length, lessThan(shortPages.first.text.length));
      _assertPaging(_config(), longTitle);
    });

    test('窄栏大字号', () {
      _screen(width: 280);
      _assertPaging(
        _config(fontSize: 22, height: 1.7),
        _ch('Narrow Title 标题也比较长会换行', [
          'I 中 you 文 we mix punctuation—dash, comma, and “quotes”. '
              '超长英文单词 Supercalifragilisticexpialidocious 夹在中文里。' *
              6,
        ]),
      );
    });

    test('宽屏小字号', () {
      _screen(width: 720, height: 1280);
      _assertPaging(
        _config(fontSize: 12, height: 1.2),
        _ch('宽', List.filled(30, '宽屏小字也会跨页，Hello world 混排。' * 10)),
      );
    });

    test('行高 1.0 与 1.8', () {
      final chapter = _ch('行高', List.filled(15, '行距变化 The line height changes. ' * 12));
      _assertPaging(_config(height: 1.0), chapter);
      _assertPaging(_config(height: 1.8), chapter);
    });
  });

  group('真实章节', () {
    test('红楼梦第一回', () {
      _assertPaging(_config(), sampleBook.chapters.first);
    });

    test('Willows 其余几章', () {
      for (final chapter in sampleBook6.chapters.take(4)) {
        _assertPaging(_config(), chapter);
      }
    });
  });
}
