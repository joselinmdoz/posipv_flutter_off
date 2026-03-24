import 'package:flutter/material.dart';

import '../../data/manual_sync_local_datasource.dart';

class ManualSyncExportCard extends StatelessWidget {
  const ManualSyncExportCard({
    super.key,
    required this.sessions,
    required this.selectedSessionId,
    required this.onSessionChanged,
    required this.onExport,
    required this.exporting,
    this.lastExportPath,
  });

  final List<ManualSyncSessionOption> sessions;
  final String? selectedSessionId;
  final ValueChanged<String?> onSessionChanged;
  final VoidCallback onExport;
  final bool exporting;
  final String? lastExportPath;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ManualSyncSessionOption? selected = _selectedSession();

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
          const Row(
            children: <Widget>[
              Icon(Icons.upload_rounded, color: Color(0xFF1152D4)),
              SizedBox(width: 8),
              Text(
                'Exportar turno cerrado',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Genera un paquete JSON para llevarlo al dispositivo administrador.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: sessions.any((ManualSyncSessionOption row) =>
                    row.sessionId == selectedSessionId)
                ? selectedSessionId
                : null,
            decoration: const InputDecoration(
              labelText: 'Turno cerrado',
              border: OutlineInputBorder(),
            ),
            items: sessions
                .map(
                  (ManualSyncSessionOption row) => DropdownMenuItem<String>(
                    value: row.sessionId,
                    child: Text(
                      '${row.terminalName} • ${_formatDateTime(row.closedAt)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: exporting ? null : onSessionChanged,
          ),
          if (selected != null) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Ventas: ${selected.saleCount}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    _formatCents(selected.totalCents),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: exporting || selected == null ? null : onExport,
              icon: exporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(exporting ? 'Exportando...' : 'Exportar paquete'),
            ),
          ),
          if ((lastExportPath ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Archivo generado:\n$lastExportPath',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (sessions.isEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'No hay turnos cerrados disponibles para exportar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  ManualSyncSessionOption? _selectedSession() {
    final String id = (selectedSessionId ?? '').trim();
    if (id.isEmpty) {
      return null;
    }
    for (final ManualSyncSessionOption row in sessions) {
      if (row.sessionId == id) {
        return row;
      }
    }
    return null;
  }

  static String _formatDateTime(DateTime value) {
    final String d = value.day.toString().padLeft(2, '0');
    final String m = value.month.toString().padLeft(2, '0');
    final String y = value.year.toString().padLeft(4, '0');
    final String hh = value.hour.toString().padLeft(2, '0');
    final String mm = value.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  static String _formatCents(int cents) {
    return '\$${(cents / 100).toStringAsFixed(2)}';
  }
}
