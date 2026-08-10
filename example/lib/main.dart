import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mail_to_native/mail_to_native.dart';

void main() => runApp(const ExampleApp());

/// Palette shared by every widget on [ComposeMailScreen].
class AppColors {
  static const background = Color(0xFF201E1D);
  static const text = Color(0xFFF3F2F2);
  static const label = Color(0xFFA09A96);
  static const hint = Color(0xFF6F6A67);
  static const caption = Color(0xFF8D8783);
  static const field = Color(0xFF2B2826);
  static const border = Color(0xFF3B3734);
  static const divider = Color(0xFF35322F);
  static const accent = Color(0xFFEC3013);
  static const accentPressed = Color(0xFFC02508);
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.accent,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.archivoTextTheme(
          base.textTheme,
        ).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      ),
      home: const ComposeMailScreen(),
    );
  }
}

class ComposeMailScreen extends StatefulWidget {
  const ComposeMailScreen({super.key});

  @override
  State<ComposeMailScreen> createState() => _ComposeMailScreenState();
}

class _ComposeMailScreenState extends State<ComposeMailScreen> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  bool _sent = false;

  bool get _isEmpty => _subject.text.isEmpty && _body.text.isEmpty;

  @override
  void initState() {
    super.initState();
    _subject.addListener(_onChanged);
    _body.addListener(_onChanged);
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() => _sent = false);

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final isComposed = await MailTo.pickAndCompose(
      MailMessage(subject: _subject.text, body: _body.text),
      dialogTitle: 'Send with',
    );
    if (!mounted) return;
    if (isComposed) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
              const SizedBox(height: 26),
              _LabelRow(
                label: 'SUBJECT',
                trailing: '${_subject.text.characters.length}/80',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _subject,
                maxLength: 80,
                style: const TextStyle(fontSize: 17, color: AppColors.text),
                decoration: _fieldDecoration(
                  hint: 'Quarterly figures',
                  radius: 16,
                ).copyWith(counterText: ''),
              ),
              const SizedBox(height: 24),
              _LabelRow(
                label: 'BODY',
                trailing: _body.text.isEmpty
                    ? ''
                    : '${_body.text.characters.length} chars',
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TextField(
                  controller: _body,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.text,
                  ),
                  decoration: _fieldDecoration(
                    hint: 'Write your message.',
                    radius: 20,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SendButton(enabled: !_isEmpty, sent: _sent, onPressed: _send),
              const SizedBox(height: 14),
              Text(
                _sent
                    ? 'Handed to the mail client.'
                    : 'Opens your mail app with this draft.',
                style: const TextStyle(fontSize: 12, color: AppColors.caption),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required double radius,
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.hint),
      filled: true,
      fillColor: AppColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: border(AppColors.border, 1),
      enabledBorder: border(AppColors.border, 1),
      focusedBorder: border(AppColors.accent, 2),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chevron_left,
              size: 22,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'New Message',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.text,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'DRAFT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, required this.trailing});

  final String label;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.label,
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.hint,
          ),
        ),
      ],
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({
    required this.enabled,
    required this.sent,
    required this.onPressed,
  });

  final bool enabled;
  final bool sent;
  final VoidCallback onPressed;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fill = _pressed ? AppColors.accentPressed : AppColors.accent;

    return Opacity(
      opacity: widget.enabled ? 1 : 0.45,
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _pressed = false)
            : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed();
              }
            : null,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.sent ? 'SENT' : 'SEND MAIL',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: Colors.white,
                ),
              ),
              const Icon(Icons.send, size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
