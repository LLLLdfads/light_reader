import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// class PageImg(final ui.Image img, final double fontSize, final Color bg, final int pageIndex);
class PageImg {
  const PageImg(this.img, this.fontSize, this.bg, this.pageIndex);
  final ui.Image img;
  final double fontSize;
  final Color bg;
  final int pageIndex;
  bool same(int pageIndex, double fontSize, Color bg) =>
      this.pageIndex == pageIndex && this.fontSize == fontSize && this.bg == bg;
  void dispose() => img.dispose();
}

class PageImgCache {
  PageImg? abovePage, nextPage;

  bool match(int pageIndex, double fontSize, Color bg, bool isAbovePage) {
    final page = isAbovePage ? abovePage : nextPage;
    if (page != null && page.same(pageIndex, fontSize, bg)) return true;
    final other = isAbovePage ? nextPage : abovePage;
    if (other != null && other.same(pageIndex, fontSize, bg)) {
      if (isAbovePage) {
        abovePage = other;
        nextPage = page;
      } else {
        nextPage = other;
        abovePage = page;
      }
      return true;
    }
    page?.dispose();
    if (isAbovePage) {
      abovePage = null;
    } else {
      nextPage = null;
    }
    return false;
  }

  void update(bool isAbovePage, PageImg page) {
    if (isAbovePage) {
      abovePage?.dispose();
      abovePage = page;
    } else {
      nextPage?.dispose();
      nextPage = page;
    }
  }

  void dispose() {
    abovePage?.dispose();
    nextPage?.dispose();
    abovePage = null;
    nextPage = null;
  }
}
