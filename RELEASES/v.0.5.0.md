# Beta Release V.0.5

**Tag:** v.0.5.0  
**Published:** 2026-10-31

## Summary

AniLedger v.0.5 is a reliability release. The downloaded app can now log in without extra setup, the Library updates by itself instead of needing the Sync button, and several sync bugs that lost offline edits, brought back deleted entries, or left entries stuck have been fixed.

## Highlights

- 🔐 **Login that works out of the box**: AniLedger now uses AniList's implicit grant. It only needs the app's public client ID, so the DMG logs in without any setup and no client secret ships with the app.
- 🔄 **Library updates by itself**: Changes made in the detail sheet, Search, Discover, or by a background sync appear in the Library automatically. You no longer need to press Sync to see them.
- 💬 **Sync errors no longer hide your library**: A failed sync shows a small banner with Retry and Dismiss buttons. Your local library stays visible.
- 💾 **Offline edits are kept**: Several changes to the same anime made while offline (for example progress, then score) are now all sent to AniList.
- 🚪 **Expired logins handled**: If AniList rejects your login (expired or revoked), AniLedger returns you to the login screen instead of failing on every screen.
- 💻 **Universal app**: The DMG now runs natively on both Apple Silicon and Intel Macs.

## Full Changelog

**Added**

- Implicit-grant OAuth login (`response_type=token`); the access token is read from the redirect URL
- Automatic Library reload when anime or library entries change in Core Data
- Non-blocking error banner on the Library screen with Retry and Dismiss
- App-wide sign-out when AniList reports an expired or revoked token
- `SaveMediaListEntryMutation`, which sends status, progress, and score together
- Lookup of the AniList entry ID before deleting, for entries that were added offline

**Improved**

- Sync calls now run one after another instead of being skipped while another sync is running
- The user profile is loaded before syncing if the app was launched offline
- Network errors, timeouts, rate limits, and server errors keep queued changes for the next attempt instead of counting as failures
- Library and detail-sheet actions look up the current entry, so they work right after a sync changes its ID
- Release build script stops on build errors, removes the previous build first, embeds the client ID, re-signs the app, and builds for both architectures

**Fixed**

- Fixed offline edits to the same anime overwriting each other
- Fixed a change made during an in-flight sync request being dropped
- Fixed entries getting stuck and never refreshing from AniList after 5 failed sync attempts
- Fixed deleted entries coming back after a sync, and deletes of offline-added entries never reaching AniList
- Fixed "User anime not found" errors when moving, deleting, or editing an entry right after a sync
- Fixed "User not authenticated" errors after launching the app offline
- Fixed the Library error screen's Retry button doing nothing
- Fixed the Sync button sometimes doing nothing when a background sync was running
- Fixed "Clear data" leaving deleted items on screen until a refresh

**Removed**

- Client secret handling (`ANILIST_CLIENT_SECRET`); it is no longer used anywhere

## Migration & Notes for Users

- **You may need to log in again** after updating, because macOS can treat the newly signed app as a different app when reading the saved login. Your library is kept.
- Changes waiting to sync from v.0.4 are kept and sent with the new sync logic.
- **For developers building from source:** set only `ANILIST_CLIENT_ID` (Xcode scheme, or `.env` for `./scripts/build-dmg.sh`). The AniList client's redirect URI must be `aniledger://auth-callback`. The client secret is not needed.

## Known Issues

- The app is ad-hoc signed and not notarized. On first launch, right-click the app and choose **Open**, or allow it in **System Settings → Privacy & Security**.
- Requires macOS 26.0 or later.
- The unit tests in `AniLedgerTests/` are not yet attached to an Xcode test target.

## Assets

- [AniLedger-Installer.dmg](https://github.com/infinit3HQ/aniledger/releases/download/v.0.5.0/AniLedger-Installer.dmg)
- [AniLedger-0.5.0.dmg](https://github.com/infinit3HQ/aniledger/releases/download/v.0.5.0/AniLedger-0.5.0.dmg)

## Credits

- Thanks to everyone who reported sync issues on the Library screen.
