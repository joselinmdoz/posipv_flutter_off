import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../auth/presentation/auth_providers.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../data/data_management_local_datasource.dart';
import 'configuracion_providers.dart';

class GestionDatosPage extends ConsumerStatefulWidget {
  const GestionDatosPage({super.key});

  @override
  ConsumerState<GestionDatosPage> createState() => _GestionDatosPageState();
}

class _GestionDatosPageState extends ConsumerState<GestionDatosPage> {
  static const String _pickBackupSentinelPath = '__pick_backup_file__';
  bool _loadingFiles = true;
  bool _working = false;
  String? _rootPath;
  List<DataFileEntry> _csvFiles = <DataFileEntry>[];
  List<DataFileEntry> _backupFiles = <DataFileEntry>[];
  List<DataFileEntry> _qrPdfFiles = <DataFileEntry>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadFiles();
    });
  }

  Future<void> _loadFiles() async {
    if (mounted) {
      setState(() => _loadingFiles = true);
    }
    final DataManagementLocalDataSource ds =
        ref.read(dataManagementLocalDataSourceProvider);
    try {
      final String rootPath = await ds.dataRootPath();
      final List<DataFileEntry> csvFiles = await ds.listCsvFiles();
      final List<DataFileEntry> backupFiles = await ds.listBackupFiles();
      final List<DataFileEntry> qrPdfFiles = await ds.listQrPdfFiles();
      if (!mounted) {
        return;
      }
      setState(() {
        _rootPath = rootPath;
        _csvFiles = csvFiles;
        _backupFiles = backupFiles;
        _qrPdfFiles = qrPdfFiles;
        _loadingFiles = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingFiles = false);
      _show('No se pudo cargar gestión de datos: $e');
    }
  }

  Future<void> _createBackup() async {
    setState(() => _working = true);
    try {
      final BackupResult result = await ref
          .read(dataManagementLocalDataSourceProvider)
          .createDatabaseBackup();
      await _loadFiles();
      if (!mounted) {
        return;
      }
      _show(
        'Copia creada (${_bytes(result.sizeBytes)})\n${result.path}',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo crear la copia: $e');
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _openBackupRestoreSheet() async {
    final DataManagementLocalDataSource ds =
        ref.read(dataManagementLocalDataSourceProvider);
    final List<DataFileEntry> backupFiles = _backupFiles;
    final TextEditingController manualPathCtrl = TextEditingController();

    DataFileEntry? selected = await showModalBottomSheet<DataFileEntry>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              const ListTile(
                title: Text(
                  'Selecciona copia para restaurar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Selecciona una copia detectada automáticamente o pega la ruta manual del archivo .db',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: manualPathCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ruta manual del respaldo',
                    hintText:
                        '/storage/emulated/0/Download/POSIPV/Backups/mi-copia.db',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final String path = manualPathCtrl.text.trim();
                      if (path.isEmpty) {
                        return;
                      }
                      Navigator.of(context).pop(
                        DataFileEntry(
                          path: path,
                          name: p.basename(path),
                          modifiedAt: DateTime.now(),
                          sizeBytes: 0,
                        ),
                      );
                    },
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Usar esta ruta'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(
                        DataFileEntry(
                          path: _pickBackupSentinelPath,
                          name: 'Explorar archivo',
                          modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
                          sizeBytes: 0,
                        ),
                      );
                    },
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('Explorar archivo (.db)'),
                  ),
                ),
              ),
              if (backupFiles.isEmpty)
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('No se encontraron copias automáticamente'),
                  subtitle: Text(
                    'Coloca un respaldo en ${_rootPath ?? "Download/POSIPV/Backups"} o usa ruta manual.',
                  ),
                ),
              for (final DataFileEntry file in backupFiles)
                ListTile(
                  leading: const Icon(Icons.folder_copy_outlined),
                  title: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${_dateTime(file.modifiedAt)} • ${_bytes(file.sizeBytes)}',
                  ),
                  onTap: () => Navigator.of(context).pop(file),
                ),
            ],
          ),
        );
      },
    );
    manualPathCtrl.dispose();
    if (selected == null || !mounted) {
      return;
    }

    if (selected.path == _pickBackupSentinelPath) {
      try {
        final String? pickedPath = await ds.pickBackupFileWithSystemExplorer();
        if (!mounted || pickedPath == null || pickedPath.trim().isEmpty) {
          return;
        }
        selected = DataFileEntry(
          path: pickedPath,
          name: p.basename(pickedPath),
          modifiedAt: DateTime.now(),
          sizeBytes: 0,
        );
      } catch (e) {
        if (mounted) {
          _show('No se pudo abrir el explorador: $e');
        }
        return;
      }
    }

    final bool confirm = await _confirm(
      title: 'Restaurar copia de seguridad',
      message:
          'Se reemplazarán todos los datos actuales por:\n${selected.path}\n\n¿Deseas continuar?',
    );
    if (!confirm || !mounted) {
      return;
    }
    await _restoreBackup(selected.path);
  }

  Future<void> _restoreBackup(String filePath) async {
    setState(() => _working = true);
    try {
      final BackupRestoreResult result = await ref
          .read(dataManagementLocalDataSourceProvider)
          .restoreDatabaseBackup(filePath);
      if (!mounted) {
        return;
      }

      await _showRestoreSuccessDialog(result.tablesRestored);
      if (!mounted) {
        return;
      }

      await ref.read(authLocalDataSourceProvider).markForceReloginOnce();
      ref.read(currentSessionProvider.notifier).state = null;
      try {
        await ref
            .read(localAuthServiceProvider)
            .clearRememberedSession()
            .timeout(const Duration(seconds: 2));
      } catch (_) {}
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo restaurar la copia: $e');
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _exportProductsCsv() async {
    setState(() => _working = true);
    try {
      final CsvExportResult result = await ref
          .read(dataManagementLocalDataSourceProvider)
          .exportProductsCsv();
      await _loadFiles();
      if (!mounted) {
        return;
      }
      _show(
        'Exportados ${result.count} producto(s)\n${result.path}',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo exportar CSV: $e');
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _exportProductsQrPdf() async {
    setState(() => _working = true);
    try {
      final QrPdfExportResult result = await ref
          .read(dataManagementLocalDataSourceProvider)
          .exportProductsQrPdf();
      await _loadFiles();
      if (!mounted) {
        return;
      }
      _show(
        'PDF QR generado (${result.count} productos)\n${result.path}',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo exportar PDF QR: $e');
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _openCsvImportSheet() async {
    final List<DataFileEntry> csvFiles = _csvFiles;
    if (csvFiles.isEmpty) {
      _show(
        'No hay archivos CSV.\n'
        'Coloca tu CSV en: ${_rootPath ?? "Download/POSIPV/Import"}',
      );
      return;
    }

    final DataFileEntry? selected = await showModalBottomSheet<DataFileEntry>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              const ListTile(
                title: Text(
                  'Selecciona CSV para importar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              for (final DataFileEntry file in csvFiles)
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${_dateTime(file.modifiedAt)} • ${_bytes(file.sizeBytes)}',
                  ),
                  onTap: () => Navigator.of(context).pop(file),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    final bool confirm = await _confirm(
      title: 'Importar productos',
      message:
          'Se importará el archivo:\n${selected.path}\n\n¿Deseas continuar?',
    );
    if (!confirm || !mounted) {
      return;
    }
    await _importProductsCsv(selected.path);
  }

  Future<void> _importProductsCsv(String filePath) async {
    setState(() => _working = true);
    try {
      final CsvImportResult result = await ref
          .read(dataManagementLocalDataSourceProvider)
          .importProductsCsv(filePath);
      await _loadFiles();
      if (!mounted) {
        return;
      }
      final StringBuffer msg = StringBuffer()
        ..writeln('Importación completada')
        ..writeln('Creados: ${result.created}')
        ..writeln('Actualizados: ${result.updated}')
        ..writeln('Omitidos: ${result.skipped}');
      if (result.warnings.isNotEmpty) {
        msg.writeln('Avisos: ${result.warnings.length}');
      }
      _show(msg.toString().trim());
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo importar CSV: $e');
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _resetData() async {
    final bool confirm = await _confirm(
      title: 'Reiniciar datos',
      message:
          'Esta acción eliminará datos operativos del negocio: productos, almacenes, TPV, empleados, inventario, ventas, clientes, IPV y auditoría.\n\n'
          'No eliminará usuarios ni permisos.\n\n'
          '¿Deseas continuar?',
    );
    if (!confirm || !mounted) {
      return;
    }

    setState(() => _working = true);
    try {
      final DataResetResult result = await ref
          .read(dataManagementLocalDataSourceProvider)
          .resetOperationalData();
      await _loadFiles();
      if (!mounted) {
        return;
      }
      _show(
        'Datos reiniciados correctamente.\n'
        'Tablas limpiadas: ${result.tablesCleared}\n'
        'Fecha: ${_dateTime(result.resetAt)}',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo reiniciar datos: $e');
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  void _showSoon() {
    _show('Próximamente.');
  }

  void _showFullLicenseRequired() {
    _show(
      'Modo demo: esta función está disponible solo con licencia activa.',
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showRestoreSuccessDialog(int tablesRestored) async {
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Copia restaurada'),
          content: Text(
            'Se restauraron $tablesRestored tablas correctamente.\n'
            'Debes iniciar sesión nuevamente.',
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final license = ref.watch(currentLicenseStatusProvider);
    final bool isFullLicense = license.isFull;
    final bool isLicenseLoading = license.isLoading;
    final bool blockDataOps = !isFullLicense && !isLicenseLoading;

    return AppScaffold(
      title: 'Gestión de datos',
      currentRoute: '/configuracion',
      showTopTabs: false,
      onRefresh: _loadFiles,
      body: _loadingFiles
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: <Widget>[
                if (_working) const LinearProgressIndicator(minHeight: 3),
                if (blockDataOps)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Modo demo: importación/exportación y salvas de base de datos requieren licencia activa.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                _section('Copia de seguridad y restaurar'),
                _option(
                  icon: Icons.storage_rounded,
                  title: 'Almacenamiento del teléfono',
                  subtitle: isFullLicense
                      ? 'Crear copia completa de la base de datos'
                      : 'Disponible con licencia activa',
                  onTap: _working || isLicenseLoading
                      ? null
                      : (isFullLicense
                          ? _createBackup
                          : _showFullLicenseRequired),
                ),
                _option(
                  icon: Icons.restore_rounded,
                  title: 'Restaurar copia',
                  subtitle: isFullLicense
                      ? 'Restaurar base de datos desde respaldo (.db)'
                      : 'Disponible con licencia activa',
                  onTap: _working || isLicenseLoading
                      ? null
                      : (isFullLicense
                          ? _openBackupRestoreSheet
                          : _showFullLicenseRequired),
                ),
                const SizedBox(height: 16),
                _section('Importar Datos'),
                _option(
                  icon: Icons.table_chart_outlined,
                  title: 'Excel (.csv)',
                  subtitle: isFullLicense
                      ? 'Importar productos desde CSV'
                      : 'Disponible con licencia activa',
                  onTap: _working || isLicenseLoading
                      ? null
                      : (isFullLicense
                          ? _openCsvImportSheet
                          : _showFullLicenseRequired),
                ),
                _option(
                  icon: Icons.receipt_long_outlined,
                  title: 'QIF',
                  subtitle: 'Próximamente',
                  onTap: _working ? null : _showSoon,
                ),
                const SizedBox(height: 16),
                _section('Exportar Datos'),
                _option(
                  icon: Icons.ios_share_rounded,
                  title: 'Productos (.csv)',
                  subtitle: isFullLicense
                      ? 'Exportar productos activos'
                      : 'Disponible con licencia activa',
                  onTap: _working || isLicenseLoading
                      ? null
                      : (isFullLicense
                          ? _exportProductsCsv
                          : _showFullLicenseRequired),
                ),
                _option(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Etiquetas QR (.pdf)',
                  subtitle: isFullLicense
                      ? 'Exportar QR para impresión'
                      : 'Disponible con licencia activa',
                  onTap: _working || isLicenseLoading
                      ? null
                      : (isFullLicense
                          ? _exportProductsQrPdf
                          : _showFullLicenseRequired),
                ),
                const SizedBox(height: 16),
                _section('Reiniciar datos'),
                _option(
                  icon: Icons.restart_alt_rounded,
                  title: 'Reiniciar datos',
                  subtitle: isFullLicense
                      ? 'Eliminar datos operativos y restaurar estado base'
                      : 'Disponible con licencia activa',
                  onTap: _working || isLicenseLoading
                      ? null
                      : (isFullLicense ? _resetData : _showFullLicenseRequired),
                ),
                const SizedBox(height: 20),
                if (_rootPath != null)
                  Text(
                    'Ruta base: $_rootPath',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (_backupFiles.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  const Text(
                    'Copias recientes',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  for (final DataFileEntry item in _backupFiles.take(5))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.folder_copy_outlined),
                      title: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_dateTime(item.modifiedAt)} • ${_bytes(item.sizeBytes)}',
                      ),
                    ),
                ],
                if (_qrPdfFiles.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  const Text(
                    'PDF QR recientes',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  for (final DataFileEntry item in _qrPdfFiles.take(5))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_dateTime(item.modifiedAt)} • ${_bytes(item.sizeBytes)}',
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _option({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  String _bytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final double kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final double mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _dateTime(DateTime value) {
    final DateTime local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
