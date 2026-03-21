import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/app_permissions.dart';
import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../data/clientes_local_datasource.dart';
import 'clientes_providers.dart';
import 'widgets/client_form_intro_card.dart';
import 'widgets/client_type_selector.dart';
import 'widgets/clients_bottom_nav.dart';

class ClienteFormPage extends ConsumerStatefulWidget {
  const ClienteFormPage({
    super.key,
    this.clientId,
  });

  final String? clientId;

  bool get isEditing => (clientId ?? '').trim().isNotEmpty;

  @override
  ConsumerState<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends ConsumerState<ClienteFormPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _creditCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _noteCtrl;

  String _customerType = 'general';
  bool _isVip = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _companyCtrl = TextEditingController();
    _creditCtrl = TextEditingController();
    _discountCtrl = TextEditingController();
    _noteCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _bootstrap();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _companyCtrl.dispose();
    _creditCtrl.dispose();
    _discountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!widget.isEditing) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      return;
    }
    try {
      final ClienteDetail? detail = await ref
          .read(clientesLocalDataSourceProvider)
          .getClientById(widget.clientId!);
      if (!mounted) {
        return;
      }
      if (detail == null) {
        setState(() => _loading = false);
        _show('No se encontro el cliente para editar.');
        return;
      }

      _nameCtrl.text = detail.fullName;
      _phoneCtrl.text = detail.phone ?? '';
      _emailCtrl.text = detail.email ?? '';
      _addressCtrl.text = detail.address ?? '';
      _companyCtrl.text = detail.company ?? '';
      _creditCtrl.text = _moneyText(detail.creditAvailableCents);
      _discountCtrl.text = (detail.discountBps / 100).toStringAsFixed(2);
      _noteCtrl.text = detail.adminNote ?? '';
      _customerType = detail.customerType;
      _isVip = detail.isVip;

      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo abrir el cliente: $error');
    }
  }

  Future<void> _save() async {
    final String fullName = _nameCtrl.text.trim();
    if (fullName.isEmpty) {
      _show('El nombre del cliente es obligatorio.');
      return;
    }
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final ClienteUpsertInput input = ClienteUpsertInput(
        fullName: fullName,
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        company: _companyCtrl.text.trim(),
        customerType: _customerType,
        isVip: _isVip,
        creditAvailableCents: _moneyToCents(_creditCtrl.text),
        discountBps: _percentToBps(_discountCtrl.text),
        adminNote: _noteCtrl.text.trim(),
      );

      final ClientesLocalDataSource ds =
          ref.read(clientesLocalDataSourceProvider);
      if (widget.isEditing) {
        await ds.updateClient(clientId: widget.clientId!, input: input);
      } else {
        await ds.createClient(input);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _show('No se pudo guardar el cliente: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  int _moneyToCents(String value) {
    final String clean = value.trim().replaceAll(',', '.');
    if (clean.isEmpty) {
      return 0;
    }
    final double? parsed = double.tryParse(clean);
    if (parsed == null || !parsed.isFinite) {
      return 0;
    }
    return (parsed * 100).round();
  }

  int _percentToBps(String value) {
    final String clean = value.trim().replaceAll(',', '.');
    if (clean.isEmpty) {
      return 0;
    }
    final double? parsed = double.tryParse(clean);
    if (parsed == null || !parsed.isFinite) {
      return 0;
    }
    final int bps = (parsed * 100).round();
    if (bps < 0) {
      return 0;
    }
    if (bps > 10000) {
      return 10000;
    }
    return bps;
  }

  String _moneyText(int cents) {
    return (cents / 100).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final UserSession? session = ref.watch(currentSessionProvider);
    final AppConfig config = ref.watch(currentAppConfigProvider);
    final bool canManage =
        session?.hasPermission(AppPermissionKeys.customersManage) ?? false;
    final String pageTitle =
        widget.isEditing ? 'Editar Cliente' : 'Anadir Cliente';

    return AppScaffold(
      title: pageTitle,
      currentRoute: '/clientes',
      showTopTabs: false,
      showDrawer: false,
      useDefaultActions: false,
      showBottomNavigationBar: false,
      appBarLeading: IconButton(
        onPressed: () => Navigator.of(context).pop(false),
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF11141A)),
      ),
      appBarActions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Center(
            child: Text(
              config.businessName,
              style: const TextStyle(
                color: Color(0xFF1152D4),
                fontWeight: FontWeight.w800,
                fontSize: 31 / 2,
              ),
            ),
          ),
        ),
      ],
      bottomNavigationBar: const ClientsBottomNav(
        activeTab: ClientsBottomTab.clientes,
      ),
      body: !canManage
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No tienes permisos para gestionar clientes.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                  children: <Widget>[
                    const ClientFormIntroCard(),
                    const SizedBox(height: 14),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const _SectionTitle(title: 'Informacion General'),
                          const SizedBox(height: 14),
                          _LabeledField(
                            label: 'Nombre Completo',
                            child: _input(
                              controller: _nameCtrl,
                              hint: 'Ej. Carlos Mendoza',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                            label: 'Telefono',
                            child: _input(
                              controller: _phoneCtrl,
                              hint: '+53 000 000 000',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                            label: 'Correo Electronico',
                            child: _input(
                              controller: _emailCtrl,
                              hint: 'cliente@empresa.com',
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const _SectionTitle(title: 'Detalles de Cuenta'),
                          const SizedBox(height: 14),
                          _LabeledField(
                            label: 'Direccion Completa',
                            child: _input(
                              controller: _addressCtrl,
                              hint: 'Calle, numero, ciudad y codigo postal...',
                              minLines: 3,
                              maxLines: 4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                            label: 'Empresa',
                            child: _input(
                              controller: _companyCtrl,
                              hint: 'Nombre de empresa (opcional)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                            label:
                                'Credito Disponible (${config.currencySymbol})',
                            child: _input(
                              controller: _creditCtrl,
                              hint: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                            label: 'Descuento Global (%)',
                            child: _input(
                              controller: _discountCtrl,
                              hint: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                            label: 'Tipo de Cliente',
                            child: ClientTypeSelector(
                              value: _customerType,
                              onChanged: (String value) =>
                                  setState(() => _customerType = value),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            value: _isVip,
                            onChanged: (bool value) {
                              setState(() => _isVip = value);
                            },
                            activeTrackColor: const Color(0xFF1152D4),
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Cliente VIP',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            subtitle: const Text(
                              'Destaca al cliente como prioritario.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                            label: 'Observacion Interna',
                            child: _input(
                              controller: _noteCtrl,
                              hint: 'Notas del administrador...',
                              minLines: 2,
                              maxLines: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(
                          _saving ? 'Guardando...' : 'Guardar Cliente',
                          style: const TextStyle(
                            fontSize: 22 / 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1152D4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8A93A3)),
        filled: true,
        fillColor: const Color(0xFFE1E5EA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF9FB4E8)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E9F0)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 4,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF1152D4),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 42 / 2,
            fontWeight: FontWeight.w700,
            color: Color(0xFF11141A),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 18 / 1.15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF30384A),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
