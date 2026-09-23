---
# gstack: design-md-format=spec
name: Amiro
description: A wearable digital identity, styled like a status object you'd want to show off — refined, restrained, and quietly expensive.
colors:
  primary: "#C08A3E"
  on-primary: "#1D1509"
  surface: "#1F1D17"
  surface-border: "#322F26"
  text: "#EDE8DE"
  text-muted: "#8C8474"
  ground: "#161510"
  success: "#6E8F5C"
  warning: "#C08A3E"
  error: "#B4543B"
typography:
  display:
    fontFamily: "Instrument Serif"
    fontWeight: 400
    fontSize: "clamp(18px, 5vw, 23px)"
    letterSpacing: "0.01em"
  body:
    fontFamily: "Instrument Sans"
    fontSize: 1rem
    lineHeight: 1.5
  label:
    fontFamily: "Instrument Sans"
    fontSize: 0.75rem
    letterSpacing: 0.04em
  mono:
    fontFamily: "JetBrains Mono"
    fontFeature: tnum
rounded:
  sm: 6px
  md: 14px
  lg: 16px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  2xl: 48px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.md}"
    fontFamily: "{typography.body.fontFamily}"
    fontWeight: 600
  button-primary-hover:
    backgroundColor: "#D6A254"
  chip-active:
    backgroundColor: "{colors.text}"
    textColor: "{colors.ground}"
    rounded: "{rounded.full}"
  chip-inactive:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.surface-border}"
    textColor: "{colors.text-muted}"
    rounded: "{rounded.full}"
  card:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.surface-border}"
    rounded: "{rounded.lg}"
  card-equipped:
    borderColor: "{colors.primary}"
    borderWidth: 2px
  price-tag:
    backgroundColor: "{colors.surface-border}"
    textColor: "{colors.text}"
    fontFamily: "{typography.mono.fontFamily}"
  nav-link:
    textColor: "{colors.text}"
---

# Amiro

## Overview

**Creative North Star:** A wearable digital identity styled as a status object — a serif carries the "worth showing off" read, one brass accent does all the emphasis work, and nothing is decorated for decoration's sake.
**Product context:** Amiro is a local-first Flutter app: create a 3D identity, customize it with paid cosmetics, share it by NFC/QR. Premium/cult-status positioning — users pay real money because the product feels worth collecting, not because they're gated out of a free experience.
**Mode per surface:** Avatar/Profile = Operate (calm surface, the avatar itself is the content). Store = Operate (browsing/collecting, cards ARE the interaction). Share screen = Experience (the identity card is the artifact, chrome gets out of the way). Onboarding/first-launch = Experience (the reveal ceremony owns the moment).
**Reference sites:** none — no competitive research round-trip was run this session (explicit user choice to build straight from the validated avatar-screen mockup).
**Key characteristics:**
- Warm charcoal ground, never pure black — reads as a display case, not a dev-tool dark mode
- One accent color (brass) means everything: equipped state, price, primary action
- Serif display voice signals "object," not "toy" — the deliberate departure from category norms (Bitmoji/Genies use rounded/playful sans)
- No gradients, no glow, no halo — depth comes from real offset shadows only
- Numbers (prices, valuation) are always monospaced with tabular figures — collecting should feel precise, not cute

## Colors

**Strategy:** Restrained — one accent (`#C08A3E` brass), everything else is neutral. The accent is rare on purpose: when it shows up (equipped badge, a price, the primary button) it should read as a signal, not decoration.
**Light or dark:** Dark. The use scene is someone privately customizing a thing they'll show off in a moment — a dim "display case" mood, not a productivity tool's dark mode. Never invert to light: this isn't a category default, it's the specific scene.
Neutrals (`ground` `#161510`, `surface` `#1F1D17`, `surface-border` `#322F26`, `text` `#EDE8DE`, `text-muted` `#8C8474`) are all warm-toned, derived from the same brown-black family as the ground — never cool gray. Secondary text on the brass accent is never plain gray; if it needs to sit on a brass surface, tint it toward `on-primary` (`#1D1509`), not `text-muted`.

## Typography

Instrument Serif and Instrument Sans are a matched Google Fonts pairing — same type family lineage, so display and body read as one coherent voice rather than two unrelated fonts glued together.
- **Display** (Instrument Serif, regular only — this family has no bold weight, don't fake one): screen titles, the wordmark, a person's name. Reserved for identity-level text; never body copy, never buttons.
- **Body/UI** (Instrument Sans): everything interactive — buttons, chips, labels, descriptions. Weight 600 for buttons/emphasis, 400 for body.
- **Mono** (JetBrains Mono, tabular figures): every number that represents money or a count — item prices, the avatar valuation total. This is a deliberate signal: numbers get a different voice than prose, so a price never gets mistaken for a label.
- Loading: Google Fonts `@import`, `display=swap` — a 3D-avatar screen already has a load moment (the branded loading state), so a font swap is not the first thing a user notices.
- Exception to the overused-list: none taken. Instrument Serif/Sans/JetBrains Mono are all on the "freely available, not overused" list.

## Layout

Hybrid: the avatar stage is full-bleed and breaks any grid (it's the hero, treated like an object on a plinth, not a component in a layout). Store/profile lists (cosmetic tray, future catalog grid) are grid-disciplined — predictable columns, since browsing many items fast matters more than composition there.
Base unit 4px. Comfortable density around the avatar (generous whitespace, nothing crowds it), tighter density in scrollable item rows (72px cards, 12px gap) so more of the catalog is visible without feeling sparse.
Mobile-first; only breakpoint considered so far is phone portrait (390×844). Tablet/landscape layout is an open gap — flagged in TODOS.md, not yet specified.

## Elevation & Depth

Depth comes only from real offset + soft-blur shadows (e.g. the avatar's cast shadow: `0 24px 40px -18px rgba(0,0,0,0.7)`) — never a zero-offset glow or halo. This was a corrected mistake: the first draft of this mockup used a radial glow behind the avatar, which is a recognizable AI-generated pattern ("dark-mode glow"). Removed entirely in favor of a real shadow reading as weight, not light-source decoration.

## Shapes

Radius scale: `sm` 6px (small badges/tags), `md` 14px (buttons, cosmetic item cards), `lg` 16px (larger containers), `full` (pills/chips, circular avatars/icons). No radius is used purely decoratively — every rounded element is a tappable or containing surface.

## Components

- **Chips (category tray):** active = filled `text` color on `ground`, inactive = `surface` + `surface-border` outline. Hover/press: inactive chip gets a subtle `surface-border`→`text-muted` border brighten; no color change on active (it's already maximally prominent).
- **Cosmetic item card:** default = `surface` + `surface-border`. Equipped = 2px `primary` border, "EQUIPPED" badge in `on-primary`-on-`primary`. Locked/premium = `55%` black overlay + lock icon + mono price badge. Purchased-but-unequipped: same as default, no badge (tap to equip). Disabled/out-of-stock (limited items sold out): reduce opacity to 40%, remove tap affordance, badge reads "SOLD OUT" not the price.
- **Primary button:** solid `primary` fill, `on-primary` text, Instrument Sans 600. Disabled state (nothing changed to save): 40% opacity, no shadow, not tappable — this is the fix for the "dead tap on unchanged save" gap from the design review.
- **Price/valuation tag:** always mono, always tabular figures, `$` prefix, two decimals.

## Do's and Don'ts

- Do: use the brass accent only for equipped/price/primary-action — if you're reaching for it a fourth way, it's not restrained anymore.
- Do: keep every number (price, valuation, count) in JetBrains Mono with tabular figures.
- Do: give every interactive element a real offset shadow or border — never a flat, contextless surface floating with nothing to anchor it.
- Do: use Instrument Serif only for identity-level text (names, screen titles) — never for a button, a chip, or body copy.
- Don't: add a second accent color "just for variety" — if something needs to stand out, it's either equipped/priced/primary (use brass) or it isn't (use neutral).
- Don't: use any glow, halo, or zero-offset colored shadow, on any surface, ever — this was explicitly identified as this project's biggest AI-slop risk and corrected once already.
- Don't: use real trademarked brand names (Ray-Ban, Gucci, Prada, etc.) for cosmetic items — original brand-inspired naming only; explicitly rejected during this project's design review for trademark/IP risk (see `docs/legal/asset-policy.md`).
- Don't: center everything by default — the identity row, chips, and item cards are left-aligned/flowing; only the avatar stage itself is centered, because it's the one true focal point.

## Motion

- **Approach:** Intentional — meaningful transitions only, no full choreography.
- **Easing:** enter(ease-out) exit(ease-in) move(ease-in-out)
- **Duration:** micro(50-100ms) short(150-250ms) medium(250-400ms) long(400-700ms)
- **The one authored moment:** the first-launch reveal ceremony — the avatar assembles/materializes (fade + scale-in, medium duration, ease-out) before any UI chrome appears. This is the product's single biggest emotional beat and the only place a real choreography moment is earned; everywhere else, motion just confirms a state changed (equip, purchase, save).

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-09-23 | Initial design system created | Created by /design-consultation, building on the avatar-screen mockup validated during the same day's /plan-design-review |
| 2026-09-23 | Serif display voice (Instrument Serif) chosen over sans/playful convention | Deliberate risk: signals "status object" over "toy," which is the product's core differentiation bet against Bitmoji/Genies-style competitors |
| 2026-09-23 | No gradients/glow anywhere, including for "premium" surfaces | Corrects a first-draft mistake (radial glow behind avatar) that matched a recognizable AI-generated look; real offset shadows only |
| 2026-09-23 | Original brand-inspired cosmetic naming only, no real trademarks | Real brand names (Ray-Ban/Gucci/Prada) rejected for trademark/IP risk per docs/legal/asset-policy.md |
