import 'package:flutter/foundation.dart';

/// The message a mail app's compose screen opens with.
///
/// Everything is optional — an empty message just opens a blank draft.
@immutable
class MailMessage {
  const MailMessage({
    this.subject = '',
    this.body = '',
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.isHtml = false,
  });

  final String subject;
  final String body;
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;

  /// Renders [body] as HTML.
  ///
  /// Only honoured by Apple Mail's native composer; URL-driven apps always
  /// receive plain text, since `mailto:` has no way to express HTML.
  final bool isHtml;

  Map<String, Object?> toMap() => {
    'subject': subject,
    'body': body,
    'to': to,
    'cc': cc,
    'bcc': bcc,
    'isHtml': isHtml,
  };

  @override
  String toString() =>
      'MailMessage(subject: $subject, to: $to, body: ${body.length} chars)';
}
