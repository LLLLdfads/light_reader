import 'package:flutter/material.dart';
import 'package:light_reader/config/screen_size.dart';
import 'package:light_reader/feature/book_shelf/book_shelf_page.dart';
import 'package:light_reader/feature/utils/toast.dart';

void main() {
  runApp(
    SToast.init(
      MaterialApp(debugShowCheckedModeBanner: false, home: MainApp()),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (screenSize.screenWidth == 0) {
      screenSize.screenWidth = MediaQuery.sizeOf(context).width;
      screenSize.screenHeight = MediaQuery.sizeOf(context).height;
      screenSize.screenTopInset = MediaQuery.paddingOf(context).top;
      screenSize.screenBottomInset = MediaQuery.paddingOf(context).bottom;
    }
    return const BookShelfPage();
  }
}
