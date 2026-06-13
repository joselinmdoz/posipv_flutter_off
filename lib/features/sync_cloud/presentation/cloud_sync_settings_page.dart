import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../configuracion/presentation/widgets/config_option_tile.dart';
import '../data/cloud_sync_models.dart';
import 'cloud_sync_providers.dart';

class CloudSyncSettingsPage extends ConsumerStatefulWidget {
  const CloudSyncSettingsPage({super.key});

  @override
  ConsumerState<CloudSyncSettingsPage> createState() =>
      _CloudSyncSettingsPageState();
}

class _CloudSyncSettingsPageState extends ConsumerState<CloudSyncSettingsPage> {
  final TextEditingController _serverUrlCtrl = TextEditingController();
  final TextEditingController _databaseCtrl = TextEditingController();
  final TextEditingController _deviceLabelCtrl = TextEditingController();
  final TextEditingController _bootstrapTokenCtrl = TextEditingController();
  bool _obscureBootstrapToken = true;

  bool _loading = true;
  bool _saving = false;
  bool _enabled = false;
  bool _autoPullCatalogs = true;
  bool _autoPushSales = true;
  bool _autoPushInventory = true;
  bool _autoPushOrders = true;
  String? _registeredDeviceUuid;
  DateTime? _lastPushAt;
  DateTime? _lastPullAt;
  String? _apiKeyMasked;
  CloudSyncQueueStats _queueStats = const CloudSyncQueueStats(
    pending: 0,
    processing: 0,
    failed: 0,
    done: 0,
  );
  List<CloudSyncQueueEntryView> _recentEntries =
      const <CloudSyncQueueEntryView>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _serverUrlCtrl.dispose();
    _databaseCtrl.dispose();
    _deviceLabelCtrl.dispose();
    _bootstrapTokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final ds = ref.read(cloudSyncLocalDataSourceProvider);
      final config = await ds.loadConfig();
      final credentials = await ds.loadCredentials();
      final stats = await ds.loadQueueStats();
      final entries = await ds.listQueueEntries();
      if (!mounted) {
        return;
      }
      _serverUrlCtrl.text = config.serverUrl;
      _databaseCtrl.text = config.databaseName;
      _deviceLabelCtrl.text = config.deviceLabel;
      _bootstrapTokenCtrl.text = credentials.bootstrapToken ?? '';
      setState(() {
        _enabled = config.enabled;
        _autoPullCatalogs = config.autoPullCatalogs;
        _autoPushSales = config.autoPushSales;
        _autoPushInventory = config.autoPushInventory;
        _autoPushOrders = config.autoPushOrders;
        _registeredDeviceUuid = config.registeredDeviceUuid;
        _lastPushAt = config.lastPushAt;
        _lastPullAt = config.lastPullAt;
        _apiKeyMasked = _maskKey(credentials.apiKey);
        _queueStats = stats;
        _recentEntries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar la configuración cloud: $e');
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final ds = ref.read(cloudSyncLocalDataSourceProvider);
      final config = CloudSyncConfig(
        enabled: _enabled,
        serverUrl: _serverUrlCtrl.text.trim(),
        databaseName: _databaseCtrl.text.trim(),
        deviceLabel: _deviceLabelCtrl.text.trim(),
        autoPullCatalogs: _autoPullCatalogs,
        autoPushSales: _autoPushSales,
        autoPushInventory: _autoPushInventory,
        autoPushOrders: _autoPushOrders,
        registeredDeviceUuid: _registeredDeviceUuid,
        lastPushAt: _lastPushAt,
        lastPullAt: _lastPullAt,
      );
      final bool profileChanged = await ds.saveConfig(config);
      await ds.saveBootstrapToken(_bootstrapTokenCtrl.text.trim());
      if (!mounted) {
        return;
      }
      if (profileChanged) {
        setState(() {
          _registeredDeviceUuid = null;
          _lastPushAt = null;
          _lastPullAt = null;
          _apiKeyMasked = null;
        });
        _show(
          'Servidor actualizado. Se limpió el vínculo anterior y al registrar este dispositivo se preparará una resincronización completa.',
        );
      } else {
        _show('Configuración de sincronización guardada.');
      }
    } catch (e) {
      _show('No se pudo guardar la configuración: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() => _saving = true);
    try {
      await _save();
      final result =
          await ref.read(cloudSyncOrchestratorProvider).testConnection();
      if (!mounted) {
        return;
      }
      _show(result.message);
    } catch (e) {
      _show('No se pudo probar la conexión: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _registerDevice() async {
    setState(() => _saving = true);
    try {
      await _save();
      final String token = _bootstrapTokenCtrl.text.trim();
      if (token.isEmpty) {
        throw Exception(
          'Debes escribir el token de arranque antes de registrar el dispositivo.',
        );
      }
      final result =
          await ref.read(cloudSyncOrchestratorProvider).registerCurrentDevice();
      if (!mounted) {
        return;
      }
      _show(result.message);
      await _loadData();
    } catch (e) {
      _show('No se pudo registrar el dispositivo: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pushPending() async {
    setState(() => _saving = true);
    try {
      final result =
          await ref.read(cloudSyncOrchestratorProvider).pushPendingQueue();
      if (!mounted) {
        return;
      }
      _show(result.message);
      await _loadData();
    } catch (e) {
      _show('No se pudieron enviar los cambios pendientes: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pullPreview() async {
    setState(() => _saving = true);
    try {
      final snapshot =
          await ref.read(cloudSyncOrchestratorProvider).pullMasterDataPreview();
      if (!mounted) {
        return;
      }
      _show(
        'Catálogos recibidos: ${snapshot.products.length} productos, '
        '${snapshot.customers.length} clientes, '
        '${snapshot.employees.length} empleados.',
      );
      await _loadData();
    } catch (e) {
      _show('No se pudieron descargar los catálogos: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pullWorkOrders() async {
    setState(() => _saving = true);
    try {
      final snapshot =
          await ref.read(cloudSyncOrchestratorProvider).pullWorkOrdersPreview();
      if (!mounted) {
        return;
      }
      _show(
        'Pedidos recibidos: ${snapshot.workOrders.length} registros del taller.',
      );
      await _loadData();
    } catch (e) {
      _show('No se pudieron descargar los pedidos del taller: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _prepareInitialSync() async {
    setState(() => _saving = true);
    try {
      final CloudSyncBootstrapSummary summary = await ref
          .read(cloudSyncOrchestratorProvider)
          .prepareInitialSyncBackfill();
      if (!mounted) {
        return;
      }
      _show(
        'Sincronización inicial preparada: '
        '${summary.productsQueued} productos, '
        '${summary.customersQueued} clientes, '
        '${summary.employeesQueued} empleados, '
        '${summary.warehousesQueued} almacenes y '
        '${summary.terminalsQueued} TPV, '
        '${summary.salesQueued} ventas, '
        '${summary.stockMovementsQueued} movimientos y '
        '${summary.workOrdersQueued} pedidos encolados.',
      );
      await _loadData();
    } catch (e) {
      _show('No se pudo preparar la sincronización inicial: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final bool canManageSync = session?.hasPermission('settings.data') ?? false;
    return AppScaffold(
      title: 'Sincronización Cloud',
      currentRoute: '/sync-cloud',
      showBottomNavigationBar: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: <Widget>[
                if (_saving) const LinearProgressIndicator(minHeight: 3),
                SwitchListTile.adaptive(
                  value: _enabled,
                  onChanged: canManageSync
                      ? (bool value) => setState(() => _enabled = value)
                      : null,
                  title: const Text('Activar sincronización con Odoo'),
                  subtitle: const Text(
                    'La app seguirá funcionando offline y sincronizará cuando tú lo decidas.',
                  ),
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _serverUrlCtrl,
                  label: 'URL del servidor',
                  hint: 'http://192.168.1.20:8062',
                  enabled: canManageSync,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _databaseCtrl,
                  label: 'Base de datos Odoo',
                  hint: 'posipv',
                  enabled: canManageSync,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _deviceLabelCtrl,
                  label: 'Etiqueta del dispositivo',
                  hint: 'Caja principal / Redmi admin',
                  enabled: canManageSync,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _bootstrapTokenCtrl,
                  label: 'Token de arranque',
                  hint: 'Solo para registrar el dispositivo',
                  enabled: canManageSync,
                  obscureText: _obscureBootstrapToken,
                  suffixIcon: IconButton(
                    tooltip: _obscureBootstrapToken
                        ? 'Mostrar token'
                        : 'Ocultar token',
                    onPressed: () {
                      setState(() {
                        _obscureBootstrapToken = !_obscureBootstrapToken;
                      });
                    },
                    icon: Icon(
                      _obscureBootstrapToken
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    _statusCard('Dispositivo',
                        _registeredDeviceUuid ?? 'Sin registrar'),
                    _statusCard('API key', _apiKeyMasked ?? 'No disponible'),
                    _statusCard('Último push', _formatDate(_lastPushAt)),
                    _statusCard('Último pull', _formatDate(_lastPullAt)),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Alcance de sincronización',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                CheckboxListTile(
                  value: _autoPullCatalogs,
                  onChanged: canManageSync
                      ? (bool? value) =>
                          setState(() => _autoPullCatalogs = value ?? true)
                      : null,
                  title: const Text('Descargar catálogos'),
                ),
                CheckboxListTile(
                  value: _autoPushSales,
                  onChanged: canManageSync
                      ? (bool? value) =>
                          setState(() => _autoPushSales = value ?? true)
                      : null,
                  title: const Text('Subir ventas y pagos'),
                ),
                CheckboxListTile(
                  value: _autoPushInventory,
                  onChanged: canManageSync
                      ? (bool? value) =>
                          setState(() => _autoPushInventory = value ?? true)
                      : null,
                  title: const Text('Subir inventario y movimientos'),
                ),
                CheckboxListTile(
                  value: _autoPushOrders,
                  onChanged: canManageSync
                      ? (bool? value) =>
                          setState(() => _autoPushOrders = value ?? true)
                      : null,
                  title: const Text('Subir pedidos del taller'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: canManageSync && !_saving ? _save : null,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          canManageSync && !_saving ? _testConnection : null,
                      icon: const Icon(Icons.wifi_tethering_outlined),
                      label: const Text('Probar conexión'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          canManageSync && !_saving ? _registerDevice : null,
                      icon: const Icon(Icons.app_registration_outlined),
                      label: const Text('Registrar dispositivo'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          canManageSync && !_saving ? _pushPending : null,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Enviar pendientes'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          canManageSync && !_saving ? _pullPreview : null,
                      icon: const Icon(Icons.cloud_download_outlined),
                      label: const Text('Descargar catálogos'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          canManageSync && !_saving ? _pullWorkOrders : null,
                      icon: const Icon(Icons.assignment_return_outlined),
                      label: const Text('Descargar pedidos taller'),
                    ),
                    OutlinedButton.icon(
                      onPressed: canManageSync && !_saving
                          ? _prepareInitialSync
                          : null,
                      icon: const Icon(Icons.queue_play_next_outlined),
                      label: const Text('Preparar sincronización inicial'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Cola local de sincronización',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    _statusCard('Pendientes', '${_queueStats.pending}'),
                    _statusCard('Procesando', '${_queueStats.processing}'),
                    _statusCard('Fallidos', '${_queueStats.failed}'),
                    _statusCard('Completados', '${_queueStats.done}'),
                  ],
                ),
                const SizedBox(height: 12),
                if (_recentEntries.isEmpty)
                  const ConfigOptionTile(
                    icon: Icons.inbox_outlined,
                    title: 'Sin movimientos en la cola',
                    subtitle: 'Cuando conectemos los módulos, aparecerán aquí.',
                  )
                else
                  ..._recentEntries.map(_buildQueueTile),
              ],
            ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool enabled,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        filled: true,
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _statusCard(String title, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueTile(CloudSyncQueueEntryView item) {
    return ConfigOptionTile(
      icon: item.status == 'failed'
          ? Icons.error_outline_rounded
          : Icons.sync_outlined,
      title: '${item.entityType} • ${item.operation}',
      subtitle:
          '${item.entityId} • ${item.status} • ${_formatDate(item.createdAt)}',
      onTap: item.lastError == null ? null : () => _show(item.lastError!),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Nunca';
    }
    final DateTime local = value.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }

  String? _maskKey(String? value) {
    final String clean = (value ?? '').trim();
    if (clean.isEmpty) {
      return null;
    }
    if (clean.length <= 8) {
      return '••••••••';
    }
    return '${clean.substring(0, 4)}••••${clean.substring(clean.length - 4)}';
  }
}
