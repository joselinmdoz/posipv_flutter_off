import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../data/data_management_local_datasource.dart';
import 'configuracion_providers.dart';

class GestionDatosPage extends ConsumerStatefulWidget {
  const GestionDatosPage({super.key});

  @override
  ConsumerState<GestionDatosPage> createState() => _GestionDatosPageState();
}

class _GestionDatosPageState extends ConsumerState<GestionDatosPage> {
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

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
                _section('Copia de seguridad y restaurar'),
                _option(
                  icon: Icons.storage_rounded,
                  title: 'Almacenamiento del teléfono',
                  subtitle: 'Crear copia completa de la base de datos',
                  onTap: _working ? null : _createBackup,
                ),
                _option(
                  icon: Icons.restore_rounded,
                  title: 'Restaurar copia',
                  subtitle: 'Próximamente',
                  onTap: _working ? null : _showSoon,
                ),
                const SizedBox(height: 16),
                _section('Importar Datos'),
                _option(
                  icon: Icons.table_chart_outlined,
                  title: 'Excel (.csv)',
                  subtitle: 'Importar productos desde CSV',
                  onTap: _working ? null : _openCsvImportSheet,
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
                  subtitle: 'Exportar productos activos',
                  onTap: _working ? null : _exportProductsCsv,
                ),
                _option(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Etiquetas QR (.pdf)',
                  subtitle: 'Exportar QR para impresión',
                  onTap: _working ? null : _exportProductsQrPdf,
                ),
                const SizedBox(height: 16),
                _section('Reiniciar datos'),
                _option(
                  icon: Icons.restart_alt_rounded,
                  title: 'Reiniciar datos',
                  subtitle: 'Próximamente',
                  onTap: _working ? null : _showSoon,
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
