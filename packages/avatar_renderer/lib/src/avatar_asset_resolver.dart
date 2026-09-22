/// Maps a (slot, assetId) pair to the packaged glTF/GLB asset path.
///
/// `body` renders from `assets/avatars/`; every other slot renders from
/// `assets/cosmetics/`. This pass only ships placeholder assets for
/// `body`, `top`, and `glasses` (see Task 9).
String resolveAssetPath(String slot, String assetId) {
  const validSlots = {
    'body',
    'face',
    'skin',
    'hair',
    'eyes',
    'eyebrows',
    'facialHair',
    'top',
    'bottom',
    'shoes',
    'glasses',
    'earrings',
    'necklace',
    'goldChain',
    'watch',
    'hat',
    'background',
    'effects',
  };
  if (!validSlots.contains(slot)) {
    throw ArgumentError.value(slot, 'slot', 'unknown avatar slot');
  }
  final folder = slot == 'body' ? 'avatars' : 'cosmetics';
  return 'packages/avatar_renderer/assets/$folder/$assetId.glb';
}
