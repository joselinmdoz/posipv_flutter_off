import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/licensing/license_providers.dart';
import '../../../../core/utils/perf_trace.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../data/reportes_local_datasource.dart';
import '../reportes_providers.dart';
import '../../../tpv/presentation/tpv_providers.dart';

class IpvReporteDetailPage extends ConsumerStatefulWidget {
  final IpvReportSummaryStat summary;

  const IpvReporteDetailPage({super.key, required this.summary});

  @override
  ConsumerState<IpvReporteDetailPage> createState() =>
      _IpvReporteDetailPageState();
}

class _IpvReporteDetailPageState extends ConsumerState<IpvReporteDetailPage> {
  bool _loading = true;
  bool _reconciling = false;
  IpvReportDetailStat? _detail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDetail();
      }
    });
  }

  Future<void> _loadDetail() async {
    final PerfTrace trace = PerfTrace('ipv_detail.load');
    setState(() => _loading = true);
    final ReportesLocalDataSource ds =
        ref.read(reportesLocalDataSourceProvider);
    try {
      final IpvReportDetailStat? detail =
          await ds.loadIpvReportDetail(widget.summary.reportId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
      trace.end('ok');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      trace.end('error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar detalle: $e')),
      );
    }
  }

  Future<void> _exportFormat(String format) async {
    final ReportesLocalDataSource ds =
        ref.read(reportesLocalDataSourceProvider);
    try {
      final String path = format == 'pdf'
          ? await ds.exportIpvReportPdf(widget.summary.reportId)
          : await ds.exportIpvReportCsv(widget.summary.reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exportado $format en: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar IPV: $e')),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    final DateTime local = dt.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)} de ${_monthName(local.month)}, ${local.year} - ${two(local.hour)}:${two(local.minute)}';
  }

  String _monthName(int month) {
    const List<String> months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return months[month - 1];
  }

  String _moneyWithSymbol(int cents, String symbol) {
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }

  int _lineTotalAmountCents(IpvReportLineStat line) {
    return line.totalAmountCents;
  }

  int _tableTotalAmountCents(IpvReportDetailStat detail) {
    int total = 0;
    for (final IpvReportLineStat line in detail.lines) {
      total += _lineTotalAmountCents(line);
    }
    return total;
  }

  Future<void> _reconcileIpv() async {
    final session = ref.read(currentSessionProvider);
    if (session == null || !session.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo el administrador puede reconciliar IPV.'),
        ),
      );
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reconciliar IPV'),
          content: const Text(
            'Se recalcularán las líneas del IPV con ventas y movimientos actuales. '
            'Úsalo para corregir conciliaciones administrativas.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reconciliar'),
            ),
          ],
        );
      },
    );
    if (confirm != true || !mounted) {
      return;
    }

    setState(() => _reconciling = true);
    try {
      await ref.read(tpvLocalDataSourceProvider).reconcileIpvReport(
            reportId: widget.summary.reportId,
            userId: session.userId,
          );
      if (!mounted) {
        return;
      }
      await _loadDetail();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IPV reconciliado correctamente.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo reconciliar IPV: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _reconciling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final session = ref.watch(currentSessionProvider);
    final bool canReconcile = session?.isAdmin ?? false;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            height: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'IPV ${widget.summary.terminalName}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Informe de Inventario, Ventas y Precios',
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (canReconcile)
            IconButton(
              tooltip: 'Reconciliar IPV',
              onPressed: _loading || _reconciling ? null : _reconcileIpv,
              icon: _reconciling
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    )
                  : Icon(
                      Icons.sync_rounded,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? const Center(child: Text('No se encontraron detalles'))
              : _buildContent(context, isDark),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    final IpvReportDetailStat detail = _detail!;
    final int tableTotalAmountCents = _tableTotalAmountCents(detail);
    final bool canExportIpv = ref.watch(currentLicenseStatusProvider).isFull;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Información del Reporte
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'INFORMACIÓN DEL REPORTE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF1152D4),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha y Hora de Generación',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        _formatDateTime(widget.summary.openedAt),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF059669).withValues(alpha: 0.3)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.summary.status != 'open' ? 'ACTUALIZADO' : 'ABIERTO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF15803D),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Exportar Reporte
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'EXPORTAR REPORTE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: canExportIpv ? () => _exportFormat('csv') : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_rounded,
                            color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'CSV',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: canExportIpv ? () => _exportFormat('pdf') : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded,
                            color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'PDF',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!canExportIpv)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              'Modo demo: exportar IPV requiere licencia activa.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Detalle de Productos (Tabla Horizontal)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'DETALLE DE PRODUCTOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC)),
                  dataRowColor: WidgetStateProperty.all(
                      isDark ? const Color(0xFF0F172A) : Colors.white),
                  columnSpacing: 24,
                  horizontalMargin: 16,
                  dividerThickness: 1,
                  columns: const [
                    DataColumn(
                        label: Text('SKU / PRODUCTO',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(
                        label: Text('STOCK INIC.',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        numeric: true),
                    DataColumn(
                        label: Text('ENTRADAS',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        numeric: true),
                    DataColumn(
                        label: Text('SALIDAS',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        numeric: true),
                    DataColumn(
                        label: Text('VENTAS',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        numeric: true),
                    DataColumn(
                        label: Text('STOCK FINAL',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        numeric: true),
                    DataColumn(
                        label: Text('PRECIO',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        numeric: true),
                    DataColumn(
                        label: Text('TOTAL',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        numeric: true),
                  ],
                  rows: detail.lines.map((line) {
                    final int lineTotalAmountCents =
                        _lineTotalAmountCents(line);
                    return DataRow(
                      cells: [
                        DataCell(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(line.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(line.sku,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        )),
                        DataCell(Text(line.startQty.toStringAsFixed(0))),
                        DataCell(Text(
                            line.entriesQty == 0
                                ? '-'
                                : '+${line.entriesQty.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold))),
                        DataCell(Text(
                            line.outputsQty == 0
                                ? '-'
                                : '-${line.outputsQty.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold))),
                        DataCell(Text(line.salesQty.toStringAsFixed(0),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(line.finalQty.toStringAsFixed(0),
                            style:
                                const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text(_moneyWithSymbol(line.salePriceCents,
                            widget.summary.currencySymbol))),
                        DataCell(Text(
                            _moneyWithSymbol(lineTotalAmountCents,
                                widget.summary.currencySymbol),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    );
                  }).toList()
                    ..add(
                      DataRow(
                        color: WidgetStateProperty.all(isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC)),
                        cells: [
                          const DataCell(Text('TOTAL GENERAL',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey))),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          DataCell(Text(
                            _moneyWithSymbol(tableTotalAmountCents,
                                widget.summary.currencySymbol),
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1152D4),
                                fontSize: 16),
                          )),
                        ],
                      ),
                    ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48), // Bottom safe area
      ],
    );
  }
}
