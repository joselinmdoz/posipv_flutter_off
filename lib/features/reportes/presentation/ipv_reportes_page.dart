import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../data/reportes_local_datasource.dart';
import 'reportes_providers.dart';
import 'widgets/ipv_report_card.dart';
import 'widgets/ipv_reporte_detail_page.dart';

class IpvReportesPage extends ConsumerStatefulWidget {
  const IpvReportesPage({super.key});

  @override
  ConsumerState<IpvReportesPage> createState() => _IpvReportesPageState();
}

class _IpvReportesPageState extends ConsumerState<IpvReportesPage> {
  bool _loading = true;
  bool _loadingIpv = false;
  List<PosTerminal> _terminalOptions = <PosTerminal>[];
  String? _terminalId;
  DateTime? _fromDate;
  DateTime? _toDate;
  List<IpvReportSummaryStat> _reports = <IpvReportSummaryStat>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _load();
    });
  }

  Future<void> _load() async {
    final PerfTrace trace = PerfTrace('ipv_reportes.load');
    if (mounted) {
      setState(() => _loading = true);
    }
    final ReportesLocalDataSource ds =
        ref.read(reportesLocalDataSourceProvider);
    try {
      final Future<List<PosTerminal>> terminalsFuture =
          ds.listIpvTerminalOptions();
      List<IpvReportSummaryStat> reports = await ds.listIpvReports(
        terminalId: _terminalId,
        fromDate: _fromDate,
        toDate: _toDate,
        limit: 200,
      );
      trace.mark('reportes cargados');
      final List<PosTerminal> terminals = await terminalsFuture;
      trace.mark('terminales cargados');
      if (_terminalId != null &&
          terminals.every((PosTerminal row) => row.id != _terminalId)) {
        _terminalId = null;
        reports = await ds.listIpvReports(
          terminalId: null,
          fromDate: _fromDate,
          toDate: _toDate,
          limit: 200,
        );
      }
      if (!mounted) {
        trace.end('unmounted');
        return;
      }
      setState(() {
        _terminalOptions = terminals;
        _reports = reports;
        _loading = false;
      });
      trace.end('ok');
    } catch (e, st) {
      debugPrint('IPV export failed (reportes/ipv_reportes_page). $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      trace.end('error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar IPV: $e')),
      );
    }
  }

  Future<void> _reloadIpvReports() async {
    if (mounted) {
      setState(() => _loadingIpv = true);
    }
    final ReportesLocalDataSource ds =
        ref.read(reportesLocalDataSourceProvider);
    try {
      final List<IpvReportSummaryStat> reports = await ds.listIpvReports(
        terminalId: _terminalId,
        fromDate: _fromDate,
        toDate: _toDate,
        limit: 200,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _reports = reports;
        _loadingIpv = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingIpv = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar IPV: $e')),
      );
    }
  }


  Future<void> _pickFromDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _fromDate ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked == null) {
      return;
    }
    setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _toDate ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked == null) {
      return;
    }
    setState(() => _toDate = picked);
  }

  void _clearFilters() {
    setState(() {
      _terminalId = null;
      _fromDate = null;
      _toDate = null;
    });
    _reloadIpvReports();
  }

  Future<void> _openDetail(IpvReportSummaryStat report) async {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IpvReporteDetailPage(summary: report),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaffold(
      title: 'Reportes IPV',
      currentRoute: '/ipv-reportes',
      onRefresh: _load,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: <Widget>[
                  if (_loadingIpv)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                    
                  // Filtros Section
                  Text(
                    'FILTROS DE BÚSQUEDA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Punto de Venta',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _terminalId,
                              isExpanded: true,
                              icon: const Icon(Icons.expand_more_rounded),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Todos los TPV'),
                                ),
                                ..._terminalOptions.map(
                                  (PosTerminal t) => DropdownMenuItem<String?>(
                                    value: t.id,
                                    child: Text(t.name),
                                  ),
                                ),
                              ],
                              onChanged: (String? value) {
                                setState(() => _terminalId = value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Desde',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _pickFromDate,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _fromDate == null ? 'Seleccionar' : _fromDate.toString().split(' ')[0],
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          const Icon(Icons.calendar_today_rounded, size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hasta',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _pickToDate,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _toDate == null ? 'Seleccionar' : _toDate.toString().split(' ')[0],
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          const Icon(Icons.calendar_today_rounded, size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _loadingIpv ? null : _reloadIpvReports,
                            icon: const Icon(Icons.filter_list_rounded, size: 20),
                            label: const Text('Aplicar filtros'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF1152D4),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(
                         'RESULTADOS (${_reports.length})',
                         style: TextStyle(
                           fontSize: 12,
                           fontWeight: FontWeight.w600,
                           letterSpacing: 0.5,
                           color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
                         ),
                       ),
                       if (_fromDate != null || _toDate != null || _terminalId != null)
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                          )
                     ],
                  ),
                  const SizedBox(height: 12),
                  if (_reports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('No hay reportes IPV para el filtro actual.'),
                      ),
                    )
                  else
                    ListView.builder(
                      key: const PageStorageKey<String>('ipv-reportes-list'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reports.length,
                      itemBuilder: (BuildContext context, int index) {
                        return IpvReportCard(
                          report: _reports[index],
                          onTap: () => _openDetail(_reports[index]),
                          dateFormatter: (dt) => dt.toString().substring(0, 16),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
