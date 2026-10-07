import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:light_reader/config/screen_size.dart';

/// 和上一课同一套平移、吸附。新的一页才随机取色。
/// 往左滑过一整页就换到下一页，手指不松也能继续。往右到第一页就停住。
class SlideDemo  extends StatefulWidget {
  const SlideDemo({super.key, this.index = 0});

  final int index;

  @override
  State<SlideDemo> createState() => _SlideDemoState();
}

class _SlideDemoState extends State<SlideDemo>
    with SingleTickerProviderStateMixin {
  final _colors = <int, Color>{};
  late final AnimationController _anim;
  double pageWidth = screenSize.screenWidth;
  late int _index;
  final String _tag = "测试：";

  @override
  void initState() {
    super.initState();
    _index = widget.index;
    _ensurePage(_index);
    _anim = AnimationController.unbounded(vsync: this, value: 0)
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        if (_anim.value <= -pageWidth) {
          _index++;
        } else if (_anim.value >= pageWidth && _index > 0) {
          _index--;
        } else {
          return;
        }
        _ensurePage(_index);
        _anim.value = 0;
      });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _ensurePage(int index) async {
    if (_colors.containsKey(index)) return;
    print('$_tag 准备数据（页面索引 $index）');
    _colors.putIfAbsent(index, _randomColor);
  }

  // 方向按这一小段落下的位置算。跨过 0 就换成另一侧，下一帧要画的那页才会被准备好。
  SlideDirection _slideDirection(double offset) {
    if (offset < 0) return SlideDirection.left;
    if (offset > 0) return SlideDirection.right;
    return SlideDirection.none;
  }

  void _move(DragUpdateDetails details) {
    // 这一小段手指滑了多少像素（primaryDelta是手指滑动的距离，）。往右为正，往左为负。
    final dragPixels = details.primaryDelta ?? 0;
    if (dragPixels == 0) return;
    // 在当前偏移上加上这一小段，得到色块应该在的位置。
    var offset = _anim.value + dragPixels;
    // 滑动的方向
    final direction = _slideDirection(offset);
    print('$_tag 往${direction.label}滑动，offset: $offset, \t页索引: $_index');
    switch (direction) {
      case SlideDirection.none:
        break;
      case SlideDirection.left:
        // 往后翻。下一页马上要画出来，没有颜色就现在取。
        _ensurePage(_index + 1);
        // 一次滑过整页时，offset重置成为0，index++
        if (offset <= -pageWidth) {
          _index++;
          _ensurePage(_index + 1);
          offset += pageWidth;
          print("$_tag 切换页面索引为：$_index");
        }
      case SlideDirection.right:
        if (_index == 0) {
          // 已经是第一页，不能再往右露出上一页。
          offset = 0;
        } else {
          // 往前翻。上一页要从左边进来，没有颜色就现在取。
          _ensurePage(_index - 1);
          // 一次滑过整页时，offset重置成为0，index--
          if (offset >= pageWidth && _index > 0) {
            _index--;
            offset -= pageWidth;
            if (_index > 0) _ensurePage(_index - 1);
            print(
              '$_tag 往${direction.label}滑动，offset: $offset, index: $_index',
            );
          }
          if (_index == 0) offset = 0;
        }
    }
    _anim.value = offset.clamp(-pageWidth, pageWidth);
  }

  void _end(DragEndDetails details) {
    final fingerIntentDirect = -(details.primaryVelocity ?? 0);
    final x = _anim.value;
    double end; // 落点位置
    if (fingerIntentDirect > 0) {
      if (x <= 0) {
        end = -pageWidth;
      } else {
        end = 0;
      }
    } else if (fingerIntentDirect < 0) {
      if (x < 0) {
        end = 0;
      } else {
        end = pageWidth;
      }
    } else {
      if (x <= -pageWidth / 2) {
        end = -pageWidth;
      } else if (x >= pageWidth / 2) {
        end = pageWidth;
      } else {
        end = 0;
      }
    }
    // 第一页右侧没有上一页。往右甩没用
    if (_index == 0 && end > 0) end = 0;
    final remainingTime = (((end - _anim.value).abs() / pageWidth) * 120)
        .round();
    _anim.animateTo(
      end,
      duration: Duration(milliseconds: remainingTime),
      curve: Curves.easeOut,
    );
  }

  Widget _page(int index) {
    final color = _colors[index];
    if (color == null) return const SizedBox.expand();
    return Container(
      width: pageWidth,
      color: color,
      alignment: Alignment.center,
      child: Text(
        '页索引：$index',
        style: const TextStyle(fontSize: 40, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final x = _anim.value;
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => _anim.stop(),
        onHorizontalDragUpdate: _move,
        onHorizontalDragEnd: _end,
        child: x == 0
            ? _page(_index)
            : x < 0
            ? Stack(
                children: [
                  Transform.translate(
                    offset: Offset(pageWidth + x, 0),
                    child: _page(_index + 1),
                  ),
                  Transform.translate(
                    offset: Offset(x, 0),
                    child: _page(_index),
                  ),
                ],
              )
            : Stack(
                children: [
                  Transform.translate(
                    offset: Offset(x - pageWidth, 0),
                    child: _page(_index - 1),
                  ),
                  Transform.translate(
                    offset: Offset(x, 0),
                    child: _page(_index),
                  ),
                ],
              ),
      ),
    );
  }
}

enum SlideDirection {
  left,
  right,
  none;

  String get label => switch (this) {
    SlideDirection.left => '左',
    SlideDirection.right => '右',
    SlideDirection.none => '中',
  };
}

Color _randomColor() {
  final random = math.Random();
  return Color.fromARGB(
    255,
    random.nextInt(256),
    random.nextInt(256),
    random.nextInt(256),
  );
}
