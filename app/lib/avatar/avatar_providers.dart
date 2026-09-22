import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_renderer/avatar_renderer.dart';

/// Overridden in `main.dart` with a real [ThermionAvatarRenderer];
/// overridden in tests with a fake [AvatarRenderer].
final avatarRendererProvider = Provider<AvatarRenderer>((ref) {
  throw UnimplementedError('avatarRendererProvider must be overridden');
});
