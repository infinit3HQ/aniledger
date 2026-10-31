# Beta Release V.0.5.1

**Tag:** v.0.5.1  
**Published:** 2026-10-31

## Summary

AniLedger v.0.5.1 is a bug-fix release on top of v.0.5. It fixes the anime detail sheet resetting when you finish the last episode, cleans up inconsistent buttons on the Seasons, Discover, and Library screens, and makes cover images cache properly.

## Highlights

- ✅ **Finishing an anime works again**: Pressing Increment Episode on the last episode keeps the "Complete Anime?" prompt open and the progress you just set.
- 🎨 **Consistent controls**: The Seasons, Discover, and Library headers now use matching native macOS buttons.
- 🖼 **Faster image loading**: Cover images are now cached on disk instead of downloading again on every launch.

## Full Changelog

**Improved**

- Seasons header: the season picker, year buttons, and Current button share one style and size
- Discover filters: Genres and Format use the standard macOS menu button, turn the accent color when active, and show the number of active filters
- Library toolbar: removed the extra chevron on the Sort button so it matches the other toolbar buttons

**Fixed**

- Fixed the anime detail sheet resetting progress and closing the "Complete Anime?" prompt after incrementing the last episode. The sheet's data was rebuilt every time the screen behind it refreshed.
- Fixed the year showing as "2,026" instead of "2026" in the Seasons header
- Fixed the image cache using a relative folder path. When the app was opened from Finder, images were never saved to disk. The cache now lives in `~/Library/Caches/com.aniledger/image_cache`.

## Migration & Notes for Users

- No migration steps required. Your library and login are kept.
- Replace the app in your Applications folder with the new version from the DMG.

## Known Issues

- The app is ad-hoc signed and not notarized. On first launch, right-click the app and choose **Open**, or allow it in **System Settings → Privacy & Security**.
- Requires macOS 26.0 or later.
- The unit tests in `AniLedgerTests/` are not yet attached to an Xcode test target.

## Assets

- [AniLedger-Installer.dmg](https://github.com/infinit3HQ/aniledger/releases/download/v.0.5.1/AniLedger-Installer.dmg)
- [AniLedger-0.5.1.dmg](https://github.com/infinit3HQ/aniledger/releases/download/v.0.5.1/AniLedger-0.5.1.dmg)
