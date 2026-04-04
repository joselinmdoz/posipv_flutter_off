import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/security/app_permissions.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../configuracion/data/configuracion_local_datasource.dart';
import '../../../configuracion/presentation/configuracion_providers.dart';
import '../../../inventario/presentation/inventario_providers.dart';
import '../../data/tpv_local_datasource.dart';
import '../tpv_providers.dart';
import 'tpv_employee_avatar.dart';

class TpvFormPage extends ConsumerStatefulWidget {
  const TpvFormPage({super.key, this.terminal});

  final PosTerminal? terminal;

  @override
  ConsumerState<TpvFormPage> createState() => _TpvFormPageState();
}

class _TpvFormPageState extends ConsumerState<TpvFormPage> {
  static const String _autoCreateWarehouseValue = '__auto_create_warehouse__';

  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _denominationsCtrl;

  List<AppCurrencySetting> _currencyOptions = <AppCurrencySetting>[];
  List<TpvWarehouseOption> _warehouseOptions = <TpvWarehouseOption>[];
  List<TpvEmployee> _eligibleEmployees = <TpvEmployee>[];
  Set<String> _selectedEmployeeIds = <String>{};
  String? _selectedCurrencyCode;
  String? _selectedWarehouseId;
  String _selectedCurrencySymbolFallback =
      TpvTerminalConfig.defaults.currencySymbol;
  String? _imagePath;
  bool _payCash = true;
  bool _payCard = false;
  bool _payTransfer = false;
  bool _payWallet = false;
  bool _payConsignment = true;
  bool _loadingWarehouseOptions = true;
  bool _loadingEmployeeAccess = true;
  bool _saving = false;

  bool get _isEditing => widget.terminal != null;
  bool get _canManageTerminals {
    return ref.read(currentSessionProvider)?.hasPermission(
              AppPermissionKeys.tpvManageTerminals,
            ) ??
        false;
  }

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
    _selectedCurrencyCode = config.currencyCode.trim().toUpperCase();
    _selectedCurrencySymbolFallback = config.currencySymbol;
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
    _payConsignment = config.paymentMethods.contains('consignment');
    _imagePath = widget.terminal?.imagePath;
    _selectedWarehouseId =
        widget.terminal?.warehouseId ?? _autoCreateWarehouseValue;
    _loadCurrencyOptions();
    _loadWarehouseOptions();
    _loadEmployeeAccess();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _denominationsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencyOptions() async {
    try {
      final AppConfig config =
          await ref.read(configuracionLocalDataSourceProvider).loadConfig();
      if (!mounted) {
        return;
      }

      final AppCurrencyConfig currencyConfig =
          config.currencyConfig.normalized();
      final List<AppCurrencySetting> options =
          List<AppCurrencySetting>.from(currencyConfig.currencies);
      String selected = (_selectedCurrencyCode ?? '').trim().toUpperCase();
      if (selected.isEmpty) {
        selected = currencyConfig.primaryCurrencyCode;
      }

      if (options.every((AppCurrencySetting item) => item.code != selected)) {
        options.add(
          AppCurrencySetting(
            code: selected,
            symbol: _selectedCurrencySymbolFallback,
            rateToPrimary: 1,
          ),
        );
      }

      options.sort((AppCurrencySetting a, AppCurrencySetting b) {
        if (a.code == currencyConfig.primaryCurrencyCode) {
          return -1;
        }
        if (b.code == currencyConfig.primaryCurrencyCode) {
          return 1;
        }
        return a.code.compareTo(b.code);
      });

      setState(() {
        _currencyOptions = options;
        _selectedCurrencyCode = selected;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      final String selected =
          (_selectedCurrencyCode ?? '').trim().toUpperCase().isEmpty
              ? TpvTerminalConfig.defaults.currencyCode
              : (_selectedCurrencyCode ?? '').trim().toUpperCase();
      setState(() {
        _currencyOptions = <AppCurrencySetting>[
          AppCurrencySetting(
            code: selected,
            symbol: _selectedCurrencySymbolFallback,
            rateToPrimary: 1,
          ),
        ];
        _selectedCurrencyCode = selected;
      });
    }
  }

  String _symbolForCurrencyCode(String rawCode) {
    final String code = rawCode.trim().toUpperCase();
    for (final AppCurrencySetting item in _currencyOptions) {
      if (item.code == code) {
        return item.symbol;
      }
    }
    if (code == (_selectedCurrencyCode ?? '').trim().toUpperCase()) {
      return _selectedCurrencySymbolFallback;
    }
    return TpvTerminalConfig.defaults.currencySymbol;
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
    if (!_canManageTerminals) {
      _show('No tienes permisos para gestionar terminales.');
      return;
    }
    final String name = _nameCtrl.text.trim();
    final String code = _codeCtrl.text.trim();
    final String currencyCode =
        (_selectedCurrencyCode ?? '').trim().toUpperCase();
    final String currencySymbol = _symbolForCurrencyCode(currencyCode);
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
    if (_loadingEmployeeAccess) {
      _show('Espera a que carguen los empleados permitidos.');
      return;
    }
    if (_loadingWarehouseOptions) {
      _show('Espera a que carguen los almacenes disponibles.');
      return;
    }
    final String selectedWarehouseValue = (_selectedWarehouseId ?? '').trim();
    if (_isEditing && selectedWarehouseValue.isEmpty) {
      _show('Selecciona un almacén para el TPV.');
      return;
    }
    if (_eligibleEmployees.isNotEmpty && _selectedEmployeeIds.isEmpty) {
      _show('Selecciona al menos un empleado con acceso al TPV.');
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
              warehouseId: selectedWarehouseValue,
              config: config,
              imagePath: _imagePath,
              allowedEmployeeIds: _selectedEmployeeIds.toList(),
            );
      } else {
        final String? warehouseId =
            selectedWarehouseValue == _autoCreateWarehouseValue
                ? null
                : selectedWarehouseValue;
        await ref.read(tpvLocalDataSourceProvider).createTerminal(
              name: name,
              code: code,
              warehouseId: warehouseId,
              config: config,
              imagePath: _imagePath,
              allowedEmployeeIds: _selectedEmployeeIds.toList(),
            );
      }
      if (!mounted) {
        return;
      }
      ref.invalidate(tpvTerminalsProvider);
      ref.read(inventoryRefreshSignalProvider.notifier).state += 1;
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

  Future<void> _loadWarehouseOptions() async {
    setState(() => _loadingWarehouseOptions = true);
    try {
      final TpvLocalDataSource ds = ref.read(tpvLocalDataSourceProvider);
      final List<TpvWarehouseOption> options =
          await ds.listWarehousesEligibleForTerminalAccess(
        terminalId: widget.terminal?.id,
      );
      if (!mounted) {
        return;
      }
      String selected = (_selectedWarehouseId ?? '').trim();
      if (_isEditing) {
        selected = widget.terminal!.warehouseId;
      } else if (selected.isEmpty) {
        selected =
            options.isEmpty ? _autoCreateWarehouseValue : options.first.id;
      } else {
        final bool exists = options.any((TpvWarehouseOption item) {
          return item.id == selected;
        });
        if (!exists && selected != _autoCreateWarehouseValue) {
          selected =
              options.isEmpty ? _autoCreateWarehouseValue : options.first.id;
        }
      }

      setState(() {
        _warehouseOptions = options;
        _selectedWarehouseId = selected;
        _loadingWarehouseOptions = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _warehouseOptions = <TpvWarehouseOption>[];
        _selectedWarehouseId = _isEditing
            ? widget.terminal?.warehouseId
            : _autoCreateWarehouseValue;
        _loadingWarehouseOptions = false;
      });
    }
  }

  Future<void> _loadEmployeeAccess() async {
    setState(() => _loadingEmployeeAccess = true);
    try {
      final TpvLocalDataSource ds = ref.read(tpvLocalDataSourceProvider);
      final List<TpvEmployee> eligible =
          await ds.listEmployeesEligibleForTerminalAccess();
      Set<String> selected = <String>{};
      if (_isEditing) {
        selected =
            await ds.listAllowedEmployeeIdsForTerminal(widget.terminal!.id);
      }
      if (selected.isEmpty) {
        selected = eligible.map((TpvEmployee e) => e.id).toSet();
      } else {
        selected = selected.where((String id) {
          return eligible.any((TpvEmployee employee) => employee.id == id);
        }).toSet();
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _eligibleEmployees = eligible;
        _selectedEmployeeIds = selected;
        _loadingEmployeeAccess = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _eligibleEmployees = <TpvEmployee>[];
        _selectedEmployeeIds = <String>{};
        _loadingEmployeeAccess = false;
      });
    }
  }

  List<String> _selectedPaymentMethods() {
    final List<String> methods = <String>[];
    if (_payCash) methods.add('cash');
    if (_payCard) methods.add('card');
    if (_payTransfer) methods.add('transfer');
    if (_payWallet) methods.add('wallet');
    if (_payConsignment) methods.add('consignment');
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
    final bool canManageTerminals =
        ref.watch(currentSessionProvider)?.hasPermission(
                  AppPermissionKeys.tpvManageTerminals,
                ) ??
            false;
    final ThemeData theme = Theme.of(context);
    final bool hasSelectedCurrency = _currencyOptions.any(
      (AppCurrencySetting item) => item.code == _selectedCurrencyCode,
    );
    final String? selectedCurrencyValue =
        hasSelectedCurrency ? _selectedCurrencyCode : null;

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
      body: !canManageTerminals
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No tienes permisos para gestionar terminales.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
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
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                            ),
                            image: DecorationImage(
                              image: _imagePath != null
                                  ? FileImage(File(_imagePath!))
                                  : const AssetImage(
                                          'assets/images/tpv_default.png')
                                      as ImageProvider,
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
                            icon:
                                const Icon(Icons.camera_alt_rounded, size: 20),
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
                  const SizedBox(height: 20),
                  _buildWarehouseSelector(theme),

                  const SizedBox(height: 32),
                  _buildSectionLabel('Configuración Monetaria'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey<String?>(selectedCurrencyValue),
                    initialValue: selectedCurrencyValue,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Moneda del TPV',
                      hintText: 'Selecciona la moneda',
                      prefixIcon:
                          const Icon(Icons.currency_exchange_rounded, size: 20),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
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
                        borderSide: const BorderSide(
                          color: Color(0xFF1152D4),
                          width: 1.5,
                        ),
                      ),
                    ),
                    items: _currencyOptions
                        .map(
                          (AppCurrencySetting currency) =>
                              DropdownMenuItem<String>(
                            value: currency.code,
                            child:
                                Text('${currency.code} (${currency.symbol})'),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return;
                            }
                            setState(() => _selectedCurrencyCode =
                                value.trim().toUpperCase());
                          },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Símbolo aplicado: ${_symbolForCurrencyCode(_selectedCurrencyCode ?? '')}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
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
                      _buildMethodChip('Efectivo', _payCash,
                          (v) => setState(() => _payCash = v!)),
                      _buildMethodChip('Tarjeta', _payCard,
                          (v) => setState(() => _payCard = v!)),
                      _buildMethodChip('Transferencia', _payTransfer,
                          (v) => setState(() => _payTransfer = v!)),
                      _buildMethodChip('Wallet (NFC)', _payWallet,
                          (v) => setState(() => _payWallet = v!)),
                      _buildMethodChip('Consignación', _payConsignment,
                          (v) => setState(() => _payConsignment = v!)),
                    ],
                  ),

                  const SizedBox(height: 32),
                  _buildSectionLabel('Acceso de Empleados'),
                  const SizedBox(height: 12),
                  if (_loadingEmployeeAccess)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(minHeight: 3),
                    )
                  else if (_eligibleEmployees.isEmpty)
                    Text(
                      'No hay empleados elegibles con permisos de TPV y venta POS.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Column(
                      children: _eligibleEmployees.map((TpvEmployee employee) {
                        final bool selected =
                            _selectedEmployeeIds.contains(employee.id);
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: selected,
                          onChanged: _saving
                              ? null
                              : (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedEmployeeIds.add(employee.id);
                                    } else {
                                      _selectedEmployeeIds.remove(employee.id);
                                    }
                                  });
                                },
                          secondary: TpvEmployeeAvatar(
                            imagePath: employee.imagePath,
                            radius: 18,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            iconColor: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(employee.name),
                          subtitle: Text(
                            (employee.associatedUsername ?? '')
                                    .trim()
                                    .isNotEmpty
                                ? '@${employee.associatedUsername}'
                                : 'Sin usuario asociado',
                          ),
                        );
                      }).toList(growable: false),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Guardar Configuración',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildWarehouseSelector(ThemeData theme) {
    final bool hasSelection = _warehouseOptions.any((TpvWarehouseOption item) {
      return item.id == _selectedWarehouseId;
    });
    final bool useAutoCreate =
        !_isEditing && _selectedWarehouseId == _autoCreateWarehouseValue;
    final String? selectedValue = useAutoCreate
        ? _autoCreateWarehouseValue
        : (hasSelection ? _selectedWarehouseId : null);

    final List<DropdownMenuItem<String>> items = <DropdownMenuItem<String>>[
      if (!_isEditing)
        const DropdownMenuItem<String>(
          value: _autoCreateWarehouseValue,
          child: Text('Crear almacén TPV automático'),
        ),
      ..._warehouseOptions.map((TpvWarehouseOption warehouse) {
        final String type = warehouse.warehouseType.trim();
        final String suffix = type.isEmpty ? '' : ' • $type';
        return DropdownMenuItem<String>(
          value: warehouse.id,
          child: Text('${warehouse.name}$suffix'),
        );
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<String>(
          key: ValueKey<String?>('warehouse-$selectedValue'),
          initialValue: selectedValue,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Almacén asociado',
            hintText: 'Selecciona un almacén',
            prefixIcon: const Icon(Icons.warehouse_outlined, size: 20),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
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
              borderSide: const BorderSide(
                color: Color(0xFF1152D4),
                width: 1.5,
              ),
            ),
          ),
          items: items,
          onChanged: (_saving || _loadingWarehouseOptions)
              ? null
              : (String? value) {
                  setState(() => _selectedWarehouseId = value);
                },
        ),
        const SizedBox(height: 10),
        if (_loadingWarehouseOptions)
          const LinearProgressIndicator(minHeight: 3)
        else
          Text(
            _warehouseHelperText(),
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  String _warehouseHelperText() {
    final String selected = (_selectedWarehouseId ?? '').trim();
    if (!_isEditing && selected == _autoCreateWarehouseValue) {
      return 'Se creará un almacén dedicado para este TPV.';
    }
    for (final TpvWarehouseOption item in _warehouseOptions) {
      if (item.id == selected) {
        return 'Almacén seleccionado: ${item.name}';
      }
    }
    return _warehouseOptions.isEmpty
        ? 'No hay almacenes disponibles para seleccionar.'
        : 'Selecciona el almacén de trabajo para este TPV.';
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
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
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

  Widget _buildMethodChip(
      String label, bool isSelected, Function(bool?) onSelected) {
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
