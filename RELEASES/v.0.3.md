# Beta Release V.0.3

**Tag:** v.0.3
**Published:** 2025-11-11

## Summary

AniLedger v.0.3 introduces a robust notification system for airing anime, major improvements to error handling, and a more refined user interface. Banner image support brings richer visuals, and the auto-sync service is now more reliable than ever. This release also adds centralized app information management and removes sensitive documentation for improved security.

## Highlights

- ✨ **Airing Notifications**: Get timely alerts for upcoming anime episodes with the new AiringScheduleService and NotificationService.
- 🚀 **Error Handling**: More detailed error types, improved localization, and clearer user feedback throughout the app.
- 🎨 **UI Refinements**: Updated SearchView layout, redesigned AnimeDetailView close button, and consistent loading view sizing.
- 🖼️ **Banner Images**: Anime entities now feature banner images for a richer experience.
- 🔄 **Sync Reliability**: Thread-safe sync state management, better logging, and improved error handling in auto-sync.
- 🗂️ **App Info Management**: Centralized app metadata, version tracking, and new About/Release Notes views.
- 🧹 **Documentation Cleanup**: Sensitive configuration and documentation files removed for security.

## Full Changelog

**Added**

- Comprehensive app information management system (`AppInfo`, AboutView, ReleaseNotesView)
- AiringScheduleService and NotificationService for proactive episode notifications
- Banner image support for anime entities (Core Data, GraphQL, models)

**Improved**

- SearchView layout and frame configuration
- AnimeDetailView close button design and interaction
- Loading view sizing and frame consistency
- Auto-sync and sync service reliability (thread-safe state, logging, error handling)
- Error management and user feedback (KiroError, localization, reporting)

**Removed**

- Sensitive configuration and documentation files

**Fixed**

- No specific bug fixes reported in commits

## Migration & Notes for Users

- No migration steps required. Your existing data will be preserved.

## Known Issues

- No critical issues reported. Please report any bugs you encounter.

## Assets

- [AniLedger-Installer.dmg](https://github.com/infinit3HQ/aniledger/releases/download/v.0.3/AniLedger-Installer.dmg)

## Credits

- Thanks to the AniLedger development team for their work on these new features and improvements.
