/// Full-body hero framing and boutique stage defaults for [ThermionAvatarRenderer].
///
/// Kept free of Filament calls so orbit/background numbers stay unit-testable.
library;

/// Packaged gradient backdrop (non-flat stage environment).
const String avatarStageBackdropAsset =
    'packages/avatar_renderer/assets/stage/stage_backdrop.png';

/// Vertical focus for orbit / lookAt (standing humanoid center ~0.9m).
const double avatarOrbitFocusHeight = 0.92;

/// Camera distance for full-body framing including shoes (~1.8m tall figure).
const double avatarOrbitRadius = 2.55;

/// Slightly above focus so the lens looks gently down the figure (hero showcase).
const double avatarOrbitCameraHeight = 1.02;

/// Scene clear color — warm ground (#111110), sRGB 0–1. Used when backdrop fails.
const double avatarStageBackgroundR = 17 / 255;
const double avatarStageBackgroundG = 17 / 255;
const double avatarStageBackgroundB = 16 / 255;

/// Extended floor disk (meters) — soft shadow receiver beyond the plinth.
const double avatarStageFloorDiameter = 3.2;

/// Circular plinth top (meters).
const double avatarStageDiskDiameter = 1.35;

/// Low cylindrical lip + accent ring around the disk.
const double avatarStagePlinthRadius = 0.62;
const double avatarStagePlinthHeight = 0.055;
/// Outer brass band — sits at the plinth lip so it reads from the front camera.
const double avatarStageRingRadius = 0.615;
const double avatarStageRingHeight = 0.018;

/// Plinth center Y so the top lip sits at y=0 (feet level).
double get avatarStagePlinthCenterY => avatarStagePlinthHeight / 2;

/// Ring sits flush on the plinth top.
double get avatarStageRingCenterY =>
    avatarStagePlinthHeight + avatarStageRingHeight / 2;

/// Stage top — lifted boutique olive (#6E6D63) for clear separation from floor.
const double avatarStageDiskColorR = 110 / 255;
const double avatarStageDiskColorG = 109 / 255;
const double avatarStageDiskColorB = 99 / 255;

/// Plinth lip — mid charcoal olive (#45443C), visible against floor + disk.
const double avatarStagePlinthColorR = 69 / 255;
const double avatarStagePlinthColorG = 68 / 255;
const double avatarStagePlinthColorB = 60 / 255;

/// Floor beyond plinth — deep ground (#111110).
const double avatarStageFloorColorR = 17 / 255;
const double avatarStageFloorColorG = 17 / 255;
const double avatarStageFloorColorB = 16 / 255;

/// Warm brass rim (#D4A855 base) — emissive scaled in renderer, not neon.
const double avatarStageRingColorR = 212 / 255;
const double avatarStageRingColorG = 168 / 255;
const double avatarStageRingColorB = 85 / 255;
