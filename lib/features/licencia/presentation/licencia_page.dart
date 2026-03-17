import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/licensing/license_models.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/widgets/code_scanner_page.dart';
import '../../../shared/widgets/app_scaffold.dart';

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
                  _buildHeader(context, license),
                  const SizedBox(height: 14),
                  _buildValidityCard(context, license),
                  const SizedBox(height: 14),
                  _buildRequestSection(context, requestCode, device),
                  const SizedBox(height: 14),
                  _buildActivationSection(context, license, licenseAsync),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, LicenseStatus license) {
    final ThemeData theme = Theme.of(context);
    final bool isActive = license.isActive;
    final Color tone = isActive
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.errorContainer;
    final Color onTone = isActive
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: onTone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isActive
                      ? Icons.verified_user_outlined
                      : Icons.lock_outline_rounded,
                  color: onTone,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  license.statusLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: onTone,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            license.message,
            style: theme.textTheme.bodyMedium?.copyWith(color: onTone),
          ),
          if (license.customerName != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Cliente: ${license.customerName}',
              style: theme.textTheme.bodyMedium?.copyWith(color: onTone),
            ),
          ],
          if (license.expiresAt != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Vence: ${_formatDateTime(license.expiresAt!)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: onTone),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValidityCard(BuildContext context, LicenseStatus license) {
    final ThemeData theme = Theme.of(context);
    final int? days = license.daysRemaining;
    final bool hasExpiry = license.expiresAt != null;
    final bool expired = hasExpiry && (days ?? 0) <= 0;

    final Color tone = expired
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.secondaryContainer;
    final Color onTone = expired
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSecondaryContainer;

    final String headline = !hasExpiry
        ? 'Sin fecha de caducidad'
        : expired
            ? 'Licencia expirada'
            : 'Licencia vigente';
    final String value = !hasExpiry ? '∞' : '${days ?? 0}';
    final String suffix = !hasExpiry
        ? 'sin límite'
        : (days == 1 ? 'día restante' : 'días restantes');

    final double progress;
    if (!hasExpiry || expired) {
      progress = expired ? 0 : 1;
    } else if (license.startedAt != null) {
      final int totalDays =
          license.expiresAt!.difference(license.startedAt!).inDays + 1;
      progress = ((days ?? 0) / (totalDays <= 0 ? 1 : totalDays))
          .clamp(0.0, 1.0)
          .toDouble();
    } else {
      progress = ((days ?? 0) / 30).clamp(0.0, 1.0).toDouble();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Validez de licencia',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: onTone,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                value,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: onTone,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  suffix,
                  style: theme.textTheme.bodyLarge?.copyWith(color: onTone),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            color: onTone,
            backgroundColor: onTone.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          Text(
            headline,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onTone,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (license.expiresAt != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Vence: ${_formatDateTime(license.expiresAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(color: onTone),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestSection(
    BuildContext context,
    String? requestCode,
    DeviceIdentity? device,
  ) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Solicitud de licencia',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/configuracion'),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Ajustes'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Comparte este codigo o su QR para emitir una licencia. La fecha seleccionada es una solicitud y no reemplaza la firma final.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dispositivo'),
              subtitle: Text(device?.displayName ?? 'No disponible'),
              trailing: IconButton(
                onPressed: _pickRequestedExpiry,
                icon: const Icon(Icons.edit_calendar_outlined),
                tooltip: 'Seleccionar fecha',
              ),
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: _pickRequestedExpiry,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _requestedExpiry == null
                    ? 'Solicitar fecha de caducidad'
                    : 'Caducidad solicitada: ${_formatDate(_requestedExpiry!)}',
              ),
            ),
            if (_requestedExpiry != null) ...<Widget>[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _requestedExpiry = null),
                child: const Text('Quitar fecha solicitada'),
              ),
            ],
            const SizedBox(height: 12),
            if (requestCode != null) ...<Widget>[
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: QrImageView(
                      data: requestCode,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                      errorStateBuilder: (BuildContext context, Object? error) {
                        return SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(
                            child: Text(
                              'No se pudo generar el QR.\nUsa copiar o compartir.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _shareRequestCode(
                    requestCode: requestCode,
                    device: device,
                  ),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Compartir'),
                ),
              ),
            ] else
              const Text('No se pudo preparar el codigo del dispositivo.'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivationSection(
    BuildContext context,
    LicenseStatus license,
    AsyncValue<LicenseStatus> licenseAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Activacion',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _licenseCtrl,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Codigo de activacion',
                hintText: 'Pega aqui el codigo POSIPV1...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _activatingLicense ? null : _activateLicense,
                    icon: const Icon(Icons.verified_outlined),
                    label: Text(
                      _activatingLicense ? 'Validando...' : 'Activar',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _activatingLicense ? null : _scanAndActivateLicense,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Escanear QR'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: _activatingLicense || !license.isFull
                    ? null
                    : _clearActivation,
                child: const Text('Quitar'),
              ),
            ),
            if (licenseAsync.hasError) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                'Ultimo error de licencia: ${licenseAsync.error}',
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
