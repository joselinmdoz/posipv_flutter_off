import 'package:flutter/services.dart';

import '../domain/sale_receipt.dart';

class SaleTicketPrintService {
  static const MethodChannel _channel =
      MethodChannel('com.example.posipv/device_identity');

  Future<void> printReceipt(SaleReceipt receipt) async {
    final String html = _buildTicketHtml(receipt);
    try {
      final bool? ok = await _channel.invokeMethod<bool>(
        'printTicketHtml',
        <String, Object?>{
          'jobName': 'Ticket ${receipt.folio}',
          'html': html,
        },
      );
      if (ok != true) {
        throw Exception('No se pudo iniciar la impresion del ticket.');
      }
    } on MissingPluginException {
      throw Exception(
        'La impresion no esta disponible en este dispositivo.',
      );
    } on PlatformException catch (e) {
      throw Exception(
        (e.message ?? 'No se pudo iniciar la impresion del ticket.').trim(),
      );
    }
  }

  Future<void> shareReceipt(SaleReceipt receipt) async {
    final String text = _buildShareText(receipt);
    try {
      final bool? ok = await _channel.invokeMethod<bool>(
        'shareText',
        <String, Object?>{
          'text': text,
          'subject': 'Ticket ${receipt.folio}',
        },
      );
      if (ok != true) {
        throw Exception('No se pudo abrir el menú de compartir.');
      }
    } on MissingPluginException {
      throw Exception(
        'Compartir no esta disponible en este dispositivo.',
      );
    } on PlatformException catch (e) {
      throw Exception(
        (e.message ?? 'No se pudo compartir el ticket.').trim(),
      );
    }
  }

  String _buildTicketHtml(SaleReceipt receipt) {
    final StringBuffer rows = StringBuffer();
    for (final SaleReceiptLine line in receipt.lines) {
      rows.writeln(
        '''
        <tr>
          <td>${_escapeHtml(line.name)}</td>
          <td>${_escapeHtml(line.sku)}</td>
          <td class="num">${_formatQty(line.qty)}</td>
          <td class="num">${line.unitPriceDisplay ?? _money(receipt, line.unitPriceCents)}</td>
          <td class="num">${line.lineTotalDisplay ?? _money(receipt, line.lineTotalCents)}</td>
        </tr>
        ''',
      );
    }

    final StringBuffer payments = StringBuffer();
    for (final ReceiptPayment payment in receipt.payments) {
      payments.writeln(
        '''
        <tr>
          <td>${_escapeHtml(payment.method)}</td>
          <td class="num">${_money(receipt, payment.amountCents)}</td>
        </tr>
        ''',
      );
    }

    final int safeReceived =
        (receipt.receivedCents ?? receipt.paidCents).clamp(0, 2147483647);
    final int safePaid = receipt.paidCents.clamp(0, 2147483647);
    final int applied =
        safePaid > receipt.totalCents ? receipt.totalCents : safePaid;
    final int pending = receipt.totalCents - applied;
    final int change = receipt.changeCents.clamp(0, 2147483647);
    final String customer = (receipt.customerName ?? '').trim().isEmpty
        ? '-'
        : _escapeHtml(receipt.customerName!.trim());
    final String customerCode = (receipt.customerCode ?? '').trim().isEmpty
        ? '-'
        : _escapeHtml(receipt.customerCode!.trim());

    final String demoBanner = receipt.isDemoMode
        ? '<div class="demo">MODO DEMO • COMPROBANTE NO FISCAL</div>'
        : '';
    final String discountRow = receipt.discountCents > 0
        ? '''
          <div class="row">
            <span>Descuento</span>
            <strong>-${_money(receipt, receipt.discountCents)}</strong>
          </div>
          '''
        : '';
    final String changeRows = change > 0
        ? '''
          <div class="row">
            <span>Cambio</span>
            <strong>${_money(receipt, change)}</strong>
          </div>
          <div class="meta">${receipt.changeReturned ? 'Cambio devuelto' : 'Cambio no devuelto'}</div>
          '''
        : '';
    final String pendingRow = pending > 0
        ? '''
          <div class="row">
            <span>Pendiente</span>
            <strong>${_money(receipt, pending)}</strong>
          </div>
          '''
        : '';

    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <style>
      @page { margin: 10mm; }
      body { font-family: sans-serif; color: #111827; font-size: 12px; }
      h1 { margin: 0 0 4px 0; font-size: 18px; }
      .muted { color: #6b7280; }
      .section { margin-top: 10px; }
      .meta { font-size: 11px; color: #4b5563; margin-top: 2px; }
      .demo { margin-top: 6px; padding: 6px; background: #fff7ed; color: #9a3412; font-weight: 700; border-radius: 6px; }
      table { width: 100%; border-collapse: collapse; margin-top: 6px; }
      th, td { border-bottom: 1px solid #e5e7eb; padding: 5px 2px; text-align: left; vertical-align: top; }
      th { font-size: 11px; color: #6b7280; font-weight: 700; }
      .num { text-align: right; white-space: nowrap; }
      .totals { margin-top: 10px; border-top: 1px dashed #9ca3af; padding-top: 8px; }
      .row { display: flex; justify-content: space-between; gap: 10px; margin: 2px 0; }
      .total { font-size: 15px; font-weight: 800; margin-top: 4px; }
      .strong { font-weight: 700; }
    </style>
  </head>
  <body>
    <h1>Ticket de Venta</h1>
    <div class="meta strong">Folio: #${_escapeHtml(receipt.folio)}</div>
    <div class="meta">Fecha: ${_escapeHtml(_formatDateTime(receipt.createdAt))}</div>
    <div class="meta">Cajero: ${_escapeHtml(receipt.cashierUsername)}</div>
    <div class="meta">TPV: ${_escapeHtml(receipt.terminalName)}</div>
    <div class="meta">Almacen: ${_escapeHtml(receipt.warehouseName)}</div>
    <div class="meta">Cliente: $customer</div>
    <div class="meta">Codigo cliente: $customerCode</div>
    $demoBanner

    <div class="section">
      <table>
        <thead>
          <tr>
            <th>Producto</th>
            <th>Codigo</th>
            <th class="num">Cant.</th>
            <th class="num">Precio</th>
            <th class="num">Importe</th>
          </tr>
        </thead>
        <tbody>
          $rows
        </tbody>
      </table>
    </div>

    <div class="section">
      <div class="strong">Pagos</div>
      <table>
        <tbody>
          $payments
        </tbody>
      </table>
    </div>

    <div class="totals">
      <div class="row">
        <span>Subtotal</span>
        <strong>${_money(receipt, receipt.subtotalCents)}</strong>
      </div>
      <div class="row">
        <span>IVA</span>
        <strong>${_money(receipt, receipt.taxCents)}</strong>
      </div>
      $discountRow
      <div class="row">
        <span>Recibido</span>
        <strong>${_money(receipt, safeReceived)}</strong>
      </div>
      <div class="row">
        <span>Pagado</span>
        <strong>${_money(receipt, safePaid)}</strong>
      </div>
      $pendingRow
      $changeRows
      <div class="row total">
        <span>TOTAL</span>
        <strong>${_money(receipt, receipt.totalCents)}</strong>
      </div>
    </div>
  </body>
</html>
''';
  }

  String _money(SaleReceipt receipt, int cents) {
    final bool negative = cents < 0;
    final int abs = cents.abs();
    final String formatted =
        '${receipt.currencySymbol}${(abs / 100).toStringAsFixed(2)}';
    return negative ? '-$formatted' : formatted;
  }

  String _formatQty(double qty) {
    if (qty == qty.truncateToDouble()) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  String _formatDateTime(DateTime date) {
    final DateTime local = date.toLocal();
    final String dd = local.day.toString().padLeft(2, '0');
    final String mm = local.month.toString().padLeft(2, '0');
    final String yyyy = local.year.toString();
    final String hh = local.hour.toString().padLeft(2, '0');
    final String min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _buildShareText(SaleReceipt receipt) {
    final StringBuffer out = StringBuffer()
      ..writeln('TICKET DE VENTA')
      ..writeln('Folio: #${receipt.folio}')
      ..writeln('Fecha: ${_formatDateTime(receipt.createdAt)}')
      ..writeln('Cajero: ${receipt.cashierUsername}')
      ..writeln('TPV: ${receipt.terminalName}')
      ..writeln('Almacen: ${receipt.warehouseName}');

    final String customer = (receipt.customerName ?? '').trim();
    if (customer.isNotEmpty) {
      out.writeln('Cliente: $customer');
    }
    final String customerCode = (receipt.customerCode ?? '').trim();
    if (customerCode.isNotEmpty) {
      out.writeln('Codigo cliente: $customerCode');
    }
    if (receipt.isDemoMode) {
      out.writeln('MODO DEMO - COMPROBANTE NO FISCAL');
    }

    out.writeln('');
    out.writeln('PRODUCTOS');
    for (final SaleReceiptLine line in receipt.lines) {
      out.writeln(
        '- ${line.name} (${line.sku}) x ${_formatQty(line.qty)} '
        '@ ${line.unitPriceDisplay ?? _money(receipt, line.unitPriceCents)} '
        '= ${line.lineTotalDisplay ?? _money(receipt, line.lineTotalCents)}',
      );
    }

    out.writeln('');
    out.writeln('PAGOS');
    if (receipt.payments.isEmpty) {
      out.writeln('- Sin pagos registrados');
    } else {
      for (final ReceiptPayment payment in receipt.payments) {
        out.writeln(
            '- ${payment.method}: ${_money(receipt, payment.amountCents)}');
      }
    }

    final int safeReceived =
        (receipt.receivedCents ?? receipt.paidCents).clamp(0, 2147483647);
    final int safePaid = receipt.paidCents.clamp(0, 2147483647);
    final int applied =
        safePaid > receipt.totalCents ? receipt.totalCents : safePaid;
    final int pending = receipt.totalCents - applied;
    final int change = receipt.changeCents.clamp(0, 2147483647);

    out
      ..writeln('')
      ..writeln('RESUMEN')
      ..writeln('Subtotal: ${_money(receipt, receipt.subtotalCents)}')
      ..writeln('IVA: ${_money(receipt, receipt.taxCents)}');
    if (receipt.discountCents > 0) {
      out.writeln('Descuento: -${_money(receipt, receipt.discountCents)}');
    }
    out
      ..writeln('Recibido: ${_money(receipt, safeReceived)}')
      ..writeln('Pagado: ${_money(receipt, safePaid)}');
    if (pending > 0) {
      out.writeln('Pendiente: ${_money(receipt, pending)}');
    }
    if (change > 0) {
      out.writeln('Cambio: ${_money(receipt, change)}');
      out.writeln(
        receipt.changeReturned ? 'Cambio devuelto' : 'Cambio no devuelto',
      );
    }
    out.writeln('TOTAL: ${_money(receipt, receipt.totalCents)}');
    return out.toString();
  }
}
