import 'package:flutter/material.dart';

class CloseSessionResult {
  final int totalCents;
  final Map<int, int> breakdown;
  final String note;

  CloseSessionResult({
    required this.totalCents,
    required this.breakdown,
    required this.note,
  });
}

class PosCloseSessionDialog extends StatefulWidget {
  final String terminalName;
  final Map<String, int> expectedPayments;
  final int openingFloatCents;
  final List<int> denominations;
  final String currencySymbol;
  final String Function(String) paymentMethodLabel;
  final String Function(int, String) formatCents;

  const PosCloseSessionDialog({
    super.key,
    required this.terminalName,
    required this.expectedPayments,
    required this.openingFloatCents,
    required this.denominations,
    required this.currencySymbol,
    required this.paymentMethodLabel,
    required this.formatCents,
  });

  @override
  State<PosCloseSessionDialog> createState() => _PosCloseSessionDialogState();
}

class _PosCloseSessionDialogState extends State<PosCloseSessionDialog> {
  final Map<int, TextEditingController> _controllers = {};
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final int cents in widget.denominations) {
      _controllers[cents] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _noteCtrl.dispose();
    super.dispose();
  }

  int get _totalCountedCents {
    int total = 0;
    _controllers.forEach((cents, controller) {
      final int qty = int.tryParse(controller.text) ?? 0;
      total += qty * cents;
    });
    return total;
  }

  int get _expectedCashCents {
    final int cashFromSales = widget.expectedPayments['cash'] ?? 0;
    return widget.openingFloatCents + cashFromSales;
  }

  int get _totalExpectedCents {
    return widget.expectedPayments.values.fold(0, (a, b) => a + b) + widget.openingFloatCents;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF1152D4);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // AppBar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cerrar turno en ${widget.terminalName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expected Amounts Summary
                    _buildSectionHeader(Icons.account_balance_wallet_rounded, 'Resumen de montos esperados', primaryColor),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          ...widget.expectedPayments.entries.map((entry) {
                            int amount = entry.value;
                            if (entry.key == 'cash') amount += widget.openingFloatCents;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildSummaryRow(
                                widget.paymentMethodLabel(entry.key),
                                widget.formatCents(amount, widget.currencySymbol),
                                isDark,
                              ),
                            );
                          }),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Esperado',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                widget.formatCents(_totalExpectedCents, widget.currencySymbol),
                                style: const TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Denomination Breakdown
                    _buildSectionHeader(Icons.payments_rounded, 'Desglose por denominación (${widget.currencySymbol})', primaryColor),
                    const SizedBox(height: 16),
                    ...widget.denominations.map((cents) => _buildDenominationRow(cents, isDark, primaryColor)),

                    const SizedBox(height: 32),

                    // Results Display
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL CONTADO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey[500],
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.formatCents(_totalCountedCents, widget.currencySymbol),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'DIFERENCIA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey[500],
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.formatCents(_totalCountedCents - _expectedCashCents, widget.currencySymbol),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: (_totalCountedCents - _expectedCashCents) < 0 ? Colors.redAccent : Colors.greenAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Note field
                    TextField(
                      controller: _noteCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nota de cierre (opcional)',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final Map<int, int> breakdown = {};
                        _controllers.forEach((cents, controller) {
                          final int qty = int.tryParse(controller.text) ?? 0;
                          if (qty > 0) breakdown[cents] = qty;
                        });
                        Navigator.pop(
                          context,
                          CloseSessionResult(
                            totalCents: _totalCountedCents,
                            breakdown: breakdown,
                            note: _noteCtrl.text,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Cerrar Turno'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF334155),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDenominationRow(int cents, bool isDark, Color primaryColor) {
    final controller = _controllers[cents]!;
    
    // Calculate total for this denomination
    final int currentQty = int.tryParse(controller.text) ?? 0;
    final int currentTotal = currentQty * cents;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUP ${cents ~/ 100}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.currencySymbol,
                        style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (currentTotal / 100).toStringAsFixed(2),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cantidad',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
