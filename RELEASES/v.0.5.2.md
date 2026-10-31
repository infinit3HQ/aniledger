# Beta Release V.0.5.2

**Tag:** v.0.5.2  
**Published:** 2026-10-31

## Summary

AniLedger v.0.5.2 is a small UI release. The Library status tabs (Watching, Completed, Plan to Watch, On Hold, Dropped) have been redesigned to match the cleaner headers introduced in v.0.5.1.

## Highlights

- 🏷 **Compact Library tabs**: The status tabs are now pills that size to their labels. The selected list is filled with your accent color, and the count sits inside each tab.

## Full Changelog

**Improved**

- Library status tabs use compact pill buttons with a hover highlight
- The tab row scrolls sideways in narrow windows instead of squashing the labels

**Fixed**

- Fixed the Library tabs stretching across the whole window, which spread the labels far apart and made the selection underline very wide

## Migration & Notes for Users

- No migration steps required. Your library and login are kept.
- Replace the app in your Applications folder with the new version from the DMG.

## Known Issues

- The app is ad-hoc signed and not notarized. On first launch, right-click the app and choose **Open**, or allow it in **System Settings → Privacy & Security**.
- Requires macOS 26.0 or later.
- The unit tests in `AniLedgerTests/` are not yet attached to an Xcode test target.

## Assets

- [AniLedger-Installer.dmg](https://github.com/infinit3HQ/aniledger/releases/download/v.0.5.2/AniLedger-Installer.dmg)
- [AniLedger-0.5.2.dmg](https://github.com/infinit3HQ/aniledger/releases/download/v.0.5.2/AniLedger-0.5.2.dmg)
