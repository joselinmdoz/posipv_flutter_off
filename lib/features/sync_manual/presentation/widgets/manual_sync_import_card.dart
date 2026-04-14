import 'package:flutter/material.dart';

import '../../data/manual_sync_local_datasource.dart';

class ManualSyncImportCard extends StatelessWidget {
  const ManualSyncImportCard({
    super.key,
    required this.files,
    required this.selectedFilePath,
    required this.onSelectedFileChanged,
    required this.pathController,
    required this.onPathChanged,
    required this.onPickFromDevice,
    required this.onRefreshFiles,
    required this.onPreview,
    required this.onImport,
    required this.previewing,
    required this.importing,
    required this.preview,
    this.lastImportResult,
  });

  final List<ManualSyncPackageFileOption> files;
  final String? selectedFilePath;
  final ValueChanged<String?> onSelectedFileChanged;
  final TextEditingController pathController;
  final ValueChanged<String> onPathChanged;
  final VoidCallback onPickFromDevice;
  final VoidCallback onRefreshFiles;
  final VoidCallback onPreview;
  final VoidCallback onImport;
  final bool previewing;
  final bool importing;
  final ManualSyncPackagePreview? preview;
  final ManualSyncImportResult? lastImportResult;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ManualSyncPackagePreview? currentPreview = preview;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.sync_alt_rounded, color: Color(0xFF1152D4)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Importar paquete de sincronización',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Recargar archivos',
                onPressed: previewing || importing ? null : onRefreshFiles,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          Text(
            'Selecciona un paquete exportado desde el TPV y valida antes de importarlo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: files.any((ManualSyncPackageFileOption row) =>
                    row.filePath == selectedFilePath)
                ? selectedFilePath
                : null,
            decoration: const InputDecoration(
              labelText: 'Archivos detectados',
              border: OutlineInputBorder(),
            ),
            items: files
                .map(
                  (ManualSyncPackageFileOption row) => DropdownMenuItem<String>(
                    value: row.filePath,
                    child: Text(
                      row.fileName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (String? value) {
              if (previewing || importing) {
                return;
              }
              onSelectedFileChanged(value);
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: pathController,
            enabled: !previewing && !importing,
            decoration: const InputDecoration(
              labelText: 'Ruta de archivo',
              hintText:
                  '/storage/emulated/0/Download/Sync/POSIPV/sync_xxx.json',
              border: OutlineInputBorder(),
            ),
            onChanged: onPathChanged,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: previewing || importing ? null : onPickFromDevice,
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Explorar archivo (.json)'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: previewing || importing ? null : onPreview,
                  icon: previewing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_rounded),
                  label: Text(previewing ? 'Validando...' : 'Validar paquete'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: importing ||
                          previewing ||
                          currentPreview == null ||
                          !currentPreview.isValid
                      ? null
                      : onImport,
                  icon: importing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download_done_rounded),
                  label: Text(importing ? 'Importando...' : 'Importar'),
                ),
              ),
            ],
          ),
          if (currentPreview != null) ...<Widget>[
            const SizedBox(height: 12),
            _PreviewPanel(preview: currentPreview),
          ],
          if (lastImportResult != null) ...<Widget>[
            const SizedBox(height: 12),
            _ImportResultPanel(result: lastImportResult!),
          ],
          if (files.isEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'No se encontraron archivos JSON en las rutas de sincronización.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.preview});

  final ManualSyncPackagePreview preview;

  @override
  Widget build(BuildContext context) {
    final Color bg =
        preview.isValid ? const Color(0xFFEAF7EF) : const Color(0xFFFFECEF);
    final Color fg =
        preview.isValid ? const Color(0xFF116A3A) : const Color(0xFFA32A42);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            preview.message,
            style: TextStyle(fontWeight: FontWeight.w700, color: fg),
          ),
          const SizedBox(height: 6),
          Text('Turno: ${preview.sessionId.isEmpty ? '-' : preview.sessionId}'),
          Text(
            'TPV origen: ${preview.sourceTerminal.isEmpty ? '-' : preview.sourceTerminal}',
          ),
          Text('Ventas: ${preview.saleCount}'),
          Text('Movimientos: ${preview.movementCount}'),
          Text(
              'IPV: ${preview.ipvReportCount} (${preview.ipvLineCount} líneas)'),
          Text('Total: ${_formatCents(preview.totalCents)}'),
          if (preview.exportedAt != null)
            Text('Exportado: ${_formatDateTime(preview.exportedAt!)}'),
        ],
      ),
    );
  }
}

class _ImportResultPanel extends StatelessWidget {
  const _ImportResultPanel({required this.result});

  final ManualSyncImportResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Importación completada',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text('Ventas nuevas: ${result.saleCount}'),
          Text('Pagos nuevos: ${result.paymentCount}'),
          Text('Movimientos nuevos: ${result.movementCount}'),
          Text(
            'IPV importados: ${result.ipvReportCount} (${result.ipvLineCount} líneas)',
          ),
          Text('Total paquete: ${_formatCents(result.totalCents)}'),
          if (result.warnings.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            const Text(
              'Avisos de compatibilidad:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            ...result.warnings.take(3).map(
                  (String row) => Text('• $row'),
                ),
            if (result.warnings.length > 3)
              Text('• +${result.warnings.length - 3} avisos más'),
          ],
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final String d = value.day.toString().padLeft(2, '0');
  final String m = value.month.toString().padLeft(2, '0');
  final String y = value.year.toString().padLeft(4, '0');
  final String hh = value.hour.toString().padLeft(2, '0');
  final String mm = value.minute.toString().padLeft(2, '0');
  return '$d/$m/$y $hh:$mm';
}

String _formatCents(int cents) {
  return '\$${(cents / 100).toStringAsFixed(2)}';
}
