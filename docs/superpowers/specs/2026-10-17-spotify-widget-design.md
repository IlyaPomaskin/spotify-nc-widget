# Spotify Notification Center Widget — Design

## Intent

Control Spotify from the macOS Notification Center sidebar without switching to the Spotify app. Personal use, runs locally, not distributed.

## Goals

- WidgetKit widget in all three families: `systemSmall`, `systemMedium`, `systemLarge`.
- Shows album cover, track name, artist name (large also shows album name).
- Buttons: previous, play/pause, next — interactive (App Intents, macOS 14+).
- Track timeline: progress bar, live-animating while playing, frozen while paused. Medium/large show elapsed and remaining time labels.
- Empty state ("Not playing") when Spotify is closed or has no track; play button launches Spotify.

## Non-goals

- Seeking (widgets cannot be dragged), volume, shuffle/repeat, likes.
- Players other than Spotify.
- App Store distribution.

## Anti-goals

- Polling every second or reloading the widget timeline every second (burns budget, gets throttled).
- A visible Dock icon or main window.

## Architecture

Two targets in one Xcode project, generated from an XcodeGen `project.yml`:

1. **Host app (`SpotifyWidget`)** — `LSUIElement` menu bar agent (menu: Quit). Starts at login via `SMAppService.mainApp`.
   - Subscribes to distributed notification `com.spotify.client.PlaybackStateChanged` (userInfo: Name, Artist, Album, Player State, Playback Position, Duration, Track ID).
   - On each event and at launch, queries Spotify via AppleScript (`NSAppleScript`) for authoritative state incl. `player position`, `duration`, `artwork url`.
   - Downloads artwork (cache by track ID), writes `NowPlaying` JSON + `artwork.jpg` to App Group container, calls `WidgetCenter.shared.reloadAllTimelines()`.
   - Listens for distributed notifications posted by widget intents (`<bundle>.previous`, `.playPause`, `.next`) and executes the AppleScript command.
   - Entitlements: App Group, `com.apple.security.automation.apple-events`; `NSAppleEventsUsageDescription` in Info.plist. Not sandboxed (simplest for Apple Events + distributed notification receipt).

2. **Widget extension (`SpotifyWidgetExtension`)** — sandboxed, App Group.
   - Timeline provider reads shared JSON + artwork; single entry, policy `.never` (host drives reloads).
   - Timeline uses `ProgressView(timerInterval:countsDown:)` and `Text(timerInterval:)` for live progress while playing; static values while paused.
   - Buttons are `Button(intent:)` with App Intents that post a distributed notification to the host and optimistically flip play state is NOT done (host reload is source of truth).
   - Empty-state play button opens Spotify via `Link`/URL `spotify:`.

## Constraints

- macOS 14+ deployment target (interactive widgets). Machine runs macOS 27.
- Requires full Xcode selected via `xcode-select` and a signing team (Apple ID personal team) so the App Group entitlement is valid.
- First control triggers a one-time Automation permission prompt for Spotify.

## Builder-check decisions (Claude's calls)

- App Group ID is Team-ID-prefixed (`<TEAMID>.spotifywidget`) — valid for both free and paid teams on macOS 15+, no provisioning prompt.
- Reloads: Spotify only emits on state change; host coalesces events (~300 ms debounce) and skips reload if `NowPlaying` is unchanged. Budget exhaustion is an accepted risk to verify in testing.
- Never `tell application "Spotify"` unless `NSRunningApplication` shows it running (AppleScript would launch it).
- Empty-state play button: intent posts `.launchSpotify`; host opens Spotify via `NSWorkspace` (widget `Link` would route to the host app, not Spotify).
- Host observes with `DistributedNotificationCenter` `suspended = false` / `.deliverImmediately`.
- Commands are encoded in the notification name only (sandboxed sender cannot attach `userInfo`).
- Spotify `duration` is ms, `player position` is seconds — normalize to seconds.
- If the host is quit, widget buttons do nothing; acceptable (host autostarts at login).

## Left to the builder

- Visual styling details, spacing, fonts, container background.
- Bundle IDs (default `com.ilyapomaskin.spotifywidget`), App Group name.
- Install location (`/Applications` copy via a make/script target).
