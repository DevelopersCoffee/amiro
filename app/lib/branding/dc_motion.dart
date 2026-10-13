import 'package:flutter/animation.dart';

/// Developers Coffee sting timing (DESIGN.md "Motion"). One controller drives
/// every phase; each phase is an [Interval] of [total].
abstract final class DcMotion {
  static const total = Duration(milliseconds: 1900);

  /// Reduced-motion: a static frame, then straight to the app.
  static const reducedHold = Duration(milliseconds: 600);

  /// Cup outline traces itself (move: ease-in-out).
  static const cup = Interval(0.0, 0.26, curve: Curves.easeInOut);

  /// Two steam curls rise and fade (enter: ease-out), staggered.
  static const steamA = Interval(0.21, 0.53, curve: Curves.easeOut);
  static const steamB = Interval(0.29, 0.58, curve: Curves.easeOut);

  /// Wordmark fades up beneath the cup (enter: ease-out).
  static const wordmark = Interval(0.37, 0.53, curve: Curves.easeOut);

  /// Whole sting fades out into the app (exit: ease-in).
  static const exit = Interval(0.87, 1.0, curve: Curves.easeIn);
}
