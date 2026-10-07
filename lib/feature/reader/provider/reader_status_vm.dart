import 'package:flutter/foundation.dart';
import 'package:light_reader/feature/reader/model/book.dart';
import 'package:light_reader/feature/reader/provider/view_config_vm.dart';
import 'package:light_reader/feature/reader/service/book_service.dart';
import 'package:light_reader/feature/utils/text_utils.dart';

/// 当前书信息、阅读进度、前后中三章。
class ReaderStatusVM extends ChangeNotifier {
  ReaderStatusVM({
    required this.bookInfo,
    required this._nowChapterId,
    this._nowPageIndex = 0,
  });

  final BookInfo bookInfo;

  String _nowChapterId;
  String get nowChapterId => _nowChapterId;

  /// 当前章节的第几页(从0开始）
  int _nowPageIndex;
  int get nowPageIndex => _nowPageIndex;

  /// nowPageIndex在[pre、mid、next]三章中的索引
  int _nowFlatIndex = 0;
  int get nowFlatIndex => _nowFlatIndex;

  Chapter? _preChapter;
  Chapter? _midChapter;
  Chapter? _nextChapter;

  /// 三章屏幕正在对准或已经对准的章。翻页中途不改，避免动画没停稳就换屏幕。
  String _screenChapterId = '';

  bool get screenReady => _nowChapterId == _screenChapterId;

  void setProgress(String chapterId, int pageIndex) {
    final same = chapterId == _nowChapterId && pageIndex == _nowPageIndex;
    _nowChapterId = chapterId;
    _nowPageIndex = pageIndex;
    final oldFlat = _nowFlatIndex;
    _syncFlatIndex();
    if (same && oldFlat == _nowFlatIndex) return;
    notifyListeners();
  }

  /// 翻到邻居页。[delta]：-1 上一页，1 下一页。
  void toNearPage(int delta) {
    final page = pageNear(delta);
    if (page == null) return;
    setProgress(page.chapterIndex, page.index);
  }

  void _syncFlatIndex() {
    _nowFlatIndex = flatIndexOf(_nowChapterId, _nowPageIndex) ?? _nowFlatIndex;
  }

  /// 按参数顺序准备三章，先不改当前窗口，也不分页。已在窗口里的沿用。
  Future<List<Chapter?>> _setAroundChapters(
    String? preChapterId,
    String? midChapterId,
    String? nextChapterId,
  ) async {
    final oldList = [_preChapter, _midChapter, _nextChapter];
    final newList = <Chapter?>[null, null, null];
    final ids = [preChapterId, midChapterId, nextChapterId];
    for (var i = 0; i < ids.length; i++) {
      final id = ids[i];
      if (id == null) continue;
      final index = oldList.indexWhere((chapter) => chapter?.id == id);
      if (index >= 0) {
        newList[i] = oldList[index];
        continue;
      }
      newList[i] = await BookService.getChapter(bookInfo.id, id);
    }
    return newList;
  }

  @visibleForTesting
  void adopt(List<Chapter?> chapters) {
    _preChapter = chapters[0];
    _midChapter = chapters[1];
    _nextChapter = chapters[2];
  }

  /// 过期的摆窗口请求回来直接丢掉。
  int _screenSerial = 0;

  /// 以当前进度为中心摆前后章并分页。翻页中途也采用，只把扁平下标对齐到当前页。
  Future<int?> ensureChapters(
    ViewConfigVM viewConfig, {
    required bool Function() isFlipping,
    bool clearPages = false,
  }) async {
    var pageIndex = _nowPageIndex;
    final chapterId = _nowChapterId;
    if (!isFlipping()) _screenChapterId = chapterId;
    final oldChapterPageCount = queryChapter(chapterId)?.pageTexts.length ?? 0;
    if (clearPages) {
      _preChapter?.pageTexts.clear();
      _midChapter?.pageTexts.clear();
      _nextChapter?.pageTexts.clear();
    }
    final serial = ++_screenSerial;
    final chapters = await _setAroundChapters(
      bookInfo.getNearChapterId(chapterId, -1),
      chapterId,
      bookInfo.getNearChapterId(chapterId, 1),
    );
    if (serial != _screenSerial) return null;
    for (final chapter in chapters) {
      if (chapter != null && chapter.pageTexts.isEmpty) {
        chapter.paginate(viewConfig);
        if (serial != _screenSerial) return null;
      }
    }
    final newCount = chapters[1]?.pageTexts.length ?? 0;
    if (clearPages && oldChapterPageCount > newCount && newCount > 0) {
      if (pageIndex > 0) pageIndex--;
      if (pageIndex >= newCount) pageIndex = newCount - 1;
    }
    final kept = pageAt(_nowFlatIndex);
    adopt(chapters);
    if (isFlipping() && kept != null) {
      _nowFlatIndex =
          flatIndexOf(kept.chapterIndex, kept.index) ?? _nowFlatIndex;
    } else {
      _nowPageIndex = pageIndex;
      _syncFlatIndex();
    }
    _screenChapterId = chapterId;
    notifyListeners();
    return pageIndex;
  }

  List<Chapter> get _chapters => [?_preChapter, ?_midChapter, ?_nextChapter];

  bool get isEmpty => _chapters.isEmpty;

  Chapter? queryChapter(String id) {
    for (final chapter in _chapters) {
      if (chapter.id == id) return chapter;
    }
    return null;
  }

  /// 当前章已在窗口里时，进度对应的扁平页码。
  int? flatIndexOf(String chapterId, int pageIndex) {
    if (queryChapter(chapterId) == null) return null;
    return pageCountBefore(chapterId) + pageIndex;
  }

  /// 当前章之前已加载页的数量。
  int pageCountBefore(String chapterId) {
    var count = 0;
    for (final chapter in _chapters) {
      if (chapter.id == chapterId) break;
      count += chapter.pageTexts.length;
    }
    return count;
  }

  int get pageCount {
    var count = 0;
    for (final chapter in _chapters) {
      count += chapter.pageTexts.length;
    }
    return count;
  }

  String get _pageChapterId =>
      pageAt(_nowFlatIndex)?.chapterIndex ?? _nowChapterId;

  /// 能往后翻。窗口里有下一页，或目录里还有下一章（有章就一定有页）。
  bool get hasNextPage =>
      (pageCount > 0 && _nowFlatIndex < pageCount - 1) ||
      bookInfo.getNearChapterId(_pageChapterId, 1) != null;

  /// 能往前翻。窗口里有上一页，或目录里还有上一章。
  bool get hasPrevPage =>
      _nowFlatIndex > 0 ||
      bookInfo.getNearChapterId(_pageChapterId, -1) != null;

  /// 全书没有后一页。
  bool get atBookEnd => _chapters.isNotEmpty && !hasNextPage;

  /// 全书没有前一页。
  bool get atBookStart => _chapters.isNotEmpty && !hasPrevPage;

  PageText? pageAt(int flatIndex) {
    if (flatIndex < 0) return null;
    var cursor = flatIndex;
    for (final chapter in _chapters) {
      if (cursor < chapter.pageTexts.length) {
        return chapter.pageTexts[cursor];
      }
      cursor -= chapter.pageTexts.length;
    }
    return null;
  }

  /// [delta]：0 当前页，-1 上一页，1 下一页。
  PageText? pageNear([int delta = 0]) => pageAt(_nowFlatIndex + delta);
}
