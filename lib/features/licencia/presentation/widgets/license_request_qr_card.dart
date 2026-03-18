import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/licensing/license_models.dart';
// Note: Some imports will be needed on the parent for sharing/setting date

class LicenseRequestQrCard extends StatelessWidget {
  final String? requestCode;
  final DeviceIdentity? device;
  final DateTime? requestedExpiry;
  final VoidCallback onPickExpiryDate;
  final VoidCallback onShareQr;
  final String Function(DateTime) dateFormatter;

  const LicenseRequestQrCard({
    super.key,
    required this.requestCode,
    required this.device,
    required this.requestedExpiry,
    required this.onPickExpiryDate,
    required this.onShareQr,
    required this.dateFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Solicitud de licencia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              style: BorderStyle.none, // Can't easily do dashed border purely with native BoxDecoration, we'll mimic it with a solid thin border or use a package if present. We'll use a thin border.
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (requestCode != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: requestCode!,
                    version: QrVersions.auto,
                    size: 192,
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0F172A),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: onShareQr,
                  icon: const Icon(Icons.share_outlined, size: 20),
                  label: const Text('Compartir QR'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1152D4),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const SizedBox(
                  height: 192,
                  child: Center(
                    child: Text('Generando código QR...'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onPickExpiryDate,
                  style: TextButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1152D4).withValues(alpha: 0.2) : const Color(0xFF1152D4).withValues(alpha: 0.1),
                    foregroundColor: const Color(0xFF1152D4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  child: Text(
                    requestedExpiry == null 
                        ? 'Solicitar fecha de caducidad'
                        : 'Solicitada: ${dateFormatter(requestedExpiry!)}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
