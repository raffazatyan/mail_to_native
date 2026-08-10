import 'package:flutter/material.dart';
import 'package:mail_to_native/mail_to_native.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: ExamplePage());
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  static const _message = MailMessage(
    subject: 'mail_to',
    body: 'Composed straight from the example app.',
  );

  List<MailApp> _apps = const [];
  String _status = '';

  Future<void> _refresh() async {
    final apps = await MailTo.installedApps();
    setState(() {
      _apps = apps;
      _status = apps.isEmpty ? 'No mail app installed' : '';
    });
  }

  Future<void> _pickAndCompose() async {
    final isComposed = await MailTo.pickAndCompose(_message);
    setState(() => _status = isComposed ? 'Composer opened' : 'Cancelled');
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('mail_to')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Pick a mail app (native dialog)'),
            subtitle: Text(_status),
            trailing: const Icon(Icons.mail_outline),
            onTap: _pickAndCompose,
          ),
          const Divider(),
          for (final app in _apps)
            ListTile(
              title: Text(app.name),
              subtitle: Text(app.id),
              trailing: app.usesNativeComposer
                  ? const Icon(Icons.phone_iphone)
                  : const Icon(Icons.open_in_new),
              onTap: () => MailTo.compose(_message, app: app),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refresh,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
