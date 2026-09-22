# Amiro Product Requirements

The Amiro revision (below) supersedes the original draft where they conflict, particularly regarding unverified critique claims about conversion percentages and guaranteed availability of platform features.

## Original draft

Project Requirements — Digital Identity Avatar App v1
1. Product Definition
Build a mobile-first novelty social identity app for iOS and Android.
The app lets a person:

1. Create a personal digital identity.
2. Create and customize a 3D avatar.
3. Buy virtual cosmetic items for the avatar.
4. Share their identity with another person using NFC or QR.
5. If the receiver has the app, open the sender's rich avatar/profile.
6. If the receiver does not have the app, fall back to a normal contact/profile link.
7. Keep most data and processing on the user's device.
8. Avoid requiring a large backend or complex infrastructure.
9. Eventually support trading/reselling of digital items, but not in v1.

The product is intentionally a novelty/social identity product, not a productivity app, financial product, dating app, or cryptocurrency product.
2. Core Product Loop

```text
Create Identity
      ↓
Create Avatar
      ↓
Customize Avatar
      ↓
Buy Digital Cosmetics
      ↓
Share Identity
      ↓
Friend sees Avatar/Profile
      ↓
Friend wants their own Avatar
      ↓
Installs App
      ↓
Creates Identity
```

The important viral mechanism is:
"This is me." → Tap phones → Your digital identity appears.
NFC is part of the product experience, not merely a technical feature.
3. v1 Scope
Identity
Each user can create a profile containing:

* Display name
* Username
* Profile picture/avatar
* Mobile number
* Email
* X/Twitter username
* Instagram username
* Website
* Other social links
* Short bio
* Avatar
* Selected cosmetic items

Privacy controls should exist for individual fields.
Example:

```text
Uday
@uday

[3D Avatar]

Software Engineer

📱 Mobile
✉️ Email
𝕏 X
📸 Instagram
🌐 Website
```

4. Avatar System
The avatar should be 3D, not a simple 2D image.
The architecture must support independently configurable components:

```text
Avatar
├── Body
├── Face
├── Skin
├── Hair
├── Eyes
├── Eyebrows
├── Facial Hair
├── Top
├── Bottom
├── Shoes
├── Glasses
├── Earrings
├── Necklace
├── Gold Chain
├── Watch
├── Hat
├── Background
└── Special Effects
```

Every cosmetic should be represented as an independent asset.
Example:

```text
Avatar
    + Gold Chain #001
    + Black Glasses #004
    + Designer Jacket #012
```

This allows new cosmetics to be added without rebuilding the avatar system.
5. Digital Store
Users can purchase virtual cosmetics.
Initial categories:

* Clothes
* Glasses
* Chains
* Watches
* Hats
* Shoes
* Jewelry
* Accessories
* Backgrounds
* Limited-edition cosmetics

Do not implement:

* Trading
* Reselling
* User marketplace
* NFT ownership
* Cryptocurrency
* User-to-user item transfers

Those belong to a later phase.
6. Monetization
Use platform-native digital purchase systems.
iOS
Apple In-App Purchase / StoreKit.
Android
Google Play Billing.
Do not create a custom payment system for digital cosmetics.
Initial pricing can be simple:

```text
Free
    Basic avatar
    Basic cosmetics

$0.99
    Cosmetic

$1.99
    Premium cosmetic

$4.99
    Cosmetic bundle

$9.99
    Premium collection
```

The actual pricing should be tested later rather than hard-coded into the architecture.
7. NFC Sharing
Primary experience:

```text
Phone A
   │
   │ NFC
   ↓
Phone B
   │
   ↓
Identity detected
   │
   ├── App installed → Open profile
   │
   └── App not installed → Web/contact fallback
```

The NFC payload should not contain the entire profile.
Use a compact identity/deep-link identifier.
Example:

```text
https://app-domain.com/u/abc123
```

or an equivalent compact app-specific payload.
The receiver then resolves the identity.
8. QR Fallback
Every shareable identity should also have a QR representation.
This handles:

* Phones without compatible NFC behavior
* Desktop sharing
* Screenshots
* Social media
* Messages
* Physical displays

The sharing screen should support:

```text
[NFC]

[QR CODE]

[Share Link]
```

9. App-Not-Installed Experience
This is critical.
If somebody taps an NFC-enabled identity and does not have the app:

```text
Your friend shared their digital identity.

[Avatar]

Uday
@uday

Software Engineer

[Install App]
[View Contact]
```

The web fallback should expose only information the user has marked as public.
This means the product can work even when only one person has installed the app.
10. Local-First Architecture
The product should be local-first.
Keep on-device:

* Avatar state
* Avatar customization
* Cosmetic catalog cache
* User profile
* Privacy settings
* Local preferences
* NFC generation
* QR generation
* Rendering
* Most UI state

Backend should be minimal.
Backend responsibilities:

```text
Authentication
Purchase verification
Product catalog
Public identity resolution
Deep-link resolution
Optional profile synchronization
Abuse/security controls
Analytics
```

Do not build a large traditional backend.
11. Backend
Initial target:
Cloudflare
Use lightweight:

* Workers
* D1/KV where appropriate
* R2 if asset storage becomes necessary

Alternative:
Google Cloud
Use:

* Cloud Run
* Firestore
* Cloud Storage

The architecture must keep these behind interfaces so the backend provider can be changed later.
12. Avatar Rendering Architecture
Recommended high-level architecture:

```text
Flutter
   │
   ├── UI
   ├── Profile
   ├── Store
   ├── NFC
   ├── QR
   │
   ↓
Avatar SDK
   │
   ↓
3D Avatar Renderer
   │
   ↓
Avatar Assets
```

The avatar definition should be platform-independent.
Example conceptual format:

```json
{
  "body": "body_01",
  "hair": "hair_07",
  "top": "top_12",
  "glasses": "glasses_03",
  "necklace": "gold_chain_01"
}
```

The same avatar definition must produce the same visual identity on Android and iOS.
13. Technology Direction
Application
Flutter
Reason:

* Android + iOS
* Single application codebase
* Good fit with existing Airo engineering knowledge
* Easy UI iteration
* Good support for native platform integrations

Core
Reuse useful Rust patterns/components from Airo, but keep this as an independent application/repository.
Do not make this app depend directly on the Airo application.
Use shared packages only where they are genuinely reusable.
Potential shared components:

```text
Rust utilities
Identity model
Cryptographic primitives
QR encoding
Protocol definitions
Asset manifest format
Storage abstractions
```

14. No-Coding Requirement
This project must be designed around agent-driven/no-manual-coding development.
The owner should not need to manually write application code.
Agents are responsible for:

* Architecture
* Implementation
* Testing
* Code generation
* Refactoring
* Build configuration
* CI/CD
* Documentation
* App-store preparation
* Security review
* Legal/IP review
* QA
* Release preparation

The human role is primarily:

```text
Product decisions
      ↓
Agent execution
      ↓
Automated validation
      ↓
Human approval
      ↓
Release
```

Use tools such as:

* Cursor
* Claude Code
* Codex
* GitHub
* GitHub Actions
* automated testing
* automated builds

The project must maintain a strong agent-readable specification so agents do not independently invent architecture.
15. Multi-Agent Team
Agent 1 — Product Architect
Responsibility
Own the product specification.
Maintain:

```text
docs/product/
```

Responsibilities:

* Product requirements
* User journeys
* Feature scope
* v1/v2 boundaries
* Acceptance criteria
* Product decisions
* Prevent scope creep

Must explicitly reject v2 features from entering v1 unless approved.
Agent 2 — Technical Architect
Own:

```text
docs/architecture/
```

Responsibilities:

* System architecture
* Flutter architecture
* Rust architecture
* Avatar architecture
* Backend boundaries
* Data models
* APIs
* Security architecture
* Dependency decisions

Must ensure Android and iOS remain behaviorally consistent.
Agent 3 — Flutter Agent
Own the mobile application.
Responsibilities:

* Flutter project
* UI
* Navigation
* Profile
* Store
* Sharing UI
* Settings
* Deep links
* State management
* Platform integration

Must not independently modify Rust core architecture.
Agent 4 — Rust/Core Agent
Own:

```text
packages/core/
packages/avatar_core/
```

Responsibilities:

* Domain models
* Identity model
* Avatar model
* Cosmetic model
* Serialization
* Protocols
* Local storage abstractions
* Security primitives

Rust should remain independent of Flutter UI.
Agent 5 — 3D Avatar Agent
This is one of the most important agents.
Responsibilities:

* 3D avatar system
* Avatar skeleton
* Clothing system
* Accessory system
* Materials
* Animation
* Camera
* Lighting
* Asset format
* Asset loading
* Avatar rendering
* Cross-platform consistency

It must create an original visual style.
Do not copy Bitmoji assets, models, animations, textures, characters, or proprietary designs.
Agent 6 — Asset/Content Agent
Responsibilities:
Create the initial virtual inventory.
Example:

```text
10 hairstyles
10 tops
10 bottoms
10 glasses
10 chains
10 shoes
10 accessories
5 backgrounds
```

All assets must be:

* Original
* Properly licensed
* Commercially usable
* Documented
* Versioned

Maintain:

```text
assets/LICENSES.md
assets/ATTRIBUTIONS.md
```

Agent 7 — NFC/Sharing Agent
Responsibilities:

* NFC protocol
* Deep links
* QR generation
* QR scanning
* Contact fallback
* App-installed flow
* App-not-installed flow
* Share sheets
* Universal Links
* Android App Links

Maintain the sharing protocol independently from UI.
Agent 8 — Backend Agent
Responsibilities:

* Authentication
* Identity resolution
* Public profile API
* Purchase verification
* Catalog API
* Minimal analytics
* Abuse prevention

Keep backend stateless wherever possible.
Avoid unnecessary infrastructure.
Agent 9 — Payments Agent
Responsibilities:

* Apple StoreKit
* Google Play Billing
* Purchase validation
* Entitlement handling
* Restore purchases
* Refund handling
* Subscription avoidance unless explicitly required

Digital goods must use platform-approved purchase flows.
Agent 10 — QA Agent
Responsibilities:
Automated tests for:

```text
Android
iOS
NFC
QR
Deep links
Avatar rendering
Purchases
Offline mode
Online mode
Profile privacy
App installation fallback
```

Device matrix should include at least:

```text
Android phone
iPhone
Android device with NFC
iPhone with NFC
```

QA must produce reproducible bug reports.
Agent 11 — Security & Privacy Agent
Responsibilities:

* Threat model
* Identity security
* Profile privacy
* Deep-link abuse
* NFC payload validation
* QR tampering
* Authentication
* API abuse
* Data minimization
* Local data encryption where appropriate
* Secrets management

The app should collect as little personal data as possible.
Agent 12 — Legal/IP/App Store Agent
Responsibilities:
Review:

* Apple App Store requirements
* Google Play requirements
* Digital goods rules
* Privacy requirements
* User-generated content requirements if introduced
* Copyright
* Trademark
* Asset licenses
* Third-party SDK licenses
* Brand usage

The avatar system must be inspired by the concept of customizable digital avatars, not copied from Bitmoji/Snapchat.
No:

```text
Bitmoji assets
Snapchat assets
Snap branding
Snap characters
Snap UI copying
Unlicensed luxury brands
Unlicensed logos
Unlicensed celebrity likenesses
```

Agent 13 — DevOps Agent
Responsibilities:

* GitHub repository
* CI
* Android builds
* iOS builds
* Unit tests
* Integration tests
* Release builds
* Versioning
* Environment configuration
* Secrets

Every pull request should automatically run validation.
Agent 14 — Growth/Experiment Agent
Responsibilities:
Measure product behavior without turning the app into a data-heavy service.
Track events such as:

```text
avatar_created
avatar_customized
cosmetic_viewed
cosmetic_purchased
identity_shared
nfc_share
qr_share
profile_opened
install_from_shared_identity
```

Avoid collecting unnecessary personal information.
16. Agent Coordination Rules
All agents must use the same source of truth:

```text
/docs
```

Recommended structure:

```text
docs/
├── product/
│   ├── requirements.md
│   ├── user-flows.md
│   └── roadmap.md
│
├── architecture/
│   ├── overview.md
│   ├── avatar.md
│   ├── identity.md
│   ├── sharing.md
│   └── backend.md
│
├── protocols/
│   ├── identity-link.md
│   └── avatar-format.md
│
├── legal/
│   ├── asset-policy.md
│   └── third-party-licenses.md
│
└── qa/
    └── test-plan.md
```

Agents must update documentation when changing an architectural contract.
17. Repository Structure
Recommended:

```text
identity-avatar/
│
├── app/
│   └── Flutter application
│
├── packages/
│   ├── identity_core/
│   ├── avatar_core/
│   ├── avatar_renderer/
│   ├── sharing/
│   ├── nfc/
│   ├── qr/
│   └── store/
│
├── rust/
│   └── core
│
├── assets/
│   ├── avatars/
│   ├── cosmetics/
│   └── backgrounds/
│
├── backend/
│
├── docs/
│
├── scripts/
│
└── .github/
```

18. v1 Milestones
M0 — Architecture

```text
Repository
Flutter shell
Rust core
CI
Agent documentation
```

M1 — Identity

```text
Create profile
Edit profile
Privacy controls
Local persistence
```

M2 — Avatar

```text
3D avatar
Customization
Save/load avatar
Camera
Basic animation
```

M3 — Cosmetics

```text
Catalog
Item preview
Inventory
Purchase entitlement
```

M4 — Sharing

```text
NFC
QR
Deep links
Profile fallback
```

M5 — Backend

```text
Identity resolution
Purchase verification
Minimal catalog service
```

M6 — Store Release

```text
Privacy policy
Terms
Store metadata
Screenshots
Test builds
App Store
Google Play
```

19. Explicitly Out of Scope for v1
Do not allow agents to silently introduce:

* NFTs
* Blockchain
* Crypto
* Token wallets
* Marketplace
* Trading
* Reselling
* User-to-user cosmetic transfers
* Creator marketplace
* Ads
* Chat
* Dating
* Full social network
* Stories
* Public feed
* Complex recommendation engine
* AR
* Facial scanning
* AI-generated avatars

These can become future experiments.
20. Future Architecture
The v1 data model should not block:

```text
v2
User → owns → Cosmetic

v3
User → trades → Cosmetic

v4
User → lists → Cosmetic

v5
Creator → creates → Cosmetic

v6
Creator → sells → Cosmetic
```

But v1 only needs:

```text
User → owns → Cosmetic
```

That distinction keeps the first release much smaller.
21. Product Principle
The product should feel like:
A digital identity you can wear and tap to share.
Not:
Another social network.
Not:
A cryptocurrency product.
Not:
An NFT marketplace.
Not:
A game.
The novelty comes from combining:

```text
3D Identity
+
Digital Fashion
+
NFC
+
Social Sharing
+
Virtual Goods
```

22. Definition of Done
v1 is complete when a new user can:

```text
Install app
    ↓
Create identity
    ↓
Create avatar
    ↓
Customize avatar
    ↓
Preview cosmetics
    ↓
Purchase a cosmetic
    ↓
Equip it
    ↓
Tap/share identity
    ↓
Another phone receives it
    ↓
If app exists:
    Open rich avatar profile

If app doesn't exist:
    Open web/contact fallback
```

And the entire system can be built, tested, and released through the agent-driven workflow without the product owner manually writing application code.

## Amiro revision

Amiro works well as the product name. It is short, starts with A, and fits a personal identity product without locking the brand to avatars or NFC.
I would revise the requirements around the critique you pasted. One important correction: several claims in that critique—such as specific conversion percentages, "up to 60%" drop-offs, and guaranteed availability/behavior of Instant Apps or App Clips—should not be treated as product facts until tested and verified.
Amiro — Product Definition
Amiro is a wearable digital identity.
Users create a 3D persona, customize it with virtual fashion and accessories, then share that identity by tapping phones or showing a QR code.

```text
Create yourself
      ↓
Wear your digital style
      ↓
Tap to share
      ↓
Friend sees you
      ↓
Friend creates their own Amiro
```

The share experience is the primary product.
The virtual store is the monetization layer, not an onboarding gate.
1. Core v1 Experience
Sender

```text
Open Amiro
   ↓
Create identity
   ↓
Get instant starter avatar
   ↓
Customize if desired
   ↓
Tap / QR
```

Receiver

```text
Tap / scan
   ↓
Amiro identity link
   ↓
App installed?
   ├── Yes → Native 3D profile
   │
   └── No → Lightweight web profile
                ↓
          Add contact
          or
          Get Amiro
```

The recipient must be able to understand the product without installing the app first.
2. Monetization Change
Do not do this:

```text
Install
→ Avatar
→ Customize
→ BUY
→ Share
```

Do this:

```text
Install
→ Identity
→ Starter Avatar
→ Share
→ Return later
→ Discover cosmetics
→ Purchase
```

Free users should have enough cosmetics to make their avatar look good.
The paid items should make customization more interesting, not unlock the basic product.
3. Amiro Identity
Every user gets an Amiro identity:

```text
Amiro ID
@uday

[3D Avatar]

Software Engineer

Mobile
Email
X
Instagram
Website

[TAP TO SHARE]
[QR]
```

The owner decides which contact fields are public.
The identity URL should be stable:

```text
https://id.amiro.app/u/<id>
```

The exact domain can be decided after domain availability checks.
4. NFC Architecture
Do not try to transmit the entire avatar through NFC.
NFC contains a small signed/deep-link payload:

```text
https://id.amiro.app/u/abc123
```

Then:

```text
NFC
 ↓
HTTPS identity URL
 ↓
App Link / Universal Link
 ↓
Amiro profile
```

QR uses the same URL.
That gives NFC and QR one common protocol.
5. Three Recipient Modes
Mode A — App installed
Open the native Amiro profile.

```text
NFC
 ↓
Universal/App Link
 ↓
Amiro
 ↓
3D avatar
```

Mode B — App not installed
Open a lightweight web profile.

```text
NFC
 ↓
Browser
 ↓
3D/web profile
 ↓
"Create your Amiro"
```

Mode C — Old/incompatible device
Show a simple profile:

```text
Avatar
Name
Social links
Contact information

[Add Contact]
[Get Amiro]
```

This fallback is mandatory.
6. Do Not Make Instant Apps/App Clips a v1 Dependency
The architecture should allow App Clips and Android instant experiences later.
But v1 should not depend on them.
Reason:

* They add platform-specific build complexity.
* They have platform-specific limits.
* They require additional testing and distribution configuration.
* The web fallback already solves the zero-install requirement.

Therefore:

```text
v1

Native App
   +
Web Profile
   +
NFC
   +
QR
```

Later:

```text
Native App
   +
App Clip
   +
Android Instant Experience
   +
Web
```

7. 3D Avatar Architecture
The avatar must be modular.

```text
Avatar
├── Body
├── Face
├── Hair
├── Eyes
├── Clothing
├── Shoes
├── Glasses
├── Chains
├── Jewelry
├── Watches
├── Hats
└── Effects
```

Avatar state should be separate from the actual 3D assets.
Example:

```json
{
  "avatar": "base_001",
  "hair": "hair_007",
  "top": "top_014",
  "glasses": "glass_003",
  "chain": "gold_chain_002"
}
```

This makes the catalog expandable without changing the avatar system.
8. Virtual Goods
Initial catalog:

```text
Free
├── Hair
├── Shirts
├── Pants
├── Shoes
├── Glasses
└── Accessories

Premium
├── Chains
├── Jewelry
├── Premium clothes
├── Special effects
├── Limited cosmetics
└── Avatar environments
```

Do not build a marketplace yet.
The underlying data model should support ownership:

```text
User
  ↓
owns
  ↓
Cosmetic
```

Later it can support:

```text
User
  ↓
lists
  ↓
Cosmetic
```

and eventually trading.
9. Technology
Mobile
Flutter
Use Flutter for:

* Navigation
* Profile
* Store
* Settings
* Sharing
* Authentication UI
* Native platform integration

Core
Rust
Use Rust for:

* Identity models
* Avatar state
* Serialization
* Protocols
* Local data logic
* Cryptographic verification
* Shared domain logic

3D
The 3D renderer needs to be selected through a technical spike.
Candidates should be evaluated rather than assuming Unity immediately:

```text
Flutter + native 3D renderer
Flutter + embedded 3D engine
Flutter + platform rendering layer
```

The deciding criteria are:

* Android/iOS parity
* Rendering performance
* App size
* Asset pipeline
* Animation
* Material support
* Flutter integration
* License
* Agent-driven development complexity

Do not lock the project to Unity until this spike is completed.
10. Asset Format
Use an industry-standard 3D asset format such as:
glTF / GLB
Evaluate:

* Meshopt
* Draco
* KTX2/Basis textures

The asset pipeline should produce optimized mobile assets.
Example:

```text
source_asset
     ↓
validation
     ↓
optimization
     ↓
compression
     ↓
GLB
     ↓
CDN
     ↓
Amiro
```

11. Local-First
The phone should handle:

* Avatar state
* Avatar rendering
* Equipped cosmetics
* Profile editing
* QR generation
* NFC payload generation
* Local cache
* Basic profile presentation

Cloud handles:

* Account identity
* Public profile resolution
* Product catalog
* Purchase verification
* Entitlements
* Optional sync
* Abuse controls

This keeps infrastructure cheap.
12. Backend
Start extremely small.
Possible architecture:

```text
Cloudflare
├── Worker
├── KV / D1
└── R2

or

Google Cloud
├── Cloud Run
├── Firestore
└── Cloud Storage
```

Don't introduce Redis, Kubernetes, microservices, or a large database architecture for v1.
A few thousand users should not require a complicated infrastructure.
13. Authentication
Don't force account creation before the user experiences the product.
Ideal flow:

```text
Open
 ↓
Create temporary local identity
 ↓
Build avatar
 ↓
Share
 ↓
Account claim/sync
```

Then support:

* Passkeys
* Apple Sign In
* Google Sign In

The exact authentication strategy should be validated against Apple's and Google's current requirements during implementation.
14. Contact Interoperability
Amiro should support exporting a normal contact card.
Example:

```text
Amiro Profile
     +
vCard
     ↓
Phone Contacts
```

Use standard vCard rather than inventing another contact format.
This gives the product utility even when the recipient doesn't use Amiro.
15. Privacy Model
The user controls:

```text
Mobile     ON/OFF
Email      ON/OFF
X          ON/OFF
Instagram  ON/OFF
Website    ON/OFF
Bio        ON/OFF
```

The public identity should contain only explicitly public fields.
The NFC payload should never contain private contact data directly.
16. Agent Organization
Use the following agent structure.

```text
                    PRODUCT ORCHESTRATOR
                            │
          ┌─────────────────┼──────────────────┐
          ↓                 ↓                  ↓
     Architecture        Product             QA
          │
    ┌─────┼──────┬─────────┬──────────┐
    ↓     ↓      ↓         ↓          ↓
 Flutter Rust   3D       Sharing    Backend
 Agent  Agent  Agent      Agent       Agent
                                      │
                              ┌───────┴───────┐
                              ↓               ↓
                          Payments        Security
                              │
                              ↓
                         Release Agent
```

Product Orchestrator
Owns the entire execution plan.
It prevents agents from independently changing the product.
Product Agent
Owns:

* Requirements
* User journeys
* Acceptance criteria
* Scope

Architecture Agent
Owns:

* System boundaries
* Interfaces
* Technical decisions
* ADRs

Flutter Agent
Owns the mobile application.
Rust Agent
Owns shared domain/core logic.
3D Agent
Owns:

* Avatar
* Renderer
* Animation
* Asset pipeline

Asset Agent
Owns original cosmetic assets and licensing records.
Sharing Agent
Owns:

* NFC
* QR
* Deep links
* Web fallback

Backend Agent
Owns minimal cloud infrastructure.
Payments Agent
Owns:

* Apple IAP
* Google Play Billing
* Entitlements
* Receipt verification

Security Agent
Owns:

* Threat model
* Identity security
* Privacy
* API security

Legal/App Store Agent
Owns:

* IP review
* Asset licensing
* Store compliance
* Privacy requirements
* Terms

QA Agent
Owns:

* Automated testing
* Device testing
* Regression testing
* Release gates

DevOps Agent
Owns:

* GitHub
* CI/CD
* Signing
* Build pipelines
* Release automation

17. No-Code Owner Workflow
You remain the Product Owner.
You don't manually implement features.

```text
You
 ↓
Product decision
 ↓
Orchestrator Agent
 ↓
Specialized agents
 ↓
Git branches
 ↓
Automated tests
 ↓
Integration
 ↓
Release candidate
 ↓
You approve
```

Every agent must:

1. Read the current requirements.
2. Read architecture decisions.
3. Inspect existing implementation.
4. Make the smallest required change.
5. Write tests.
6. Run tests.
7. Update documentation.
8. Report changed files and validation results.

No agent should rewrite unrelated parts of the system.
18. v1 Release Gate
Amiro v1 is ready when this works:

```text
Person A
   │
   ├── creates identity
   ├── gets avatar
   ├── equips cosmetics
   └── taps phone
             │
             ↓
          Person B
             │
       ┌─────┴─────┐
       ↓           ↓
   App exists    No app
       ↓           ↓
  Native 3D      Web profile
   profile          ↓
       │        Add contact
       │            /
       └──────┬─────
              ↓
        Create Amiro
```

That is the product.
Everything else is secondary.
Amiro positioning
Amiro — Your digital identity, made wearable.
The strongest product decision from the critique is to make identity sharing the free, instant core experience and move cosmetic purchases into the retention layer. That gives Amiro a reason to exist before it asks users to spend money.
