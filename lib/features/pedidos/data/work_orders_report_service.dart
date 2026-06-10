import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pedidos_local_datasource.dart';

class WorkOrdersReportService {
  Future<String> exportOrdersReportPdf({
    required List<WorkOrderDetail> orders,
    required WorkOrderDashboardSummary summary,
    required String rangeLabel,
    required String criterionLabel,
    required String statusFilterLabel,
    required String? insightFilterLabel,
    required String searchQuery,
  }) async {
    final DateTime now = DateTime.now();
    final Directory dir = await _resolveReportsDir();
    final String stamp = _stamp(now);
    final File file = File(
      p.join(dir.path, 'informe-pedidos-$stamp.pdf'),
    );

    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 24),
        build: (pw.Context context) => <pw.Widget>[
          _header(now),
          pw.SizedBox(height: 14),
          _filtersCard(
            rangeLabel: rangeLabel,
            criterionLabel: criterionLabel,
            statusFilterLabel: statusFilterLabel,
            insightFilterLabel: insightFilterLabel,
            searchQuery: searchQuery,
            totalOrders: orders.length,
          ),
          pw.SizedBox(height: 14),
          _summaryCard(summary),
          pw.SizedBox(height: 14),
          _sectionTitle('Detalle de pedidos'),
          if (orders.isEmpty)
            _emptyText('No hay pedidos para exportar con los filtros actuales.')
          else
            ...orders.map(_orderCard),
        ],
      ),
    );

    await file.writeAsBytes(await doc.save(), flush: true);
    return file.path;
  }

  pw.Widget _header(DateTime now) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1152D4'),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            'Informe de Pedidos',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Generado el ${_formatDateTime(now)}',
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _filtersCard({
    required String rangeLabel,
    required String criterionLabel,
    required String statusFilterLabel,
    required String? insightFilterLabel,
    required String searchQuery,
    required int totalOrders,
  }) {
    return _infoCard(
      <pw.Widget>[
        _infoRow('Rango', rangeLabel),
        _infoRow('Base del rango', criterionLabel),
        _infoRow('Estado', statusFilterLabel),
        _infoRow('Filtro rápido', insightFilterLabel ?? 'Ninguno'),
        _infoRow(
          'Búsqueda',
          searchQuery.trim().isEmpty ? 'Sin búsqueda activa' : searchQuery,
        ),
        _infoRow('Pedidos exportados', totalOrders.toString()),
      ],
    );
  }

  pw.Widget _summaryCard(WorkOrderDashboardSummary summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionTitle('Resumen del panel'),
        pw.SizedBox(height: 8),
        _infoCard(
          <pw.Widget>[
            _infoRow('Pendientes', summary.pendingCount.toString()),
            _infoRow('En producción', summary.inProgressCount.toString()),
            _infoRow('Pendientes a entregar', summary.readyCount.toString()),
            _infoRow('Cobrados', summary.paidCount.toString()),
            _infoRow('Pend. cobro', summary.unpaidCount.toString()),
            _infoRow('Vencen hoy', summary.dueTodayCount.toString()),
            _infoRow(
              'Registros de consumo',
              summary.materialUsageEntriesCount.toString(),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        if (summary.topConsumedMaterials.isEmpty)
          _emptyText('No hay consumos de materiales en el rango seleccionado.')
        else
          ...summary.topConsumedMaterials.map(
            (WorkOrderMaterialConsumptionSummary item) => pw.Container(
              width: double.infinity,
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColor.fromHex('#D8E0EC')),
              ),
              child: pw.Row(
                children: <pw.Widget>[
                  pw.Expanded(
                    child: pw.Text(
                      '${item.productName} · ${item.productSku}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Text(
                    '${_qty(item.qty)} ${item.unitLabel}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1152D4'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _orderCard(WorkOrderDetail detail) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColor.fromHex('#D8E0EC')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(
                      detail.folio,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#64748B'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      detail.title,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Text(
                WorkOrderStatusCatalog.label(detail.status),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _statusColor(detail.status).accent,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          _infoCard(
            <pw.Widget>[
              _infoRow(
                  'Cliente', detail.customerName ?? 'Sin cliente asignado'),
              _infoRow(
                'Contacto',
                <String>[
                  detail.customerPhone ?? '',
                  detail.customerEmail ?? '',
                ]
                        .where((String item) => item.trim().isNotEmpty)
                        .join(' · ')
                        .trim()
                        .isEmpty
                    ? '-'
                    : <String>[
                        detail.customerPhone ?? '',
                        detail.customerEmail ?? '',
                      ]
                        .where((String item) => item.trim().isNotEmpty)
                        .join(' · '),
              ),
              _infoRow('Creado', _formatDateTime(detail.createdAt)),
              _infoRow(
                'Entrega estimada',
                detail.dueAt == null ? '-' : _formatDateTime(detail.dueAt!),
              ),
              _infoRow(
                'Prioridad',
                WorkOrderPriorityCatalog.label(detail.priority),
              ),
              _infoRow(
                'Estado de cobro',
                WorkOrderPaymentStatusCatalog.label(detail.paymentStatus),
              ),
              _infoRow(
                'Cobrado el',
                detail.paidAt == null ? '-' : _formatDateTime(detail.paidAt!),
              ),
              _infoRow(
                'Cotización fijada',
                detail.pricingSnapshot == null
                    ? '-'
                    : _formatDateTime(detail.pricingSnapshot!.capturedAt),
              ),
              if (detail.pricingSnapshot != null)
                _infoRow(
                  'Reglas de cobro',
                  '${detail.pricingSnapshot!.foreignCurrencyCode} -> ${detail.pricingSnapshot!.localCurrencyCode} · +${detail.pricingSnapshot!.localCashFixedSurcharge.toStringAsFixed(2)} efectivo · +${detail.pricingSnapshot!.localTransferPercentSurcharge.toStringAsFixed(2)}% transf.',
                ),
              _infoRow('Creado por', detail.createdByUsername),
            ],
          ),
          pw.SizedBox(height: 10),
          _subsectionTitle('Productos solicitados'),
          if (detail.items.isEmpty)
            _emptyText('Sin productos registrados.')
          else
            ...detail.items.map(_productCard),
          pw.SizedBox(height: 8),
          _subsectionTitle('Responsables asignados'),
          if (detail.assignments.isEmpty)
            _emptyText('Sin responsables asignados.')
          else
            ...detail.assignments.map(_assignmentCard),
          pw.SizedBox(height: 8),
          _subsectionTitle('Trabajos realizados'),
          if (detail.tasks.isEmpty)
            _emptyText('Aún no se han registrado trabajos realizados.')
          else
            ...detail.tasks.map(_taskCard),
          pw.SizedBox(height: 8),
          _subsectionTitle('Valor del pedido'),
          if (detail.requestedCostLines.isEmpty)
            _emptyText('Sin información de valor comercial.')
          else
            _costTotalsCard(
              detail.paymentValues.isEmpty
                  ? detail.totalCosts
                  : detail.paymentValues
                      .map(
                        (WorkOrderPaymentValue item) => WorkOrderCostTotal(
                          currencyCode: item.currencyCode,
                          totalCostCents: item.amountCents,
                        ),
                      )
                      .toList(growable: false),
            ),
          pw.SizedBox(height: 8),
          _subsectionTitle('Pagos registrados'),
          if (detail.paymentLines.isEmpty)
            _emptyText('Sin líneas de pago registradas.')
          else
            ...detail.paymentLines.map(_paymentLineCard),
          pw.SizedBox(height: 8),
          _subsectionTitle('Costos de materiales y merma'),
          if (detail.materialCostLines.isEmpty)
            _emptyText('Sin consumos registrados.')
          else
            _costTotalsCard(detail.materialTotalCosts),
          if ((detail.description ?? '').trim().isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 8),
            _subsectionTitle('Descripción'),
            _emptyText(detail.description!.trim()),
          ],
          if ((detail.note ?? '').trim().isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 8),
            _subsectionTitle('Observaciones'),
            _emptyText(detail.note!.trim()),
          ],
        ],
      ),
    );
  }

  pw.Widget _paymentLineCard(WorkOrderRecordedPaymentLine line) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Row(
            children: <pw.Widget>[
              pw.Expanded(
                child: pw.Text(
                  line.methodLabel,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                _formatMoney(line.enteredAmountCents, line.currencyCode),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1152D4'),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${line.currencyCode} · ${_formatDateTime(line.paidAt)}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          if ((line.transactionId ?? '').trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                'Transacción: ${line.transactionId}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          if ((line.note ?? '').trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                line.note!.trim(),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _costTotalsCard(List<WorkOrderCostTotal> totals) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#D8E0EC')),
      ),
      child: pw.Column(
        children: totals
            .map(
              (WorkOrderCostTotal item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  children: <pw.Widget>[
                    pw.Expanded(
                      child: pw.Text(
                        item.currencyCode,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#475569'),
                        ),
                      ),
                    ),
                    pw.Text(
                      _formatCents(item.totalCostCents, item.currencyCode),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  pw.Widget _productCard(WorkOrderProductItem item) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
      ),
      child: pw.Text(
        '${item.productName} · ${_qty(item.qty)} ${item.unitLabel} · ${item.productSku}',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  pw.Widget _assignmentCard(WorkOrderAssignmentItem item) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
      ),
      child: pw.Text(
        '${item.employeeName} · ${item.roleName} · ${item.employeeCode}',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  pw.Widget _taskCard(WorkOrderTaskItem task) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            task.title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Registrado: ${_formatDateTime(task.createdAt)}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          if ((task.description ?? '').trim().isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 4),
            pw.Text(
              task.description!.trim(),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
          pw.SizedBox(height: 4),
          _taskSubsection(
            'Trabajadores',
            task.workers.isEmpty
                ? 'Sin trabajadores registrados.'
                : task.workers.map((WorkOrderTaskWorkerItem item) {
                    return '${item.employeeName} · ${item.roleName}';
                  }).join(' | '),
          ),
          _taskSubsection(
            'Materiales usados',
            task.materials.isEmpty
                ? 'Sin consumo de materiales.'
                : task.materials.map((WorkOrderTaskMaterialItem item) {
                    return '${item.productName} (${_qty(item.qty)} ${item.unitLabel})';
                  }).join(' | '),
          ),
          _taskSubsection(
            'Merma',
            task.wasteMaterials.isEmpty
                ? 'Sin merma registrada.'
                : task.wasteMaterials.map((WorkOrderTaskMaterialItem item) {
                    return '${item.productName} (${_qty(item.qty)} ${item.unitLabel})';
                  }).join(' | '),
          ),
          _taskSubsection(
            'Evidencias',
            task.imagePaths.isEmpty
                ? 'Sin imágenes adjuntas.'
                : '${task.imagePaths.length} imagen(es) registradas.',
          ),
        ],
      ),
    );
  }

  pw.Widget _taskSubsection(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 3),
      child: pw.RichText(
        text: pw.TextSpan(
          children: <pw.TextSpan>[
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#334155'),
              ),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#0F172A'),
      ),
    );
  }

  pw.Widget _subsectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#0F172A'),
      ),
    );
  }

  pw.Widget _infoCard(List<pw.Widget> children) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#D8E0EC')),
      ),
      child: pw.Column(children: children),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.SizedBox(
            width: 112,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#475569'),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _emptyText(String text) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#D8E0EC')),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  Future<Directory> _resolveReportsDir() async {
    final Directory base = await _resolveDownloadsBaseDir();
    final Directory dir = Directory(
      p.join(base.path, 'POSIPV', 'Pedidos', 'Informes'),
    );
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _resolveDownloadsBaseDir() async {
    if (Platform.isAndroid) {
      const List<String> candidates = <String>[
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Descargas',
      ];
      for (final String path in candidates) {
        final Directory dir = Directory(path);
        try {
          if (dir.existsSync()) {
            return dir;
          }
          await dir.create(recursive: true);
          if (dir.existsSync()) {
            return dir;
          }
        } catch (_) {}
      }
      return getApplicationDocumentsDirectory();
    }

    final Directory? downloads = await getDownloadsDirectory();
    if (downloads != null) {
      return downloads;
    }
    return getApplicationDocumentsDirectory();
  }

  _PdfStatusColors _statusColor(String status) {
    switch (status) {
      case WorkOrderStatusCatalog.inProgress:
        return _PdfStatusColors(
          shade: PdfColor.fromHex('#DBEAFE'),
          accent: PdfColor.fromHex('#1D4ED8'),
        );
      case WorkOrderStatusCatalog.ready:
        return _PdfStatusColors(
          shade: PdfColor.fromHex('#DCFCE7'),
          accent: PdfColor.fromHex('#15803D'),
        );
      case WorkOrderStatusCatalog.delivered:
        return _PdfStatusColors(
          shade: PdfColor.fromHex('#EDE9FE'),
          accent: PdfColor.fromHex('#6D28D9'),
        );
      case WorkOrderStatusCatalog.cancelled:
        return _PdfStatusColors(
          shade: PdfColor.fromHex('#FEE2E2'),
          accent: PdfColor.fromHex('#B91C1C'),
        );
      case WorkOrderStatusCatalog.pending:
      default:
        return _PdfStatusColors(
          shade: PdfColor.fromHex('#FEF3C7'),
          accent: PdfColor.fromHex('#B45309'),
        );
    }
  }

  String _stamp(DateTime value) {
    final String y = value.year.toString().padLeft(4, '0');
    final String m = value.month.toString().padLeft(2, '0');
    final String d = value.day.toString().padLeft(2, '0');
    final String hh = value.hour.toString().padLeft(2, '0');
    final String mm = value.minute.toString().padLeft(2, '0');
    final String ss = value.second.toString().padLeft(2, '0');
    return '$y$m$d-$hh$mm$ss';
  }

  String _formatDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hh:$mm';
  }

  String _formatMoney(int cents, String currencyCode) {
    return '${_symbol(currencyCode)}${(cents / 100).toStringAsFixed(2)}';
  }

  String _symbol(String currencyCode) {
    switch (currencyCode.trim().toUpperCase()) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'CUP':
        return '₱';
      default:
        return '${currencyCode.trim().toUpperCase()} ';
    }
  }

  String _qty(double value) {
    if ((value - value.roundToDouble()).abs() < 0.0001) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _formatCents(int cents, String currencyCode) {
    return '${_symbolFor(currencyCode)}${(cents / 100).toStringAsFixed(2)}';
  }

  String _symbolFor(String currencyCode) {
    switch (currencyCode.trim().toUpperCase()) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'CUP':
        return '₱';
      default:
        return '${currencyCode.trim().toUpperCase()} ';
    }
  }
}

class _PdfStatusColors {
  const _PdfStatusColors({
    required this.shade,
    required this.accent,
  });

  final PdfColor shade;
  final PdfColor accent;
}
