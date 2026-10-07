import 'package:flutter/material.dart';
import 'package:light_reader/feature/reader/model/book.dart';
import 'package:light_reader/feature/reader/provider/view_config_vm.dart';

class ReaderCatalog extends StatelessWidget {
  const ReaderCatalog({
    super.key,
    required this.bookInfo,
    required this.chapterId,
    required this.config,
  });

  final BookInfo bookInfo;
  final String chapterId;
  final ViewConfigVM config;

  static Future<int?> show(
    BuildContext context, {
    required BookInfo bookInfo,
    required String chapterId,
    required ViewConfigVM config,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: config.pageColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ReaderCatalog(
        bookInfo: bookInfo,
        chapterId: chapterId,
        config: config,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: config.bodyColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '目录',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: config.bodyColor,
                ),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: bookInfo.chapterIds.length,
              itemBuilder: (context, index) {
                final id = bookInfo.chapterIds[index];
                final active = id == chapterId;
                return ListTile(
                  title: Text(
                    bookInfo.getChapterTitle(id),
                    style: TextStyle(
                      color: config.bodyColor,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing: active
                      ? Icon(Icons.check, color: config.bodyColor, size: 18)
                      : null,
                  onTap: () => Navigator.pop(context, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
