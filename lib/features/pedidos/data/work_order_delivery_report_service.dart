import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pedidos_local_datasource.dart';

class WorkOrderDeliveryReportService {
  Future<String> exportDeliveryCertificatePdf({
    required WorkOrderDetail detail,
  }) async {
    final DateTime now = DateTime.now();
    final Directory dir = await _resolveDeliveryCertificatesDir();
    final String safeFolio =
        detail.folio.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final String stamp = _stamp(now);
    final File file = File(
      p.join(dir.path, 'acta-entrega-$safeFolio-$stamp.pdf'),
    );

    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 24),
        build: (pw.Context context) => <pw.Widget>[
          _header(detail, now),
          pw.SizedBox(height: 14),
          _sectionTitle('Datos del cliente'),
          _infoCard(
            <pw.Widget>[
              _infoRow('Nombre', detail.customerName ?? 'Sin cliente asignado'),
              _infoRow('Código', detail.customerCode ?? '-'),
              _infoRow('Teléfono', detail.customerPhone ?? '-'),
              _infoRow('Correo', detail.customerEmail ?? '-'),
              _infoRow('Dirección', detail.customerAddress ?? '-'),
            ],
          ),
          pw.SizedBox(height: 14),
          _sectionTitle('Detalles del pedido'),
          _infoCard(
            <pw.Widget>[
              _infoRow('Folio', detail.folio),
              _infoRow('Título', detail.title),
              _infoRow('Estado', WorkOrderStatusCatalog.label(detail.status)),
              _infoRow(
                'Estado de cobro',
                WorkOrderPaymentStatusCatalog.label(detail.paymentStatus),
              ),
              _infoRow(
                'Cobrado el',
                detail.paidAt == null
                    ? 'Pendiente'
                    : _formatDateTime(detail.paidAt!),
              ),
              _infoRow(
                'Cotización fijada',
                detail.pricingSnapshot == null
                    ? '-'
                    : _formatDateTime(detail.pricingSnapshot!.capturedAt),
              ),
              _infoRow(
                  'Prioridad', WorkOrderPriorityCatalog.label(detail.priority)),
              _infoRow('Creado', _formatDateTime(detail.createdAt)),
              _infoRow(
                'Entrega estimada',
                detail.dueAt == null ? '-' : _formatDateTime(detail.dueAt!),
              ),
              _infoRow(
                'Finalizado producción',
                detail.completedAt == null
                    ? '-'
                    : _formatDateTime(detail.completedAt!),
              ),
              _infoRow(
                'Entregado',
                detail.deliveredAt == null
                    ? 'Pendiente'
                    : _formatDateTime(detail.deliveredAt!),
              ),
              _infoRow('Creado por', detail.createdByUsername),
              if ((detail.description ?? '').trim().isNotEmpty)
                _infoRow('Descripción', detail.description!.trim()),
              if ((detail.note ?? '').trim().isNotEmpty)
                _infoRow('Nota', detail.note!.trim()),
            ],
          ),
          pw.SizedBox(height: 14),
          _sectionTitle('Productos solicitados'),
          ...detail.items.map(_productCard),
          pw.SizedBox(height: 14),
          _sectionTitle('Responsables asignados'),
          if (detail.assignments.isEmpty)
            _emptyText('No hay responsables asignados para este pedido.')
          else
            ...detail.assignments.map(_assignmentCard),
          pw.SizedBox(height: 14),
          _sectionTitle('Trabajos realizados'),
          if (detail.tasks.isEmpty)
            _emptyText('Aún no se han registrado trabajos realizados.')
          else
            ...detail.tasks.map(_taskCard),
          pw.SizedBox(height: 14),
          _sectionTitle('Pagos registrados'),
          if (detail.paymentLines.isEmpty)
            _emptyText('Sin pagos registrados para este pedido.')
          else
            ...detail.paymentLines.map(_paymentLineCard),
          pw.SizedBox(height: 18),
          _sectionTitle('Firmas de conformidad'),
          pw.SizedBox(height: 8),
          pw.Row(
            children: <pw.Widget>[
              pw.Expanded(child: _signatureBox('Entrega realizada por')),
              pw.SizedBox(width: 16),
              pw.Expanded(child: _signatureBox('Recibido por cliente')),
            ],
          ),
        ],
      ),
    );

    await file.writeAsBytes(await doc.save(), flush: true);
    return file.path;
  }

  pw.Widget _header(WorkOrderDetail detail, DateTime now) {
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
            'Acta de Entrega',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Pedido ${detail.folio}',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
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
            width: 108,
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

  pw.Widget _productCard(WorkOrderProductItem item) {
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
          pw.Text(
            item.productName,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${_qty(item.qty)} ${item.unitLabel} · ${item.productSku}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _assignmentCard(WorkOrderAssignmentItem item) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.all(12),
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
          pw.Text(
            task.title,
            style: pw.TextStyle(
              fontSize: 12,
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
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
          pw.SizedBox(height: 6),
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
                '${_symbol(line.currencyCode)}${(line.enteredAmountCents / 100).toStringAsFixed(2)}',
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
        ],
      ),
    );
  }

  pw.Widget _taskSubsection(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4),
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

  pw.Widget _emptyText(String text) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 8),
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

  pw.Widget _signatureBox(String label) {
    return pw.Container(
      height: 86,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: <pw.Widget>[
          pw.Container(
            height: 1,
            color: PdfColor.fromHex('#94A3B8'),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Future<Directory> _resolveDeliveryCertificatesDir() async {
    final Directory base = await _resolveDownloadsBaseDir();
    final Directory dir = Directory(
      p.join(base.path, 'POSIPV', 'Pedidos', 'Actas'),
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

  String _stamp(DateTime value) {
    final String y = value.year.toString().padLeft(4, '0');
    final String m = value.month.toString().padLeft(2, '0');
    final String d = value.day.toString().padLeft(2, '0');
    final String hh = value.hour.toString().padLeft(2, '0');
    final String mm = value.minute.toString().padLeft(2, '0');
    final String ss = value.second.toString().padLeft(2, '0');
    return '$y$m$d-$hh$mm$ss';
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

  String _formatDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hh:$mm';
  }

  String _qty(double value) {
    if ((value - value.roundToDouble()).abs() < 0.0001) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}
