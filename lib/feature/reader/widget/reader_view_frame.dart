// 阅读器的页面结构,具体参考文件layout_preview.dart
// 包括页眉、页脚、内容区域、两边padding、顶部inset、底部inset等
import 'package:flutter/material.dart';
import 'package:light_reader/config/screen_size.dart';
import 'package:light_reader/feature/reader/model/book.dart';
import 'package:light_reader/feature/reader/provider/view_config_vm.dart';

class ReaderViewFrame extends StatelessWidget {
  const ReaderViewFrame({
    super.key,
    required this.pageText,
    required this.pageColor,
    required this.textColor,
  });

  final PageText pageText;
  final Color pageColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: pageColor,
      child: Column(
        children: [
          SizedBox(height: screenSize.screenTopInset, width: double.infinity),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: ViewConfigVM.horizontalPadding,
                  height: double.infinity,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: ViewConfigVM.headerHeight,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          pageText.bookName,
                          style: const TextStyle(
                            fontSize: ViewConfigVM.headerFontSize,
                            color: ViewConfigVM.metaColor,
                          ),
                        ),
                      ),
                      SizedBox(height: ViewConfigVM.gapHeaderAndTitle),
                      if (pageText.index == 0) ...[
                        Container(
                          height: pageText.chapterTitleHeight,
                          width: double.infinity,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            pageText.chapterTitle,
                            style: TextStyle(
                              fontSize: pageText.titleFontSize,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              color: ViewConfigVM.titleColor,
                            ),
                          ),
                        ),
                        SizedBox(height: ViewConfigVM.gapTitleAndBody),
                      ],
                      Expanded(
                        // 不能直接用SelectableText，一页容纳的文字更少，和排版结果不一致
                        child: Text(
                          pageText.text,
                          style: TextStyle(
                            fontSize: pageText.fontSize,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: double.infinity,
                  width: ViewConfigVM.horizontalPadding,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: ViewConfigVM.footerHeight,
            alignment: Alignment.center,
            child: Text(
              '${pageText.index + 1}/${pageText.pageCount}',
              style: const TextStyle(
                fontSize: ViewConfigVM.footerFontSize,
                height: 1.2,
                color: ViewConfigVM.metaColor,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: screenSize.screenBottomInset,
          ),
        ],
      ),
    );
  }
}
