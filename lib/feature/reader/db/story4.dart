import 'package:light_reader/feature/reader/model/book.dart';

Chapter _ch(int i, String title, String text) {
  assert(text.length <= 100, '${text.length} $title');
  return Chapter(
    id: '$i',
    chapterTitle: title,
    paragraphs: [text],
    bookName: '守株待兔',
  );
}

final sampleBook4 = Book(
  id: 'shouzhu-daitu',
  title: '守株待兔',
  author: '韩非',
  chapters: [
    _ch(0, '守株待兔', '宋人有耕田者，田中有株。兔走触株，折颈而死。因释其耒而守株，冀复得兔。兔不可复得，而身为宋国笑。'),
  ],
);
