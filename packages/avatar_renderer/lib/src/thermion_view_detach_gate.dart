/// Lets the app detach [ThermionWidget] from the tree before Filament mutates
/// or destroys skinned assets (avoids SIGSEGV on Android when leaving tabs).
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
