# Breathia

![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20iPadOS%20%7C%20macOS%20%7C%20watchOS-blue)
![Minimum OS](https://img.shields.io/badge/OS-27%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-27%2B-147EFB?logo=xcode&logoColor=white)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0D96F6)
![Tests](https://img.shields.io/badge/tests-Swift%20Testing-34C759)
![Localized](https://img.shields.io/badge/localized-EN%20%7C%20DE%20%7C%20ES%20%7C%20FR-8E8E93)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow)](LICENSE)

Guided breathing for iPhone, iPad, Mac and Apple Watch, with live heart-rate and HRV biofeedback.

Breathia paces you through 24 breathing techniques — from Box Breathing and the Physiological
Sigh to Resonance and Alternate Nostril Breathing — with a breathing circle and haptic and sound
cues. Connect a Bluetooth chest strap such as the Polar H10 to see your heart rate and HRV
respond while you breathe.

## Features

- **24 techniques** in seven categories, each with how it works, what it's best for,
  step-by-step practice notes and safety guidance
- **Guided sessions** — a breathing circle that grows and shrinks with the breath; its count goes
  up while you breathe in and hold, and down while you breathe out. The screen stays on during a
  session, and leaving the app pauses it, so time away isn't counted.
- **Live biofeedback** — heart rate and HRV (RMSSD or SDNN) from a Bluetooth heart-rate sensor,
  with missed beats and readings without skin contact filtered out
- **Live Activity** — elapsed and total time with Pause, Resume and End on the Lock Screen and in
  the Dynamic Island
- **Apple Watch app** — sessions on the wrist with heart rate from a workout and haptic cues,
  synced to History on iPhone
- **History** — every session with its heart-rate and HRV trends, stored on device
- **Apple Health** — optionally saves sessions as mindful minutes
- **iPad and Mac** — a three-column layout; on the Mac, a native app with soft sound cues and the
  same Bluetooth sensor support
- **Support the Developer** — optional tips and subscriptions that unlock nothing
- **Localized** in English, German, Spanish and French

## Privacy

Breathia has no account and no server. History and settings stay on your devices; sessions reach
Apple Health only if you turn that on. Read the privacy policy in
[English](https://www.linkandreas.de/breathia/privacy/en) or
[German](https://www.linkandreas.de/breathia/privacy/de), or write to
[privacy@linkandreas.de](mailto:privacy@linkandreas.de).

## Requirements

- Xcode 27 or later
- iOS / iPadOS 27, macOS 27 and watchOS 27
- For biofeedback: a Bluetooth LE heart-rate sensor using the standard Heart Rate service.
  HRV needs a sensor that sends beat-to-beat (RR) intervals, such as the Polar H10; every
  session also works without a sensor.

The only dependency, [NavigationKit](https://github.com/LinkAndreas/NavigationKit), is fetched
by Swift Package Manager when you open the project.

## Getting started

```bash
git clone <this repository>
open Breathia.xcodeproj
```

Choose the **Breathia** scheme and run it — no further setup is needed:

- **iOS Simulator** — has no Bluetooth, so it connects to a simulated heart-rate strap.
- **My Mac** — connects to a real sensor over Bluetooth.

The **BreathiaWatch** scheme runs the Apple Watch app.

### Running on a device

Signing is configured in [`Config/Signing.xcconfig`](Config/Signing.xcconfig) and can be
overridden locally without touching the project file:

```bash
cp Config/Local.xcconfig.example Config/Local.xcconfig
```

Then set your `DEVELOPMENT_TEAM` and a `BUNDLE_ID_PREFIX` you own in `Config/Local.xcconfig`
(it's git-ignored). The targets use `<prefix>.breathia`, `<prefix>.breathia.watchkitapp`,
`<prefix>.breathia.widgets` and `<prefix>.breathia.tests`.

### In-app purchases

The optional *Support the Developer* tips run against the local StoreKit configuration
[`Config/Breathia.storekit`](Config/Breathia.storekit), selected in the Breathia scheme. See
[`Docs/AppStoreConnect-Support.md`](Docs/AppStoreConnect-Support.md) for the App Store Connect setup.

## Tests

`BreathiaTests` covers the logic where mistakes are costly: the breathing clock, HRV calculation
and artifact filtering, heart-rate packet parsing, session recording, pausing and leaving the
app, History, settings compatibility, and the rating prompt. The tests need no device, sensor or
HealthKit.

```bash
xcodebuild test -project Breathia.xcodeproj -scheme Breathia -destination 'platform=macOS'
```

Or press ⌘U in Xcode.

## Project structure

| Folder | Contents |
|---|---|
| `Breathia/` | iPhone, iPad and Mac app (one multiplatform target) |
| `BreathiaWatch/` | Apple Watch app |
| `BreathiaWidgets/` | WidgetKit extension drawing the Live Activity |
| `Shared/` | Domain, stores, design system, string catalogs and the app icon — compiled into both apps |
| `LiveActivityShared/` | Live Activity attributes and intents, shared by the app and the widget extension |
| `Config/` | Entitlements, Info.plists, signing and the StoreKit configuration |
| `BreathiaTests/` | Unit tests (Swift Testing), hosted by the app |
| `Docs/` | Architecture and App Store Connect notes |

The code is layered into Domain, Infrastructure, Stores and Features, with Apple frameworks kept
behind protocols. [`Docs/Architecture.md`](Docs/Architecture.md) describes the layers, platform
differences, sessions, heart-rate data quality, navigation, History, the Live Activity,
localization and tests.

## Localization

All user-facing text lives in [`Shared/Localizable.xcstrings`](Shared/Localizable.xcstrings)
under semantic keys (for example `technique.box.name`), with English as the source language.
App name and permission prompts are in [`Shared/InfoPlist.xcstrings`](Shared/InfoPlist.xcstrings).

## Branches

The repository follows git flow:

- `main` — released versions, tagged (for example `v1.0.0`)
- `develop` — the next release; branch from here
- `feature/<name>` — one feature or fix, merged into `develop`
- `release/<version>` — final preparation, merged into `main` and back into `develop`

## Feedback

Questions and ideas are welcome at [feedback@linkandreas.de](mailto:feedback@linkandreas.de), or
open an issue.

## Disclaimer

Breathia is a wellness tool. It is not a medical device and isn't intended to diagnose or treat
any condition. Some techniques aren't suitable for everyone — read each technique's safety
note, and stop if you feel unwell.

## License

Breathia is available under the MIT license. See [LICENSE](LICENSE).

The name "Breathia" and the app icon identify the published app; please use your own name and
icon if you ship a fork on the App Store.
