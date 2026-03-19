import 'package:flutter/material.dart';

class SecurityPasswordDialog extends StatefulWidget {
  const SecurityPasswordDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
  });

  final String title;
  final String confirmLabel;

  @override
  State<SecurityPasswordDialog> createState() => _SecurityPasswordDialogState();
}

class _SecurityPasswordDialogState extends State<SecurityPasswordDialog> {
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final String password = _passwordCtrl.text.trim();
    final String confirm = _confirmCtrl.text.trim();
    if (password.length < 4) {
      setState(() =>
          _errorMessage = 'La contrasena debe tener al menos 4 caracteres.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Las contrasenas no coinciden.');
      return;
    }
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _passwordCtrl,
            obscureText: _hidePassword,
            decoration: InputDecoration(
              labelText: 'Contrasena',
              suffixIcon: IconButton(
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmCtrl,
            obscureText: _hideConfirm,
            decoration: InputDecoration(
              labelText: 'Confirmar contrasena',
              suffixIcon: IconButton(
                icon: Icon(
                  _hideConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_errorMessage != null) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
