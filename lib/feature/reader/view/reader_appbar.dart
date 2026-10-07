import 'package:flutter/material.dart';
import 'package:light_reader/feature/reader/provider/reader_status_vm.dart';
import 'package:provider/provider.dart';

class ReaderAppbar extends StatelessWidget {
  const ReaderAppbar({super.key, required this.showToolbar});

  final bool showToolbar;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ReaderStatusVM>();
    return AnimatedPositioned(
      top: showToolbar ? 0 : -76,
      left: 0,
      right: 0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        height: 76,
        child: Padding(
          padding: EdgeInsets.only(top: 20),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                IconButton(
                  tooltip: '返回',
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(Icons.arrow_back_ios_new),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.bookInfo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        session.bookInfo.getChapterTitle(session.nowChapterId),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
