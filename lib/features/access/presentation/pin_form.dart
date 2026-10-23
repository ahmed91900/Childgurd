import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/strings.dart';

String normalizePin(String value) =>
    value.replaceAllMapped(RegExp('[٠-٩۰-۹০-৯]'), (m) {
      final code = m[0]!.codeUnitAt(0);
      return '${code >= 0x9e6
          ? code - 0x9e6
          : code >= 0x6f0
          ? code - 0x6f0
          : code - 0x660}';
    });

class PinField extends StatefulWidget {
  const PinField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
  });
  final TextEditingController controller;
  final String label;
  final bool enabled;
  @override
  State<PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<PinField> {
  bool _hidden = true;
  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: widget.controller,
        enabled: widget.enabled,
        obscureText: _hidden,
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
          labelText: widget.label,
          counterText: '',
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            tooltip: s[_hidden ? 'showPin' : 'hidePin'],
            onPressed: widget.enabled
                ? () => setState(() => _hidden = !_hidden)
                : null,
            icon: Icon(
              _hidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
      ),
    );
  }
}

class ChangePinsForm extends StatefulWidget {
  const ChangePinsForm({
    super.key,
    required this.busy,
    required this.firstSetup,
    required this.submit,
  });
  final bool busy;
  final bool firstSetup;
  final Future<bool> Function(String current, String parent, String kid) submit;
  @override
  State<ChangePinsForm> createState() => _ChangePinsFormState();
}

class _ChangePinsFormState extends State<ChangePinsForm> {
  final _parent = TextEditingController(),
      _kid = TextEditingController(),
      _current = TextEditingController();
  bool _authorizing = false;
  @override
  void dispose() {
    for (final field in [_parent, _kid, _current]) {
      field.clear();
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!widget.firstSetup && !_authorizing) {
      setState(() => _authorizing = true);
      return;
    }
    final saved = await widget.submit(
      widget.firstSetup ? '1020' : _current.text,
      _parent.text,
      _kid.text,
    );
    if (!mounted) return;
    _current.clear();
    if (saved) {
      _parent.clear();
      _kid.clear();
      setState(() => _authorizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s[_authorizing ? 'authorizePinChange' : 'simplePinTitle'],
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        if (_authorizing)
          PinField(
            controller: _current,
            label: s['parentPinLabel'],
            enabled: !widget.busy,
          )
        else ...[
          Text(s['simplePinHelp']),
          PinField(
            controller: _parent,
            label: s['parentPinLabel'],
            enabled: !widget.busy,
          ),
          PinField(
            controller: _kid,
            label: s['kidsPinLabel'],
            enabled: !widget.busy,
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: widget.busy ? null : _save,
          child: Text(s['saveSimplePins']),
        ),
        if (_authorizing)
          TextButton(
            onPressed: widget.busy
                ? null
                : () {
                    _current.clear();
                    setState(() => _authorizing = false);
                  },
            child: Text(s['back']),
          ),
      ],
    );
  }
}
