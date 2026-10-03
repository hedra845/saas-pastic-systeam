import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../state/factory_store.dart';
import 'dialogs/add_waste_dialog.dart';

class WasteView extends StatelessWidget {
  final FactoryStore store;

  const WasteView({super.key, required this.store});

  String _formatNumber(num value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
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
                    'إدارة الهالك وسكراب البلاستيك والراجع',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'تتبع هالك مطلع الفيلم، قطعيات اليد، عيوب الطباعة، وتوجيهها لخط المخرزة لإعادة التدوير',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.wasteRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('تسجيل هالك جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddWasteDialog(store: store),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // كروت الهالك والراجع
          Row(
            children: [
              Expanded(
                child: _statCard('إجمالي الهالك', '${_formatNumber(store.totalWasteKg)} كجم', Icons.delete_outline, AppTheme.wasteRed, AppTheme.wasteRedSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('نسبة الهالك العامة', '${store.overallWastePercentage.toStringAsFixed(2)}%', Icons.pie_chart_outline, const Color(0xFFE11D48), const Color(0xFFFFF1F2)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('المحول لإعادة التدوير (الراجع)', '${_formatNumber(store.totalRecycledKg)} كجم', Icons.recycling, AppTheme.cyanAccent, AppTheme.cyanSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('وفر إعادة التدوير المقدر', '${_formatNumber(store.totalRecycledKg * (store.plasticTonPrice / 1000) * 0.75)} ج.م', Icons.savings_outlined, AppTheme.successGreen, AppTheme.successGreenSoft),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // جدول سجلات الهالك
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تفاصيل سجلات الهالك حسب الصنوع ونوع العيب',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2.5), // الصنف
                      1: FlexColumnWidth(1.5), // كمية الهالك
                      2: FlexColumnWidth(2.2), // نوع الهالك
                      3: FlexColumnWidth(1.8), // المعاملة (راجع / بيع كسر)
                      4: FlexColumnWidth(2.5), // ملاحظات
                      5: FlexColumnWidth(1.5), // التاريخ
                      6: FlexColumnWidth(0.8), // حذف
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: AppTheme.background,
                          border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                        ),
                        children: [
                          _headerCell('الصنف'),
                          _headerCell('الوزن (كجم)'),
                          _headerCell('نوع الهالك'),
                          _headerCell('حالة التدوير'),
                          _headerCell('ملاحظات'),
                          _headerCell('التاريخ'),
                          _headerCell('إجراء'),
                        ],
                      ),
                      ...store.wasteRecords.map((w) {
                        return TableRow(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                          ),
                          children: [
                            _textCell(w.productName, isBold: true),
                            _textCell('${_formatNumber(w.wasteKg)} كجم', isBold: true, color: AppTheme.wasteRed),
                            _textCell(w.wasteType),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: w.isRecycled ? AppTheme.cyanSoft : AppTheme.background,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    w.isRecycled ? 'محول للراجع' : 'كسر للبيع',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: w.isRecycled ? AppTheme.cyanAccent : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _textCell(w.notes ?? '—'),
                            _textCell('${w.date.day}/${w.date.month}/${w.date.year}'),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.wasteRed, size: 18),
                                  tooltip: 'حذف سجل الهالك',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('تأكيد حذف سجل الهالك'),
                                        content: Text('هل أنت متأكد من حذف سجل هالك صنف "${w.productName}" بوزن ${_formatNumber(w.wasteKg)} كجم؟'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.wasteRed, foregroundColor: Colors.white),
                                            onPressed: () {
                                              Navigator.of(ctx).pop();
                                              store.deleteWasteRecord(w.id);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('تم حذف سجل الهالك بنجاح!'), backgroundColor: AppTheme.successGreen),
                                              );
                                            },
                                            child: const Text('حذف'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _textCell(String text, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? AppTheme.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
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
                  Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
