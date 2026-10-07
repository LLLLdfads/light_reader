import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'dart:ui' as ui;

class PageSnapshot extends SnapshotPainter {
  PageSnapshot(this.onGetImage);
  final void Function(ui.Image image) onGetImage;
  var _hasGotImage = false;

  void reset() => _hasGotImage = false;

  @override
  void paint(
    // allowSnapshotting=true时的绘制方法
    PaintingContext context,
    Offset offset,
    Size size,
    PaintingContextCallback painter,
  ) {
    painter(context, offset);
  }

  @override
  void paintSnapshot(
    // allowSnapshotting=false时的绘制方法
    PaintingContext context,
    Offset offset,
    Size size,
    ui.Image image,
    Size sourceSize,
    double pixelRatio,
  ) {
    context.canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, sourceSize.width, sourceSize.height),
      Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
      Paint()..filterQuality = FilterQuality.medium,
    ); // 绘制完这一帧之后，通过postFrameCallback返回图片
    if (!_hasGotImage) {
      _hasGotImage = true;
      final clone = image.clone();
      WidgetsBinding.instance.addPostFrameCallback((_) => onGetImage(clone));
    }
  }

  @override
  bool shouldRepaint(covariant SnapshotPainter oldPainter) => false;
}

class SimulatePainter extends CustomPainter {
  SimulatePainter({
    required this.tPos,
    required this.fPos,
    required this.isMidStart,
    required this.bgColor,
    required this.currentImg,
    required this.nextImg,
  });

  final Offset tPos;
  final Offset fPos;
  final bool isMidStart;
  final Color bgColor;
  final ui.Image? currentImg;
  final ui.Image? nextImg;
  late Size canvasSize;
  late Canvas canvas;
  late SimulateHelper simulateHelper;

  @override
  void paint(Canvas canvas, Size size) {
    if (currentImg == null || nextImg == null) return;
    canvasSize = size;
    this.canvas = canvas;
    simulateHelper = SimulateHelper(canvas: canvas, size: size, bg: bgColor);
    if ((size.width - tPos.dx) < 0.5) return; // 太靠右，不用绘制
    Offset aPos = Offset(
      tPos.dx.clamp(-size.width, size.width),
      tPos.dy.clamp(0, size.height),
    );
    // 如果是中间起手（tPos.x <= -width/3也走中间起手)，a 贴底边只跟t.x即可
    if (isMidStart || aPos.dx <= -size.width / 3) {
      // if (aPos.dx <= -size.width / 3) {
      // print("apos x:${aPos.dx},tpos x:${tPos.dx}");
      aPos = Offset(tPos.dx, fPos.dy);
      Offset gPos = (aPos + fPos) / 2;
      final m2Pos = Offset(fPos.dx, gPos.dy);
      double hfDistance =
          (gPos - fPos).distanceSquared / (m2Pos - fPos).distance;
      // h点要区分f点在上方和下方的情况
      Offset hPos = Offset(aPos.dx, fPos.dy - hfDistance);
      var bPos = (aPos + gPos) / 2;
      var yPos = (bPos + gPos) / 2;
      // 圈定绘制区域
      Path bgArea = Path()
        ..addPolygon([
          aPos,
          Offset(aPos.dx, fPos.dy == 0 ? size.height : 0),
          Offset(fPos.dx, fPos.dy == 0 ? size.height : 0),
          fPos,
        ], true);
      // 纸背边缘贴在前一页上的阴影
      simulateHelper.drawBg(bgArea, bgColor);

      // 圈定第二页露出区域
      Path page2Area = Path()
        ..addPolygon([
          Offset(yPos.dx, fPos.dy == 0 ? size.height : 0),
          Offset(fPos.dx, fPos.dy == 0 ? size.height : 0),
          fPos,
          Offset(yPos.dx, fPos.dy),
        ], true);

      simulateHelper.drawNextPagePart(page2Area, nextImg!);

      // 圈定书背区域(当前页面页背经过旋转后绘制一角)
      final backArea = Path()
        ..addPolygon([
          aPos,
          yPos,
          Offset(yPos.dx, fPos.dy == 0 ? size.height : 0),
          Offset(aPos.dx, fPos.dy == 0 ? size.height : 0),
        ], true);
      final ang = math.atan2(hPos.dy - gPos.dy, hPos.dx - gPos.dx);
      final transform = Matrix4.identity()
        ..translateByDouble(gPos.dx, gPos.dy, 0, 1)
        ..rotateZ(ang)
        ..scaleByDouble(1, -1, 1, 1)
        ..rotateZ(-ang)
        ..translateByDouble(-gPos.dx, -gPos.dy, 0, 1);
      simulateHelper.drawCurrentPagePart(backArea, currentImg!, transform);

      // 圈定当前页折叠区域，该区域内绘制阴影
      final flapShadowArea = (Path()
        ..addPolygon([
          aPos,
          yPos,
          Offset(yPos.dx, fPos.dy == 0 ? size.height : 0),
          Offset(aPos.dx, fPos.dy == 0 ? size.height : 0),
        ], true));
      simulateHelper.drawFlapShadow(
        flapShadowArea,
        Offset(yPos.dx, 0),
        Offset(yPos.dx, size.height),
      );
      return;
    }
    // ！！！！！！从这里开始，就不是中间起手了，而是上/下角起手！！！！！！
    // 非中间起手，t点可能不落在半圆内（直接带入a，看此时c是否越界(c.x<0),越界则需要重新计算a点）
    // 先计算c.x>=是否成立，是的话重新计算a点，否则t就是a点

    // 当tPos.x <= -size.width / 3时，只可能由动画触发，此时不需要重新计算
    final gForC = (aPos + fPos) / 2;
    final mf = (gForC.dx - fPos.dx).abs();
    final ef = (gForC - fPos).distanceSquared / mf;
    final eX = fPos.dx - ef;
    final cX = eX - (fPos.dx - eX) / 2;
    if (cX < 0) {
      // 越界，重新计算a点
      final dx = aPos.dx - fPos.dx;
      final dy = aPos.dy - fPos.dy;
      final den = dx * dx + dy * dy;
      var t = (4 / 3) * fPos.dx * (fPos.dx - aPos.dx) / den;
      aPos = Offset(
        fPos.dx + t * dx,
        fPos.dy == 0 ? t * aPos.dy : fPos.dy + t * dy,
      );
    }

    Offset gPos = (aPos + fPos) / 2;
    var mPos = Offset(gPos.dx, fPos.dy);
    double efDistance = (gPos - fPos).distanceSquared / (mPos - fPos).distance;
    Offset ePos = Offset(fPos.dx - efDistance, fPos.dy);
    final m2Pos = Offset(fPos.dx, gPos.dy);
    double hfDistance = (gPos - fPos).distanceSquared / (m2Pos - fPos).distance;
    // h点要区分f点在上方和下方的情况
    Offset hPos = Offset(
      fPos.dx,
      fPos.dy == 0 ? hfDistance : fPos.dy - hfDistance,
    );
    // ag中点n
    // final nPos = (aPos + gPos) / 2;
    // ag垂直平分线落在右侧和上/下侧的j和c点，图中可以发现：
    // ∵n在af线的1/4位置上，∴根据相似原理，ce=ef/2、jh=hf/2
    final cPos = Offset(ePos.dx - (fPos.dx - ePos.dx) / 2, fPos.dy);
    final jPos = Offset(fPos.dx, fPos.dy - (fPos.dy - hPos.dy) / 2 * 3);
    // 接着找到cj和ae、ah的交点b、k，图中可以发现：
    // ∵n在ag中点，∴根据相似原理，b在ae中点，k在ah中点
    var bPos = (aPos + ePos) / 2;
    var kPos = (aPos + hPos) / 2;
    // 接着作cb中点p、kj中点o；连接pe、oh
    var pPos = (bPos + cPos) / 2;
    var oPos = (kPos + jPos) / 2;
    // 接着作pe中点d、oh中点i；连接di
    var dPos = (pPos + ePos) / 2;
    var iPos = (oPos + hPos) / 2;
    // 接着作di和pe、oh的交点y、z。
    // ∵d在pe中点，i在oh中点∴根据相似原理，y在be中点，z在kh中点
    var yPos = (bPos + ePos) / 2;
    var zPos = (kPos + hPos) / 2;
    // 圈定绘制区域
    Path bgArea = Path()
      ..moveTo(cPos.dx, cPos.dy)
      ..quadraticBezierTo(ePos.dx, ePos.dy, bPos.dx, bPos.dy)
      ..lineTo(aPos.dx, aPos.dy)
      ..lineTo(kPos.dx, kPos.dy)
      ..quadraticBezierTo(hPos.dx, hPos.dy, jPos.dx, jPos.dy)
      ..lineTo(fPos.dx, fPos.dy)
      ..close();
    // 纸背边缘贴在前一页上的阴影
    simulateHelper.drawBg(bgArea, bgColor);

    // 圈定第二页露出区域
    Path page2Area = Path();
    final newEPos = (ePos + cPos) / 2;
    final newHPos = (hPos + jPos) / 2;
    page2Area = Path()
      ..moveTo(cPos.dx, cPos.dy)
      ..quadraticBezierTo(newEPos.dx, newEPos.dy, dPos.dx, dPos.dy)
      ..lineTo(iPos.dx, iPos.dy)
      ..quadraticBezierTo(newHPos.dx, newHPos.dy, jPos.dx, jPos.dy)
      ..lineTo(fPos.dx, fPos.dy)
      ..close();
    simulateHelper.drawNextPagePart(page2Area, nextImg!);

    // 圈定书背区域(当前页面页背经过旋转后绘制一角)
    final backArea = Path()..addPolygon([aPos, yPos, zPos], true);
    final ang = math.atan2(hPos.dy - ePos.dy, hPos.dx - ePos.dx);
    final transform = Matrix4.identity()
      ..translateByDouble(ePos.dx, ePos.dy, 0, 1)
      ..rotateZ(ang)
      ..scaleByDouble(1, -1, 1, 1)
      ..rotateZ(-ang)
      ..translateByDouble(-ePos.dx, -ePos.dy, 0, 1);
    simulateHelper.drawCurrentPagePart(backArea, currentImg!, transform);

    // 圈定当前页折叠区域，该区域内绘制阴影
    final flapShadowArea = (Path()
      ..moveTo(dPos.dx, dPos.dy)
      ..quadraticBezierTo(yPos.dx, yPos.dy, bPos.dx, bPos.dy)
      ..lineTo(kPos.dx, kPos.dy)
      ..quadraticBezierTo(zPos.dx, zPos.dy, iPos.dx, iPos.dy)
      ..close());
    simulateHelper.drawFlapShadow(flapShadowArea, dPos, iPos);
  }

  @override
  bool shouldRepaint(covariant SimulatePainter oldDelegate) {
    return tPos != oldDelegate.tPos ||
        fPos != oldDelegate.fPos ||
        isMidStart != oldDelegate.isMidStart ||
        currentImg != oldDelegate.currentImg ||
        nextImg != oldDelegate.nextImg ||
        bgColor != oldDelegate.bgColor;
  }
}

class SimulateHelper {
  const SimulateHelper({
    required this.canvas,
    required this.size,
    required this.bg,
  });
  final Canvas canvas;
  final Size size;
  final Color bg;
  // 包括背景和背景的高斯模糊
  void drawBg(Path bgArea, Color bgColor) {
    canvas.drawPath(
      bgArea,
      Paint()
        ..color = const Color(0x4D000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      bgArea,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill,
    );
  }

  // 绘制页背区域
  void drawCurrentPagePart(Path area, ui.Image img, Matrix4 trans) {
    canvas.save();
    canvas.clipPath(area);
    canvas.transform(trans.storage);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
    // 背面需要加上遮罩，不然太亮了
    canvas.drawColor(bg.withValues(alpha: 0.6), BlendMode.srcOver);
    canvas.restore();
  }

  // 绘制第二页露出区域
  void drawNextPagePart(Path area, ui.Image img) {
    canvas.save();
    canvas.clipPath(area);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  // 绘制折痕区域的在纸背边的阴影
  void drawFlapShadow(Path area, Offset pos1, Offset pos2) {
    canvas.save();
    canvas.clipPath(area);
    canvas.drawLine(
      pos1,
      pos2,
      Paint()
        ..color = const Color(0x2A000000)
        ..strokeWidth = 16 * (size.width - pos1.dx) / size.width + 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.restore();
  }

  void drawPos(Offset pos, {String? text}) {
    Paint paint = Paint()
      ..color = const Color.fromRGBO(244, 67, 54, 1)
      ..strokeWidth = 2;
    canvas.drawCircle(pos, 4, paint);
    if (text != null) {
      drawText(text, pos);
    }
  }

  void drawLine(Offset pos1, Offset pos2) {
    Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.5;
    canvas.drawLine(pos1, pos2, paint);
  }

  void drawText(String text, Offset pos) {
    final fontSize = 12.0;
    final offsetTextPos = Offset(pos.dx - fontSize, pos.dy - fontSize);
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.blue,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(); // 进行布局计算
    textPainter.paint(canvas, offsetTextPos); // 在指定位置绘制文字
  }

  /// 绘制贝塞尔曲线
  void drawBezier(Offset pos1, Offset pos2, Offset pos3) {
    Path path = Path()
      ..moveTo(pos1.dx, pos1.dy)
      ..quadraticBezierTo(pos2.dx, pos2.dy, pos3.dx, pos3.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}

// 绘制关键位置、线段、贝塞尔曲线的代码，加进去太长了，需要用到再粘贴吧
// if (showDetail) {
//   // 关键位置
//   final List<Map<String, Offset>> keyPos = [
//     {'a': aPos},
//     {'c': cPos},
//     {'b': bPos},
//     {'d': dPos},
//     {'y': yPos},
//     {'j': jPos},
//     {'k': kPos},
//     {'i': iPos},
//     {'z': zPos},
//   ];
//   // 关键线段
//   final List<List<Offset>> keyLine = [
//     [aPos, bPos],
//     [aPos, yPos],
//     [aPos, kPos],
//     [aPos, zPos],
//     [dPos, iPos],
//   ];
//   // 关键的贝塞尔曲线
//   final List<List<Offset>> keyBezier = [
//     [cPos, ePos, bPos],
//     [kPos, hPos, jPos],
//   ];

//   // 次要位置
//   final List<Map<String, Offset>> minorPos = [
//     {'f': fPos},
//     {'g': gPos},
//     {'m': mPos},
//     {'e': ePos},
//     {'m2': m2Pos},
//     {'h': hPos},
//     {'n': nPos},
//     {'p': pPos},
//     {'o': oPos},
//   ];
//   // 次要线段
//   final List<List<Offset>> minorLine = [
//     [aPos, fPos],
//     [gPos, mPos],
//     [fPos, ePos],
//     [ePos, gPos],
//     [aPos, ePos],
//     [gPos, m2Pos],
//     [fPos, hPos],
//     [hPos, gPos],
//     [aPos, hPos],
//     [cPos, jPos],
//     [cPos, fPos],
//     [jPos, fPos],
//     [pPos, ePos],
//     [oPos, hPos],
//   ];
//   for (var pos in [...keyPos, ...minorPos]) {
//     simulateHelper.drawPos(pos.values.first, text: pos.keys.first);
//   }
//   for (var line in [...keyLine, ...minorLine]) {
//     simulateHelper.drawLine(line[0], line[1]);
//   }
//   for (var bezier in keyBezier) {
//     simulateHelper.drawBezier(bezier[0], bezier[1], bezier[2]);
//   }
// }
