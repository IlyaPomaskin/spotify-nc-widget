# Spotify Notification Center Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** WidgetKit widget (S/M/L) in Notification Center showing Spotify cover, artist, track, live timeline, and prev/play-pause/next buttons.

**Architecture:** Menu bar agent app reads Spotify via AppleScript on `com.spotify.client.PlaybackStateChanged`, writes `NowPlaying` JSON + artwork into a Team-ID-prefixed App Group container, and reloads widget timelines. Widget renders from the container; its App Intents post distributed notifications that the host turns into AppleScript commands. Pure logic lives in a local Swift package so it is testable with `swift test`.

**Tech Stack:** Swift 6, SwiftUI, WidgetKit, AppIntents, ServiceManagement, XcodeGen, XCTest.

**Spec:** `docs/superpowers/specs/2026-10-17-spotify-widget-design.md`

## Global Constraints

- Deployment target macOS 14.0.
- Bundle IDs: host `com.ilyapomaskin.spotifywidget`, widget `com.ilyapomaskin.spotifywidget.widget`.
- App Group: `$(TeamIdentifierPrefix)spotifywidget` in entitlements; runtime value read from Info.plist key `AppGroupID`.
- Host: `LSUIElement = YES`, not sandboxed, `com.apple.security.automation.apple-events`, `NSAppleEventsUsageDescription = "Controls Spotify playback from the widget."`.
- Widget: sandboxed, App Group only.
- Never send Apple Events to Spotify unless `NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client")` is non-empty.
- Spotify `duration` is milliseconds, `player position` is seconds; model stores seconds.
- Distributed notification names carry the command; no `userInfo`.
- Code style: guard clauses, no nested ternaries, named constants, no comments except for hacks.
- No git commits unless the user asks.

## Review Focus

1. Spotify not running at host launch → widget shows "Not playing", Spotify is NOT launched. (Task 3, manual check 1)
2. Spotify quit while playing → `Player State` = `Stopped` notification → widget switches to empty state. (Task 1 `test_parse_stopped`, Task 3 manual check 4)
3. Paused track → bar frozen at correct position, not animating. (Task 1 `test_progress_paused`)
4. Track without artwork URL (local file / some podcasts) → placeholder cover, no crash. (Task 1 `test_parse_missing_artwork`)
5. Long titles → single line, truncated tail, layout intact in all sizes. (Task 4 preview check)

## File Structure

```
project.yml                                  XcodeGen spec (2 targets + package)
Makefile                                     gen / build / install
NowPlayingKit/Package.swift                  local package, macOS 14
NowPlayingKit/Sources/NowPlayingKit/
  NowPlaying.swift                           model + AppleScript parsing + progress math
  NowPlayingStore.swift                      read/write JSON + artwork in a container URL
  PlayerCommand.swift                        command enum + distributed notification names
  AppGroup.swift                             container URL from Info.plist AppGroupID
NowPlayingKit/Tests/NowPlayingKitTests/*.swift
App/SpotifyWidgetApp.swift                   MenuBarExtra (Quit), login item registration
App/SpotifyController.swift                  AppleScript fetch + commands
App/NowPlayingMonitor.swift                  observes Spotify + commands, debounces, writes, reloads
App/ArtworkCache.swift                       downloads artwork per trackID
App/Info.plist, App/App.entitlements
Widget/SpotifyWidgetBundle.swift             @main, Widget config, supportedFamilies S/M/L
Widget/Provider.swift                        TimelineProvider, policy .never
Widget/PlayerIntents.swift                   Previous/PlayPause/Next/LaunchSpotify AppIntents
Widget/Views/{Small,Medium,Large,Empty,Controls,Timeline}View.swift
Widget/Info.plist, Widget/Widget.entitlements
```

---

### Task 1: NowPlayingKit package

**Files:** all of `NowPlayingKit/`

**Interfaces — Produces:**
```swift
public struct NowPlaying: Codable, Equatable, Sendable {
  public enum State: String, Codable, Sendable { case playing, paused, stopped }
  public let trackID, title, artist, album: String
  public let durationSeconds: Double
  public let positionSeconds: Double
  public let capturedAt: Date
  public let state: State
  public let artworkURL: URL?
  public static let fieldSeparator: String            // "\u{1F}"
  public static func parse(appleScriptOutput: String, capturedAt: Date) -> NowPlaying?
  public var startDate: Date { get }                  // capturedAt - position
  public var endDate: Date { get }                    // startDate + duration
  public func elapsedSeconds(at date: Date) -> Double // clamped 0...duration; frozen when not playing
}
public struct NowPlayingStore: Sendable {
  public init(containerURL: URL)
  public func save(_ nowPlaying: NowPlaying?) throws  // nil removes file
  public func load() -> NowPlaying?
  public func saveArtwork(_ data: Data, trackID: String) throws
  public func artworkFileURL(trackID: String) -> URL?   // nil if missing
}
public enum PlayerCommand: String, CaseIterable, Sendable {
  case previous, playPause, next, launchSpotify
  public var notificationName: Notification.Name    // "com.ilyapomaskin.spotifywidget.command.<rawValue>"
}
public enum AppGroup { public static func containerURL() -> URL? }
```
AppleScript output field order: `state, trackID, title, artist, album, durationMs, positionSeconds, artworkURL` joined by `fieldSeparator`. `state` values are Spotify's `playing`/`paused`/`stopped`. Returns `nil` on wrong field count, `stopped`, or non-numeric duration/position.

- [ ] **Step 1: Write failing tests** in `NowPlayingKitTests`:
  - `test_parse_playing`: `"playing␟spotify:track:1␟Midnight City␟M83␟Hurry Up␟243000␟91.5␟https://i.scdn.co/a.jpg"` → durationSeconds 243, positionSeconds 91.5, state .playing, artworkURL set.
  - `test_parse_stopped` → nil.
  - `test_parse_missing_artwork`: empty last field → artworkURL nil, non-nil result.
  - `test_parse_malformed`: 3 fields → nil; `"abc"` duration → nil.
  - `test_progress_playing`: captured at t0, position 10, elapsed at t0+5 == 15; at t0+10_000 == duration (clamped).
  - `test_progress_paused`: state .paused, elapsed at t0+60 == position.
  - `test_store_roundtrip`: save → load equal; save(nil) → load nil; artwork save → `artworkFileURL` non-nil, unknown trackID → nil. Use a temp dir.
  - `test_command_names`: `PlayerCommand.next.notificationName.rawValue == "com.ilyapomaskin.spotifywidget.command.next"`.
- [ ] **Step 2:** `cd NowPlayingKit && swift test` → compile failure.
- [ ] **Step 3:** Implement. Artwork file name: track ID with non-alphanumerics replaced by `_`, `.jpg`. JSON via `JSONEncoder` with `.iso8601` dates, file `nowplaying.json`.
- [ ] **Step 4:** `swift test` → all pass.

### Task 2: Xcode project + host skeleton

**Files:** `project.yml`, `Makefile`, `App/SpotifyWidgetApp.swift`, `App/Info.plist`, `App/App.entitlements`, `.gitignore`

- [ ] **Step 1:** `brew install xcodegen` if missing.
- [ ] **Step 2:** `project.yml`: targets `SpotifyWidget` (application) embedding `SpotifyWidgetExtension` (app-extension, `NSExtensionPointIdentifier = com.apple.widgetkit-extension`), both depend on package `NowPlayingKit`, `CODE_SIGN_STYLE: Automatic`, `DEVELOPMENT_TEAM` from env `TEAM_ID`. Info.plist `AppGroupID = $(TeamIdentifierPrefix)spotifywidget` in both.
- [ ] **Step 3:** `SpotifyWidgetApp`: `MenuBarExtra("Spotify Widget", systemImage: "music.note")` with Quit; on launch `try? SMAppService.mainApp.register()`.
- [ ] **Step 4:** `Makefile` targets: `gen` (xcodegen), `build` (`xcodebuild -scheme SpotifyWidget -configuration Release -derivedDataPath build -allowProvisioningUpdates`), `install` (copy `.app` to `~/Applications`, `open` it).
- [ ] **Step 5:** `make gen build` → `** BUILD SUCCEEDED **`.

### Task 3: Host monitoring + commands

**Files:** `App/SpotifyController.swift`, `App/NowPlayingMonitor.swift`, `App/ArtworkCache.swift`, wire into `SpotifyWidgetApp`

**Interfaces — Produces:**
```swift
@MainActor final class SpotifyController {
  var isRunning: Bool { get }
  func fetch() -> NowPlaying?                 // nil if not running / stopped / script error
  func perform(_ command: PlayerCommand)      // launchSpotify uses NSWorkspace; others AppleScript
}
@MainActor final class NowPlayingMonitor { init(controller:store:artwork:); func start() }
actor ArtworkCache { init(store:); func ensureArtwork(for: NowPlaying) async }
```

- [ ] **Step 1:** `SpotifyController.fetch` runs one `NSAppleScript` returning the joined fields (see Task 1 order) and parses via `NowPlaying.parse`. Commands: `previous track`, `playpause`, `next track`.
- [ ] **Step 2:** `NowPlayingMonitor.start`: observe `com.spotify.client.PlaybackStateChanged` and each `PlayerCommand.notificationName` on `DistributedNotificationCenter.default()` with `suspensionBehavior: .deliverImmediately`; refresh at start. Refresh is debounced 300 ms; ensures artwork; saves; calls `WidgetCenter.shared.reloadAllTimelines()` only if the saved value differs from the last one (compare ignoring `capturedAt` and `positionSeconds` drift < 2 s).
- [ ] **Step 3:** `make build install`. Manual checks:
  1. Spotify closed → launch host → Spotify stays closed; `nowplaying.json` absent.
  2. Start Spotify, play → JSON + artwork appear in `~/Library/Group Containers/<TEAMID>.spotifywidget/`.
  3. Post `com.ilyapomaskin.spotifywidget.command.next` from a one-line Swift script → Spotify skips.
  4. Quit Spotify → JSON removed.

### Task 4: Widget extension

**Files:** all of `Widget/`

**Interfaces — Consumes:** `NowPlaying`, `NowPlayingStore`, `AppGroup`, `PlayerCommand`.

- [ ] **Step 1:** Intents: `PreviousTrackIntent`, `PlayPauseIntent`, `NextTrackIntent`, `LaunchSpotifyIntent`; each `perform()` posts its command name via `DistributedNotificationCenter.default().postNotificationName(_:object:nil, userInfo:nil, deliverImmediately: true)`.
- [ ] **Step 2:** `Provider`: entry `{ date, nowPlaying: NowPlaying?, artwork: NSImage? }`; `getTimeline` returns one entry, `.never`. Placeholder/preview uses a sample `NowPlaying`.
- [ ] **Step 3:** Views per the approved mockup (`.superpowers/brainstorm/*/content/layout.html`):
  - `TimelineView`: playing → `ProgressView(timerInterval: startDate...endDate, countsDown: false)` + `Text(timerInterval:)` labels; paused → `ProgressView(value: elapsed, total: duration)` + static labels. Small hides labels. Accent `#1ED760`.
  - `ControlsView`: three `Button(intent:)` with `backward.fill`, `play.fill`/`pause.fill`, `forward.fill`.
  - Small: 44pt cover + title/artist row, bar, controls. Medium: 130pt cover left, text/bar/controls right. Large: full-width cover, title, "artist — album", bar, controls.
  - `EmptyView`: "Not playing" + `Button(intent: LaunchSpotifyIntent())`.
  - All text `.lineLimit(1)`, `.truncationMode(.tail)`. Missing artwork → `music.note` on gray rounded rect.
- [ ] **Step 4:** `#Preview(as: .systemSmall/.systemMedium/.systemLarge)` with a 120-char title; check truncation.
- [ ] **Step 5:** `make gen build install` → BUILD SUCCEEDED; add widget from Notification Center "Edit Widgets" in all three sizes.

### Task 5: End-to-end verification

- [ ] Play/pause, next, prev from each widget size → Spotify responds, widget updates < 2 s.
- [ ] Timeline animates while playing, freezes on pause, resets on track change.
- [ ] Quit Spotify → empty state; tap play → Spotify launches.
- [ ] Reboot/log out → host restarts at login.
