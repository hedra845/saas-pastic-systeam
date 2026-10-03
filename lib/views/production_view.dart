import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../state/factory_store.dart';
import 'dialogs/add_production_dialog.dart';

class ProductionView extends StatelessWidget {
  final FactoryStore store;

  const ProductionView({super.key, required this.store});

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
                    'سجل عمليات وتشغيلات الإنتاج',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'متابعة خطوط تصنيع الفيلم والتقطيع ومراقبة أوزان الخام والهالك لكل وردية',
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
                icon: const Icon(Icons.add, size: 18),
                label: const Text('تسجيل تشغيلة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddProductionDialog(store: store),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // كروت إحصاءات الإنتاج
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 750) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      children: [
                        _statCard('إجمالي التشغيلات', '${store.batches.length} تشغيلة', Icons.precision_manufacturing_outlined, AppTheme.primaryBlue, AppTheme.primaryBlueSoft),
                        const SizedBox(width: 14),
                        _statCard('إجمالي الوزن الصافي', '${_formatNumber(store.totalProductionKg)} كجم', Icons.scale_outlined, AppTheme.successGreen, AppTheme.successGreenSoft),
                        const SizedBox(width: 14),
                        _statCard('إجمالي هالك التشغيل', '${_formatNumber(store.totalWasteKg)} كجم', Icons.warning_amber_rounded, AppTheme.wasteRed, AppTheme.wasteRedSoft),
                        const SizedBox(width: 14),
                        _statCard('متوسط تكلفة التشغيلة', '${_formatNumber(store.totalExpenses / (store.batches.isEmpty ? 1 : store.batches.length))} ج.م', Icons.receipt_long_outlined, AppTheme.costPurple, AppTheme.costPurpleSoft),
                      ],
                    ),
                  ),
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _statCard('إجمالي التشغيلات', '${store.batches.length} تشغيلة', Icons.precision_manufacturing_outlined, AppTheme.primaryBlue, AppTheme.primaryBlueSoft),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _statCard('إجمالي الوزن الصافي', '${_formatNumber(store.totalProductionKg)} كجم', Icons.scale_outlined, AppTheme.successGreen, AppTheme.successGreenSoft),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _statCard('إجمالي هالك التشغيل', '${_formatNumber(store.totalWasteKg)} كجم', Icons.warning_amber_rounded, AppTheme.wasteRed, AppTheme.wasteRedSoft),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _statCard('متوسط تكلفة التشغيلة', '${_formatNumber(store.totalExpenses / (store.batches.isEmpty ? 1 : store.batches.length))} ج.م', Icons.receipt_long_outlined, AppTheme.costPurple, AppTheme.costPurpleSoft),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // جدول التشغيلات
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'سجل التشغيل والورديات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.2), // الحالة
                      1: FlexColumnWidth(2.5), // الصنف
                      2: FlexColumnWidth(1.2), // الخامة
                      3: FlexColumnWidth(1.6), // الوزن الصافي
                      4: FlexColumnWidth(1.5), // الهالك الناتج
                      5: FlexColumnWidth(1.5), // التكلفة
                      6: FlexColumnWidth(1.8), // الماكينة
                      7: FlexColumnWidth(1.8), // المشغل
                      8: FlexColumnWidth(2.4), // التاريخ
                      9: FlexColumnWidth(0.8), // حذف
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: AppTheme.background,
                          border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                        ),
                        children: [
                          _headerCell('الحالة'),
                          _headerCell('الصنف المستهدف'),
                          _headerCell('الخامة'),
                          _headerCell('الإنتاج الصافي'),
                          _headerCell('الهالك'),
                          _headerCell('التكلفة'),
                          _headerCell('الماكينة'),
                          _headerCell('المشغل'),
                          _headerCell('التاريخ والوقت'),
                          _headerCell('إجراء'),
                        ],
                      ),
                      ...store.batches.map((b) {
                        return TableRow(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successGreenSoft,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    b.status,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                  ),
                                ),
                              ),
                            ),
                            _textCell(b.productName, isBold: true),
                            _textCell(b.rawMaterialType),
                            _textCell('${_formatNumber(b.quantityKg)} كجم', isBold: true, color: AppTheme.primaryBlue),
                            _textCell('${_formatNumber(b.wasteKg)} كجم (${b.wastePercentage.toStringAsFixed(1)}%)', color: AppTheme.wasteRed),
                            _textCell('${_formatNumber(b.cost)} ج.م', isBold: true),
                            _textCell(b.machineId ?? 'خط عام'),
                            _textCell(b.operatorName ?? 'فني وردية'),
                            _textCell(b.dateText),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.wasteRed, size: 18),
                                  tooltip: 'حذف التشغيلة وخصم رصيدها',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('تأكيد حذف التشغيلة'),
                                        content: Text('هل أنت متأكد من حذف تشغيلة "${b.productName}" بإنتاج ${_formatNumber(b.quantityKg)} كجم؟\n\n⚠️ سيتم خصم الكمية من رصيد المخزن وإجمالي إنتاج الصنف.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.wasteRed, foregroundColor: Colors.white),
                                            onPressed: () {
                                              Navigator.of(ctx).pop();
                                              store.deleteProductionBatch(b.id);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('تم حذف التشغيلة وخصم كميتها بنجاح!'), backgroundColor: AppTheme.successGreen),
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
