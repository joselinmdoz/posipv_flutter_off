import 'package:flutter/material.dart';
import '../../../../core/licensing/license_models.dart';

class LicenseStatusCard extends StatelessWidget {
  final LicenseStatus license;
  final String Function(DateTime) dateFormatter;

  const LicenseStatusCard({
    super.key,
    required this.license,
    required this.dateFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final int? days = license.daysRemaining;
    final bool hasExpiry = license.expiresAt != null;
    final bool isDemoWithoutExpiry = license.isDemo && !hasExpiry;
    final bool expired = hasExpiry && (days ?? 0) <= 0;

    final double progress;
    if (!hasExpiry || expired) {
      progress = expired
          ? 1
          : 0; // if infinite, no progress. if expired, full progress consumed.
    } else if (license.startedAt != null) {
      final int totalDays =
          license.expiresAt!.difference(license.startedAt!).inDays + 1;
      progress = (1 - ((days ?? 0) / (totalDays <= 0 ? 1 : totalDays)))
          .clamp(0.0, 1.0)
          .toDouble();
    } else {
      progress = (1 - ((days ?? 0) / 30)).clamp(0.0, 1.0).toDouble();
    }

    final int progressPercent = (progress * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Colorido
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1152D4).withValues(alpha: 0.2),
                  const Color(0xFF1152D4).withValues(alpha: 0.05),
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF1152D4),
                size: 64,
              ),
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
                        license.statusLabel,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: license.isActive
                            ? (isDark
                                ? const Color(0xFF059669).withValues(alpha: 0.3)
                                : const Color(0xFFDCFCE7))
                            : (isDark
                                ? const Color(0xFFDC2626).withValues(alpha: 0.3)
                                : const Color(0xFFFEE2E2)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        license.isActive ? 'ACTIVA' : 'INACTIVA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: license.isActive
                              ? (isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF15803D))
                              : (isDark
                                  ? const Color(0xFFF87171)
                                  : const Color(0xFFB91C1C)),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (hasExpiry)
                  Text.rich(
                    TextSpan(
                      text: 'Tu licencia caduca el ',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      children: [
                        TextSpan(
                          text: dateFormatter(license.expiresAt!),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    isDemoWithoutExpiry
                        ? 'Modo demo con límites: '
                            '${DemoLicenseLimits.maxActiveProducts} productos, '
                            '${DemoLicenseLimits.maxActiveTerminals} TPV, '
                            '${DemoLicenseLimits.maxSalesPerDay} ventas por día y sin reportes generales.'
                        : 'Licencia sin fecha de caducidad.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                const SizedBox(height: 20),
                if (hasExpiry) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progreso de la licencia',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        (days ?? 0) > 0 ? '$days días restantes' : '0 días',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1152D4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: MediaQuery.of(context).size.width *
                            progress, // Appears as full-width proportional to screen, sufficient for UI
                        decoration: BoxDecoration(
                          color: const Color(0xFF1152D4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$progressPercent% del periodo consumido',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
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
}
