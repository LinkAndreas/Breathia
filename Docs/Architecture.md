# Architecture

Breathia has two app targets — `Breathia` (iPhone, iPad, Mac) and `BreathiaWatch` — and a
`Shared` folder compiled into both. Code is organized in layers; each folder
states which layer it belongs to.

| Layer | Contains | May depend on |
|---|---|---|
| **Domain** | Models (`SessionRecord`, `Technique`, `AppSettings`, …), pure logic (`BreathingClock`, `BiofeedbackAnalyzer`, `HRVCalculator`, `SessionRecordFactory`, `ReviewPromptPolicy`, `FeedbackEmail`), and the contracts infrastructure fulfils (`SessionRepository`, `SettingsRepository`, `HeartRateSource`, `LiveHeartRateProviding`, `MindfulMinutesService`, `WorkoutSessionControlling`, `BreathingCuePlaying`, `ReviewPromptRepository`, `ReviewRequesting`, `FeedbackMailing`). | Foundation only |
| **Infrastructure** | Implementations of those contracts against Apple frameworks and storage: SwiftData, UserDefaults, Core Bluetooth, HealthKit, StoreKit, WatchConnectivity, haptics and sounds. In-memory versions for previews and tests. | Domain, system frameworks |
| **Stores** | Application state the screens read and the use cases they call — `SessionHistory`, `SettingsStore`, `HeartRateMonitor`, `MindfulMinutesStore`, `AppIconStore`, `BreathingSessionModel`, `BreathingSessionFactory`, `SessionRecorder`, `ReviewPrompter`; on the watch, `WatchSessionRunner`. | Domain contracts (never concrete infrastructure) |
| **Features / DesignSystem / Navigation** | SwiftUI screens and components; the navigation state and the layouts that show it. | Stores, Domain |
| **App** | The composition root (`AppDependencies`, `WatchDependencies`): the only place that picks concrete infrastructure and wires everything together. Nothing is put in the environment app-wide — on iPhone the views in `Navigation/Columns` give each screen only the stores it reads; on the watch, screens get what they need as parameters. | Everything |

## Folders

```
Shared/
  Domain/          Model/, Session/, Health/, Repositories/
  Infrastructure/  Persistence/ (UserDefaults), HealthKit/, WatchConnectivity/, InMemory/
  Stores/          SettingsStore, MindfulMinutesStore, BreathingSessionModel, BreathingSessionFactory, SessionRecorder
  DesignSystem/
Breathia/
  App/             Composition root
  Domain/          Repositories/, Sensor/, HeartRate/, AppIcon/, Rating/
  Infrastructure/  Persistence/SwiftData/, Bluetooth/, Sensor/, WatchConnectivity/, Feedback/, Rating/, InMemory/
  Stores/          SessionHistory, HeartRateMonitor, AppIconStore, ReviewPrompter
  Features/        One folder per screen area (Breathe, TechniqueDetail, Session,
                   SessionReport, History, Settings, Sensor, Onboarding)
  DesignSystem/    Components/, Headers/, Settings/, Layout/, Theme
  Navigation/  Preview/
BreathiaWatch/
  App/  Domain/  Infrastructure/  Stores/  Navigation/
  Features/        Techniques/, Session/ (Countdown/, Live/, Summary/), Health/
BreathiaWidgets/
  LiveActivity/    The activity and its views
```

Within a feature, the screen's root view sits at the top of its folder and the parts
of the screen are grouped in sub-folders named after what they make up — for example
`Session/Countdown/`, `Session/Live/` and `Session/Layout/`, or `Settings/Rows/` and
`Settings/Info/`. Platform-only parts go in `iOS/` or `Mac/` (`TechniqueDetail/`).
Every view is its own `View` struct in its own file, named after the type; helper
properties or functions returning `some View` aren't used. View modifiers and
presentation extensions on models (`HRVTrend+Presentation`) live next to the views
that use them.

## Platforms

`Breathia` is one multiplatform target: the same code builds a native macOS app. Differences
are handled with `#if os(...)` at the edges, never in the domain:

- **Layout** — Mac uses the iPad split view. Sessions and onboarding open as sheets there.
- **Infrastructure** — cue sounds without haptics (`SystemBreathingCuePlayer`), keeping the
  display awake during a session, the review prompt, mail, and device details each have a
  Mac branch.
- **iPhone only** — Apple Watch sync (`PhoneWatchSync`, WatchConnectivity), Live Activities
  (ActivityKit is importable on macOS but unavailable, so it's guarded by `os(iOS)`, not
  `canImport`). The Watch app and widget extension are embedded for iOS only.
- **Apple Health** — hidden on the Mac, where `HKHealthStore.isHealthDataAvailable()` is
  false; the Mac build signs with `Config/BreathiaMac.entitlements`, without HealthKit.
- Sessions recorded on a Mac are stored with `SessionSource.mac`.

## Running a session

Both devices run sessions with the same `BreathingSessionModel`. Each composition root
builds a `BreathingSessionFactory` with that device's heart-rate source (a Bluetooth heart-rate
sensor through `HeartRateMonitor` on iPhone, a HealthKit workout on Apple Watch), its cue player,
and a `SessionRecorder`; session screens only call `makeSession(for:)`. A recorded session
goes into History on iPhone, or to iPhone over WatchConnectivity from the watch, and to
Apple Health as mindful minutes when the user turned that on. Health access is requested
only when the user turns the setting on — never at the end of a session. On the watch,
`WatchSessionRunner` pairs each session with a workout and keeps it in Health only when the
session was recorded.

## Heart-rate data quality

Readings are screened before they reach a session, so History never stores noise:

- `MeasurementParser` reads the sensor-contact flags; `HeartRateMonitor` drops readings
  without skin contact and heart rates of 0, and shows the heart rate as unknown instead.
- `HRVCalculator` rejects RR intervals outside 300–2000 ms and beats that differ from the
  previous one by more than 20% (missed or extra beats). After three rejections in a row it
  accepts the new rhythm, so a real change isn't filtered out forever.

## Tests

`BreathiaTests` (Swift Testing, hosted by the app) covers the domain and stores: the breathing
clock, HRV, packet parsing, record statistics, `BreathingSessionModel`'s recording rules,
`SessionHistory`, settings decoding, and the rating policy. Tests use the in-memory
repositories and inject the clock, so they need no device, sensor, or HealthKit.

## Navigation

Navigation is split by concern (`Breathia/Navigation/`):

- **`AppNavigator`** — where the user is: an `@Observable` state with the selected section,
  each section's opened page (`AppDetail`), the modals, the running session, and the question
  asked over the app (`AppDialog`), plus the intents that change them. Knows destinations,
  not screens or stores.
- **Layouts** (`Navigation/Layout/`) — plain SwiftUI. `AppRootView` picks `TabLayout` (a
  `TabView` with a `NavigationStack` per section, whose path is the section's opened page)
  in a narrow window and `SplitLayout` (a three-column `NavigationSplitView`) in a wide one.
  Both read the same state, so a page stays open when the window changes width. Sheets, the
  onboarding cover, and alerts are attached in `AppRootView`. On iPhone and iPad the running
  session is a layer over the whole window (`SessionLayer`) rather than a full-screen cover,
  which iPhone Duo left sideways after unfolding; on the Mac it's a sheet.
- **Columns** (`Navigation/Columns/`) — what each section's list and detail page show: they
  build the screen, give it only the stores it reads (from `AppScreens`), and connect what it
  reports to the navigator, stores, and flows.
- **Flows** (`Navigation/Flows/`) — conversations that span screens, such as `RatingFlow`.
- Onboarding's Health step is built by `HealthAccessStep.make(mindfulMinutes:settingsStore:)`
  next to the onboarding screens.

`AppDependencies` creates all of them and shows onboarding on first launch.

## Rating and feedback

Breathia follows Apple's guidance for ratings (App Review Guideline 5.6.1 and the Human
Interface Guidelines): it uses only the system's rating dialog, never a rating prompt of its
own, and never asks a question first that sends only happy users to the App Store.

- **When** — `ReviewPromptPolicy`: after a recorded session that lasted at least 80% of its
  planned length, once the user has 3 recorded sessions on at least 2 different days; at most
  once per app version and 120 days apart. The system itself shows the dialog at most three
  times a year.
- **How** — `RatingFlow` waits until the session screen has closed and History has settled,
  checks that nothing is in the way (no session, sheet or question, `AppNavigator.isCalm`),
  records the request and asks `AppRootView` to call SwiftUI's `requestReview`.
- **Always available** — Settings › Feedback: *Rate Breathia* opens the App Store on writing a
  review (`AppStoreLinks.writeReview`), *Send Feedback* opens an email to
  feedback@linkandreas.de with the app version, build, device model, system version and
  language at the bottom, and *Share Breathia* shares the App Store link.

Requests are stored in UserDefaults (`com.breathia.reviewPrompt.lastRequestDate` and
`…lastRequestVersion`). Someone asked by a version before 1.7 counts as asked on the day they
update.

## History storage

Completed sessions are stored with **SwiftData, on the device only** (CloudKit
sync disabled).

- `SessionRecord` (Domain) is a plain value type used by the whole app.
- `SessionEntity` (Infrastructure) is the persisted `@Model`, defined in the
  versioned `HistorySchemaV1`. Conversion lives in `SessionEntity+Record.swift`;
  no other layer sees the entity.
- `SwiftDataSessionRepository` implements `SessionRepository`; `SessionHistory`
  only knows the protocol.

To change the stored shape, add `HistorySchemaV2` and a stage in
`HistoryMigrationPlan`; don't edit a shipped schema.

## Localization

All text lives in `Shared/Localizable.xcstrings` (English, German, Spanish,
French), shared by both apps. Code uses semantic keys, never English text:

- `<screen>.<name>` for text on one screen — `history.detail.deleteSession`,
  `sensor.status.connecting`, `watch.summary.avg`.
- `common.<name>` for text shared by several screens — `common.cancel`, `common.done`.
- `technique.<id>.<field>` for technique copy — `technique.box.name`,
  `technique.box.steps.2` (list items are 1-based).
- `cue.<name>` for the short in-session instructions (`BreathCue`) — `cue.hum`,
  `cue.throughNose`. They're resolved at runtime, so they're marked *manual*.
- Interpolated values follow the key: `Text("sensor.connectingTo \(name)")` has the key
  `sensor.connectingTo %@`; the English value carries the sentence.

English is the catalog's source value, so a key missing from the catalog shows
up as the raw key in the UI. Keys only resolved at runtime (the tab titles in
`AppTab.titleKey`) can't be extracted by the compiler and are marked *manual* in
the catalog.

## Live Activity

A running session on iPhone shows as a Live Activity on the Lock Screen, in the
Dynamic Island, and in Apple Watch's Smart Stack: the technique's name and the session's
progress bar. `BreathingSessionModel` reports a `SessionActivitySnapshot` through
`SessionActivityReporting` when the session starts and on pause or resume, and ends it
when the session ends or is left. The bar fills by itself from the session's end date,
so the activity stays correct while iOS suspends the app. `ActivityKitSessionActivity`
(iPhone infrastructure) turns that into ActivityKit calls, sent strictly in order, and
removes activities left behind by a session the app was quit during. Apple Watch uses
`NoSessionActivity`.

- `LiveActivityShared/BreathingActivityAttributes.swift` — compiled into the app and the
  extension.
- `BreathiaWidgets/` — the WidgetKit extension that draws the activity. It shows
  only the technique's name, which the app sends already localized, so it needs no
  string catalog.
