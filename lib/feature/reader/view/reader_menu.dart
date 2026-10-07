import 'package:flutter/material.dart';
import 'package:light_reader/feature/reader/provider/reader_status_vm.dart';
import 'package:light_reader/feature/reader/provider/turn_vm.dart';
import 'package:light_reader/feature/reader/provider/view_config_vm.dart';
import 'package:light_reader/feature/reader/view/reader_catalog.dart';
import 'package:light_reader/feature/reader/view/reader_setting.dart';

import 'package:provider/provider.dart';

class ReaderMenu extends StatefulWidget {
  const ReaderMenu({super.key, required this.showToolbar});
  final bool showToolbar;

  @override
  State<ReaderMenu> createState() => _ReaderMenuState();
}

class _ReaderMenuState extends State<ReaderMenu> {
  double _sliderValue = 0;
  bool _sliding = false;

  void _jumpTo(int index) {
    final ids = context.read<ReaderStatusVM>().bookInfo.chapterIds;
    if (ids.isEmpty) return;
    context.read<ReaderStatusVM>().setProgress(
      ids[index.clamp(0, ids.length - 1)],
      0,
    );
  }

  Future<void> _onTapCatalog() async {
    final session = context.read<ReaderStatusVM>();
    final selected = await ReaderCatalog.show(
      context,
      bookInfo: session.bookInfo,
      chapterId: session.nowChapterId,
      config: context.read<ViewConfigVM>(),
    );
    if (selected != null) _jumpTo(selected);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ReaderStatusVM>();
    final theme = context.watch<ViewConfigVM>().theme;
    final ids = session.bookInfo.chapterIds;
    final found = ids.indexOf(session.nowChapterId);
    final chapterIndex = found < 0 ? 0 : found;
    if (!_sliding) _sliderValue = chapterIndex.toDouble();
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnimatedPositioned(
      bottom: widget.showToolbar ? 0 : -120,
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
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
        height: 120,
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  _textButton(
                    '上一章',
                    Colors.black,
                    () => _jumpTo(chapterIndex - 1),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFB7AA9C),
                        inactiveTrackColor: const Color(0xFFE4DDD4),
                        thumbColor: const Color.fromARGB(255, 248, 245, 242),
                        overlayColor: Colors.transparent,
                        trackHeight: 16,
                        trackShape: const RoundedRectSliderTrackShape(),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 12,
                          elevation: 3,
                          pressedElevation: 4,
                        ),
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: _sliderValue,
                        max: session.bookInfo.totalChapterCount - 1,
                        min: 0,
                        onChanged: (value) {
                          setState(() {
                            _sliding = true;
                            _sliderValue = value;
                          });
                        },
                        onChangeEnd: (value) {
                          _sliding = false;
                          _jumpTo(value.toInt());
                        },
                      ),
                    ),
                  ),
                  _textButton(
                    '下一章',
                    Colors.black,
                    () => _jumpTo(chapterIndex + 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  _iconButton(
                    Icons.menu_book_outlined,
                    '目录',
                    () => _onTapCatalog(),
                  ),
                  _iconButton(
                    theme == ThemeType.light
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    theme == ThemeType.light ? '日间' : '夜间',
                    () => context.read<ViewConfigVM>().setTheme(
                      theme == ThemeType.light
                          ? ThemeType.dark
                          : ThemeType.light,
                    ),
                  ),
                  _iconButton(
                    Icons.tune,
                    '设置',
                    () => ReaderSetting.show(
                      context,
                      config: context.read<ViewConfigVM>(),
                      turn: context.read<TurnVM>(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _textButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(label, style: TextStyle(color: color, fontSize: 14)),
      ),
    );
  }
}
