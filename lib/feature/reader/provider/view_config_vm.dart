import 'package:flutter/material.dart';
import 'package:light_reader/config/screen_size.dart';

enum ThemeType { light, dark }

/// 字号和主题。章节进度不在这里。
class ViewConfigVM extends ChangeNotifier {
  ViewConfigVM({required this.contentStyle, this.theme = ThemeType.light});
  TextStyle contentStyle;
  ThemeType theme;

  void setFontSize(double fontSize) {
    if (fontSize == contentStyle.fontSize) return;
    contentStyle = contentStyle.copyWith(fontSize: fontSize);
    notifyListeners();
  }

  void setTheme(ThemeType theme) {
    if (theme == this.theme) return;
    this.theme = theme;
    contentStyle = contentStyle.copyWith(
      color: theme == ThemeType.dark ? const Color(0xFFE6E6E6) : textColor,
    );
    notifyListeners();
  }

  Color get pageColor =>
      theme == ThemeType.dark ? const Color(0xFF1D1D1D) : backgroundColor;

  Color get bodyColor =>
      theme == ThemeType.dark ? const Color(0xFF797979) : textColor;

  ViewConfigVM copyWith({double? fontSize, ThemeType? theme}) {
    final nextTheme = theme ?? this.theme;
    return ViewConfigVM(
      theme: nextTheme,
      contentStyle: contentStyle.copyWith(
        fontSize: fontSize ?? contentStyle.fontSize,
        color: nextTheme == ThemeType.dark
            ? const Color(0xFFE6E6E6)
            : textColor,
      ),
    );
  }

  static const double horizontalPadding = 24;

  static const Color backgroundColor = Color(0xffE1DCC2);
  static const Color textColor = Color(0xFF0F0D01);
  static const Color titleColor = Color(0xFF756F69);
  static const Color metaColor = Color(0xFF9A918A);

  ///高度：页眉
  static const double headerHeight = 28;
  static const double headerFontSize = 12;

  ///间距：页眉-标题（标题可能没有）
  static const double gapHeaderAndTitle = 12;

  ///字体大小：标题
  TextStyle get titleStyle => contentStyle.copyWith(
    fontSize: contentStyle.fontSize! * 1.2,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: titleColor,
  );

  ///间距：标题-内容
  static const double gapTitleAndBody = 18;

  ///宽高（文本容纳最大宽高）：内容
  double bodyMaxHeight(double titleHeight) // 章节第一页，可能有章标题
  {
    return screenSize.screenHeight -
        screenSize.screenTopInset -
        screenSize.screenBottomInset -
        headerHeight -
        gapHeaderAndTitle -
        footerHeight -
        (titleHeight > 0 ? titleHeight + gapTitleAndBody : 0);
  }

  ///宽度（最大）：内容
  double get bodyMaxWidth => screenSize.screenWidth - horizontalPadding * 2;

  ///高度：页脚
  static const double footerHeight = 28;

  ///字体大小：页脚
  static const double footerFontSize = 12;
}
