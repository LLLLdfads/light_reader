import 'package:light_reader/feature/reader/model/book.dart';

Chapter _ch(int i, String title, String text) {
  assert(text.length <= 100, '${text.length} $title');
  return Chapter(
    id: '$i',
    chapterTitle: title,
    paragraphs: [text],
    bookName: '刻舟求剑',
  );
}

final sampleBook5 = Book(
  id: 'kezhou-qiujian',
  title: '刻舟求剑',
  author: '吕氏春秋',
  chapters: [
    _ch(0, '坠剑', '楚人有涉江者，其剑自舟中坠于水。遽契其舟，曰：“是吾剑之所从坠。”'),
    _ch(1, '求剑', '舟止，从其所契者入水求之。舟已行矣，而剑不行。求剑若此，不亦惑乎？'),
  ],
);
