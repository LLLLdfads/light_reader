import 'package:light_reader/feature/reader/model/book.dart';

Chapter _ch(int i, String title, String text) {
  assert(text.length <= 100, '${text.length} $title');
  return Chapter(
    id: '$i',
    chapterTitle: title,
    paragraphs: [text],
    bookName: "Alice's Adventures in Wonderland",
  );
}

final sampleBook2 = Book(
  id: 'alice-wonderland',
  title: "Alice's Adventures in Wonderland",
  author: 'Lewis Carroll',
  chapters: [
    _ch(0, 'The Bank1', 'Alice sat by her sister, bored by a book with no pictures.'),
    _ch(1, 'The Rabbit2', 'A White Rabbit with a watch ran past. Alice jumped up, curious.'),
    _ch(2, 'The Hole3', 'She ran across the field and saw it pop down a hole under the hedge.'),
    _ch(3, 'The Fall4', 'Alice went down after it, never thinking how she would get out.'),
    _ch(4, 'The Well5', 'The hole dipped suddenly. She fell down a very deep well, slowly.'),
    _ch(5, 'The Jar6', 'She took a jar labelled ORANGE MARMALADE. It was empty. She put it back.'),
    _ch(6, 'The Centre7', 'Down, down. How many miles? Near the centre of the earth, she guessed.'),
    _ch(7, 'The Hall8', 'She landed in a long hall lined with locked doors and a tiny key.'),
    _ch(8, 'The Door9', 'The golden key fitted a little door. Beyond it lay a bright garden.'),
    _ch(9, 'Too Big10', 'She drank from a bottle: DRINK ME. She shrank, but forgot the key.'),
    _ch(10, 'Too Small11', 'A cake said EAT ME. She grew tall. Her head hit the roof of the hall.'),
    _ch(11, 'Tears12', 'Poor Alice cried until a pool of tears spread around her feet.'),
    _ch(12, 'The Gloves13', 'The White Rabbit dropped gloves and a fan, then hurried away.'),
    _ch(13, 'The Fan14', 'She fanned herself, shrank again, and slipped into the pool of tears.'),
    _ch(14, 'The Mouse15', 'She met a wet Mouse and tried French: Où est ma chatte? It was offended.'),
    _ch(15, 'The Shore16', 'A queer wet party gathered on the bank: birds, animals, all dripping.'),
    _ch(16, 'Caucus-Race17', 'The Dodo had them run in a circle until they were dry. All had won.'),
    _ch(17, 'Prizes18', 'Alice gave comfits as prizes. The Mouse told a long, dry tale.'),
    _ch(18, 'The House19', 'The Rabbit sent her to fetch gloves. She grew and filled his house.'),
    _ch(19, 'Bill20', 'Poor Bill the Lizard was kicked out the chimney. Alice shrank and fled.'),
  ],
);
