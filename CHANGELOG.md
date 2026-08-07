## 0.1.0

* Initial release.
* `MailTo.installedApps()` — mail apps installed on the device.
* `MailTo.compose()` — open a mail app's compose screen prefilled.
* `MailTo.pickApp()` / `MailTo.pickAndCompose()` — native picker dialog
  (`UIAlertController` on iOS, `AlertDialog` on Android).
* Apple Mail composes through `MFMailComposeViewController`, so it is not
  hijacked by whichever app owns the `mailto:` scheme.
