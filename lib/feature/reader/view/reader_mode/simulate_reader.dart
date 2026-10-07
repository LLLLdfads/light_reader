import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:light_reader/config/screen_size.dart';
import 'package:light_reader/feature/anim/simulate/model/page_img_cache.dart';
import 'package:light_reader/feature/anim/simulate/simulate_helper.dart';
import 'package:light_reader/feature/reader/model/book.dart';
import 'package:light_reader/feature/reader/provider/reader_status_vm.dart';
import 'package:light_reader/feature/reader/provider/view_config_vm.dart';
import 'package:light_reader/feature/reader/widget/reader_view_frame.dart';
import 'package:light_reader/feature/utils/toast.dart';
import 'package:provider/provider.dart';

class SimulateReader extends StatefulWidget {
  const SimulateReader({super.key, this.onVisaualToolbar});
  final Function(bool? isShow)? onVisaualToolbar;

  @override
  State<SimulateReader> createState() => _SimulateReaderState();
}

class _SimulateReaderState extends State<SimulateReader>
    with SingleTickerProviderStateMixin {
  late final ReaderStatusVM _session;
  late final ViewConfigVM _viewConfig;
  late final AnimationController _anim;
  final _pageImgCache = PageImgCache();
  final _aboveCtrl = SnapshotController(allowSnapshotting: false);
  final _nextCtrl = SnapshotController(allowSnapshotting: false);
  PageSnapshot? _aboveGrab;
  PageSnapshot? _nextGrab;
  Offset? _touchPos;
  Offset? _startTouchPos;
  bool _isForward = true;

  double get _pageWidth => screenSize.screenWidth;
  Color get _bgColor => _viewConfig.pageColor;
  double get _fontSize => _viewConfig.contentStyle.fontSize!;
  // 是否正在折叠
  bool get _isFlipping => _anim.isAnimating || _touchPos != null;
  PageText? get _abovePage => _session.pageNear(_isForward ? 0 : -1);
  PageText? get _underPage => _session.pageNear(_isForward ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _session = context.read<ReaderStatusVM>();
    _session.addListener(_onSessionChanged);
    _viewConfig = context.read<ViewConfigVM>();
    _viewConfig.addListener(_onViewConfigChanged);
    _anim = AnimationController.unbounded(vsync: this, value: 0)
      ..addStatusListener(_onAnimStatus);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _viewConfig.removeListener(_onViewConfigChanged);
    _aboveCtrl.dispose();
    _nextCtrl.dispose();
    _aboveGrab?.dispose();
    _nextGrab?.dispose();
    _pageImgCache.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _touchPos == null) return;
    final didTurn = _anim.value == (_isForward ? -_pageWidth : _pageWidth);
    if (didTurn) {
      _clearFlip();
      _session.toNearPage(_isForward ? 1 : -1);
    }
    setState(() {});
  }

  void _onViewConfigChanged() {
    _pageImgCache.dispose();
    _session.ensureChapters(
      _viewConfig,
      isFlipping: () => _isFlipping,
      clearPages: true,
    );
  }

  void _onSessionChanged() {
    if (_session.screenReady) {
      setState(() {});
      return;
    }
    _session.ensureChapters(_viewConfig, isFlipping: () => _isFlipping);
  }

  void _onGetPageImg(bool isAbove, ui.Image img, int cacheId) {
    if (!mounted) {
      img.dispose();
      return;
    }
    setState(() {
      _pageImgCache.update(isAbove, PageImg(img, _fontSize, _bgColor, cacheId));
      (isAbove ? _aboveCtrl : _nextCtrl).allowSnapshotting = false;
    });
  }

  int _cacheId(PageText page) => Object.hash(page.chapterIndex, page.index);

  void _enablePageSnapshot({required bool isAbove}) {
    final page = isAbove ? _abovePage : _underPage;
    if (page == null) return;
    final cacheId = _cacheId(page);
    if (_pageImgCache.match(cacheId, _fontSize, _bgColor, isAbove)) return;
    final grab = PageSnapshot((img) => _onGetPageImg(isAbove, img, cacheId));
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
    _aboveCtrl.allowSnapshotting = false;
    _nextCtrl.allowSnapshotting = false;
    _aboveGrab?.dispose();
    _aboveGrab = null;
    _nextGrab?.dispose();
    _nextGrab = null;
  }

  bool get isPanStartMidVertical {
    final y = _startTouchPos?.dy ?? 0;
    final h = screenSize.screenHeight;
    return h / 3 <= y && y <= h * 2 / 3;
  }

  Offset get _cornerPos {
    final h = screenSize.screenHeight;
    final y = _startTouchPos!.dy;
    return Offset(
      _pageWidth,
      isPanStartMidVertical ? h : (y > h / 2 ? h : 0.0),
    );
  }

  Offset _tPos() {
    final from = _touchPos!;
    final dx = _anim.value - from.dx;
    final denom = from.dx + _pageWidth / 3;
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

  void _onPanEnd(DragEndDetails details) {
    if (_anim.isAnimating || _touchPos == null) return;
    final x = _anim.value;
    final v = details.velocity.pixelsPerSecond.dx;
    final xEnd = v == 0
        ? (x < _pageWidth / 2 ? -_pageWidth : _pageWidth)
        : (v < 0 ? -_pageWidth : _pageWidth);
    _anim.animateTo(
      xEnd,
      duration: Duration(
        milliseconds: (((xEnd - x).abs() / _pageWidth) * 400).round(),
      ),
      curve: Curves.easeOut,
    );
  }

  void _onTapUp(TapUpDetails d) {
    if (_anim.isAnimating) return;
    final p = d.localPosition;
    final width = _pageWidth;
    if (p.dx > width / 3 && p.dx < width * 2 / 3) {
      widget.onVisaualToolbar?.call(null);
      return;
    }
    widget.onVisaualToolbar?.call(false);
    final dx = p.dx < width / 3 ? 7.0 : -7.0;
    onPanStart(DragStartDetails(globalPosition: Offset.zero, localPosition: p));
    onPanUpdate(
      DragUpdateDetails(
        globalPosition: Offset.zero,
        localPosition: p.translate(dx, 0),
        delta: Offset(dx, 0),
      ),
    );
    _onPanEnd(
      DragEndDetails(velocity: Velocity(pixelsPerSecond: Offset(dx, 0))),
    );
  }

  void onPanStart(DragStartDetails details) {
    if (_anim.isAnimating) return;
    _touchPos = null;
    _startTouchPos = details.localPosition;
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (_anim.isAnimating) return;
    final pos = details.localPosition;
    if (_touchPos == null) {
      final deltaX = _startTouchPos!.dx - pos.dx;
      if (deltaX.abs() < 6) return;
      _isForward = deltaX > 0;
      if (_isForward && !_session.hasNextPage) {
        if (_session.atBookEnd) SToast.toast('已经是最后一页');
        return;
      }
      if (!_isForward && !_session.hasPrevPage) {
        if (_session.atBookStart) SToast.toast('已经是第一页');
        return;
      }
      _enablePageSnapshot(isAbove: true);
      _enablePageSnapshot(isAbove: false);
      widget.onVisaualToolbar?.call(false);
      _touchPos = pos;
      _anim.value = pos.dx;
      setState(() {});
    } else {
      _touchPos = pos;
      _anim.value = pos.dx;
    }
  }

  Widget _pageSnapshot({required bool isAbove}) {
    final page = isAbove
        ? (_touchPos == null ? _session.pageNear() : _abovePage)
        : _underPage;
    if (page == null) return ColoredBox(color: _bgColor);
    final live = ReaderViewFrame(
      pageText: page,
      pageColor: _bgColor,
      textColor: _viewConfig.contentStyle.color!,
    );
    final grab = isAbove ? _aboveGrab : _nextGrab;
    final ctrl = isAbove ? _aboveCtrl : _nextCtrl;
    if (grab == null) {
      return SnapshotWidget(controller: ctrl, child: live);
    }
    return SnapshotWidget(controller: ctrl, painter: grab, child: live);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                  bgColor: _bgColor,
                  currentImg: _pageImgCache.abovePage?.img,
                  nextImg: _pageImgCache.nextPage?.img,
                  isMidStart: isPanStartMidVertical,
                ),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }
}
