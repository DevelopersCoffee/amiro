/// Lets the app pause Filament presentation before destroying skinned assets
/// (see [ThermionAvatarRenderer.pausePresentation]).
///
/// Registered once from the app shell (`main` / root tabs). When null, mutations
/// run immediately (unit tests and fakes).
class ThermionViewDetachGate {
  ThermionViewDetachGate._();

  static Future<void> Function()? beforeEngineMutation;

  static Future<void> runMutation(Future<void> Function() action) async {
    final detach = beforeEngineMutation;
    if (detach != null) {
      await detach();
    }
    await action();
  }
}
