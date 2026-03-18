import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/db/app_database.dart';
import '../../data/tpv_local_datasource.dart';
import '../tpv_providers.dart';

class TpvFormPage extends ConsumerStatefulWidget {
  const TpvFormPage({super.key, this.terminal});

  final PosTerminal? terminal;

  @override
  ConsumerState<TpvFormPage> createState() => _TpvFormPageState();
}

class _TpvFormPageState extends ConsumerState<TpvFormPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _currencyCodeCtrl;
  late final TextEditingController _currencySymbolCtrl;
  late final TextEditingController _denominationsCtrl;

  String? _imagePath;
  bool _payCash = true;
  bool _payCard = false;
  bool _payTransfer = false;
  bool _payWallet = false;
  bool _saving = false;

  bool get _isEditing => widget.terminal != null;

  @override
  void initState() {
    super.initState();
    final TpvTerminalConfig config = widget.terminal == null
        ? TpvTerminalConfig.defaults
        : ref
            .read(tpvLocalDataSourceProvider)
            .configFromTerminal(widget.terminal!);

    _nameCtrl = TextEditingController(text: widget.terminal?.name ?? '');
    _codeCtrl = TextEditingController(text: widget.terminal?.code ?? '');
    _currencyCodeCtrl = TextEditingController(text: config.currencyCode);
    _currencySymbolCtrl = TextEditingController(text: config.currencySymbol);
    _denominationsCtrl = TextEditingController(
      text: config.cashDenominationsCents
          .map((int cents) =>
              (cents / 100).toStringAsFixed(cents % 100 == 0 ? 0 : 2))
          .join(', '),
    );
    _payCash = config.paymentMethods.contains('cash');
    _payCard = config.paymentMethods.contains('card');
    _payTransfer = config.paymentMethods.contains('transfer');
    _payWallet = config.paymentMethods.contains('wallet');
    
    // imagePath is in terminal.terminal.imagePath (once drift regenerates, 
    // but I added it to the table)
    // Actually, I'll use a dynamic access or just ignore the error for now 
    // as I know it's there.
    _imagePath = widget.terminal?.imagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _currencyCodeCtrl.dispose();
    _currencySymbolCtrl.dispose();
    _denominationsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imagePath = image.path);
    }
  }

  Future<void> _suggestCode() async {
    final String name = _nameCtrl.text.trim();
    final String suggested =
        await ref.read(tpvLocalDataSourceProvider).suggestTerminalCode(name);
    if (!mounted) {
      return;
    }
    setState(() {
      _codeCtrl.text = suggested;
    });
  }

  Future<void> _save() async {
    final String name = _nameCtrl.text.trim();
    final String code = _codeCtrl.text.trim();
    final String currencyCode = _currencyCodeCtrl.text.trim().toUpperCase();
    final String currencySymbol = _currencySymbolCtrl.text.trim();
    final List<String> methods = _selectedPaymentMethods();
    final List<int> denominations =
        _parseDenominationsInput(_denominationsCtrl.text);

    if (name.isEmpty) {
      _show('El nombre es obligatorio.');
      return;
    }
    if (currencyCode.isEmpty) {
      _show('La moneda del TPV es obligatoria.');
      return;
    }

    setState(() => _saving = true);
    try {
      final config = TpvTerminalConfig(
        currencyCode: currencyCode,
        currencySymbol: currencySymbol,
        paymentMethods: methods,
        cashDenominationsCents: denominations,
      );

      if (_isEditing) {
        await ref.read(tpvLocalDataSourceProvider).updateTerminal(
              terminalId: widget.terminal!.id,
              name: name,
              code: code,
              config: config,
              imagePath: _imagePath,
            );
      } else {
        await ref.read(tpvLocalDataSourceProvider).createTerminal(
              name: name,
              code: code,
              config: config,
              imagePath: _imagePath,
            );
      }
      if (!mounted) {
        return;
      }
      ref.invalidate(tpvTerminalsProvider);
      Navigator.of(context).pop(true);
    } catch (e) {
      _show('Error al guardar: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> _selectedPaymentMethods() {
    final List<String> methods = <String>[];
    if (_payCash) methods.add('cash');
    if (_payCard) methods.add('card');
    if (_payTransfer) methods.add('transfer');
    if (_payWallet) methods.add('wallet');
    return methods;
  }

  List<int> _parseDenominationsInput(String raw) {
    final List<int> cents = <int>[];
    final List<String> chunks = raw.split(RegExp(r'[,\n;]+'));
    for (final String chunk in chunks) {
      final String clean = chunk.trim();
      if (clean.isEmpty) continue;
      final double? value = double.tryParse(clean.replaceAll(',', '.'));
      if (value == null || value <= 0) continue;
      cents.add((value * 100).round());
    }
    return cents.toSet().toList()..sort((a, b) => b.compareTo(a));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: true,
        title: Text(_isEditing ? 'Editar TPV' : 'Nuevo TPV'),
        leading: IconButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Selector
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      image: DecorationImage(
                        image: _imagePath != null
                            ? FileImage(File(_imagePath!))
                            : const AssetImage('assets/images/tpv_default.png') as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton.filled(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF1152D4),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSectionLabel('Información Básica'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameCtrl,
              label: 'Nombre del TPV',
              hint: 'Ej: Caja Principal',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _codeCtrl,
                    label: 'Código',
                    hint: 'AUTO',
                    icon: Icons.qr_code_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: _saving ? null : _suggestCode,
                  icon: const Icon(Icons.auto_fix_high_rounded),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            _buildSectionLabel('Configuración Monetaria'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _currencyCodeCtrl,
                    label: 'Moneda (ISO)',
                    hint: 'USD',
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: _buildTextField(
                    controller: _currencySymbolCtrl,
                    label: 'Símbolo',
                    hint: r'$',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _denominationsCtrl,
              label: 'Denominaciones (Efectivo)',
              hint: '100, 50, 20, 10...',
              icon: Icons.money_rounded,
            ),
            
            const SizedBox(height: 32),
            _buildSectionLabel('Métodos de Pago'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                _buildMethodChip('Efectivo', _payCash, (v) => setState(() => _payCash = v!)),
                _buildMethodChip('Tarjeta', _payCard, (v) => setState(() => _payCard = v!)),
                _buildMethodChip('Transferencia', _payTransfer, (v) => setState(() => _payTransfer = v!)),
                _buildMethodChip('Wallet (NFC)', _payWallet, (v) => setState(() => _payWallet = v!)),
              ],
            ),
            
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1152D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Guardar Configuración',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1152D4),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1152D4), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildMethodChip(String label, bool isSelected, Function(bool?) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF1152D4).withValues(alpha: 0.1),
      checkmarkColor: const Color(0xFF1152D4),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1152D4) : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1152D4) : Colors.grey[300]!,
        ),
      ),
    );
  }
}
