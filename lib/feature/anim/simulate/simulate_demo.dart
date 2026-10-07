import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:light_reader/config/screen_size.dart';
import 'package:light_reader/feature/anim/simulate/model/page_img_cache.dart';
import 'package:light_reader/feature/anim/simulate/simulate_helper.dart';
import 'package:light_reader/feature/reader/db/story.dart';

// 先build，后拿图片，一直只有两张图片，当前页和下一页。
// 左滑时，index对应页就是当前页，index+1就是下一页
// 右滑时，index-1就是当前页面，index对应页就是下一页
class SimulateDemo extends StatefulWidget {
  const SimulateDemo({super.key});

  @override
  State<SimulateDemo> createState() => _SimulateDemoState();
}

class _SimulateDemoState extends State<SimulateDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  final Color bgColor = const Color(0xffE1DCC2);
  final Color textColor = const Color.fromARGB(255, 66, 63, 48);
  final double fontSize = 20;
  Offset? _touchPos;
  Offset? _startTouchPos; // 开始滑动时，手指的触点位置，用来判断是左滑还是右滑
  bool _isForward = true; // 当前翻页是否是向前翻页（向左滑动，逐渐能看到下一页）
  // 松手前最后一次水平移动：>0 往左，<0 往右
  double _fingerIntentDirect = 0;
  final _pageImgCache = PageImgCache();
  final _aboveCtrl = SnapshotController(allowSnapshotting: false);
  final _nextCtrl = SnapshotController(allowSnapshotting: false);
  PageSnapshot? _aboveGrab;
  PageSnapshot? _nextGrab;
  late final double pageWidth;
  int _nowPageIndex = 0;

  int get _aboveIndex => _isForward ? _nowPageIndex : _nowPageIndex - 1;
  int get _nextIndex => _isForward ? _nowPageIndex + 1 : _nowPageIndex;

  void _onGetPageImg(bool isAbove, ui.Image img, int pageIndex) {
    if (!mounted) {
      img.dispose();
      return;
    }
    setState(() {
      _pageImgCache.update(isAbove, PageImg(img, fontSize, bgColor, pageIndex));
      (isAbove ? _aboveCtrl : _nextCtrl).allowSnapshotting = false;
    });
  }

  void _enablePageSnapshot({required bool isAbove}) {
    final index = isAbove ? _aboveIndex : _nextIndex;
    if (_pageImgCache.match(index, fontSize, bgColor, isAbove)) return;
    final grab = PageSnapshot((img) => _onGetPageImg(isAbove, img, index));
    if (isAbove) {
      _aboveGrab?.dispose();
      _aboveGrab = grab;
      _aboveCtrl.allowSnapshotting = true;
    } else {
      _nextGrab?.dispose();
      _nextGrab = grab;
      _nextCtrl.allowSnapshotting = true;
    }
  }

  void _clearFlip() {
    _isForward = true;
    _touchPos = null;
    _anim.value = 0;
  }

  @override
  void initState() {
    super.initState();
    pageWidth = screenSize.screenWidth;
    _anim = AnimationController.unbounded(vsync: this, value: 0)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed || _touchPos == null) return;
        final didTurn = _anim.value == (_isForward ? -pageWidth : pageWidth);
        if (didTurn) {
          if (!_isForward && _nowPageIndex > 0) {
            _nowPageIndex--;
          } else if (_isForward &&
              _nowPageIndex < sampleBook.chapters.length - 1) {
            _nowPageIndex++;
          }
        }
        _clearFlip();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _aboveCtrl.dispose();
    _nextCtrl.dispose();
    _aboveGrab?.dispose();
    _nextGrab?.dispose();
    _pageImgCache.dispose();
    _anim.dispose();
    super.dispose();
  }

  bool get isPanStartMidVertical {
    final y = _startTouchPos?.dy ?? 0;
    final h = screenSize.screenHeight;
    return h / 3 <= y && y <= h * 2 / 3;
  }

  Offset get _cornerPos {
    final h = screenSize.screenHeight;
    final y = _startTouchPos!.dy;
    return Offset(pageWidth, isPanStartMidVertical ? h : (y > h / 2 ? h : 0.0));
  }

  Offset _tPos() {
    final from = _touchPos!;
    final dx = _anim.value - from.dx;
    final denom = from.dx + pageWidth / 3;
    final dy = denom.abs() < 0.5 ? 0.0 : dx * (from.dy - _cornerPos.dy) / denom;
    return Offset(
      from.dx + dx,
      (from.dy + dy).clamp(0.0, screenSize.screenHeight),
    );
  }

  void _resetFlip() {
    if (_anim.isAnimating || _touchPos == null) return;
    _clearFlip();
    setState(() {});
  }

  void _onPanEnd(DragEndDetails _) {
    if (_anim.isAnimating || _touchPos == null) return;
    final x = _anim.value;
    final xEnd = _fingerIntentDirect == 0
        ? (x < pageWidth / 2 ? -pageWidth : pageWidth)
        : (_fingerIntentDirect > 0 ? -pageWidth : pageWidth);
    _anim.animateTo(
      xEnd,
      duration: Duration(
        milliseconds: (((xEnd - x).abs() / pageWidth) * 400).round(),
      ),
      curve: Curves.easeOut,
    );
  }

  void _onTapUp(TapUpDetails d) {
    final p = d.localPosition;
    if (_anim.isAnimating ||
        (p.dx > pageWidth / 3 && p.dx < pageWidth * 2 / 3)) {
      return;
    }
    final dx = p.dx < pageWidth / 3 ? 7.0 : -7.0;
    onPanStart(DragStartDetails(globalPosition: Offset.zero, localPosition: p));
    onPanUpdate(
      DragUpdateDetails(
        globalPosition: Offset.zero,
        localPosition: p.translate(dx, 0),
        delta: Offset(dx, 0),
      ),
    );
    _onPanEnd(DragEndDetails());
  }

  void onPanStart(DragStartDetails details) {
    if (_anim.isAnimating) return;
    _touchPos = null;
    _fingerIntentDirect = 0;
    _startTouchPos = details.localPosition;
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (_anim.isAnimating) return;
    final pos = details.localPosition;
    if (_touchPos == null) {
      // 说明只是开始滑动
      final deltaX = _startTouchPos!.dx - pos.dx;
      if (deltaX.abs() < 6) return; // 滑动距离太短，认为是抖动
      _isForward = deltaX > 0; // true说明向左滑动，逐渐能看到下一页；否则是向右滑动
      if ((_isForward && _nowPageIndex >= sampleBook.chapters.length - 1) ||
          (!_isForward && _nowPageIndex <= 0)) {
        // 左滑动则要求当前页不能是最后一页
        // 右滑动则要求当前页不能是第一页
        return;
      }
      _enablePageSnapshot(isAbove: true);
      _enablePageSnapshot(isAbove: false);
      _touchPos = pos;
      _anim.value = pos.dx;
      setState(() {});
    } else {
      _touchPos = pos;
      _anim.value = pos.dx;
    }
    if (details.delta.dx != 0) _fingerIntentDirect = -details.delta.dx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: onPanStart,
        onPanEnd: _onPanEnd,
        onPanCancel: _resetFlip,
        onPanUpdate: onPanUpdate,
        onTapUp: _onTapUp,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_touchPos != null && _pageImgCache.nextPage == null)
              _pageSnapshot(isAbove: false),
            _pageSnapshot(isAbove: true),
            if (_touchPos != null)
              AnimatedBuilder(
                animation: _anim,
                builder: (_, _) => CustomPaint(
                  painter: SimulatePainter(
                    tPos: _tPos(),
                    fPos: _cornerPos,
                    bgColor: bgColor,
                    currentImg: _pageImgCache.abovePage?.img,
                    nextImg: _pageImgCache.nextPage?.img,
                    isMidStart: isPanStartMidVertical,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pageSnapshot({required bool isAbove}) {
    final index = isAbove
        ? (_touchPos == null ? _nowPageIndex : _aboveIndex)
        : _nextIndex;
    final live = _page(index);
    final grab = isAbove ? _aboveGrab : _nextGrab;
    final ctrl = isAbove ? _aboveCtrl : _nextCtrl;
    if (grab == null) {
      return SnapshotWidget(controller: ctrl, child: live);
    }
    return SnapshotWidget(controller: ctrl, painter: grab, child: live);
  }

  Widget? _page(int index) {
    if (index < 0 || index >= sampleBook.chapters.length) {
      return ColoredBox(color: bgColor);
    }
    return ColoredBox(
      color: bgColor,
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              sampleBook.chapters[index].content,
              style: TextStyle(fontSize: fontSize, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
