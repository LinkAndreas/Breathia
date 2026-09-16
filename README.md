# Breathia

Guided breathing for iPhone, iPad, Mac and Apple Watch, with live heart-rate and HRV biofeedback.

Breathia paces you through 24 breathing techniques — from Box Breathing and the Physiological
Sigh to Resonance and Alternate Nostril Breathing — with visual, haptic and sound cues.
Connect a Bluetooth chest strap such as the Polar H10 to see your heart rate and HRV respond
while you breathe.

## Features

- **24 techniques**, each with how it works, what it's best for, step-by-step practice notes
  and safety guidance
- **Live biofeedback** — heart rate and HRV (RMSSD or SDNN) from a Bluetooth heart-rate sensor
- **Apple Watch app** — runs sessions on the wrist with heart rate from a workout session, and
  syncs them to iPhone
- **Live Activity** — elapsed time and Pause/Stop controls on the Lock Screen and in the Dynamic Island
- **History** — every session with its heart-rate and HRV trends, stored on device with SwiftData
- **Apple Health** — optionally saves sessions as mindful minutes
- **iPad and Mac** — three-column split view; on the Mac, a native app with sound cues and the
  same Bluetooth sensor support
- **Localized** in English, German, Spanish and French

Breathia has no account and no server; your data stays on your devices.

## Requirements

- Xcode 27 or later
- iOS / iPadOS 27, macOS 27 and watchOS 27

The only dependency, [NavigationKit](https://github.com/LinkAndreas/NavigationKit), is fetched
by Swift Package Manager when you open the project.

## Getting started

```bash
git clone <this repository>
open Breathia.xcodeproj
```

Choose the **Breathia** scheme and run it on a simulator or on *My Mac* — no further setup is
needed. Without a sensor, the simulator build uses a simulated heart-rate source.

### Running on a device

Signing is configured in [`Config/Signing.xcconfig`](Config/Signing.xcconfig) and can be
overridden locally without touching the project file:

```bash
cp Config/Local.xcconfig.example Config/Local.xcconfig
```

Then set your `DEVELOPMENT_TEAM` and a `BUNDLE_ID_PREFIX` you own in `Config/Local.xcconfig`
(it's git-ignored). The targets use `<prefix>.breathia`, `<prefix>.breathia.watchkitapp` and
`<prefix>.breathia.widgets`.

### In-app purchases

The optional *Support the Developer* tips run against the local StoreKit configuration
[`Config/Breathia.storekit`](Config/Breathia.storekit), selected in the Breathia scheme. See
[`Docs/AppStoreConnect-Support.md`](Docs/AppStoreConnect-Support.md) for the App Store Connect setup.

## Tests

`BreathiaTests` covers the logic where mistakes are costly: the breathing clock, HRV
calculation and artifact filtering, heart-rate packet parsing, session recording, History,
settings compatibility, and the rating prompt.

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

The code is layered into Domain, Infrastructure, Stores and Features, with Apple frameworks
kept behind protocols. [`Docs/Architecture.md`](Docs/Architecture.md) describes the layers,
navigation, session flow, Live Activity and localization.

## Localization

All user-facing text lives in [`Shared/Localizable.xcstrings`](Shared/Localizable.xcstrings)
under semantic keys (for example `technique.box.name`), with English as the source language.
App name and permission prompts are in [`Shared/InfoPlist.xcstrings`](Shared/InfoPlist.xcstrings).

## Disclaimer

Breathia is a wellness tool. It is not a medical device and isn't intended to diagnose or treat
any condition. Some techniques aren't suitable for everyone — read each technique's safety
note, and stop if you feel unwell.

## License

Breathia is available under the MIT license. See [LICENSE](LICENSE).

The name "Breathia" and the app icon identify the published app; please use your own name and
icon if you ship a fork on the App Store.
