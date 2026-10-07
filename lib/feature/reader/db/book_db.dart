// 模拟从数据库中获取存储的上次阅读的chapterId
class BookDb {
  static Future<String?> getLastReadChapterId(String bookId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return '0';
  }
}
