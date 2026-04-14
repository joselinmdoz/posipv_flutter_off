import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../data/manual_sync_local_datasource.dart';
import 'manual_sync_providers.dart';
import 'widgets/manual_sync_export_card.dart';
import 'widgets/manual_sync_import_card.dart';

class ManualSyncPage extends ConsumerStatefulWidget {
  const ManualSyncPage({super.key});

  @override
  ConsumerState<ManualSyncPage> createState() => _ManualSyncPageState();
}

class _ManualSyncPageState extends ConsumerState<ManualSyncPage> {
  final TextEditingController _pathController = TextEditingController();

  bool _loading = true;
  bool _exporting = false;
  bool _previewing = false;
  bool _importing = false;

  List<ManualSyncSessionOption> _sessions = <ManualSyncSessionOption>[];
  List<ManualSyncPackageFileOption> _files = <ManualSyncPackageFileOption>[];

  String? _selectedSessionId;
  String? _selectedFilePath;

  String? _lastExportPath;
  ManualSyncPackagePreview? _preview;
  ManualSyncImportResult? _lastImportResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadData();
    });
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final ManualSyncLocalDataSource ds =
          ref.read(manualSyncLocalDataSourceProvider);
      final List<ManualSyncSessionOption> sessions =
          await ds.listClosedSessionsForExport();
      final List<ManualSyncPackageFileOption> files =
          await ds.listPackageFiles();
      if (!mounted) {
        return;
      }

      final String? sessionId = _ensureSelectedSession(
        current: _selectedSessionId,
        sessions: sessions,
      );
      final String? filePath = _ensureSelectedFile(
        current: _selectedFilePath,
        files: files,
      );

      setState(() {
        _sessions = sessions;
        _files = files;
        _selectedSessionId = sessionId;
        _selectedFilePath = filePath;
        _loading = false;
      });
      if ((filePath ?? '').isNotEmpty && _pathController.text.trim().isEmpty) {
        _pathController.text = filePath!;
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar la sincronización: $e');
    }
  }

  Future<void> _exportSelectedSession() async {
    final String sessionId = (_selectedSessionId ?? '').trim();
    if (sessionId.isEmpty) {
      _show('Selecciona un turno cerrado.');
      return;
    }

    setState(() => _exporting = true);
    try {
      final ManualSyncLocalDataSource ds =
          ref.read(manualSyncLocalDataSourceProvider);
      final ManualSyncExportResult result = await ds.exportClosedSessionPackage(
        sessionId: sessionId,
        sourceLabel: 'TPV-${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lastExportPath = result.filePath;
      });
      _show('Paquete exportado correctamente.');
      await _loadData();
    } catch (e) {
      _show('No se pudo exportar el turno: $e');
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _shareLastExportPackage() async {
    final String path = (_lastExportPath ?? '').trim();
    if (path.isEmpty) {
      _show('Primero exporta un paquete para poder compartirlo.');
      return;
    }
    final File file = File(path);
    if (!file.existsSync()) {
      _show('El archivo exportado no existe. Exporta nuevamente.');
      return;
    }
    try {
      await Share.shareXFiles(
        <XFile>[XFile(path)],
        text: 'Paquete de sincronización manual POSIPV',
        subject: 'Sincronización manual POSIPV',
      );
    } catch (e) {
      _show('No se pudo compartir el paquete: $e');
    }
  }

  Future<void> _previewPackage() async {
    final String path = _pathController.text.trim();
    if (path.isEmpty) {
      _show('Indica la ruta del archivo o selecciónalo de la lista.');
      return;
    }

    setState(() {
      _previewing = true;
      _preview = null;
    });

    try {
      final ManualSyncPackagePreview preview = await ref
          .read(manualSyncLocalDataSourceProvider)
          .previewPackageFromFile(
            path,
          );
      if (!mounted) {
        return;
      }
      setState(() => _preview = preview);
      _show(preview.message);
    } catch (e) {
      _show('No se pudo validar el paquete: $e');
    } finally {
      if (mounted) {
        setState(() => _previewing = false);
      }
    }
  }

  Future<void> _importPackage() async {
    final String path = _pathController.text.trim();
    if (path.isEmpty) {
      _show('Indica la ruta del paquete a importar.');
      return;
    }

    if (_preview == null || !_preview!.isValid || _preview!.filePath != path) {
      await _previewPackage();
      if (_preview == null ||
          !_preview!.isValid ||
          _preview!.filePath != path) {
        return;
      }
    }

    setState(() => _importing = true);
    try {
      final ManualSyncImportResult result = await ref
          .read(manualSyncLocalDataSourceProvider)
          .importPackageFromFile(
            path,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _lastImportResult = result;
      });
      _show('Importación finalizada con éxito.');
      await _loadData();
    } catch (e) {
      _show('No se pudo importar el paquete: $e');
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  Future<void> _pickPackageFromDevice() async {
    try {
      final String? pickedPath = await ref
          .read(manualSyncLocalDataSourceProvider)
          .pickSyncPackageFileWithSystemExplorer();
      if (!mounted || pickedPath == null || pickedPath.trim().isEmpty) {
        return;
      }
      setState(() {
        _selectedFilePath = null;
        _preview = null;
        _lastImportResult = null;
      });
      _pathController.text = pickedPath;
      _show('Archivo seleccionado desde el gestor de archivos.');
    } catch (e) {
      _show('No se pudo seleccionar archivo: $e');
    }
  }

  void _onFileSelected(String? path) {
    setState(() {
      _selectedFilePath = path;
      _preview = null;
      _lastImportResult = null;
    });
    if ((path ?? '').trim().isNotEmpty) {
      _pathController.text = path!;
    }
  }

  void _onPathChanged(String value) {
    setState(() {
      _preview = null;
      _lastImportResult = null;
      if (value.trim() != (_selectedFilePath ?? '').trim()) {
        _selectedFilePath = null;
      }
    });
  }

  String? _ensureSelectedSession({
    required String? current,
    required List<ManualSyncSessionOption> sessions,
  }) {
    final String currentId = (current ?? '').trim();
    if (currentId.isNotEmpty &&
        sessions
            .any((ManualSyncSessionOption row) => row.sessionId == currentId)) {
      return currentId;
    }
    if (sessions.isEmpty) {
      return null;
    }
    return sessions.first.sessionId;
  }

  String? _ensureSelectedFile({
    required String? current,
    required List<ManualSyncPackageFileOption> files,
  }) {
    final String currentPath = (current ?? '').trim();
    if (currentPath.isNotEmpty &&
        files.any(
            (ManualSyncPackageFileOption row) => row.filePath == currentPath)) {
      return currentPath;
    }
    if (files.isEmpty) {
      return null;
    }
    return files.first.filePath;
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
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: AppScaffold(
        title: 'Sincronización Manual',
        currentRoute: '/sync-manual',
        showDrawer: false,
        useDefaultActions: false,
        showBottomNavigationBar: false,
        appBarLeading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EFFB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Flujo recomendado: en el TPV exporta el turno cerrado y en el dispositivo administrador impórtalo para consolidar ventas y movimientos.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    ManualSyncExportCard(
                      sessions: _sessions,
                      selectedSessionId: _selectedSessionId,
                      onSessionChanged: (String? value) {
                        setState(() => _selectedSessionId = value);
                      },
                      onExport: _exportSelectedSession,
                      onShare: _shareLastExportPackage,
                      exporting: _exporting,
                      lastExportPath: _lastExportPath,
                    ),
                    const SizedBox(height: 14),
                    ManualSyncImportCard(
                      files: _files,
                      selectedFilePath: _selectedFilePath,
                      onSelectedFileChanged: _onFileSelected,
                      pathController: _pathController,
                      onPathChanged: _onPathChanged,
                      onPickFromDevice: _pickPackageFromDevice,
                      onRefreshFiles: _loadData,
                      onPreview: _previewPackage,
                      onImport: _importPackage,
                      previewing: _previewing,
                      importing: _importing,
                      preview: _preview,
                      lastImportResult: _lastImportResult,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
