import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../state/factory_store.dart';
import '../models/sale_order.dart';
import '../models/stocktake_record.dart';

class PdfReportService {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  static final NumberFormat _numberFormat = NumberFormat('#,###');
  static final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm');
  static final DateFormat _shortDate = DateFormat('yyyy/MM/dd');

  /// توليد وثيقة PDF للتقرير الشامل
  static Future<pw.Document> generateComprehensiveReport({
    required FactoryStore store,
    required List<SaleOrder> orders,
    required String period,
    required String saleType,
    required String productName,
    required double totalRevenue,
    required double totalWeightKg,
    required double totalProfit,
    required double laborElectricityCost,
  }) async {
    // تحميل خط Tahoma لدعم الحروف العربية بدقة عالية
    pw.Font fontRegular;
    pw.Font fontBold;

    try {
      final regularData = await rootBundle.load('assets/fonts/tahoma.ttf');
      final boldData = await rootBundle.load('assets/fonts/tahomabd.ttf');
      fontRegular = pw.Font.ttf(regularData);
      fontBold = pw.Font.ttf(boldData);
    } catch (_) {
      // بديل احتياطي في حال عدم العثور على الخط في الحزمة
      fontRegular = await PdfGoogleFonts.cairoRegular();
      fontBold = await PdfGoogleFonts.cairoBold();
    }

    // محاولة تحميل الشعار
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final doc = pw.Document();

    // ألوان التقرير المتناسقة
    final primaryColor = PdfColor.fromHex('#1E3A8A'); // كحلي أنيق
    final secondaryColor = PdfColor.fromHex('#2563EB'); // أزرق مريح
    final accentGreen = PdfColor.fromHex('#10B981'); // أخضر للأرباح
    final bgLight = PdfColor.fromHex('#F8FAFC'); // رمادي ثلجي للخلفيات
    final borderCol = PdfColor.fromHex('#E2E8F0');

    // تجميع إحصائيات المخزون
    final totalStockKg = store.products.fold(0.0, (sum, p) => sum + p.stockKg);
    final totalProducedKg = store.products.fold(0.0, (sum, p) => sum + p.totalProducedKg);

    // تجميع مصروفات التشغيل
    final totalExpenses = store.expenses.fold(0.0, (sum, e) => sum + e.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        header: (context) {
          if (context.pageNumber > 1) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.only(bottom: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    store.factoryName.isNotEmpty ? store.factoryName : 'النجمة بلاست',
                    style: pw.TextStyle(font: fontBold, fontSize: 10, color: primaryColor),
                  ),
                  pw.Text(
                    'التقرير الشامل - استمرار الصفحة ${context.pageNumber}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            );
          }
          return pw.SizedBox();
        },
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'نظام إدارة النجمة بلاست المتكامل | صُدر بتاريخ: ${_dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
        build: (context) => [
          // -----------------------------------------------------------
          // الترويسة الرئيسية للتقرير
          // -----------------------------------------------------------
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: bgLight,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: borderCol, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      store.factoryName.isNotEmpty ? store.factoryName : 'النجمة بلاست',
                      style: pw.TextStyle(font: fontBold, fontSize: 18, color: primaryColor),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'تقرير شامل لتحليلات المبيعات، الإنتاج، التكاليف والأرباح',
                      style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        _buildFilterBadge('الفترة: $period', secondaryColor, fontRegular),
                        pw.SizedBox(width: 6),
                        _buildFilterBadge('نوع البيع: $saleType', primaryColor, fontRegular),
                        pw.SizedBox(width: 6),
                        _buildFilterBadge('الصنف: $productName', PdfColors.teal, fontRegular),
                      ],
                    ),
                  ],
                ),
                if (logoImage != null)
                  pw.Container(
                    width: 64,
                    height: 64,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // -----------------------------------------------------------
          // بطاقات مؤشرات الأداء المالي (KPIs)
          // -----------------------------------------------------------
          pw.Row(
            children: [
              _buildKpiBox(
                title: 'إجمالي المبيعات',
                value: '${_currencyFormat.format(totalRevenue)} ج.م',
                subtitle: 'إيراد الفواتير للفترة',
                bgColor: PdfColor.fromHex('#EFF6FF'),
                borderColor: PdfColor.fromHex('#BFDBFE'),
                textColor: secondaryColor,
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
              pw.SizedBox(width: 8),
              _buildKpiBox(
                title: 'صافي الأرباح',
                value: '${_currencyFormat.format(totalProfit)} ج.م',
                subtitle: totalRevenue > 0 ? 'الهامش: ${((totalProfit / totalRevenue) * 100).toStringAsFixed(1)}%' : '0.0%',
                bgColor: PdfColor.fromHex('#ECFDF5'),
                borderColor: PdfColor.fromHex('#A7F3D0'),
                textColor: accentGreen,
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
              pw.SizedBox(width: 8),
              _buildKpiBox(
                title: 'وزن المبيعات',
                value: '${_numberFormat.format(totalWeightKg)} كجم',
                subtitle: 'إجمالي وزن البضاعة المباعة',
                bgColor: PdfColor.fromHex('#FEF3C7'),
                borderColor: PdfColor.fromHex('#FDE68A'),
                textColor: PdfColor.fromHex('#B45309'),
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
              pw.SizedBox(width: 8),
              _buildKpiBox(
                title: 'كهرباء وعمالة',
                value: '${_currencyFormat.format(laborElectricityCost)} ج.م',
                subtitle: 'تكاليف تشغيل محملة',
                bgColor: PdfColor.fromHex('#F1F5F9'),
                borderColor: PdfColor.fromHex('#CBD5E1'),
                textColor: PdfColor.fromHex('#475569'),
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // -----------------------------------------------------------
          // ملخص تشغيلي للمصنع والمخزون
          // -----------------------------------------------------------
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: borderCol, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('رصيد الخزينة الحالي', '${_currencyFormat.format(store.currentVaultBalance)} ج.م', fontBold, fontRegular),
                _buildDivider(),
                _buildSummaryStat('رصيد المخزون الجاهز', '${_numberFormat.format(totalStockKg)} كجم', fontBold, fontRegular),
                _buildDivider(),
                _buildSummaryStat('إجمالي إنتاج المصنع', '${_numberFormat.format(totalProducedKg)} كجم', fontBold, fontRegular),
                _buildDivider(),
                _buildSummaryStat('المصروفات العامة المسجلة', '${_currencyFormat.format(totalExpenses)} ج.م', fontBold, fontRegular),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // -----------------------------------------------------------
          // جدول فواتير المبيعات المدرجة
          // -----------------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'كشف فواتير المبيعات المعتمدة (${orders.length} فاتورة)',
                style: pw.TextStyle(font: fontBold, fontSize: 12, color: primaryColor),
              ),
              pw.Text(
                'الترتيب من الأحدث إلى الأقدم',
                style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          if (orders.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderCol),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                'لا توجد فواتير مبيعات مسجلة تطابق محددات البحث والفترة المحددة.',
                style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey600),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: borderCol, width: 0.8),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2), // رقم الفاتورة
                1: pw.FlexColumnWidth(1.2), // التاريخ
                2: pw.FlexColumnWidth(2.2), // العميل
                3: pw.FlexColumnWidth(1.0), // النوع
                4: pw.FlexColumnWidth(1.2), // الوزن كجم
                5: pw.FlexColumnWidth(1.4), // الإجمالي
                6: pw.FlexColumnWidth(1.3), // الربح
                7: pw.FlexColumnWidth(1.2), // طريقة السداد
              },
              children: [
                // رأس الجدول
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryColor),
                  children: [
                    _buildTableCell('رقم الفاتورة', fontBold, isHeader: true),
                    _buildTableCell('التاريخ', fontBold, isHeader: true),
                    _buildTableCell('اسم العميل / المنفذ', fontBold, isHeader: true),
                    _buildTableCell('النوع', fontBold, isHeader: true),
                    _buildTableCell('الوزن (كجم)', fontBold, isHeader: true),
                    _buildTableCell('المبلغ (ج.م)', fontBold, isHeader: true),
                    _buildTableCell('الربح (ج.م)', fontBold, isHeader: true),
                    _buildTableCell('طريقة الدفع', fontBold, isHeader: true),
                  ],
                ),
                // صفوف الفواتير
                ...orders.map((order) {
                  final isWholesale = order.saleType == 'جملة';
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: orders.indexOf(order) % 2 == 0 ? PdfColors.white : bgLight,
                    ),
                    children: [
                      _buildTableCell(order.invoiceNumber, fontBold, fontSize: 8.5),
                      _buildTableCell(_shortDate.format(order.date), fontRegular, fontSize: 8.5),
                      _buildTableCell(order.customerName, fontRegular, fontSize: 8.5),
                      _buildTableCell(
                        order.saleType,
                        fontBold,
                        textColor: isWholesale ? primaryColor : accentGreen,
                        fontSize: 8.5,
                      ),
                      _buildTableCell(_numberFormat.format(order.totalWeightKg), fontRegular, fontSize: 8.5),
                      _buildTableCell(_currencyFormat.format(order.totalAmount), fontBold, fontSize: 8.5),
                      _buildTableCell(
                        '+${_currencyFormat.format(order.totalProfit)}',
                        fontBold,
                        textColor: accentGreen,
                        fontSize: 8.5,
                      ),
                      _buildTableCell(order.paymentMethod, fontRegular, fontSize: 8.5),
                    ],
                  );
                }),
                // صف الإجماليات
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9')),
                  children: [
                    _buildTableCell('الإجمالي', fontBold, isHeader: false, fontSize: 9),
                    _buildTableCell('-', fontRegular, fontSize: 8.5),
                    _buildTableCell('${orders.length} فاتورة', fontBold, fontSize: 8.5),
                    _buildTableCell('-', fontRegular, fontSize: 8.5),
                    _buildTableCell('${_numberFormat.format(totalWeightKg)} كجم', fontBold, fontSize: 8.5),
                    _buildTableCell('${_currencyFormat.format(totalRevenue)} ج', fontBold, textColor: secondaryColor, fontSize: 8.5),
                    _buildTableCell('${_currencyFormat.format(totalProfit)} ج', fontBold, textColor: accentGreen, fontSize: 8.5),
                    _buildTableCell('-', fontRegular, fontSize: 8.5),
                  ],
                ),
              ],
            ),
        ],
      ),
    );

    return doc;
  }

  /// فتح نافذة المعاينة والطباعة المباشرة عبر محرك الطباعة
  static Future<void> printReport({
    required FactoryStore store,
    required List<SaleOrder> orders,
    required String period,
    required String saleType,
    required String productName,
    required double totalRevenue,
    required double totalWeightKg,
    required double totalProfit,
    required double laborElectricityCost,
  }) async {
    final pdfDoc = await generateComprehensiveReport(
      store: store,
      orders: orders,
      period: period,
      saleType: saleType,
      productName: productName,
      totalRevenue: totalRevenue,
      totalWeightKg: totalWeightKg,
      totalProfit: totalProfit,
      laborElectricityCost: laborElectricityCost,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfDoc.save(),
      name: 'تقرير_شامل_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
    );
  }

  /// تصدير وحفظ ملف PDF مباشرة على جهاز المستخدم
  static Future<String?> exportAndSavePdf({
    required FactoryStore store,
    required List<SaleOrder> orders,
    required String period,
    required String saleType,
    required String productName,
    required double totalRevenue,
    required double totalWeightKg,
    required double totalProfit,
    required double laborElectricityCost,
  }) async {
    final pdfDoc = await generateComprehensiveReport(
      store: store,
      orders: orders,
      period: period,
      saleType: saleType,
      productName: productName,
      totalRevenue: totalRevenue,
      totalWeightKg: totalWeightKg,
      totalProfit: totalProfit,
      laborElectricityCost: laborElectricityCost,
    );

    final bytes = await pdfDoc.save();
    final defaultFileName = 'تقرير_شامل_النجمة_بلاست_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    String? outputFilePath;
    try {
      outputFilePath = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكان حفظ تقرير PDF',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    } catch (_) {
      outputFilePath = null;
    }

    if (outputFilePath != null && outputFilePath.isNotEmpty) {
      if (!outputFilePath.toLowerCase().endsWith('.pdf')) {
        outputFilePath += '.pdf';
      }
      final file = File(outputFilePath);
      await file.writeAsBytes(bytes);
      return outputFilePath;
    }

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final reportsFolder = Directory('${docsDir.path}/تقارير_النجمة_بلاست');
      if (!await reportsFolder.exists()) {
        await reportsFolder.create(recursive: true);
      }
      final fallbackPath = '${reportsFolder.path}/$defaultFileName';
      final file = File(fallbackPath);
      await file.writeAsBytes(bytes);
      return fallbackPath;
    } catch (_) {
      return null;
    }
  }

  /// توليد محضر جرد مخزني رسمي PDF (يومي، أسبوعي، شهري)
  static Future<pw.Document> generateStocktakeReport({
    required FactoryStore store,
    required StocktakeRecord record,
  }) async {
    pw.Font fontRegular;
    pw.Font fontBold;

    try {
      final regularData = await rootBundle.load('assets/fonts/tahoma.ttf');
      final boldData = await rootBundle.load('assets/fonts/tahomabd.ttf');
      fontRegular = pw.Font.ttf(regularData);
      fontBold = pw.Font.ttf(boldData);
    } catch (_) {
      fontRegular = await PdfGoogleFonts.cairoRegular();
      fontBold = await PdfGoogleFonts.cairoBold();
    }

    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final doc = pw.Document();

    final primaryColor = PdfColor.fromHex('#1E3A8A');
    final secondaryColor = PdfColor.fromHex('#2563EB');
    final accentGreen = PdfColor.fromHex('#10B981');
    final dangerRed = PdfColor.fromHex('#EF4444');
    final bgLight = PdfColor.fromHex('#F8FAFC');
    final borderCol = PdfColor.fromHex('#E2E8F0');

    final isDeficit = record.totalVarianceKg < 0;
    final isExact = record.totalVarianceKg == 0;

    PdfColor typeColor;
    if (record.type == 'يومي') {
      typeColor = PdfColor.fromHex('#F59E0B');
    } else if (record.type == 'أسبوعي') {
      typeColor = PdfColor.fromHex('#8B5CF6');
    } else {
      typeColor = PdfColor.fromHex('#0284C7');
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'محضر جرد رسمي معتمد - نظام إدارة النجمة بلاست | صُدر: ${_dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: bgLight,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: borderCol, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      store.factoryName.isNotEmpty ? store.factoryName : 'النجمة بلاست',
                      style: pw.TextStyle(font: fontBold, fontSize: 18, color: primaryColor),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'محضر جرد مخزني وتسوية فروقات الأرصدة (${record.title})',
                      style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        _buildFilterBadge('نوع الجرد: جرد ${record.type}', typeColor, fontRegular),
                        pw.SizedBox(width: 6),
                        _buildFilterBadge('المسؤول: ${record.auditorName}', secondaryColor, fontRegular),
                        pw.SizedBox(width: 6),
                        _buildFilterBadge('الحالة: ${record.status}', accentGreen, fontRegular),
                      ],
                    ),
                  ],
                ),
                if (logoImage != null)
                  pw.Container(
                    width: 64,
                    height: 64,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          pw.Row(
            children: [
              _buildKpiBox(
                title: 'الرصيد الدفتري (بالنظام)',
                value: '${_numberFormat.format(record.totalBookQtyKg)} كجم',
                subtitle: 'إجمالي الأرصدة المسجلة',
                bgColor: PdfColor.fromHex('#EFF6FF'),
                borderColor: PdfColor.fromHex('#BFDBFE'),
                textColor: secondaryColor,
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
              pw.SizedBox(width: 8),
              _buildKpiBox(
                title: 'الرصيد الفعلي (بالميزان)',
                value: '${_numberFormat.format(record.totalActualQtyKg)} كجم',
                subtitle: 'نتيجة الوزن الفعلي بالمخزن',
                bgColor: PdfColor.fromHex('#ECFDF5'),
                borderColor: PdfColor.fromHex('#A7F3D0'),
                textColor: accentGreen,
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
              pw.SizedBox(width: 8),
              _buildKpiBox(
                title: 'فرق الوزن (عجز/زيادة)',
                value: isExact
                    ? 'مطابق 0 كجم'
                    : '${record.totalVarianceKg > 0 ? "+" : ""}${_numberFormat.format(record.totalVarianceKg)} كجم',
                subtitle: isExact ? 'مطابقة 100%' : (isDeficit ? 'عجز مخزني' : 'زيادة مخزنية'),
                bgColor: isExact ? bgLight : (isDeficit ? PdfColor.fromHex('#FEF2F2') : PdfColor.fromHex('#F0F9FF')),
                borderColor: isExact ? borderCol : (isDeficit ? PdfColor.fromHex('#FECACA') : PdfColor.fromHex('#BAE6FD')),
                textColor: isExact ? PdfColors.grey800 : (isDeficit ? dangerRed : secondaryColor),
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
              pw.SizedBox(width: 8),
              _buildKpiBox(
                title: 'الأثر المالي للفارق',
                value: '${_currencyFormat.format(record.totalVarianceCost.abs())} ج.م',
                subtitle: record.totalVarianceCost >= 0 ? 'موجب / لصالح المخزن' : 'سالب / تكلفة عجز',
                bgColor: PdfColor.fromHex('#F8FAFC'),
                borderColor: PdfColor.fromHex('#CBD5E1'),
                textColor: record.totalVarianceCost >= 0 ? accentGreen : dangerRed,
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'تفاصيل فحص الأصناف (${record.entries.length} صنف)',
                style: pw.TextStyle(font: fontBold, fontSize: 12, color: primaryColor),
              ),
              pw.Text(
                'تاريخ المحضر: ${_dateFormat.format(record.date)}',
                style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          pw.Table(
            border: pw.TableBorder.all(color: borderCol, width: 0.8),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.5),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(1.5),
              3: pw.FlexColumnWidth(1.6),
              4: pw.FlexColumnWidth(1.6),
              5: pw.FlexColumnWidth(2.5),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: [
                  _buildTableCell('الصنف المفحوص', fontBold, isHeader: true),
                  _buildTableCell('الرصيد الدفتري', fontBold, isHeader: true),
                  _buildTableCell('الفعلي (بالميزان)', fontBold, isHeader: true),
                  _buildTableCell('فرق الوزن (كجم)', fontBold, isHeader: true),
                  _buildTableCell('الأثر المالي (ج.م)', fontBold, isHeader: true),
                  _buildTableCell('ملاحظات وسبب الفارق', fontBold, isHeader: true),
                ],
              ),
              ...record.entries.map((entry) {
                final isItemExact = entry.varianceKg == 0;
                final isItemDeficit = entry.varianceKg < 0;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: record.entries.indexOf(entry) % 2 == 0 ? PdfColors.white : bgLight,
                  ),
                  children: [
                    _buildTableCell(entry.productName, fontBold, fontSize: 8.5),
                    _buildTableCell('${_numberFormat.format(entry.bookQtyKg)} كجم', fontRegular, fontSize: 8.5),
                    _buildTableCell('${_numberFormat.format(entry.actualQtyKg)} كجم', fontBold, fontSize: 8.5),
                    _buildTableCell(
                      isItemExact
                          ? 'مطابق 0'
                          : '${entry.varianceKg > 0 ? "+" : ""}${entry.varianceKg.toStringAsFixed(1)} كجم',
                      fontBold,
                      textColor: isItemExact ? accentGreen : (isItemDeficit ? dangerRed : secondaryColor),
                      fontSize: 8.5,
                    ),
                    _buildTableCell(
                      '${_currencyFormat.format(entry.varianceCost)} ج',
                      fontBold,
                      textColor: isItemDeficit ? dangerRed : PdfColors.grey900,
                      fontSize: 8.5,
                    ),
                    _buildTableCell(entry.reason ?? '—', fontRegular, fontSize: 8),
                  ],
                );
              }),
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9')),
                children: [
                  _buildTableCell('الإجمالي العام', fontBold, fontSize: 9),
                  _buildTableCell('${_numberFormat.format(record.totalBookQtyKg)} كجم', fontBold, fontSize: 8.5),
                  _buildTableCell('${_numberFormat.format(record.totalActualQtyKg)} كجم', fontBold, fontSize: 8.5),
                  _buildTableCell(
                    '${record.totalVarianceKg > 0 ? "+" : ""}${record.totalVarianceKg.toStringAsFixed(1)} كجم',
                    fontBold,
                    textColor: isDeficit ? dangerRed : accentGreen,
                    fontSize: 8.5,
                  ),
                  _buildTableCell(
                    '${_currencyFormat.format(record.totalVarianceCost)} ج',
                    fontBold,
                    textColor: record.totalVarianceCost < 0 ? dangerRed : accentGreen,
                    fontSize: 8.5,
                  ),
                  _buildTableCell('مطابقة تامة لكافة الأصناف', fontRegular, fontSize: 8),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderCol),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text('مسؤول الجرد / أمين المخزن', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                    pw.SizedBox(height: 4),
                    pw.Text(record.auditorName, style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700)),
                    pw.SizedBox(height: 14),
                    pw.Text('التوقيع: ..........................', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey500)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('مدير الإنتاج والتشغيل', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                    pw.SizedBox(height: 4),
                    pw.Text('المطابقة الميدانية', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700)),
                    pw.SizedBox(height: 14),
                    pw.Text('التوقيع: ..........................', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey500)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('اعتماد الإدارة العامة والمالية', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                    pw.SizedBox(height: 4),
                    pw.Text('اعتماد التسوية الدفترية', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700)),
                    pw.SizedBox(height: 14),
                    pw.Text('التوقيع والختم: ..........................', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  /// طباعة محضر الجرد مباشرة
  static Future<void> printStocktakeReport({
    required FactoryStore store,
    required StocktakeRecord record,
  }) async {
    final pdfDoc = await generateStocktakeReport(store: store, record: record);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfDoc.save(),
      name: 'محضر_جرد_${record.type}_${DateFormat('yyyyMMdd').format(record.date)}',
    );
  }

  /// تصدير وحفظ محضر الجرد PDF
  static Future<String?> exportStocktakePdf({
    required FactoryStore store,
    required StocktakeRecord record,
  }) async {
    final pdfDoc = await generateStocktakeReport(store: store, record: record);
    final bytes = await pdfDoc.save();
    final defaultFileName = 'محضر_جرد_${record.type}_${DateFormat('yyyyMMdd_HHmm').format(record.date)}.pdf';

    final outputFilePath = await FilePicker.platform.saveFile(
      dialogTitle: 'اختر مكان حفظ محضر الجرد PDF',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputFilePath != null) {
      final file = File(outputFilePath);
      await file.writeAsBytes(bytes);
      return outputFilePath;
    }
    return null;
  }

  /// توليد فاتورة بيع رسمية PDF مع لوجو المصنع
  static Future<pw.Document> generateInvoicePdf({
    required FactoryStore store,
    required SaleOrder order,
  }) async {
    pw.Font fontRegular;
    pw.Font fontBold;

    try {
      final regularData = await rootBundle.load('assets/fonts/tahoma.ttf');
      final boldData = await rootBundle.load('assets/fonts/tahomabd.ttf');
      fontRegular = pw.Font.ttf(regularData);
      fontBold = pw.Font.ttf(boldData);
    } catch (_) {
      fontRegular = await PdfGoogleFonts.cairoRegular();
      fontBold = await PdfGoogleFonts.cairoBold();
    }

    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final doc = pw.Document();

    final primaryColor = PdfColor.fromHex('#1E3A8A'); // كحلي أنيق
    final secondaryColor = PdfColor.fromHex('#2563EB'); // أزرق
    final accentGreen = PdfColor.fromHex('#10B981'); // أخضر
    final amberColor = PdfColor.fromHex('#F59E0B'); // كهرماني
    final bgLight = PdfColor.fromHex('#F8FAFC');
    final borderCol = PdfColor.fromHex('#E2E8F0');

    final isWholesale = order.saleType == 'جملة';
    final isPaid = order.paymentStatus == 'مدفوع بالكامل';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 14),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'فاتورة ضريبية رسمية | نظام إدارة النجمة بلاست المتكامل | صُدرت: ${_dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
        build: (context) => [
          // -----------------------------------------------------------
          // الترويسة الرئيسية للفاتورة مع لوجو المصنع
          // -----------------------------------------------------------
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: bgLight,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              border: pw.Border.all(color: borderCol, width: 1.2),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      store.factoryName.isNotEmpty ? store.factoryName : 'النجمة بلاست',
                      style: pw.TextStyle(font: fontBold, fontSize: 20, color: primaryColor),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      isWholesale
                          ? 'فاتورة مبيعات جملة - كبار الموزعين والتجار'
                          : 'فاتورة مبيعات قطاعي - منافذ بيع النجمة بلاست',
                      style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        _buildFilterBadge('رقم الفاتورة: ${order.invoiceNumber}', primaryColor, fontBold),
                        pw.SizedBox(width: 8),
                        _buildFilterBadge('النوع: ${order.saleType}', isWholesale ? secondaryColor : PdfColors.teal, fontRegular),
                        pw.SizedBox(width: 8),
                        _buildFilterBadge(order.paymentStatus, isPaid ? accentGreen : amberColor, fontBold),
                      ],
                    ),
                  ],
                ),
                // شعار المصنع (اللوجو)
                if (logoImage != null)
                  pw.Container(
                    width: 72,
                    height: 72,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: borderCol, width: 1),
                    ),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.Container(
                    width: 72,
                    height: 72,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: borderCol, width: 1),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'شعار\nالمصنع',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: fontBold, fontSize: 10, color: primaryColor),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // -----------------------------------------------------------
          // بيانات العميل وتفاصيل الفاتورة
          // -----------------------------------------------------------
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // بيانات العميل
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: borderCol, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'بيانات العميل / الموزع:',
                        style: pw.TextStyle(font: fontBold, fontSize: 10, color: primaryColor),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('الاسم:', style: pw.TextStyle(font: fontRegular, fontSize: 9.5, color: PdfColors.grey700)),
                          pw.Text(order.customerName, style: pw.TextStyle(font: fontBold, fontSize: 10.5, color: PdfColors.black)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('رقم الهاتف:', style: pw.TextStyle(font: fontRegular, fontSize: 9.5, color: PdfColors.grey700)),
                          pw.Text(
                            (order.customerPhone != null && order.customerPhone!.isNotEmpty)
                                ? order.customerPhone!
                                : '—',
                            style: pw.TextStyle(font: fontRegular, fontSize: 9.5, color: PdfColors.grey800),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('طريقة الدفع:', style: pw.TextStyle(font: fontRegular, fontSize: 9.5, color: PdfColors.grey700)),
                          pw.Text(order.paymentMethod, style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: secondaryColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),

              // بيانات وتاريخ الفاتورة
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: borderCol, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'تفاصيل المعاملة:',
                        style: pw.TextStyle(font: fontBold, fontSize: 10, color: primaryColor),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('تاريخ الفاتورة:', style: pw.TextStyle(font: fontRegular, fontSize: 9.5, color: PdfColors.grey700)),
                          pw.Text(_shortDate.format(order.date), style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColors.black)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('وقت الإصدار:', style: pw.TextStyle(font: fontRegular, fontSize: 9.5, color: PdfColors.grey700)),
                          pw.Text(DateFormat('HH:mm').format(order.date), style: pw.TextStyle(font: fontRegular, fontSize: 9.5, color: PdfColors.grey800)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('حالة السداد:', style: pw.TextStyle(font: fontRegular, fontSize: 9.5, color: PdfColors.grey700)),
                          pw.Text(order.paymentStatus, style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: isPaid ? accentGreen : amberColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // -----------------------------------------------------------
          // جدول بنود الفاتورة
          // -----------------------------------------------------------
          pw.Text(
            'بيان الأصناف والكميات المباعة:',
            style: pw.TextStyle(font: fontBold, fontSize: 11.5, color: primaryColor),
          ),
          pw.SizedBox(height: 6),

          pw.Table(
            border: pw.TableBorder.all(color: borderCol, width: 0.8),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.8), // م
              1: pw.FlexColumnWidth(3.5), // اسم الصنف
              2: pw.FlexColumnWidth(1.8), // الكمية كجم
              3: pw.FlexColumnWidth(1.8), // سعر الكيلو
              4: pw.FlexColumnWidth(2.1), // الإجمالي
            },
            children: [
              // رأس الجدول
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: [
                  _buildTableCell('م', fontBold, isHeader: true),
                  _buildTableCell('بيان المنتج / الصنف', fontBold, isHeader: true),
                  _buildTableCell('الوزن (كجم)', fontBold, isHeader: true),
                  _buildTableCell('سعر الكيلو (ج.م)', fontBold, isHeader: true),
                  _buildTableCell('إجمالي القيمة (ج.م)', fontBold, isHeader: true),
                ],
              ),
              // صفوف الأصناف
              ...order.items.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final item = entry.value;
                final isEven = entry.key % 2 == 0;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : bgLight),
                  children: [
                    _buildTableCell('$idx', fontBold, fontSize: 9),
                    _buildTableCell(item.productName, fontBold, fontSize: 9.5, textColor: PdfColors.grey900),
                    _buildTableCell(_numberFormat.format(item.quantityKg), fontRegular, fontSize: 9.5),
                    _buildTableCell(_currencyFormat.format(item.unitPrice), fontRegular, fontSize: 9.5),
                    _buildTableCell(_currencyFormat.format(item.totalPrice), fontBold, fontSize: 9.5, textColor: primaryColor),
                  ],
                );
              }),
              // صف الإجمالي
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#EFF6FF')),
                children: [
                  _buildTableCell('-', fontBold, fontSize: 9),
                  _buildTableCell('الإجمالي العام للفاتورة', fontBold, fontSize: 10, textColor: primaryColor),
                  _buildTableCell('${_numberFormat.format(order.totalWeightKg)} كجم', fontBold, fontSize: 10, textColor: secondaryColor),
                  _buildTableCell('-', fontBold, fontSize: 9),
                  _buildTableCell('${_currencyFormat.format(order.totalAmount)} ج.م', fontBold, fontSize: 10.5, textColor: accentGreen),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // -----------------------------------------------------------
          // صندوق الإجمالي والملاحظات
          // -----------------------------------------------------------
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ملاحظات الفاتورة
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: borderCol, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ملاحظات وشروط البيع:', style: pw.TextStyle(font: fontBold, fontSize: 9, color: primaryColor)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        (order.notes != null && order.notes!.isNotEmpty)
                            ? order.notes!
                            : '• البضاعة المباعة خضعت للفحص والوزن المعتمد بميزان المصنع.\n• لا يُعتد بأي تعديل على هذه الفاتورة إلا بختم وتوقيع الإدارة.',
                        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),

              // كرت المبلغ الإجمالي المستحق
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#ECFDF5'),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColor.fromHex('#A7F3D0'), width: 1.2),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('المبلغ الإجمالي المستحق', style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${_currencyFormat.format(order.totalAmount)} ج.م',
                        style: pw.TextStyle(font: fontBold, fontSize: 16, color: accentGreen),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'الوزن الكلي: ${_numberFormat.format(order.totalWeightKg)} كجم',
                        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 26),

          // -----------------------------------------------------------
          // التوقيعات والختم الرسمي للمصنع
          // -----------------------------------------------------------
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderCol, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  children: [
                    pw.Text('توقيع المستلم / العميل', style: pw.TextStyle(font: fontBold, fontSize: 9.5)),
                    pw.SizedBox(height: 4),
                    pw.Text(order.customerName, style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey700)),
                    pw.SizedBox(height: 16),
                    pw.Text('التوقيع: ...........................', style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey500)),
                  ],
                ),
                // ختم المصنع
                pw.Container(
                  width: 76,
                  height: 76,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: primaryColor, width: 1.5, style: pw.BorderStyle.dashed),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'ختم النجمة بلاست\nالمعتمد',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: primaryColor),
                  ),
                ),
                pw.Column(
                  children: [
                    pw.Text('مسؤول المبيعات والخزينة', style: pw.TextStyle(font: fontBold, fontSize: 9.5)),
                    pw.SizedBox(height: 4),
                    pw.Text('اعتماد الفاتورة والصرف', style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey700)),
                    pw.SizedBox(height: 16),
                    pw.Text('التوقيع: ...........................', style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  /// طباعة الفاتورة مباشرة
  static Future<void> printInvoice({
    required FactoryStore store,
    required SaleOrder order,
  }) async {
    final pdfDoc = await generateInvoicePdf(store: store, order: order);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfDoc.save(),
      name: 'فاتورة_${order.invoiceNumber}',
    );
  }

  /// تصدير وحفظ الفاتورة كملف PDF
  static Future<String?> exportInvoicePdf({
    required FactoryStore store,
    required SaleOrder order,
  }) async {
    final pdfDoc = await generateInvoicePdf(store: store, order: order);
    final bytes = await pdfDoc.save();

    final safeCustomer = (order.customerName.isEmpty ? 'عميل' : order.customerName)
        .replaceAll(RegExp(r'[<>:"/\\|?*\n\r]'), '_')
        .replaceAll(' ', '_')
        .trim();
    final safeInvNum = order.invoiceNumber.replaceAll(RegExp(r'[<>:"/\\|?*\n\r]'), '_').trim();
    final defaultFileName = 'فاتورة_${safeInvNum}_$safeCustomer.pdf';

    String? outputFilePath;
    try {
      outputFilePath = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكان حفظ فاتورة PDF',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        lockParentWindow: true,
      );
    } catch (_) {
      outputFilePath = null;
    }

    if (outputFilePath != null && outputFilePath.isNotEmpty) {
      if (!outputFilePath.toLowerCase().endsWith('.pdf')) {
        outputFilePath += '.pdf';
      }
      final file = File(outputFilePath);
      await file.writeAsBytes(bytes);
      return outputFilePath;
    }

    // حفظ احتياطي تلقائي في مجلد المستندات لتفادي أي مشاكل في نوافذ ويندوز
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final invoicesFolder = Directory('${docsDir.path}/فواتير_النجمة_بلاست');
      if (!await invoicesFolder.exists()) {
        await invoicesFolder.create(recursive: true);
      }
      final fallbackPath = '${invoicesFolder.path}/$defaultFileName';
      final file = File(fallbackPath);
      await file.writeAsBytes(bytes);
      return fallbackPath;
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // عناصر مساعدة لبناء واجهة PDF
  // -------------------------------------------------------------

  static pw.Widget _buildFilterBadge(String text, PdfColor color, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: color.luminance > 0.5 ? color : PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: color, width: 0.6),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 8.5, color: color),
      ),
    );
  }

  static pw.Widget _buildKpiBox({
    required String title,
    required String value,
    required String subtitle,
    required PdfColor bgColor,
    required PdfColor borderColor,
    required PdfColor textColor,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: borderColor, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 3),
            pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 10.5, color: textColor)),
            pw.SizedBox(height: 2),
            pw.Text(subtitle, style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryStat(String label, String value, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.black)),
      ],
    );
  }

  static pw.Widget _buildDivider() {
    return pw.Container(
      height: 24,
      width: 1,
      color: PdfColors.grey300,
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    PdfColor? textColor,
    double fontSize = 8,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          color: isHeader ? PdfColors.white : (textColor ?? PdfColors.grey900),
        ),
      ),
    );
  }
}
