import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/app_permissions.dart';
import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../data/clientes_local_datasource.dart';
import 'cliente_form_page.dart';
import 'clientes_providers.dart';
import 'widgets/client_admin_note_card.dart';
import 'widgets/client_contact_info_card.dart';
import 'widgets/client_detail_profile_card.dart';
import 'widgets/client_purchase_summary_card.dart';
import 'widgets/client_quick_contact_panel.dart';
import 'widgets/client_transactions_list.dart';
import 'widgets/clients_bottom_nav.dart';

class ClienteDetailPage extends ConsumerStatefulWidget {
  const ClienteDetailPage({
    super.key,
    required this.clientId,
  });

  final String clientId;

  @override
  ConsumerState<ClienteDetailPage> createState() => _ClienteDetailPageState();
}

class _ClienteDetailPageState extends ConsumerState<ClienteDetailPage> {
  ClienteDetail? _client;
  bool _loading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _load();
    });
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final ClienteDetail? data = await ref
          .read(clientesLocalDataSourceProvider)
          .getClientById(widget.clientId);
      if (!mounted) {
        return;
      }
      setState(() {
        _client = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar el detalle del cliente: $error');
    }
  }

  Future<void> _editClient() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ClienteFormPage(clientId: widget.clientId),
      ),
    );
    if (saved == true) {
      _changed = true;
      await _load();
    }
  }

  void _close() {
    Navigator.of(context).pop(_changed);
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final UserSession? session = ref.watch(currentSessionProvider);
    final bool canManage =
        session?.hasPermission(AppPermissionKeys.customersManage) ?? false;
    final AppConfig config = ref.watch(currentAppConfigProvider);

    return AppScaffold(
      title: 'Detalle de Cliente',
      currentRoute: '/clientes',
      showTopTabs: false,
      showDrawer: false,
      useDefaultActions: false,
      showBottomNavigationBar: false,
      appBarLeading: IconButton(
        onPressed: _close,
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1152D4)),
      ),
      appBarActions: canManage
          ? <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _editClient,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1152D4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ]
          : null,
      bottomNavigationBar: const ClientsBottomNav(
        activeTab: ClientsBottomTab.clientes,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _client == null
              ? const Center(
                  child: Text('Cliente no encontrado o inactivo.'),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                    children: <Widget>[
                      ClientDetailProfileCard(client: _client!),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints c) {
                          if (c.maxWidth >= 760) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: ClientPurchaseSummaryCard(
                                    totalCents: _client!.lifetimeSpentCents,
                                    lastPurchaseAt: _client!.lastPurchaseAt,
                                    currencySymbol: config.currencySymbol,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ClientQuickContactPanel(
                                    phone: _client!.phone,
                                    email: _client!.email,
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: <Widget>[
                              ClientPurchaseSummaryCard(
                                totalCents: _client!.lifetimeSpentCents,
                                lastPurchaseAt: _client!.lastPurchaseAt,
                                currencySymbol: config.currencySymbol,
                              ),
                              const SizedBox(height: 12),
                              ClientQuickContactPanel(
                                phone: _client!.phone,
                                email: _client!.email,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      ClientContactInfoCard(
                        address: _client!.address,
                        company: _client!.company,
                      ),
                      const SizedBox(height: 14),
                      ClientTransactionsList(
                        transactions: _client!.transactions,
                        currencySymbol: config.currencySymbol,
                      ),
                      if ((_client!.adminNote ?? '')
                          .trim()
                          .isNotEmpty) ...<Widget>[
                        const SizedBox(height: 14),
                        ClientAdminNoteCard(note: _client!.adminNote!.trim()),
                      ],
                    ],
                  ),
                ),
    );
  }
}
