import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/reportes_local_datasource.dart';

class SalesTrendCard extends StatelessWidget {
  const SalesTrendCard({
    super.key,
    required this.points,
    required this.currencySymbol,
  });

  final List<SalesTrendPointStat> points;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> labels = _buildAxisLabels(points);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF263244) : const Color(0xFFD8E0EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Tendencias de Ventas',
                  style: TextStyle(
                    fontSize: 35 / 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.more_horiz_rounded,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: points.isEmpty
                ? Center(
                    child: Text(
                      'No hay ventas para mostrar tendencia.',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _TrendChartPainter(
                      values: points
                          .map((SalesTrendPointStat p) => p.totalCents / 100)
                          .toList(growable: false),
                      isDark: isDark,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          if (labels.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
                  .map(
                    (String label) => Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          if (points.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Último valor: $currencySymbol${(points.last.totalCents / 100).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _buildAxisLabels(List<SalesTrendPointStat> source) {
    if (source.isEmpty) {
      return <String>[];
    }
    if (source.length <= 4) {
      return source
          .map((SalesTrendPointStat p) => p.label.toUpperCase())
          .toList();
    }
    final List<int> indexes = <int>[
      0,
      ((source.length - 1) * 0.33).round(),
      ((source.length - 1) * 0.66).round(),
      source.length - 1,
    ];
    final Set<int> seen = <int>{};
    final List<String> labels = <String>[];
    for (final int idx in indexes) {
      if (seen.add(idx)) {
        labels.add(source[idx].label.toUpperCase());
      }
    }
    while (labels.length < 4) {
      labels.add('');
    }
    return labels;
  }
}

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({
    required this.values,
    required this.isDark,
  });

  final List<double> values;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final double y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) {
      return;
    }

    final double maxValue = math.max(values.reduce(math.max), 0.0001);
    final double minValue = math.min(values.reduce(math.min), 0.0);
    final double spread = math.max(maxValue - minValue, 0.0001);

    final List<Offset> points = <Offset>[];
    final int count = values.length;
    for (int i = 0; i < count; i++) {
      final double x = count == 1 ? size.width : (i * size.width / (count - 1));
      final double normalized = (values[i] - minValue) / spread;
      final double y = size.height - (normalized * (size.height - 16)) - 8;
      points.add(Offset(x, y));
    }

    final Paint linePaint = Paint()
      ..color = const Color(0xFF1152D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    if (points.length == 1) {
      path.addOval(Rect.fromCircle(center: points.first, radius: 2));
    } else {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final Offset current = points[i];
        final Offset next = points[i + 1];
        final double midX = (current.dx + next.dx) / 2;
        path.quadraticBezierTo(
            current.dx, current.dy, midX, (current.dy + next.dy) / 2);
      }
      path.lineTo(points.last.dx, points.last.dy);
    }
    canvas.drawPath(path, linePaint);

    final Paint dotPaint = Paint()..color = const Color(0xFF1152D4);
    canvas.drawCircle(points.last, 4.5, dotPaint);
    canvas.drawCircle(
      points.last,
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = isDark ? const Color(0xFF0F172A) : Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    if (oldDelegate.isDark != isDark) {
      return true;
    }
    if (oldDelegate.values.length != values.length) {
      return true;
    }
    for (int i = 0; i < values.length; i++) {
      if ((oldDelegate.values[i] - values[i]).abs() > 0.0001) {
        return true;
      }
    }
    return false;
  }
}
