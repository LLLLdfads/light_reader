import 'package:flutter/material.dart';
import 'package:light_reader/config/screen_size.dart';
import 'package:light_reader/feature/reader/provider/turn_vm.dart';
import 'package:light_reader/feature/reader/provider/view_config_vm.dart';

class ReaderSetting extends StatelessWidget {
  const ReaderSetting({super.key, required this.config, required this.turn});

  final ViewConfigVM config;
  final TurnVM turn;

  static Future<void> show(
    BuildContext context, {
    required ViewConfigVM config,
    required TurnVM turn,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ReaderSetting(config: config, turn: turn),
    );
  }

  Widget _fontStepButton(String label, double fontSize, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 72,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: fontSize, color: Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: config,
      builder: (context, _) => _build(),
    );
  }

  Widget _build() {
    final labelStyle = TextStyle(fontSize: 12, color: Colors.black);
    final size = config.contentStyle.fontSize ?? 16;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        28 + screenSize.screenBottomInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: config.bodyColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('字号', style: labelStyle),
          const SizedBox(height: 8),
          Row(
            children: [
              _fontStepButton('A-', 14, () => config.setFontSize(size - 1)),
              Expanded(
                child: Text(
                  size.toInt().toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black),
                ),
              ),
              _fontStepButton('A+', 18, () => config.setFontSize(size + 1)),
            ],
          ),
          const SizedBox(height: 16),
          Text('翻页', style: labelStyle),
          const SizedBox(height: 8),
          _TurnModeCapsule(turn: turn),
        ],
      ),
    );
  }
}

class _TurnModeCapsule extends StatelessWidget {
  const _TurnModeCapsule({required this.turn});

  static const _modes = [TurnMode.slide, TurnMode.cover, TurnMode.simulation];
  static const _height = 40.0;
  static const _inset = 3.0;

  final TurnVM turn;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: turn,
      builder: (context, _) => _build(turn.mode),
    );
  }

  Widget _build(TurnMode selected) {
    final index = _modes.indexOf(selected);
    final thumb = Colors.white;
    return SizedBox(
      height: _height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segment = constraints.maxWidth / _modes.length;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(_height / 2),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: segment * index + _inset,
                  top: _inset,
                  width: segment - _inset * 2,
                  height: _height - _inset * 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: thumb,
                      borderRadius: BorderRadius.circular(
                        (_height - _inset * 2) / 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    children: [
                      for (final mode in _modes)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => turn.setMode(mode),
                            child: Center(
                              child: Text(
                                mode.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: mode == turn.mode
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
