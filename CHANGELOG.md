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
