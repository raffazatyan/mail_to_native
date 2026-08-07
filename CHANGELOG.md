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
