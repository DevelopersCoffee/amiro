/// Full-body hero framing and cinematic stage defaults for [ThermionAvatarRenderer].
///
/// Kept free of Filament calls so orbit/background numbers stay unit-testable.
library;

/// Vertical focus for orbit / lookAt (standing humanoid center ~0.9m).
const double avatarOrbitFocusHeight = 0.92;

/// Camera distance for full-body framing including shoes (~1.8m tall figure).
const double avatarOrbitRadius = 2.55;

/// Slightly above focus so the lens looks gently down the figure (hero showcase).
const double avatarOrbitCameraHeight = 1.02;

/// Scene clear color — DESIGN.md `ground` (#161510), sRGB 0–1.
const double avatarStageBackgroundR = 22 / 255;
const double avatarStageBackgroundG = 21 / 255;
const double avatarStageBackgroundB = 16 / 255;

/// Stage disk under the avatar (meters). Sized to read on a ~2.5m camera orbit.
const double avatarStageDiskDiameter = 1.5;

/// Low cylindrical lip around the disk (visible thickness from the front camera).
const double avatarStagePlinthRadius = 0.58;
const double avatarStagePlinthHeight = 0.07;

/// Plinth center Y so the top lip sits at y=0 (feet level).
double get avatarStagePlinthCenterY => avatarStagePlinthHeight / 2;

/// Stage top — DESIGN.md `surface-border` (#322F26), lighter than ground bg.
const double avatarStageDiskColorR = 50 / 255;
const double avatarStageDiskColorG = 47 / 255;
const double avatarStageDiskColorB = 38 / 255;

/// Plinth edge — DESIGN.md `surface` (#1F1D17), still contrast vs ground.
const double avatarStagePlinthColorR = 31 / 255;
const double avatarStagePlinthColorG = 29 / 255;
const double avatarStagePlinthColorB = 23 / 255;
