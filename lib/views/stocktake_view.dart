import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/stocktake_record.dart';
import '../state/factory_store.dart';
import '../services/pdf_report_service.dart';

class StocktakeView extends StatefulWidget {
  final FactoryStore store;

  const StocktakeView({super.key, required this.store});

  @override
  State<StocktakeView> createState() => _StocktakeViewState();
}

class _StocktakeViewState extends State<StocktakeView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _formatNumber(num value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'نظام الجرد الدوري والرقابة المخزنية',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'جرد يومي لنهاية الورديات، جرد أسبوعي للمستودعات، وجرد شهري شامل لحساب العجز والزيادة وأسبابها',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('تسجيل محضر جرد جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showNewStocktakeDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // كروت إحصاءات الجرد
          Row(
            children: [
              Expanded(
                child: _statCard('إجمالي محاضر الجرد', '${store.stocktakeRecords.length} محاضر', Icons.assignment_turned_in_outlined, AppTheme.primaryBlue, AppTheme.primaryBlueSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('الجرد اليومي (الورديات)', '${store.stocktakeRecords.where((s) => s.type == 'يومي').length} تقرير', Icons.today_outlined, AppTheme.profitAmber, AppTheme.profitAmberSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('الجرد الأسبوعي', '${store.stocktakeRecords.where((s) => s.type == 'أسبوعي').length} تقرير', Icons.date_range_outlined, AppTheme.costPurple, AppTheme.costPurpleSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('الجرد الشهري الشامل', '${store.stocktakeRecords.where((s) => s.type == 'شهري').length} تقرير', Icons.calendar_month_outlined, const Color(0xFF0284C7), const Color(0xFFF0F9FF)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('دقة المطابقة المخزنية', '99.88%', Icons.verified_outlined, AppTheme.successGreen, AppTheme.successGreenSoft),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // التبويبات الثلاثة
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryBlue,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.wb_sunny_outlined), text: 'الجرد اليومي (نهاية الورديات)'),
                Tab(icon: Icon(Icons.view_week_outlined), text: 'الجرد الأسبوعي للمستودعات'),
                Tab(icon: Icon(Icons.calendar_month_outlined), text: 'الجرد الشهري العام للمصنع'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // عرض تقارير الجرد لكل فترة
          SizedBox(
            height: 520,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStocktakeList(store, 'يومي'),
                _buildStocktakeList(store, 'أسبوعي'),
                _buildStocktakeList(store, 'شهري'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStocktakeList(FactoryStore store, String type) {
    final list = store.stocktakeRecords.where((s) => s.type == type).toList();

    if (list.isEmpty) {
      return Center(
        child: Text('لا توجد تقارير جرد $type مسجلة حالياً', style: const TextStyle(color: AppTheme.textMuted)),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final st = list[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.primaryBlueSoft, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(st.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            const SizedBox(height: 2),
                            Text('التاريخ: ${st.date.day}/${st.date.month}/${st.date.year} | المسؤول: ${st.auditorName}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreenSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            st.status,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.picture_as_pdf, size: 14),
                          label: const Text('استخراج PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _exportStocktakePdf(context, st),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.print, size: 14),
                          label: const Text('طباعة المحضر', style: TextStyle(fontSize: 12)),
                          onPressed: () => _printStocktake(context, st),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),

                // جدول مقارنة الأصناف في محضر الجرد
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.6), // الصنف
                    1: FlexColumnWidth(1.6), // الدفتري
                    2: FlexColumnWidth(1.6), // الفعلي بالميزان
                    3: FlexColumnWidth(1.6), // فرق الوزن
                    4: FlexColumnWidth(1.6), // فرق القيمة
                    5: FlexColumnWidth(2.8), // السبب
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        color: AppTheme.background,
                        border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                      ),
                      children: [
                        _headerCell('الصنف المفحوص'),
                        _headerCell('الرصيد الدفتري'),
                        _headerCell('الرصيد الفعلي'),
                        _headerCell('فرق الوزن (عجز/زيادة)'),
                        _headerCell('الأثر المالي'),
                        _headerCell('ملاحظات وسبب الفارق'),
                      ],
                    ),
                    ...st.entries.map((entry) {
                      final isExact = entry.varianceKg == 0;
                      final isDeficit = entry.varianceKg < 0;

                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                        ),
                        children: [
                          _textCell(entry.productName, isBold: true),
                          _textCell('${_formatNumber(entry.bookQtyKg)} كجم'),
                          _textCell('${_formatNumber(entry.actualQtyKg)} كجم', isBold: true),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Center(
                              child: Text(
                                isExact ? 'مطابق 0' : '${entry.varianceKg > 0 ? "+" : ""}${entry.varianceKg.toStringAsFixed(1)} كجم',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: isExact ? AppTheme.successGreen : (isDeficit ? AppTheme.wasteRed : const Color(0xFF0284C7)),
                                ),
                              ),
                            ),
                          ),
                          _textCell('${entry.varianceCost.toStringAsFixed(1)} ج.م', color: isDeficit ? AppTheme.wasteRed : AppTheme.textPrimary),
                          _textCell(entry.reason ?? '—', color: AppTheme.textSecondary),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _headerCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary), textAlign: TextAlign.center),
    );
  }

  Widget _textCell(String text, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? AppTheme.textPrimary), textAlign: TextAlign.center),
    );
  }

  Widget _statCard(String title, String val, IconData icon, Color color, Color bg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                  const SizedBox(height: 2),
                  Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewStocktakeDialog(BuildContext context) {
    final store = widget.store;
    if (store.products.isEmpty) return;

    String type = 'يومي';
    final auditorCtrl = TextEditingController(text: 'أمين المخزن: خالد صبحي');
    final now = DateTime.now();
    final todayFormatted = DateFormat('yyyy/MM/dd').format(now);
    final titleCtrl = TextEditingController(text: 'جرد يومي لوردية اليوم ($todayFormatted)');
    bool updateStock = true;

    // Controllers لكل صنف
    final actualControllers = <String, TextEditingController>{};
    final reasonControllers = <String, TextEditingController>{};

    for (var p in store.products) {
      actualControllers[p.id] = TextEditingController(text: p.stockKg.toStringAsFixed(0));
      reasonControllers[p.id] = TextEditingController(text: 'مطابق للميزان');
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('تسجيل محضر جرد مخزني وتسوية الفروقات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: type,
                              decoration: const InputDecoration(labelText: 'نوع الجرد'),
                              items: const [
                                DropdownMenuItem(value: 'يومي', child: Text('جرد يومي (نهاية وردية)')),
                                DropdownMenuItem(value: 'أسبوعي', child: Text('جرد أسبوعي للمستودع')),
                                DropdownMenuItem(value: 'شهري', child: Text('جرد شهري شامل')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() {
                                    type = v;
                                    final currentNow = DateTime.now();
                                    final dateStr = DateFormat('yyyy/MM/dd').format(currentNow);
                                    final monthStr = DateFormat('MM/yyyy').format(currentNow);
                                    if (v == 'يومي') {
                                      titleCtrl.text = 'جرد يومي لوردية اليوم ($dateStr)';
                                    } else if (v == 'أسبوعي') {
                                      final weekNum = ((currentNow.day / 7).ceil());
                                      titleCtrl.text = 'جرد أسبوعي للمستودع - الأسبوع $weekNum ($monthStr)';
                                    } else {
                                      titleCtrl.text = 'جرد شهري شامل لكافة المخازن ($monthStr)';
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(controller: auditorCtrl, decoration: const InputDecoration(labelText: 'اسم مسؤول الجرد')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان المحضر')),
                      const SizedBox(height: 16),

                      const Text('أوزان الأصناف المفحوصة في العنابر:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),

                      ...store.products.map((p) {
                        final actCtrl = actualControllers[p.id]!;
                        final rsnCtrl = reasonControllers[p.id]!;
                        final actual = double.tryParse(actCtrl.text) ?? p.stockKg;
                        final diff = actual - p.stockKg;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: diff == 0 ? AppTheme.borderSubtle : (diff < 0 ? AppTheme.wasteRed : AppTheme.successGreen)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('الرصيد بالسيستم: ${p.stockKg} كجم', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: actCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'الفعلي (كجم)', border: OutlineInputBorder()),
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: rsnCtrl,
                                  decoration: const InputDecoration(labelText: 'السبب / الملاحظة', border: OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('اعتماد الجرد وتسوية أرصدة المخازن فورياً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: const Text('تحديث رصيد المخزن الفعلي في النظام تلقائياً ليتطابق مع نتيجة الميزان', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        value: updateStock,
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (v) => setDialogState(() => updateStock = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                  onPressed: () {
                    final entries = store.products.map((p) {
                      final act = double.tryParse(actualControllers[p.id]!.text) ?? p.stockKg;
                      final rsn = reasonControllers[p.id]!.text.trim();
                      return StocktakeEntry(
                        productId: p.id,
                        productName: p.name,
                        bookQtyKg: p.stockKg,
                        actualQtyKg: act,
                        costPerKg: p.costPerKg,
                        reason: rsn,
                      );
                    }).toList();

                    widget.store.addStocktakeRecord(
                      StocktakeRecord(
                        id: 'st-${DateTime.now().millisecondsSinceEpoch}',
                        type: type,
                        title: titleCtrl.text.trim(),
                        date: DateTime.now(),
                        auditorName: auditorCtrl.text.trim(),
                        entries: entries,
                        status: updateStock ? 'معتمد ومسوى' : 'مسودة قيد المراجعة',
                      ),
                      updateStock: updateStock,
                    );

                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تسجيل تقرير الجرد واعتماد التسويات بنجاح!'), backgroundColor: AppTheme.successGreen),
                    );
                  },
                  child: const Text('اعتماد وتسجيل محضر الجرد'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportStocktakePdf(BuildContext context, StocktakeRecord record) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري إعداد محضر الجرد بصيغة PDF...'),
          duration: Duration(seconds: 1),
        ),
      );

      final path = await PdfReportService.exportStocktakePdf(
        store: widget.store,
        record: record,
      );

      if (context.mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ محضر الجرد بنجاح في:\n$path'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تصدير محضر الجرد: $e'),
            backgroundColor: AppTheme.wasteRed,
          ),
        );
      }
    }
  }

  Future<void> _printStocktake(BuildContext context, StocktakeRecord record) async {
    try {
      await PdfReportService.printStocktakeReport(
        store: widget.store,
        record: record,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إرسال المحضر للطباعة: $e'),
            backgroundColor: AppTheme.wasteRed,
          ),
        );
      }
    }
  }
}
