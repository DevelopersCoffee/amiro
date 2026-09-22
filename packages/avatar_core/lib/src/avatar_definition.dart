/// An avatar's equipped cosmetics, one asset id per slot.
///
/// Slot list matches the PRD's full 17-slot avatar system exactly, even
/// though this pass only ever populates `body`, `top`, and `glasses` —
/// this avoids a schema migration when later milestones add real
/// cosmetics for the remaining slots.
class AvatarDefinition {
  static const List<String> slots = [
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
  ];

  final String id;
  final String? body;
  final String? face;
  final String? skin;
  final String? hair;
  final String? eyes;
  final String? eyebrows;
  final String? facialHair;
  final String? top;
  final String? bottom;
  final String? shoes;
  final String? glasses;
  final String? earrings;
  final String? necklace;
  final String? goldChain;
  final String? watch;
  final String? hat;
  final String? background;
  final String? effects;

  const AvatarDefinition({
    required this.id,
    this.body,
    this.face,
    this.skin,
    this.hair,
    this.eyes,
    this.eyebrows,
    this.facialHair,
    this.top,
    this.bottom,
    this.shoes,
    this.glasses,
    this.earrings,
    this.necklace,
    this.goldChain,
    this.watch,
    this.hat,
    this.background,
    this.effects,
  });

  Map<String, String?> _asMap() => {
        'body': body,
        'face': face,
        'skin': skin,
        'hair': hair,
        'eyes': eyes,
        'eyebrows': eyebrows,
        'facialHair': facialHair,
        'top': top,
        'bottom': bottom,
        'shoes': shoes,
        'glasses': glasses,
        'earrings': earrings,
        'necklace': necklace,
        'goldChain': goldChain,
        'watch': watch,
        'hat': hat,
        'background': background,
        'effects': effects,
      };

  /// Returns a copy with exactly one slot replaced. Throws [ArgumentError]
  /// if [slot] is not one of [slots].
  AvatarDefinition copyWithSlot(String slot, String? assetId) {
    if (!slots.contains(slot)) {
      throw ArgumentError.value(slot, 'slot', 'must be one of AvatarDefinition.slots');
    }
    final current = _asMap();
    current[slot] = assetId;
    return AvatarDefinition(
      id: id,
      body: current['body'],
      face: current['face'],
      skin: current['skin'],
      hair: current['hair'],
      eyes: current['eyes'],
      eyebrows: current['eyebrows'],
      facialHair: current['facialHair'],
      top: current['top'],
      bottom: current['bottom'],
      shoes: current['shoes'],
      glasses: current['glasses'],
      earrings: current['earrings'],
      necklace: current['necklace'],
      goldChain: current['goldChain'],
      watch: current['watch'],
      hat: current['hat'],
      background: current['background'],
      effects: current['effects'],
    );
  }

  Map<String, dynamic> toJson() => {'id': id, ..._asMap()};

  factory AvatarDefinition.fromJson(Map<String, dynamic> json) {
    return AvatarDefinition(
      id: json['id'] as String,
      body: json['body'] as String?,
      face: json['face'] as String?,
      skin: json['skin'] as String?,
      hair: json['hair'] as String?,
      eyes: json['eyes'] as String?,
      eyebrows: json['eyebrows'] as String?,
      facialHair: json['facialHair'] as String?,
      top: json['top'] as String?,
      bottom: json['bottom'] as String?,
      shoes: json['shoes'] as String?,
      glasses: json['glasses'] as String?,
      earrings: json['earrings'] as String?,
      necklace: json['necklace'] as String?,
      goldChain: json['goldChain'] as String?,
      watch: json['watch'] as String?,
      hat: json['hat'] as String?,
      background: json['background'] as String?,
      effects: json['effects'] as String?,
    );
  }
}
