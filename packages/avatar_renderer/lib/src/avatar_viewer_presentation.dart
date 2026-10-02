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

/// Low plinth under the avatar (meters).
const double avatarStagePlinthRadius = 0.52;
const double avatarStagePlinthHeight = 0.035;

/// Plinth center Y so the top surface sits at y=0 (feet level).
double get avatarStagePlinthCenterY => avatarStagePlinthHeight / 2;

/// Unlit plinth tint — DESIGN.md `surface` (#1F1D17), sRGB 0–1.
const double avatarStagePlinthColorR = 31 / 255;
const double avatarStagePlinthColorG = 29 / 255;
const double avatarStagePlinthColorB = 23 / 255;
