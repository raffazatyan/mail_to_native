# mail_to

Pick an installed mail app and open its **compose** screen with subject and body prefilled — through a **native** dialog, not a Flutter widget.

Most packages in this space open the mail app's *inbox*. `mail_to` opens a prefilled draft, in the app the user picks.

| | iOS | Android |
|---|---|---|
| Detection | Known schemes probed with `canOpenURL` + `MFMailComposeViewController.canSendMail()` | Every `mailto:` handler, via `PackageManager` |
| Picker | `UIAlertController` (`.alert`, centred) | `AlertDialog` |
| Apple Mail | `MFMailComposeViewController` — an in-app sheet | n/a |
| Others | Per-app compose deep link | Explicit `ACTION_SENDTO` intent |

## Why Apple Mail is special

On iOS 14+ `mailto:` is handed to the user's **default** mail app. If that default is Gmail, a `mailto:` link labelled "Apple Mail" opens Gmail. There is no Apple-Mail-only compose URL, so this plugin drives `MFMailComposeViewController` instead — which always composes in Apple Mail, as an in-app sheet.

## Usage

```dart
import 'package:mail_to/mail_to.dart';

const message = MailMessage(
  subject: 'Meeting notes',
  body: 'Here is the summary…',
  to: ['someone@example.com'],
);

// Native dialog, then compose. Skips the dialog when only one app exists.
await MailTo.pickAndCompose(message);
```

Driving the list yourself:

```dart
final apps = await MailTo.installedApps();   // [] when none installed
if (apps.isNotEmpty) {
  await MailTo.compose(message, app: apps.first);
}
```

Handing the message to the platform default:

```dart
await MailTo.compose(message);   // no app → default mailto handler
```

## iOS setup (required)

iOS cannot enumerate installed apps. `canOpenURL` returns `false` for any scheme not declared by the **host app**, so add this to `ios/Runner/Info.plist` — without it, only Apple Mail is ever detected:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>googlegmail</string>
  <string>ms-outlook</string>
  <string>readdle-spark</string>
  <string>ymail</string>
  <string>airmail</string>
  <string>fastmail</string>
  <string>protonmail</string>
</array>
```

Keep any schemes already in that array — add to it, don't replace it.

## Android setup

None. The plugin's own manifest contributes the Android 11+ `<queries>` block.

## Notes

- `MailMessage.isHtml` is honoured only by Apple Mail's native composer. `mailto:`-driven apps have no way to express HTML and always get plain text.
- `compose` resolves `true` when the composer opened (for Apple Mail: when the sheet closed without an error), `false` when nothing could be opened.
- Long bodies: `mailto:` URLs are length-limited by the receiving app. Apple Mail's native composer has no such limit.
- Apple Mail is reported as installed only when it has an account configured — simulators usually don't.

## License

MIT
