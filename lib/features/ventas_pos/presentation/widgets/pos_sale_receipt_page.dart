import 'package:flutter/material.dart';
import '../../domain/sale_receipt.dart';

/// Modern full-screen receipt page following the design from the mockup.
/// Shows a sale receipt with success status, item details, totals, and
/// payment information.
class PosSaleReceiptPage extends StatelessWidget {
  const PosSaleReceiptPage({
    super.key,
    required this.receipt,
    this.onPrint,
  });

  final SaleReceipt receipt;
  final VoidCallback? onPrint;

  String _money(int cents) {
    final bool negative = cents < 0;
    final int absCents = cents.abs();
    final String value =
        '${receipt.currencySymbol}${(absCents / 100).toStringAsFixed(2)}';
    return negative ? '-$value' : value;
  }

  String _formatQty(double qty) {
    if (qty == qty.truncateToDouble()) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  String _formatDateTime(DateTime date) {
    const List<String> months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    final DateTime local = date.toLocal();
    final String month = months[local.month - 1];
    final String day = local.day.toString();
    final String year = local.year.toString();
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hh:$mm';
  }

  String _formatDateShort(DateTime date) {
    final DateTime local = date.toLocal();
    final String d = local.day.toString().padLeft(2, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String y = local.year.toString();
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context, scheme, isDark),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Success status
                    _buildSuccessStatus(isDark),

                    // General details
                    _buildGeneralDetails(scheme, isDark),

                    _buildDivider(scheme),

                    // Itemized list
                    _buildItemizedList(scheme, isDark),

                    _buildDivider(scheme),

                    // Totals
                    _buildTotals(scheme, isDark),

                    // Payment details
                    _buildPaymentDetails(scheme, isDark),
                  ],
                ),
              ),
            ),

            // Action footer
            _buildFooter(context, scheme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme scheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: scheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              'Comprobante de venta',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildSuccessStatus(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1152D4).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF1152D4),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Venta Realizada',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¡Gracias por su compra!',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralDetails(ColorScheme scheme, bool isDark) {
    final Color labelColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final Color valueColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          _detailRow('Folio', '#${receipt.folio}', labelColor, valueColor, isBoldValue: true),
          const SizedBox(height: 12),
          _detailRow('Fecha', _formatDateTime(receipt.createdAt), labelColor, valueColor),
          const SizedBox(height: 12),
          _detailRow('Cajero', receipt.cashierUsername, labelColor, valueColor),
          const SizedBox(height: 12),
          _detailRow('TPV', receipt.terminalName, labelColor, valueColor),
        
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor, {
    bool isBoldValue = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w400,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(
        height: 24,
        thickness: 1,
        color: scheme.outline.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildItemizedList(ColorScheme scheme, bool isDark) {
    final Color titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtitleColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DETALLE DE PRODUCTOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: titleColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          ...receipt.lines.map((SaleReceiptLine line) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatQty(line.qty)} x ${_money(line.unitPriceCents)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _money(line.lineTotalCents),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotals(ColorScheme scheme, bool isDark) {
    final Color labelColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final Color valueColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          _detailRow('Subtotal', _money(receipt.subtotalCents), labelColor, valueColor),
          const SizedBox(height: 8),
          _detailRow(
            'Impuesto',
            _money(receipt.taxCents),
            labelColor,
            valueColor,
          ),
          if (receipt.discountCents > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Descuento',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF16A34A),
                  ),
                ),
                Text(
                  '-${_money(receipt.discountCents)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
              Text(
                _money(receipt.totalCents),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1152D4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(ColorScheme scheme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        children: receipt.payments.map((ReceiptPayment payment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.7)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _paymentIcon(payment.method),
                  size: 24,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.method,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Pagado el ${_formatDateShort(receipt.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _money(payment.amountCents),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pagado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme scheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1152D4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: const Color(0xFF1152D4).withValues(alpha: 0.3),
              ),
              child: const Text(
                'Cerrar',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
          if (onPrint != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onPrint?.call();
                },
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text(
                  'Imprimir Comprobante',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _paymentIcon(String method) {
    final String lower = method.toLowerCase();
    if (lower.contains('efectivo') || lower.contains('cash')) {
      return Icons.payments_outlined;
    }
    if (lower.contains('tarjeta') || lower.contains('card')) {
      return Icons.credit_card_rounded;
    }
    if (lower.contains('transfer')) {
      return Icons.swap_horiz_rounded;
    }
    return Icons.payment_rounded;
  }
}
