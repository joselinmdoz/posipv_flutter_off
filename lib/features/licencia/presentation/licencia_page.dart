import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/licensing/license_models.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/widgets/code_scanner_page.dart';
import '../../../shared/widgets/app_scaffold.dart';
import 'widgets/license_activation_card.dart';
import 'widgets/license_request_qr_card.dart';
import 'widgets/license_status_card.dart';

class LicenciaPage extends ConsumerStatefulWidget {
  const LicenciaPage({super.key});

  @override
  ConsumerState<LicenciaPage> createState() => _LicenciaPageState();
}

class _LicenciaPageState extends ConsumerState<LicenciaPage> {
  final TextEditingController _licenseCtrl = TextEditingController();

  bool _refreshing = true;
  bool _activatingLicense = false;
  DateTime? _requestedExpiry;
  DeviceIdentity? _deviceIdentity;
  String? _requestCode;

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

  @override
  void dispose() {
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final PerfTrace trace = PerfTrace('licencia.load');
    setState(() => _refreshing = true);
    try {
      final Future<LicenseStatus> licenseFuture = forceRefresh
          ? ref.read(licenseControllerProvider.notifier).refresh()
          : ref.read(licenseControllerProvider.future);
      final Future<DeviceIdentity> identityFuture =
          (_deviceIdentity != null && !forceRefresh)
              ? Future<DeviceIdentity>.value(_deviceIdentity!)
              : ref.read(offlineLicenseServiceProvider).loadDeviceIdentity();

      final List<Object> loaded = await Future.wait<Object>(
        <Future<Object>>[
          licenseFuture,
          identityFuture,
        ],
      );
      trace.mark('datos cargados');
      final DeviceIdentity identity = loaded[1] as DeviceIdentity;
      if (!mounted) {
        trace.end('unmounted');
        return;
      }
      setState(() {
        _deviceIdentity = identity;
        _requestCode = _buildRequestCode(identity, _requestedExpiry);
        _refreshing = false;
      });
      trace.end(forceRefresh ? 'ok-refresh' : 'ok');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _refreshing = false);
      trace.end('error');
      _show('No se pudo cargar la licencia: $e');
    }
  }

  Future<void> _activateLicense() async {
    final String rawCode = _licenseCtrl.text.trim();
    if (rawCode.isEmpty) {
      _show('Pega un codigo de licencia valido.');
      return;
    }
    await _activateLicenseCode(rawCode, fromScan: false);
  }

  Future<void> _scanAndActivateLicense() async {
    if (_activatingLicense) {
      return;
    }
    final String? raw = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const CodeScannerPage(
          title: 'Escanear licencia',
          subtitle:
              'Escanea el QR del codigo de activacion para validarlo automaticamente.',
        ),
        fullscreenDialog: true,
      ),
    );
    if (!mounted) {
      return;
    }

    final String scanned = (raw ?? '').trim();
    if (scanned.isEmpty) {
      _show('No se detecto ningun codigo en el escaneo.');
      return;
    }

    final String? activationCode = _extractActivationCode(scanned);
    if (activationCode == null) {
      _show('El QR no contiene un codigo de activacion valido.');
      return;
    }

    _licenseCtrl.text = activationCode;
    await _activateLicenseCode(activationCode, fromScan: true);
  }

  Future<void> _activateLicenseCode(
    String rawCode, {
    required bool fromScan,
  }) async {
    final String normalized = rawCode.trim();
    if (normalized.isEmpty) {
      _show('Pega un codigo de licencia valido.');
      return;
    }

    setState(() => _activatingLicense = true);
    try {
      final LicenseStatus status = await ref
          .read(licenseControllerProvider.notifier)
          .activate(normalized);
      if (!mounted) {
        return;
      }
      if (!fromScan) {
        _licenseCtrl.clear();
      }
      _show('Licencia valida. ${status.message}');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('Licencia no valida: $e');
    } finally {
      if (mounted) {
        setState(() => _activatingLicense = false);
      }
    }
  }

  Future<void> _clearActivation() async {
    setState(() => _activatingLicense = true);
    try {
      final LicenseStatus status =
          await ref.read(licenseControllerProvider.notifier).clearActivation();
      if (!mounted) {
        return;
      }
      _show(status.message);
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo limpiar la licencia: $e');
    } finally {
      if (mounted) {
        setState(() => _activatingLicense = false);
      }
    }
  }

  Future<void> _pickRequestedExpiry() async {
    final DateTime now = DateTime.now();
    final DateTime initial =
        _requestedExpiry ?? now.add(const Duration(days: 365));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10, 12, 31),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _requestedExpiry = picked;
      _requestCode = _buildRequestCode(_deviceIdentity, picked);
    });
  }

  Future<void> _copyRequestCode(String requestCode) async {
    await Clipboard.setData(ClipboardData(text: requestCode));
    if (!mounted) {
      return;
    }
    _show('Codigo del dispositivo copiado.');
  }

  Future<void> _shareRequestCode({
    required String requestCode,
    required DeviceIdentity? device,
  }) async {
    final String message = _buildShareMessage(
      requestCode: requestCode,
      device: device,
    );
    final bool shared =
        await ref.read(offlineLicenseServiceProvider).shareRequestCode(
              requestCode: message,
              subject: 'Solicitud de licencia POSIPV',
            );
    if (!mounted) {
      return;
    }
    if (shared) {
      _show('Codigo del dispositivo compartido.');
    } else {
      await _copyRequestCode(requestCode);
      _show(
          'No se pudo abrir el menu de compartir. El codigo se copio al portapapeles.');
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<LicenseStatus> licenseAsync =
        ref.watch(licenseControllerProvider);
    final LicenseStatus license = ref.watch(currentLicenseStatusProvider);
    final DeviceIdentity? device = _deviceIdentity ?? license.deviceIdentity;
    final String? requestCode =
        _requestCode ?? _buildRequestCode(device, _requestedExpiry);

    return AppScaffold(
      title: 'Licencia',
      currentRoute: '/licencia',
      onRefresh: () => _load(forceRefresh: true),
      showTopTabs: false,
      body: _refreshing
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(forceRefresh: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: <Widget>[
                  LicenseStatusCard(
                    license: license,
                    dateFormatter: _formatDateTime,
                  ),
                  const SizedBox(height: 24),
                  LicenseRequestQrCard(
                    requestCode: requestCode,
                    device: device,
                    requestedExpiry: _requestedExpiry,
                    onPickExpiryDate: _pickRequestedExpiry,
                    onShareQr: () {
                      if (requestCode != null) {
                        _shareRequestCode(
                          requestCode: requestCode,
                          device: device,
                        );
                      } else {
                        _show('Aún no se ha generado el código.');
                      }
                    },
                    dateFormatter: _formatDate,
                  ),
                  const SizedBox(height: 24),
                  LicenseActivationCard(
                    controller: _licenseCtrl,
                    isActivating: _activatingLicense,
                    onActivate: _activateLicense,
                    onScanQr: _scanAndActivateLicense,
                  ),
                  if (license.isFull) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _activatingLicense ? null : _clearActivation,
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Remover licencia activa'),
                      ),
                    ),
                  ],
                  if (licenseAsync.hasError) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Último error de licencia: ${licenseAsync.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }


  String _formatDate(DateTime value) {
    final DateTime local = value.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _buildShareMessage({
    required String requestCode,
    required DeviceIdentity? device,
  }) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('Solicitud de licencia POSIPV')
      ..writeln(
        'Dispositivo: ${device?.displayName ?? 'No disponible'}',
      )
      ..writeln(
        'Caducidad solicitada: ${_requestedExpiry == null ? 'No especificada' : _formatDate(_requestedExpiry!)}',
      )
      ..writeln()
      ..writeln('Codigo:')
      ..write(requestCode);
    return buffer.toString();
  }

  String? _buildRequestCode(
    DeviceIdentity? identity,
    DateTime? requestedExpiry,
  ) {
    if (identity == null) {
      return null;
    }
    return ref.read(offlineLicenseServiceProvider).buildRequestCode(
          identity,
          requestedExpiry: requestedExpiry,
        );
  }

  String? _extractActivationCode(String value) {
    final String compact = value.replaceAll(RegExp(r'\s+'), '');
    final RegExp tokenPattern =
        RegExp(r'POSIPV1\.[A-Za-z0-9_-]+=*\.[A-Za-z0-9_-]+=*');

    final Match? compactMatch = tokenPattern.firstMatch(compact);
    if (compactMatch != null) {
      return compactMatch.group(0);
    }

    final Match? rawMatch = tokenPattern.firstMatch(value);
    return rawMatch?.group(0);
  }
}
