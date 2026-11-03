import 'package:flutter_riverpod/flutter_riverpod.dart';

/// RevenueCat is configured only after this flips true (Store tab, purchase,
/// restore, or explicit refresh).
class RevenueCatActivatedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void activate() => state = true;
}

final revenueCatActivatedProvider =
    NotifierProvider<RevenueCatActivatedNotifier, bool>(
      RevenueCatActivatedNotifier.new,
    );
