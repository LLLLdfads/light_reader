import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

class SToast {
  SToast._internal();

  static Widget init(Widget child) {
    return OKToast(
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      backgroundColor: Color(0xFF424242),
      radius: 8,
      dismissOtherOnShow: true,
      textPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      duration: const Duration(seconds: 2),
      position: ToastPosition.bottom,
      child: child,
    );
  }

  static String? _lastMsg;
  static DateTime? _lastAt;

  static void toast(
    String msg, {
    Duration duration = const Duration(seconds: 2),
  }) {
    // 防止连续弹出相同内容
    final now = DateTime.now();
    if (msg == _lastMsg &&
        _lastAt != null &&
        now.difference(_lastAt!) < const Duration(seconds: 1)) {
      return;
    }
    _lastMsg = msg;
    _lastAt = now;
    showToast(
      msg,
      duration: duration,
      backgroundColor: const Color(0xCC000000),
    );
  }

  static void waring(
    String msg, {
    Duration duration = const Duration(seconds: 2),
  }) {
    showToast(
      msg,
      duration: duration,
      backgroundColor: const Color(0xFFFF9135),
    );
  }

  static void error(
    String msg, {
    Duration duration = const Duration(seconds: 2),
  }) {
    showToast(
      msg,
      duration: duration,
      backgroundColor: const Color(0xFFFF5959),
    );
  }

  static void success(
    String msg, {
    Duration duration = const Duration(seconds: 2),
  }) {
    showToast(
      msg,
      duration: duration,
      backgroundColor: const Color(0xFF49C998),
    );
  }
}
