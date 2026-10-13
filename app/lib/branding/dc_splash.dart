import 'package:flutter/material.dart';

import '../theme/amiro_theme.dart';
import 'dc_mark_painter.dart';
import 'dc_motion.dart';

/// Developers Coffee brand sting shown once at cold start. Calls [onDone]
/// exactly once, when the sting ends or the user taps to skip.
class DcSplash extends StatefulWidget {
  final VoidCallback onDone;

  const DcSplash({super.key, required this.onDone});

  @override
  State<DcSplash> createState() => _DcSplashState();
}

class _DcSplashState extends State<DcSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _done = false;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: DcMotion.total)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      // Static final frame, then hand off.
      _controller.value = DcMotion.wordmark.end;
      Future<void>.delayed(DcMotion.reducedHold, _finish);
    } else {
      _controller.forward();
    }
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordmarkStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AmiroColors.text,
          letterSpacing: 0.01 * 23,
        );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: ColoredBox(
        color: AmiroColors.ground,
        child: Semantics(
          label: 'Developers Coffee',
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final out = 1.0 - DcMotion.exit.transform(t);
              return Opacity(
                opacity: out,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 120,
                        child: CustomPaint(
                          painter: DcMarkPainter(
                            cup: DcMotion.cup.transform(t),
                            steamA: DcMotion.steamA.transform(t),
                            steamB: DcMotion.steamB.transform(t),
                          ),
                        ),
                      ),
                      const SizedBox(height: AmiroSpacing.lg),
                      Opacity(
                        opacity: DcMotion.wordmark.transform(t),
                        child: Text('Developers Coffee', style: wordmarkStyle),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
