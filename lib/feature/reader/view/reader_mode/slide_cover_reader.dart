import 'package:flutter/material.dart';
import 'package:light_reader/config/screen_size.dart';
import 'package:light_reader/feature/reader/model/book.dart';
import 'package:light_reader/feature/reader/provider/reader_status_vm.dart';
import 'package:light_reader/feature/reader/provider/turn_vm.dart';
import 'package:light_reader/feature/reader/provider/view_config_vm.dart';
import 'package:light_reader/feature/reader/widget/reader_view_frame.dart';
import 'package:light_reader/feature/utils/toast.dart';
import 'package:provider/provider.dart';

/// 覆盖：底下那页不动。平移：底下那页也跟着偏。上面那页始终用偏移。
class SlideCoverReader extends StatefulWidget {
  const SlideCoverReader({super.key, this.onVisaualToolbar});
  final Function(bool? isShow)? onVisaualToolbar;

  @override
  State<SlideCoverReader> createState() => _SlideCoverReaderState();
}

class _SlideCoverReaderState extends State<SlideCoverReader>
    with SingleTickerProviderStateMixin {
  late final ReaderStatusVM _session;
  late final ViewConfigVM _viewConfig;
  late final AnimationController _anim;
  Offset? _start;

  double get _pageWidth => screenSize.screenWidth;
  double get _minX => _session.hasNextPage ? -_pageWidth : 0;
  double get _maxX => _session.hasPrevPage ? _pageWidth : 0;
  bool get _isFlipping => _anim.isAnimating || _anim.value != 0;

  @override
  void initState() {
    super.initState();
    _session = context.read<ReaderStatusVM>();
    _session.addListener(_onSessionChanged);
    _viewConfig = context.read<ViewConfigVM>();
    _viewConfig.addListener(_onViewConfigChanged);
    _anim = AnimationController.unbounded(vsync: this)
      ..addStatusListener(_onAnimStatus);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _viewConfig.removeListener(_onViewConfigChanged);
    _anim.dispose();
    super.dispose();
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_anim.value <= -_pageWidth) {
      _start = null;
      _anim.value = 0;
      _session.toNearPage(1);
    } else if (_anim.value >= _pageWidth) {
      _start = null;
      _anim.value = 0;
      _session.toNearPage(-1);
    }
  }

  void _onViewConfigChanged() {
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

  void _toastBound(double toward) {
    if (toward < 0 && _session.atBookEnd) {
      SToast.toast('已经是最后一页');
    } else if (toward > 0 && _session.atBookStart) {
      SToast.toast('已经是第一页');
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_anim.isAnimating) return;
    _start = details.localPosition;
    widget.onVisaualToolbar?.call(false);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_anim.isAnimating || _start == null) return;
    final dx = details.localPosition.dx - _start!.dx;
    if (_anim.value == 0 && dx.abs() < 6) return;
    final next = dx.clamp(_minX, _maxX);
    // 只在还没跟上时提示。两指交替会让相对 x 跳号，不能当成翻另一侧。
    if (_anim.value == 0 && next == 0) _toastBound(dx);
    _anim.value = next;
  }

  void _onPanEnd(DragEndDetails details) {
    if (_anim.isAnimating || _start == null) return;
    _start = null;
    final x = _anim.value;
    if (x == 0) return;
    final v = details.velocity.pixelsPerSecond.dx;
    final end = v < 0
        ? (x <= 0 ? -_pageWidth : 0.0)
        : v > 0
        ? (x >= 0 ? _pageWidth : 0.0)
        : (x.abs() < _pageWidth / 2 ? 0.0 : x.sign * _pageWidth);
    _animateTo(end);
  }

  void _onPanCancel() {
    if (_anim.isAnimating || _start == null) return;
    _start = null;
    _animateTo(0);
  }

  void _onTapUp(TapUpDetails d) {
    if (_isFlipping) return;
    final dx = d.localPosition.dx;
    if (dx > _pageWidth / 3 && dx < _pageWidth * 2 / 3) {
      widget.onVisaualToolbar?.call(null);
      return;
    }
    widget.onVisaualToolbar?.call(false);
    _animateTo(dx < _pageWidth / 3 ? _pageWidth : -_pageWidth);
  }

  void _animateTo(double end) {
    final clamped = end.clamp(_minX, _maxX);
    if (clamped != end) _toastBound(end);
    end = clamped;
    _anim.animateTo(
      end,
      duration: Duration(
        milliseconds: (((end - _anim.value).abs() / _pageWidth) * 120).round(),
      ),
      curve: Curves.easeOut,
    );
  }

  Widget _page(PageText page, {bool cover = false}) {
    final frame = ReaderViewFrame(
      pageText: page,
      pageColor: _viewConfig.pageColor,
      textColor: _viewConfig.contentStyle.color!,
    );
    if (!cover) return frame;
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: frame,
    );
  }

  Widget _near(int delta, {bool cover = false}) {
    final page = _session.pageNear(delta);
    if (page == null) return ColoredBox(color: _viewConfig.pageColor);
    return _page(page, cover: cover);
  }

  @override
  Widget build(BuildContext context) {
    final slide = context.watch<TurnVM>().mode == TurnMode.slide;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _onPanCancel,
      onTapUp: _onTapUp,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, _) {
          final x = _anim.value;
          if (x == 0) return _near(0);
          final w = _pageWidth;
          final backX = slide ? (x < 0 ? w + x : x) : 0.0;
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: Offset(backX, 0),
                child: _near(x < 0 ? 1 : 0),
              ),
              Transform.translate(
                offset: Offset(x < 0 ? x : x - w, 0),
                child: _near(x < 0 ? 0 : -1, cover: !slide),
              ),
            ],
          );
        },
      ),
    );
  }
}
