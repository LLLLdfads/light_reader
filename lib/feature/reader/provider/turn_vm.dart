import 'package:flutter/foundation.dart';

/// 翻页方式。当前页、上一页、下一页的画面以后放这里。
class TurnVM extends ChangeNotifier {
  TurnVM({this.mode = TurnMode.slide});

  TurnMode mode;

  void setMode(TurnMode mode) {
    if (mode == this.mode) return;
    this.mode = mode;
    notifyListeners();
  }
}

enum TurnMode {
  simulation,
  cover,
  slide;

  String get label {
    switch (this) {
      case TurnMode.simulation:
        return '仿真';
      case TurnMode.cover:
        return '覆盖';
      case TurnMode.slide:
        return '平移';
    }
  }
}
