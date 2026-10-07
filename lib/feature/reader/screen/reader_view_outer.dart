import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:light_reader/feature/reader/provider/reader_status_vm.dart';
import 'package:light_reader/feature/reader/provider/turn_vm.dart';
import 'package:light_reader/feature/reader/provider/view_config_vm.dart';
import 'package:light_reader/feature/reader/view/reader_mode/slide_cover_reader.dart';
import 'package:light_reader/feature/reader/view/reader_appbar.dart';
import 'package:light_reader/feature/reader/view/reader_menu.dart';
import 'package:light_reader/feature/reader/view/reader_mode/simulate_reader.dart';
import 'package:light_reader/feature/utils/loading.dart';
import 'package:provider/provider.dart';

// 主要是放appbar、toolbar的
class ReaderViewOuter extends StatefulWidget {
  const ReaderViewOuter({super.key});

  @override
  State<ReaderViewOuter> createState() => _ReaderViewOuterState();
}

class _ReaderViewOuterState extends State<ReaderViewOuter> {
  final ValueNotifier<bool> _showToolbar = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.bottom],
    );
    context.read<ReaderStatusVM>().ensureChapters(
      context.read<ViewConfigVM>(),
      isFlipping: () => false,
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void onVisaualToolbar(bool? isShow) {
    _showToolbar.value = isShow ?? !_showToolbar.value;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ReaderStatusVM>();
    if (session.isEmpty) {
      return const Scaffold(body: Center(child: Loading()));
    }
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Consumer<TurnVM>(
              builder: (context, turn, _) {
                return turn.mode == TurnMode.simulation
                    ? SimulateReader(onVisaualToolbar: onVisaualToolbar)
                    : SlideCoverReader(onVisaualToolbar: onVisaualToolbar);
              },
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _showToolbar,
            builder: (context, showToolbar, _) {
              return ReaderAppbar(showToolbar: showToolbar);
            },
          ),
          ValueListenableBuilder(
            valueListenable: _showToolbar,
            builder: (context, showToolbar, _) {
              return ReaderMenu(showToolbar: showToolbar);
            },
          ),
        ],
      ),
    );
  }
}
