# Profile and music app screens

The existing profile and leaf music icons are unchanged. Their public scene paths and UIDs are retained; the two apps now open full-window overlays over the existing world, through the phone handler. Closing restores the existing scene, pause ownership and input state. The original resting phone preview is unchanged.

## Profile

The profile uses the inventory's ivory/navy/teal theme, an identity/portrait card, wallet, live health and mana bars, current dash capacity, progression, academic fields and a scrollable spell repertoire with equipped labels. Values come from Player_Global_Data and the local Player. It adds no fictional combat statistics or XP thresholds. Missing role/study fields and empty spell lists have explicit states; long identity text wraps and retains full text in tooltips. Mouse wheel, controller directions, arrow keys and Page Up/Down scroll the details. Live values refresh while the UI owns pause.

## Music

The music screen has a library, a native drawn record visual, authored song title/artist, timeline, play/pause and volume. It references the existing Skandal / Hujan audio and local lyric-file metadata; no placeholder songs or cover art are invented. Previous/Next are disabled for the current one-track library. Empty libraries safely disable playback. The scene exports tracks, track_titles and track_artists for future authored entries; fallback titles derive from filenames.

Music does not autoplay on opening. A PhoneMusicPlayer AudioStreamPlayer belongs to the current world and processes while the UI is paused. Playback continues after closing the app, and ends when that world is freed. Volume affects this player only. Paused seeks are retained and applied on resume; natural completion resets the timeline for replay. No music save schema or global audio-setting change is introduced.

## Files and integration

- scenes/ui/player-stats-ui/player-stats-ui.tscn and .gd: profile presentation; existing UserStatsUI class retained.
- scenes/ui/music-ui/music-selection-ui.tscn and .gd: library, record visual and actual audio controls.
- scenes/ui/phone-ui/phone-app-page.gd: shared native Control layout, theme and close handling.
- scenes/ui/phone-ui/phone-app-overlay.gd: CanvasLayer/modal ownership and cleanup on world exit.
- scenes/ui/phone-ui/phone-ui.gd and .tscn: profile/music routing; icon textures and placements unchanged.
- tests/profile-music-ui.gd and .tscn: native phone-icon, layout and playback acceptance checks.

## Verification

2026-10-30, Godot 4.7.2. Native renderer checks at 1280×720 and 1920×1080: **33 checks, 0 failures, engine exit 0**. Coverage includes actual phone-icon clicks, same-world pause, live profile updates, controller scrolling, playback/pause, paused seek/resume position, natural track completion, playback after closing, empty library, long identity/empty repertoire and world-exit modal cleanup. Existing phone/input regression: 23 checks, 0 failures. Existing 58 ObjectDB / 25 resources-in-use shutdown diagnostics remain. Physical-controller hardware and audible output-device listening are not claimed by these automated checks.

```bash
flatpak run org.godotengine.Godot --path . tests/profile-music-ui.tscn -- --quest-test-mode --capture-apps
```

Fixtures require the isolated test flag, use process-local profile data and do not write campaign saves. Omit --capture-apps to avoid rewriting screenshots.

| Screen | 1280×720 | 1920×1080 |
| --- | --- | --- |
| Profile | [Preview](previews/profile-music/profile-1280x720.png) | [Preview](previews/profile-music/profile-1920x1080.png) |
| Music | [Preview](previews/profile-music/music-1280x720.png) | [Preview](previews/profile-music/music-1920x1080.png) |

[Long profile identity at 720p](previews/profile-music/profile-long-identity-1280x720.png).
