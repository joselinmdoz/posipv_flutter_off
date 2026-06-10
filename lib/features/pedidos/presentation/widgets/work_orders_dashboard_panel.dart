import 'package:flutter/material.dart';

import '../../data/pedidos_local_datasource.dart';

enum WorkOrdersDashboardMenuAction {
  exportPdf,
  sharePdf,
}

class WorkOrdersDashboardPanel extends StatelessWidget {
  const WorkOrdersDashboardPanel({
    super.key,
    required this.summary,
    required this.rangeLabel,
    required this.criterionLabel,
    required this.hasActiveRange,
    required this.onPickRange,
    required this.onPickCriterion,
    required this.onClearRange,
    required this.onMenuActionSelected,
    this.onTapPending,
    this.onTapInProgress,
    this.onTapReady,
    this.onTapDueToday,
    this.onTapMaterialUsage,
    this.onTapPaid,
    this.onTapUnpaid,
    this.menuBusy = false,
  });

  final WorkOrderDashboardSummary summary;
  final String rangeLabel;
  final String criterionLabel;
  final bool hasActiveRange;
  final VoidCallback onPickRange;
  final VoidCallback onPickCriterion;
  final VoidCallback onClearRange;
  final ValueChanged<WorkOrdersDashboardMenuAction> onMenuActionSelected;
  final VoidCallback? onTapPending;
  final VoidCallback? onTapInProgress;
  final VoidCallback? onTapReady;
  final VoidCallback? onTapDueToday;
  final VoidCallback? onTapMaterialUsage;
  final VoidCallback? onTapPaid;
  final VoidCallback? onTapUnpaid;
  final bool menuBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1152D4),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF1152D4).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Panel de producción',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(
                Icons.local_printshop_outlined,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              PopupMenuButton<WorkOrdersDashboardMenuAction>(
                enabled: !menuBusy,
                tooltip: 'Opciones del panel',
                color: Colors.white,
                icon: menuBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                      ),
                onSelected: onMenuActionSelected,
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<WorkOrdersDashboardMenuAction>>[
                  const PopupMenuItem<WorkOrdersDashboardMenuAction>(
                    value: WorkOrdersDashboardMenuAction.exportPdf,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.picture_as_pdf_outlined),
                        SizedBox(width: 10),
                        Text('Guardar informe'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<WorkOrdersDashboardMenuAction>(
                    value: WorkOrdersDashboardMenuAction.sharePdf,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.share_outlined),
                        SizedBox(width: 10),
                        Text('Compartir informe'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onPickRange,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.34)),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
                icon: const Icon(Icons.date_range_rounded, size: 18),
                label: const Text('Rango'),
              ),
              OutlinedButton.icon(
                onPressed: onPickCriterion,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.34)),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Base'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  rangeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  criterionLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (hasActiveRange)
                TextButton(
                  onPressed: onClearRange,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Limpiar'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${summary.pendingCount + summary.inProgressCount + summary.readyCount}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 38,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Trabajos activos en el taller',
            style: TextStyle(
              color: Color(0xFFDCE7FF),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricMiniCard(
                  label: 'Pendientes',
                  value: summary.pendingCount.toString(),
                  onTap: onTapPending,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricMiniCard(
                  label: 'Producción',
                  value: summary.inProgressCount.toString(),
                  onTap: onTapInProgress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricMiniCard(
                  label: 'Por entregar',
                  value: summary.readyCount.toString(),
                  onTap: onTapReady,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricMiniCard(
                  label: 'Vencen hoy',
                  value: summary.dueTodayCount.toString(),
                  onTap: onTapDueToday,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MetricMiniCard(
            label: 'Registros de consumo',
            value: summary.materialUsageEntriesCount.toString(),
            wide: true,
            onTap: onTapMaterialUsage,
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricMiniCard(
                  label: 'Cobrados',
                  value: summary.paidCount.toString(),
                  onTap: onTapPaid,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricMiniCard(
                  label: 'Pend. cobro',
                  value: summary.unpaidCount.toString(),
                  onTap: onTapUnpaid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Consumo de materiales',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (summary.topConsumedMaterials.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'No hay consumos registrados en el rango seleccionado.',
                style: TextStyle(
                  color: Color(0xFFDCE7FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...summary.topConsumedMaterials.map(
              (WorkOrderMaterialConsumptionSummary item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.productName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.productSku.trim().isEmpty
                                  ? item.unitLabel
                                  : '${item.productSku} · ${item.unitLabel}',
                              style: const TextStyle(
                                color: Color(0xFFDCE7FF),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_qty(item.qty)} ${item.unitLabel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _qty(double value) {
    if ((value - value.roundToDouble()).abs() < 0.0001) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}

class _MetricMiniCard extends StatelessWidget {
  const _MetricMiniCard({
    required this.label,
    required this.value,
    this.wide = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool wide;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: wide ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFDCE7FF),
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFDCE7FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
