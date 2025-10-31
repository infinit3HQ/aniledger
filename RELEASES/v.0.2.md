# Beta Release V.0.2

**Tag:** v.0.2

**Published:** 2025-10-31

## Summary

A small but meaningful update focused on stability, sync reliability, and usability improvements. This release improves offline sync behavior, fixes several UI and data edge-case bugs, and adds a few quality-of-life features requested by early testers.

## Highlights

- 🔁 Improved Sync Reliability
  - Redesigned sync flow to better handle intermittent network conditions.
  - Fewer duplicate entries after re-sync and improved conflict resolution for local edits.
- ⚡ Performance & Stability
  - Faster library load times for large libraries.
  - Reduced memory use during image-heavy screens.
- 🔎 Search & Discover Improvements
  - Added filters and sort options in Discover and Search views (season, format, score).
  - Improved search ranking and result stability.
- 🧭 UX / Accessibility
  - Better keyboard navigation and focus behavior across list and detail views.
  - Accessibility labels improved for VoiceOver users.
- 🧰 Offline Mode Enhancements
  - Offline edits now batch and sync more reliably when connection is restored.
  - Clearer offline indicator and sync status.
- 🐞 Bug Fixes
  - Fixed issue where progress could reset after a failed sync.
  - Fixed a crash when opening some anime detail pages with missing data.
  - Resolved a layout glitch in dark mode for the library cards.
- 🔐 Security / Auth
  - Hardened token refresh and Keychain handling to avoid stale auth and improve retry logic.

## Full changelog (selected)

- Added: filter and sort controls for Discover and Search.
- Improved: sync retry and conflict handling logic.
- Fixed: Library progress rollback during sync failure.
- Fixed: Crash in `AnimeDetail` when cover image metadata was missing.
- Improved: image caching behavior to reduce memory spikes.
- Improved: offline UI / indicator and sync status messages.
- Fixed: several visual layout bugs across macOS window sizes.

## Migration & Notes for users

- No forced data migrations are required. If you experience any inconsistent entries after updating, use "Re-sync from AniList" from Settings → Sync to refresh local data.
- If you are using offline mode and see duplicate entries after update, open the app while online and trigger a manual sync to reconcile.

## Known issues

- On very large libraries (> 2k items) some list animations may stutter. We're working on further optimizations.
- In rare cases, first-run sync may take longer on slow connections — please allow a minute on initial sync.

## Reference

See the `v.0.1` release for previous changes: https://github.com/infinit3HQ/aniledger/releases/tag/v.0.1
