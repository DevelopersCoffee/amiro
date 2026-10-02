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
const double avatarStageRingRadius = 0.52;
const double avatarStageRingHeight = 0.012;

/// Plinth center Y so the top lip sits at y=0 (feet level).
double get avatarStagePlinthCenterY => avatarStagePlinthHeight / 2;

/// Ring sits flush on the plinth top.
double get avatarStageRingCenterY =>
    avatarStagePlinthHeight + avatarStageRingHeight / 2;

/// Stage top — boutique stage olive (#48483F).
const double avatarStageDiskColorR = 72 / 255;
const double avatarStageDiskColorG = 72 / 255;
const double avatarStageDiskColorB = 63 / 255;

/// Plinth edge — surface (#1D1C19).
const double avatarStagePlinthColorR = 29 / 255;
const double avatarStagePlinthColorG = 28 / 255;
const double avatarStagePlinthColorB = 25 / 255;

/// Floor beyond plinth — slightly darker than disk for depth.
const double avatarStageFloorColorR = 22 / 255;
const double avatarStageFloorColorG = 21 / 255;
const double avatarStageFloorColorB = 18 / 255;

/// Brass accent ring — restrained (#C49343), emissiveFactor not neon.
const double avatarStageRingColorR = 196 / 255;
const double avatarStageRingColorG = 147 / 255;
const double avatarStageRingColorB = 67 / 255;
