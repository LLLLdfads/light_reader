
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.chapters,
  });

  final String id;
  final String title;
  final String author;
  final List<Chapter> chapters;
}

// 仅书本描述
class BookInfo {
  const BookInfo({
    required this.id,
    required this.title,
    required this.author,
    required this.totalChapterCount,
    required this.chapterIds,
    required this.chapterTitles,
  });
  final String id;
  final int totalChapterCount;
  final String title;
  final String author;
  final List<String> chapterIds;
  final List<String> chapterTitles;
  String getChapterTitle(String chapterId) {
    final index = chapterIds.indexOf(chapterId);
    if (index < 0) return '';
    return chapterTitles[index];
  }

  /// -1:上一章,1:下一章；0:当前章；-2:上两章；2:下两章...
  String? getNearChapterId(String chapterId, int delta) {
    final index = chapterIds.indexOf(chapterId);
    final next = index + delta;
    if (index < 0 || next < 0 || next >= chapterIds.length) return null;
    return chapterIds[next];
  }
}

class Chapter {
  Chapter({
    required this.id,
    required this.chapterTitle,
    required this.paragraphs,
    required this.bookName,
  });
  final String id;
  final String bookName;

  final String chapterTitle;
  final List<String> paragraphs;
  final List<PageText> pageTexts = [];

  String get content =>
      _indentParagraphs(paragraphs.map((p) => p.trim()).join('\n'));

  // 给定文本，返回缩进后的文本
  static String _indentParagraphs(String raw) {
    final parts = raw
        .replaceAll('\r\n', '\n')
        .split(RegExp(r'\n+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    return parts.map((part) => '　　$part').join('\n');
  }
}

// 一页文本
class PageText {
  const PageText({
    required this.text,
    required this.height,
    required this.chapterTitle,
    required this.chapterTitleHeight,
    required this.chapterIndex,
    required this.index,
    required this.fontSize,
    required this.titleFontSize,
    required this.bookName,
    this.pageCount = 0,
  });
  final String text;
  // 这些文本占用的高度
  final double height;
  // 这一页，chapterTitle占用的高度，只有第一页有效，其他页为0
  final double chapterTitleHeight;
  final String chapterTitle;
  final String chapterIndex;
  final int index;
  final double fontSize;
  final double titleFontSize;
  // 页眉书名
  final String bookName;
  // 对应chapter分页出来一共有几页
  final int pageCount;

  PageText copyWith({
    String? text,
    double? height,
    String? chapterTitle,
    double? chapterTitleHeight,
    String? chapterIndex,
    int? index,
    double? fontSize,
    double? titleFontSize,
    String? bookName,
    int? pageCount,
  }) {
    return PageText(
      text: text ?? this.text,
      height: height ?? this.height,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      chapterTitleHeight: chapterTitleHeight ?? this.chapterTitleHeight,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      index: index ?? this.index,
      fontSize: fontSize ?? this.fontSize,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      bookName: bookName ?? this.bookName,
      pageCount: pageCount ?? this.pageCount,
    );
  }
}
