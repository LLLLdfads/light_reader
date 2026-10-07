import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:light_reader/config/screen_size.dart';
import 'package:light_reader/feature/reader/db/story.dart';
import 'package:light_reader/feature/reader/model/book.dart';
import 'package:light_reader/feature/reader/provider/view_config_vm.dart';
import 'package:light_reader/feature/utils/text_utils.dart';


/// 用色块标出一页里各个区域,阅读器页面的“模板”
class LayoutPreview extends StatefulWidget {
  const LayoutPreview({super.key});

  @override
  State<LayoutPreview> createState() => _LayoutPreviewState();
}

class _LayoutPreviewState extends State<LayoutPreview> {
  static const _quietLabel = TextStyle(fontSize: 8, color: Color(0xFF455A64));

  ViewConfigVM? config;
  PageText? pageText;
  double fontSize = 12.5;
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.bottom],
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void onChangeFontSize(double delta) {
    if (fontSize + delta < 6) return;
    setState(() {
      fontSize += delta;
      print('字体大小: $fontSize');
      config = ViewConfigVM(
        contentStyle: Theme.of(context).textTheme.bodyMedium!
            .copyWith(fontSize: fontSize),
      );
      loadContent();
    });
  }

  void loadContent() {
    pageText = TextUtils.getPageTextList(
      config!,
      sampleBook.chapters.first,
    ).first;
    final text = pageText?.text;
    debugPrint(
      text?.substring(text.length > 20 ? text.length - 20 : 0),
    );
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (screenSize.screenWidth == 0) {
      final size = MediaQuery.sizeOf(context);
      final padding = MediaQuery.paddingOf(context);
      screenSize.screenWidth = size.width;
      screenSize.screenHeight = size.height;
      screenSize.screenTopInset = padding.top;
      screenSize.screenBottomInset = padding.bottom;
    }
    if (config == null) {
      config = ViewConfigVM(
        contentStyle: Theme.of(context).textTheme.bodyMedium!
            .copyWith(fontSize: fontSize),
      );
      loadContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (config == null) return const SizedBox.shrink();
    final side = (screenSize.screenWidth - config!.bodyMaxWidth) / 2;
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: screenSize.screenTopInset,
            width: double.infinity,
            color: const Color(0xFFB0BEC5),
            alignment: Alignment.center,
            child: Text(
              '顶部安全区screenTopInset:${screenSize.screenTopInset.toStringAsFixed(0)}',
              style: _quietLabel,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => onChangeFontSize(-0.5),
                  child: Container(
                    height: double.infinity,
                    width: side,
                    color: const Color(0xFFCFD8DC),
                    alignment: Alignment.center,
                    child: Text(
                      '\n左\n宽\n${side.toStringAsFixed(0)}',
                      style: _quietLabel,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: ViewConfigVM.headerHeight,
                        color: const Color(0xFF1E88E5),
                        alignment: Alignment.center,
                        child: Text(
                          '页眉  header  ${ViewConfigVM.headerHeight.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Container(
                        height: ViewConfigVM.gapHeaderAndTitle,
                        color: const Color(0xFF90A4AE),
                        alignment: Alignment.center,
                        child: Text(
                          '间距  gapHeaderAndTitle  ${ViewConfigVM.gapHeaderAndTitle.toStringAsFixed(0)}',
                          style: _quietLabel,
                        ),
                      ),
                      Container(
                        height: TextUtils.getTextHeight(
                          config!.titleStyle,
                          pageText!.chapterTitle,
                          config!.bodyMaxWidth,
                        ),
                        width: double.infinity,
                        color: const Color(0xFFFB8C00),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          pageText!.chapterTitle,
                          style: config!.titleStyle,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: ViewConfigVM.gapTitleAndBody,
                        color: const Color(0xFF90A4AE),
                        alignment: Alignment.center,
                        child: Text(
                          '间距  gapTitleAndBody  ${ViewConfigVM.gapTitleAndBody.toStringAsFixed(0)}',
                          style: _quietLabel,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: const Color(0xFF43A047),
                          child: Text(
                            pageText!.text,
                            style: config!.contentStyle.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => onChangeFontSize(.5),
                  child: Container(
                    height: double.infinity,
                    width: side,
                    color: const Color(0xFFCFD8DC),
                    alignment: Alignment.center,
                    child: Text(
                      '\n右\n宽\n${side.toStringAsFixed(0)}',
                      style: _quietLabel,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: ViewConfigVM.footerHeight,
            color: const Color(0xFF1E88E5),
            alignment: Alignment.center,
            child: Text(
              '页脚  footer  ${ViewConfigVM.footerHeight.toStringAsFixed(0)}',
              style: _quietLabel,
            ),
          ),
          Container(
            height: screenSize.screenBottomInset,
            width: double.infinity,
            color: const Color(0xFFB0BEC5),
            alignment: Alignment.center,
            child: Text(
              '底部安全区screenBottomInset:${screenSize.screenBottomInset.toStringAsFixed(0)}',
              style: _quietLabel,
            ),
          ),
        ],
      ),
    );
  }
}
