import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/strings.dart';

String normalizePin(String value) =>
    value.replaceAllMapped(RegExp('[٠-٩۰-۹]'), (m) {
      final code = m[0]!.codeUnitAt(0);
      return '${code >= 0x6f0 ? code - 0x6f0 : code - 0x660}';
    });

class PinField extends StatelessWidget {
  const PinField({super.key, required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextField(
      controller: controller,
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      enableInteractiveSelection: false,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      maxLength: 12,
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) {
          final normalized = normalizePin(newValue.text);
          if (!RegExp(r'^\d*$').hasMatch(normalized)) return oldValue;
          return newValue.copyWith(text: normalized);
        }),
        LengthLimitingTextInputFormatter(12),
      ],
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
      ),
    ),
  );
}

class ChangePinsForm extends StatefulWidget {
  const ChangePinsForm({super.key, required this.busy, required this.submit});
  final bool busy;
  final Future<void> Function(String current, String parent, String kid) submit;

  @override
  State<ChangePinsForm> createState() => _ChangePinsFormState();
}

class _ChangePinsFormState extends State<ChangePinsForm> {
  final _fields = List.generate(5, (_) => TextEditingController());
  String? _error;

  @override
  void dispose() {
    for (final field in _fields) {
      field.clear();
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final labels = [
      'currentParent',
      'newParent',
      'confirmParent',
      'newKid',
      'confirmKid',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s['choosePins'],
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(s['pinIntro']),
        for (var i = 0; i < _fields.length; i++)
          PinField(controller: _fields[i], label: s[labels[i]]),
        if (_error != null) Text(s[_error!], semanticsLabel: s[_error!]),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: widget.busy
              ? null
              : () async {
                  if (_fields[1].text != _fields[2].text ||
                      _fields[3].text != _fields[4].text) {
                    setState(() => _error = 'mismatch');
                    return;
                  }
                  setState(() => _error = null);
                  await widget.submit(
                    _fields[0].text,
                    _fields[1].text,
                    _fields[3].text,
                  );
                  if (!mounted) return;
                  for (final field in _fields) {
                    field.clear();
                  }
                },
          child: Text(s['savePins']),
        ),
      ],
    );
  }
}
