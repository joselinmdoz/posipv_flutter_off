import 'dart:io';
import 'package:flutter/material.dart';

import '../../data/tpv_local_datasource.dart';

class TpvTerminalCard extends StatelessWidget {
  final TpvTerminalView terminal;
  final VoidCallback onOpenSession;
  final VoidCallback onGoToPos;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onHistory;
  final VoidCallback onIpv;
  final bool isDark;

  const TpvTerminalCard({
    super.key,
    required this.terminal,
    required this.onOpenSession,
    required this.onGoToPos,
    this.onEdit,
    this.onDelete,
    required this.onHistory,
    required this.onIpv,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOpen = terminal.openSession != null;

    // As per user request: "en la card de los tpv no es necesario mostrar los metodos de pagos configurados,
    // ni los usuarios ni el almacen, si muestra el tipo de moneda en la que se trabaja"
    // We also need to show the status (OPEN/CLOSED) and the image if any.

    // Note: terminal.terminal currently doesn't have imagePath in DB,
    // we'll assume it will be added or we use the unsplash placeholder for now.
    // If I add it, it would be terminal.terminal.imagePath.

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header with Image and Badge
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // For now using placeholder, but ready for terminal.terminal.imagePath when added
                _buildTerminalImage(isDark, scheme),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Status Badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? const Color(0xFF10B981)
                          : Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOpen ? 'ABIERTO' : 'CERRADO',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Menu
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildPopupMenu(scheme),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        terminal.terminal.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: scheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1152D4).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        terminal.terminal.currencySymbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1152D4),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Moneda: ${terminal.terminal.currencyCode}',
                  style: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: isOpen ? onGoToPos : onOpenSession,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1152D4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                isOpen
                                    ? Icons.point_of_sale_rounded
                                    : Icons.lock_open_rounded,
                                size: 20),
                            const SizedBox(width: 10),
                            Text(
                              isOpen ? 'Ir al POS' : 'Abrir Turno',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (isOpen) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: onIpv,
                      icon: const Icon(Icons.analytics_rounded, size: 18),
                      label: const Text('Análisis de Turno (IPV)',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1152D4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalImage(bool isDark, ColorScheme scheme) {
    final String? path = terminal.terminal.imagePath;
    if (path != null && path.isNotEmpty) {
      final File file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(isDark, scheme),
        );
      }
    }

    return Image.asset(
      'assets/images/tpv_default.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholder(isDark, scheme),
    );
  }

  Widget _buildPlaceholder(bool isDark, ColorScheme scheme) {
    return Container(
      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      child: Icon(
        Icons.terminal_rounded,
        size: 48,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildPopupMenu(ColorScheme scheme) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child:
            const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
      ),
      onSelected: (value) {
        if (value == 'edit' && onEdit != null) onEdit!();
        if (value == 'history') onHistory();
        if (value == 'delete' && onDelete != null) onDelete!();
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 20),
                SizedBox(width: 12),
                Text('Editar terminal'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'history',
          child: Row(
            children: [
              Icon(Icons.history_rounded, size: 20),
              SizedBox(width: 12),
              Text('Ver historial'),
            ],
          ),
        ),
        if (onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                SizedBox(width: 12),
                Text('Eliminar', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );
  }
}
