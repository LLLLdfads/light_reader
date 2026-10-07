import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:light_reader/feature/reader/model/book.dart';
import 'package:light_reader/feature/reader/provider/view_config_vm.dart';

extension ChapterPaging on Chapter {
  void paginate(ViewConfigVM viewConfig) {
    pageTexts.addAll(TextUtils.getPageTextList(viewConfig, this));
  }
}

// 文字排版器
class TextUtils {
  /// 给定章节，viewconfig，获得章节对应的PageText list。
  /// 耗时：title排版+正文排版+切页
  static List<PageText> getPageTextList(ViewConfigVM config, Chapter chapter) {
    Stopwatch? timer;
    if (kDebugMode || kProfileMode) {
      timer = Stopwatch()..start();
      debugPrint('排版开始 chapterId:${chapter.id}');
    }
    // 有title，先计算title高度
    var titleHeight = getTextHeight(
      config.titleStyle,
      chapter.chapterTitle,
      config.bodyMaxWidth,
    );
    final titleCastTime = kDebugMode || kProfileMode
        ? timer!.elapsedMilliseconds
        : 0;
    final text = chapter.content;
    final fontSize = config.contentStyle.fontSize!;
    final titleFontSize = config.titleStyle.fontSize!;
    // 第一页正文高度要扣掉 title；后面的页用满栏高。
    final firstPageMaxHeight = config.bodyMaxHeight(titleHeight);
    final laterPageMaxHeight = config.bodyMaxHeight(0);
    if (text.isEmpty) {
      return [
        PageText(
          text: '',
          height: 0,
          chapterTitle: chapter.chapterTitle,
          chapterTitleHeight: titleHeight,
          chapterIndex: chapter.id,
          index: 0,
          fontSize: fontSize,
          titleFontSize: titleFontSize,
          bookName: chapter.bookName,
          pageCount: 1,
        ),
      ];
    }
    final painter = TextPainter(
      text: TextSpan(text: text, style: config.contentStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: config.bodyMaxWidth);
    final metrics = painter.computeLineMetrics();
    final textCastTime = kDebugMode || kProfileMode
        ? timer!.elapsedMilliseconds - titleCastTime
        : 0;
    if (metrics.isEmpty) {
      painter.dispose();
      return [
        PageText(
          text: text,
          height: painter.height,
          chapterTitle: chapter.chapterTitle,
          chapterTitleHeight: titleHeight,
          chapterIndex: chapter.id,
          index: 0,
          fontSize: fontSize,
          titleFontSize: titleFontSize,
          bookName: chapter.bookName,
          pageCount: 1,
        ),
      ];
    }
    final pages = <PageText>[];
    var start = 0;
    var startChar = 0;
    while (start < metrics.length) {
      // pages.isEmpty=true说明是第一页，最大高度就要减去title高度
      final maxH = pages.isEmpty ? firstPageMaxHeight : laterPageMaxHeight;
      // ← 行顶 = baseline - ascent
      //   中文
      // --------← 基线 baseline
      //   gp
      //  ← 行底 = baseline + descent
      // pageTop说白了就是为了知道这一页开始行的顶部位置
      final pageTop = start == 0
          ? 0.0
          : metrics[start].baseline - metrics[start].ascent;
      var endLine = start;
      var height = 0.0;
      // 每一行文本的最底部 y，用来判断本页最后一行。
      for (var i = start; i < metrics.length; i++) {
        final bottom = metrics[i].baseline + metrics[i].descent - pageTop;
        if (i > start && bottom > maxH) break;
        endLine = i;
        height = bottom;
      }
      // 点在该行字形中间，避免比例字体的行尾和从右向左文字的右缘落到别的位置。
      final line = metrics[endLine];
      final pos = painter.getPositionForOffset(
        Offset(line.left + line.width / 2, line.baseline),
      ); // 点在这一行矩形的中间
      var endCharIndex = painter
          .getLineBoundary(pos)
          .end; // 这一行结束后的逻辑位置（字符串位置，因此不分左右）
      // .end和subString截的都是左闭右开，因此一般的情况下直接用endCharIndex给subString即可
      // 特殊情况，'\n'占一个字符位，如果文本如下：
      // text:  h e l l o \n w o r l d
      // index: 0 1 2 3 4  5  6 7 8 9 10
      // endCharIndex将会是5，substring切字符是左闭右开结果不会包含\n，所以需要加1
      // 一般情况下，如果最后一行是abc这样的字符结尾，则正常截取即可。
      // 但如果是\n，不+1的话，下一个页面的第一行将会是空着的。因为目前是整页的一次排版，
      // 效果上hello就在world上面。如果不+1，下一页第一行就会是空着的，这一页将少一个高度
      // 在此基础上排会造成下一页一行文字的缺失
      if (endCharIndex < text.length && text[endCharIndex] == '\n') {
        endCharIndex += 1;
      }
      if (endCharIndex <= startChar) {
        endCharIndex = (startChar + 1).clamp(0, text.length);
      }
      pages.add(
        PageText(
          text: text.substring(startChar, endCharIndex),
          height: height,
          chapterTitle: chapter.chapterTitle,
          chapterTitleHeight: titleHeight,
          chapterIndex: chapter.id,
          index: pages.length,
          fontSize: fontSize,
          titleFontSize: titleFontSize,
          bookName: chapter.bookName,
        ),
      );
      titleHeight = 0; // titleHeight只有第一个页面有效，其他页面为0
      startChar = endCharIndex;
      start = endLine + 1;
    }
    painter.dispose();
    if (kDebugMode || kProfileMode) {
      final totalMs = timer!.elapsedMilliseconds;
      debugPrint(
        '排版结束 chapterId:${chapter.id} 总${totalMs}ms title=$titleCastTime layout=$textCastTime 切页=${totalMs - titleCastTime - textCastTime} 共${pages.length}页/${metrics.length}行',
      );
    }
    return [for (final page in pages) page.copyWith(pageCount: pages.length)];
  }

  /// 按最大宽度排版，返回文本占用的总高度。标题超出栏宽时会计入换行。
  static double getTextHeight(
    TextStyle textStyle,
    String text,
    double maxWidth,
  ) {
    if (text.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final height = painter.height;
    painter.dispose();
    return height;
  }
}
