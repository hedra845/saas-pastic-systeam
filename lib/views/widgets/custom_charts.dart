import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// -------------------------------------------------------------
// الرسم البياني الخطي لمنحنى الإنتاج (مطابق بدقة للصورة المرفقة)
// -------------------------------------------------------------
class ProductionLineChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const ProductionLineChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ترويسة الرسم البياني والفلتر
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'الإنتاج خلال آخر 7 أيام (كجم)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'آخر 7 أيام',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // لوحة الرسم المخصصة
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _ProductionChartPainter(data),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductionChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  _ProductionChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final yAxisWidth = 45.0;
    final xAxisHeight = 24.0;
    final chartWidth = size.width - yAxisWidth;
    final chartHeight = size.height - xAxisHeight;

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textStyle = const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 10,
      fontFamily: 'Segoe UI',
    );

    // خطوط الشبكة وقيم المحور الرأسي (0، 5,000، 10,000، 15,000، 20,000، 25,000)
    final yLevels = [0, 5000, 10000, 15000, 20000, 25000];
    final maxY = 25000.0;

    for (var val in yLevels) {
      final normY = chartHeight - (val / maxY) * chartHeight;

      // خط شبكة أفقي
      canvas.drawLine(
        Offset(yAxisWidth, normY),
        Offset(size.width, normY),
        gridPaint,
      );

      // النص
      final textSpan = TextSpan(
        text: val == 0 ? '0' : val.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        ),
        style: textStyle,
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(0, normY - 6));
    }

    // حساب النقاط
    final points = <Offset>[];
    final stepX = chartWidth / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = yAxisWidth + (i * stepX);
      final kg = (data[i]['kg'] as num).toDouble();
      final y = chartHeight - (kg / maxY) * chartHeight;
      points.add(Offset(x, y));

      // تسميات المحور الأفقي (التواريخ)
      final label = data[i]['date'] as String;
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(x - (tp.width / 2), chartHeight + 6));
    }

    // مسار التدرج اللوني أسفل المنحنى (Gradient Fill)
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;
      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, chartHeight);
    fillPath.lineTo(points.first.dx, chartHeight);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppTheme.primaryBlue.withValues(alpha: 0.20),
        AppTheme.primaryBlue.withValues(alpha: 0.01),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // رسم الخط الأزرق الأساسي
    final linePaint = Paint()
      ..color = AppTheme.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // رسم النقاط والدوائر
    final dotFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = AppTheme.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (var pt in points) {
      canvas.drawCircle(pt, 4.5, dotFillPaint);
      canvas.drawCircle(pt, 4.5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// -------------------------------------------------------------
// الرسم البياني الدائري لتوزيع التكاليف (Donut Chart)
// -------------------------------------------------------------
class CostDonutChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> slices;

  const CostDonutChartWidget({super.key, required this.slices});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'توزيع التكاليف',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  // الرسم الدائري
                  Expanded(
                    flex: 3,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Center(
                          child: SizedBox(
                            width: math.min(constraints.maxWidth, constraints.maxHeight),
                            height: math.min(constraints.maxWidth, constraints.maxHeight),
                            child: CustomPaint(
                              painter: _DonutChartPainter(slices),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // وسيلة الإيضاح (Legend)
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: slices.map((s) {
                        final color = s['color'] as Color;
                        final name = s['name'] as String;
                        final percent = (s['percent'] as num).toInt();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$percent%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
}

class _DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> slices;

  _DonutChartPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) * 0.92;
    final strokeWidth = radius * 0.44;

    double startAngle = -math.pi / 2;

    for (var slice in slices) {
      final percent = (slice['percent'] as num).toDouble();
      if (percent <= 0) continue;
      final sweepAngle = (percent / 100.0) * 2 * math.pi;
      final color = slice['color'] as Color;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
        startAngle,
        sweepAngle - 0.02, // هامش طفيف للفصل بين القطاعات
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
