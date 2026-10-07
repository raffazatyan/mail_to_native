## 0.1.0

* Initial release.
* `MailTo.installedApps()` — mail apps installed on the device.
* `MailTo.compose()` — open a mail app's compose screen prefilled.
* `MailTo.pickApp()` / `MailTo.pickAndCompose()` — native picker dialog
  (`UIAlertController` on iOS, `AlertDialog` on Android).
* Apple Mail composes through `MFMailComposeViewController`, so it is not
  hijacked by whichever app owns the `mailto:` scheme.

## 0.1.1

* Added Mail.ru to the iOS client list (scheme `mailru-mail`, unverified — see
  README). Android detects it automatically.
* Fixed per-client compose query keys: Spark takes `recipient`, Airmail takes
  `plainBody`. Both previously received `to`/`body` and dropped them.

## 0.2.0

* `pickApp` / `pickAndCompose` now show a native one-button alert when no mail
  app is installed, so callers need no empty-list branch. New optional
  `emptyMessage`, `okLabel` and `showEmptyAlert` parameters.
* `pickAndCompose` no longer short-circuits on an empty list — it hands the
  case to the platform dialog.

## 0.3.0

* Redesigned the Android picker: a rounded bottom sheet with a drag handle and
  each app's launcher icon, replacing the plain `AlertDialog` list. Follows the
  system light/dark setting. Drawn programmatically — no Material dependency
  and no requirement on the host activity's theme.
* The "no mail app" state now uses the same sheet instead of a separate dialog.
* `cancelLabel` is documented as iOS-only; the Android sheet dismisses by
  scrim tap or back press.

## 0.4.0

* The Android picker is now a centred dialog instead of a bottom sheet,
  matching the iOS `.alert` picker. Rounded on all corners, no drag handle,
  width capped at 400dp. Icons, ripple rows and dark-mode support unchanged.

## 0.5.0

* The picker no longer auto-selects when a single mail app is installed — the
  dialog always appears, so the new "other apps" entry stays reachable.
* Added an "other apps" entry to the picker and to the "no mail app" dialog. It
  opens the system share sheet: `UIActivityViewController` on iOS (subject
  carried through a `UIActivityItemSource`), an `ACTION_SEND` chooser on
  Android. New `otherAppsLabel` and `showOtherApps` parameters.
* Added `MailTo.share(message)` for calling the share sheet directly, and
  `MailApp.isOther` / `MailApp.otherAppsId` to identify the entry.
* The Android "no mail app" dialog now has proper OK / "other apps" buttons.

## 0.6.0

* Added `ShareMetadata` — fills the share sheet's header via `LPLinkMetadata`
  on iOS: icon, bold title, grey subtitle. Without it iOS shows a bare app icon
  and no title, since a plain text item carries no preview.
* The header icon defaults to the host app's own icon, read from
  `CFBundleIcons`; override it with PNG/JPEG bytes.
* `MailTo.share` takes `metadata:`, `MailTo.pickAndCompose` takes
  `shareMetadata:`.
* Android sets the chooser's `EXTRA_TITLE` from the same title; subtitle and
  icon are iOS-only.

## 0.7.0

* `ShareMetadata.image` — PNG bytes shared as a picture alongside the text.
  iOS adds it as a second activity item (mail attachment, photo in messengers);
  Android switches the chooser to `image/png` and serves the file through the
  plugin's own `FileProvider`, so host apps need no manifest change.
* The picture doubles as the sheet's preview thumbnail unless `icon` overrides.

## 0.7.1

* Fixed the share-sheet header icon rendering inset inside a white tile. The
  plugin no longer loads the host app's icon itself — with no `iconProvider`
  set, iOS draws that icon full-bleed on its own. Pass `ShareMetadata.icon`
  only to override it deliberately.

## 0.7.2

* Fixed the header showing a generic document glyph instead of the app icon.
  `LPLinkMetadata.originalURL` — the only way to render a subtitle — makes iOS
  treat the item as a file, so the subtitle is now skipped unless `icon` or
  `image` supplies artwork to go with it.

## 0.8.0

* README: pub/license/platform badges, a demo table, a platform-support table
  and an installation snippet.
* Example app rebuilt as a single compose screen — subject and body fields with
  live counters, and a send button that runs `MailTo.pickAndCompose`.

## 0.8.1

* Widened the Dart SDK constraint to `>=3.8.0 <4.0.0` (was `^3.12.2`), so the
  package installs on Flutter 3.32 and newer.

## 0.8.2

* Maintenance release, no functional changes.
