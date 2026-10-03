import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/sale_order.dart';
import '../state/factory_store.dart';
import '../services/pdf_report_service.dart';

class RetailSalesView extends StatefulWidget {
  final FactoryStore store;

  const RetailSalesView({super.key, required this.store});

  @override
  State<RetailSalesView> createState() => _RetailSalesViewState();
}

class _RetailSalesViewState extends State<RetailSalesView> {
  String _formatNumber(num value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final retailOrders = store.retailOrders;

    // حساب متوسط سعر القطاعي بدقة لكل كجم
    final double avgRetailPrice = store.totalRetailWeightKg > 0
        ? (store.totalRetailRevenue / store.totalRetailWeightKg)
        : (store.products.isNotEmpty
            ? (store.products.map((p) => p.retailPricePerKg).reduce((a, b) => a + b) / store.products.length)
            : 0.0);

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
                    'مبيعات القطاعي ومنافذ بيع المصنع',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'بيع الأكياس بالكيلو والباكتة للمحلات والمستهلكين بهامش ربح أعلى ودفع نقدي فوري',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.point_of_sale, size: 18),
                label: const Text('فاتورة بيع قطاعي سريعة', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showNewRetailOrderDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // كروت إحصاءات القطاعي
          Row(
            children: [
              Expanded(
                child: _statCard('إجمالي مبيعات القطاعي', '${_formatNumber(store.totalRetailRevenue)} ج.م', Icons.storefront_outlined, AppTheme.successGreen, AppTheme.successGreenSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('إجمالي وزن القطاعي المباع', '${_formatNumber(store.totalRetailWeightKg)} كجم', Icons.scale_outlined, const Color(0xFF0284C7), const Color(0xFFF0F9FF)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('صافي أرباح القطاعي', '${_formatNumber(store.totalRetailProfit)} ج.م', Icons.monetization_on_outlined, AppTheme.profitAmber, AppTheme.profitAmberSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('متوسط سعر القطاعي/كجم', '${avgRetailPrice.toStringAsFixed(2)} ج.م', Icons.loyalty_outlined, AppTheme.costPurple, AppTheme.costPurpleSoft),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // مقارنة أسعار القطاعي وهامش الربح
          // مقارنة أسعار القطاعي وهامش الربح
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppTheme.borderLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
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
                            decoration: BoxDecoration(
                              color: AppTheme.successGreenSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.sell, color: AppTheme.successGreen, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'قائمة أسعار القطاعي وهامش الربح المرتفع مقارنة بالجملة',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'مقارنة مباشرة بين تسعير الجملة والقطاعي وحساب الأرباح الإضافية',
                                style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreenSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${store.products.length} أصناف مسجلة',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (store.products.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('لا توجد أصناف مسجلة في النظام حتى الآن', style: TextStyle(color: AppTheme.textMuted)),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderLight),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2.0), // الصنف والخامة
                            1: FlexColumnWidth(1.5), // سعر الجملة المقارن
                            2: FlexColumnWidth(1.6), // سعر بيع القطاعي
                            3: FlexColumnWidth(1.4), // ربح الخامة / كجم
                            4: FlexColumnWidth(1.5), // تكلفة تشغيل (كهرباء/عمالة)
                            5: FlexColumnWidth(1.6), // صافي الربح النهائي
                            6: FlexColumnWidth(1.6), // فارق الربح عن الجملة
                            7: FlexColumnWidth(1.3), // المخزون المتاح
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                              children: [
                                _headerCell('الصنف ونوع الخامة'),
                                _headerCell('سعر الجملة المقارن'),
                                _headerCell('سعر بيع القطاعي'),
                                _headerCell('ربح الخامة / كجم'),
                                _headerCell('تكلفة تشغيل (محملة)'),
                                _headerCell('صافي الربح النهائي'),
                                _headerCell('فارق الربح عن الجملة'),
                                _headerCell('المخزون المتاح'),
                              ],
                            ),
                            ...store.products.map((p) {
                              final extraProfit = p.retailProfitPerKg - p.wholesaleProfitPerKg;
                              return TableRow(
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(color: AppTheme.successGreen, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textPrimary)),
                                              Text(
                                                p.materialType.isNotEmpty ? 'خامة ${p.materialType}' : (p.category.isNotEmpty ? p.category : 'صنف قطاعي'),
                                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _textCell('${p.wholesalePricePerKg.toStringAsFixed(2)} ج.م', isBold: false, color: AppTheme.textSecondary),
                                  _textCell('${p.retailPricePerKg.toStringAsFixed(2)} ج.م / كجم', isBold: true, color: AppTheme.successGreen),
                                  _textCell('+${p.grossRetailProfitPerKg.toStringAsFixed(2)} ج.م', isBold: true, color: AppTheme.successGreen),
                                  _textCell('${p.laborAndElectricityCostPerKg.toStringAsFixed(2)} ج.م', isBold: true, color: const Color(0xFF7C3AED)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.profitAmberSoft,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '+${p.retailProfitPerKg.toStringAsFixed(2)} ج.م',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          '+${extraProfit.toStringAsFixed(2)} ج.م',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  _textCell('${_formatNumber(p.stockKg)} كجم', isBold: true, color: p.stockKg > 50 ? AppTheme.textPrimary : AppTheme.wasteRed),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // سجل فواتير القطاعي
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppTheme.borderLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
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
                            decoration: BoxDecoration(
                              color: AppTheme.successGreenSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.receipt_long, color: AppTheme.successGreen, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'سجل فواتير مبيعات القطاعي والكاش (${retailOrders.length} فاتورة)',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      if (retailOrders.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreenSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'إجمالي الفواتير: ${_formatNumber(store.totalRetailRevenue)} ج.م',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (retailOrders.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.point_of_sale_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 10),
                          const Text('لا توجد فواتير مبيعات قطاعي مسجلة حتى الآن', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('اضغط على زر "فاتورة بيع قطاعي سريعة" بالأعلى لتسجيل أول عملية بيع', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderLight),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.7), // رقم الفاتورة
                            1: FlexColumnWidth(2.3), // العميل / المحل
                            2: FlexColumnWidth(1.4), // الوزن الإجمالي
                            3: FlexColumnWidth(1.6), // إجمالي الفاتورة
                            4: FlexColumnWidth(1.5), // الربح الصافي
                            5: FlexColumnWidth(1.3), // طريقة الدفع
                            6: FlexColumnWidth(1.6), // التاريخ
                            7: FlexColumnWidth(2.0), // إجراءات الفاتورة
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                              children: [
                                _headerCell('رقم الفاتورة'),
                                _headerCell('اسم العميل / المحل'),
                                _headerCell('الوزن (كجم)'),
                                _headerCell('الإجمالي الكاش'),
                                _headerCell('الربح الصافي'),
                                _headerCell('طريقة الدفع'),
                                _headerCell('التاريخ والوقت'),
                                _headerCell('إجراءات الفاتورة'),
                              ],
                            ),
                            ...retailOrders.map((order) {
                              return TableRow(
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFBBF7D0)),
                                        ),
                                        child: Text(
                                          order.invoiceNumber,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  _textCell(order.customerName, isBold: true),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F9FF),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${order.totalWeightKg} كجم',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  _textCell('${_formatNumber(order.totalAmount)} ج.م', isBold: true, color: AppTheme.successGreen),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.profitAmberSoft,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '+${_formatNumber(order.totalProfit)} ج.م',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  _textCell(order.paymentMethod),
                                  _textCell('${order.date.day}/${order.date.month} - ${order.date.hour}:${order.date.minute.toString().padLeft(2, '0')}'),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFDC2626), size: 19),
                                          tooltip: 'استخراج فاتورة PDF باللوجو',
                                          onPressed: () => _exportInvoicePdf(order),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          icon: const Icon(Icons.print_outlined, color: AppTheme.primaryBlue, size: 19),
                                          tooltip: 'طباعة الفاتورة',
                                          onPressed: () => _printInvoice(order),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppTheme.wasteRed, size: 19),
                                          tooltip: 'حذف الفاتورة واسترجاع المخزون',
                                          onPressed: () => _confirmDeleteOrder(context, order),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
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
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary), textAlign: TextAlign.center),
    );
  }

  Widget _textCell(String text, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
      child: Text(text, style: TextStyle(fontSize: 12.5, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? AppTheme.textPrimary), textAlign: TextAlign.center),
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

  void _showNewRetailOrderDialog(BuildContext context) {
    final store = widget.store;
    if (store.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد أصناف في المستودع بعد. يرجى إضافة أصناف أولاً.'), backgroundColor: AppTheme.profitAmber),
      );
      return;
    }

    String selectedProductId = store.products.first.id;
    final customerCtrl = TextEditingController(text: 'محل تجزئة نقدي');
    final qtyCtrl = TextEditingController(text: '25');
    final paidCtrl = TextEditingController(text: '0');
    String paymentMethod = 'نقدي كاش';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContentCtx, setDialogState) {
            final prod = store.products.firstWhere((p) => p.id == selectedProductId, orElse: () => store.products.first);
            final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
            final currentStock = prod.stockKg;
            final isOverStock = qty > currentStock;
            final isZeroOrNegative = qty <= 0;
            final remainingAfterSale = currentStock - qty;
            final willBeOutOfStock = remainingAfterSale <= 0 && !isOverStock;
            final willBeLowStock = remainingAfterSale > 0 && remainingAfterSale < 10;

            final total = qty * prod.retailPricePerKg;
            final grossSaleProfit = qty * prod.grossRetailProfitPerKg;
            final laborAndElec = qty * prod.laborAndElectricityCostPerKg;
            final profit = qty * prod.retailProfitPerKg;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.point_of_sale, color: AppTheme.successGreen),
                  SizedBox(width: 8),
                  Text('تسجيل فاتورة بيع قطاعي (كاش)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم العميل أو المحل
                      const Text('اسم العميل / المحل', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: customerCtrl,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          hintText: 'مثال: سوبر ماركت الأمانة / كاش فوري',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // اختيار الصنف
                      const Text('الصنف المراد بيعه قطاعي', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedProductId,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                        items: store.products.map((p) {
                          final stockText = p.stockKg > 0 ? '${_formatNumber(p.stockKg)} كجم متوفر' : 'نفذ المخزون';
                          return DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.name} ($stockText - ${p.retailPricePerKg} ج/كجم)'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedProductId = val);
                        },
                      ),
                      const SizedBox(height: 10),

                      // شريط فحص الرصيد المتوفر بالمستودع
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: prod.isOutOfStock
                              ? AppTheme.wasteRedSoft
                              : (prod.isLowStock ? const Color(0xFFFEF3C7) : const Color(0xFFF0FDF4)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: prod.isOutOfStock
                                ? AppTheme.wasteRed.withValues(alpha: 0.3)
                                : (prod.isLowStock ? const Color(0xFFF59E0B).withValues(alpha: 0.4) : const Color(0xFFBBF7D0)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  prod.isOutOfStock
                                      ? Icons.error_outline
                                      : (prod.isLowStock ? Icons.warning_amber_rounded : Icons.check_circle_outline),
                                  size: 18,
                                  color: prod.isOutOfStock
                                      ? AppTheme.wasteRed
                                      : (prod.isLowStock ? const Color(0xFFB45309) : AppTheme.successGreen),
                                ),
                                const SizedBox(width: 8),
                                const Text('الرصيد المتاح بالمستودع حالياً:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Text(
                              '${_formatNumber(currentStock)} كجم',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: prod.isOutOfStock
                                    ? AppTheme.wasteRed
                                    : (prod.isLowStock ? const Color(0xFFB45309) : AppTheme.successGreen),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // إدخال الكمية وطريقة السداد
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الكمية المباعة (كجم)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    suffixText: 'كجم',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    errorText: isOverStock ? 'الكمية أكبر من الرصيد المتوفر' : null,
                                  ),
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('طريقة السداد', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: paymentMethod,
                                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                  items: const [
                                    DropdownMenuItem(value: 'نقدي كاش', child: Text('نقدي كاش')),
                                    DropdownMenuItem(value: 'آجل', child: Text('آجل')),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setDialogState(() => paymentMethod = v);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (paymentMethod == 'آجل') ...[
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('المبلغ المسدد مقدماً (اختياري)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: paidCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                suffixText: 'جنيه',
                                hintText: 'اتركه 0 إذا لم يسدد العميل أي دفعة حالياً',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),

                      // تنبيهات وتحذيرات الرصيد اللحظية
                      if (isOverStock)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.wasteRedSoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.wasteRed.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cancel, color: AppTheme.wasteRed, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'عفواً! الكمية المطلوبة (${_formatNumber(qty)} كجم) أكبر من الرصيد المتوفر بالمخزن (${_formatNumber(currentStock)} كجم). العجز: ${_formatNumber(qty - currentStock)} كجم.',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.wasteRed),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (willBeOutOfStock)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF87171)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.warning, color: Color(0xFFDC2626), size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '⚠️ تحذير نفاذ: هذه الفاتورة ستؤدي إلى استهلاك رصيد الصنف بالكامل ويصبح 0 كجم بالمستودع!',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (willBeLowStock)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '⚠️ إنذار قرب النفاذ: بعد إتمام هذه الفاتورة سيتبقى ${_formatNumber(remainingAfterSale)} كجم فقط بالمستودع. يرجى تجهيز تشغيلة جديدة.',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (!isZeroOrNegative)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'الرصيد متوفر وكافٍ: سيتبقى بالمستودع ${_formatNumber(remainingAfterSale)} كجم بعد البيع.',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF15803D)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),

                      // حساب الكاش والأرباح
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.successGreenSoft, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المطلوب سداده نقداً:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text('${_formatNumber(total)} جنيه', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ربح البيع (من الخامة):', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                Text('+${_formatNumber(grossSaleProfit)} جنيه', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('⚡ الكهرباء والعمالة (على جنب):', style: TextStyle(fontSize: 11.5, color: Color(0xFF6D28D9))),
                                Text('${_formatNumber(laborAndElec)} جنيه (${prod.laborAndElectricityCostPerKg.toStringAsFixed(2)} ج/كجم)', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF6D28D9))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المكسب الصافي بعد الكهرباء والعمالة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                Text('+${_formatNumber(profit)} جنيه', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.profitAmber)),
                              ],
                            ),
                            const Divider(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المتبقي الفعلي بالمستودع بعد الخصم:', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                                Text(
                                  '${_formatNumber(remainingAfterSale.clamp(0.0, double.infinity))} كجم',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isOverStock ? AppTheme.wasteRed : (willBeLowStock ? const Color(0xFFB45309) : AppTheme.primaryBlue),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOverStock || isZeroOrNegative ? Colors.grey : AppTheme.successGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isOverStock || isZeroOrNegative
                      ? null
                      : () {
                          final enteredPaid = double.tryParse(paidCtrl.text) ?? 0.0;
                          final paidAmount = paymentMethod == 'آجل' ? enteredPaid.clamp(0.0, total) : total;
                          final calculatedStatus = paymentMethod == 'آجل'
                              ? (paidAmount >= total - 0.01 ? 'مدفوع بالكامل' : (paidAmount > 0.01 ? 'دفع جزئي' : 'آجل'))
                              : 'مدفوع بالكامل';

                          final order = SaleOrder(
                            id: 'order-${DateTime.now().millisecondsSinceEpoch}',
                            invoiceNumber: 'INV-R-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                            saleType: 'قطاعي',
                            customerName: customerCtrl.text.trim().isNotEmpty ? customerCtrl.text.trim() : 'محل تجزئة نقدي',
                            date: DateTime.now(),
                            paymentMethod: paymentMethod,
                            paymentStatus: calculatedStatus,
                            paidAmount: paidAmount,
                            items: [
                              SaleOrderItem(
                                productId: prod.id,
                                productName: prod.name,
                                quantityKg: qty,
                                unitPrice: prod.retailPricePerKg,
                                unitCost: prod.costPerKg,
                              ),
                            ],
                          );

                          widget.store.addSaleOrder(order);
                          Navigator.of(ctx).pop();

                          if (willBeOutOfStock) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('⚠️ تم تسجيل بيع القطاعي. تنبيه: صنف "${prod.name}" نفذ رصيده بالكامل من المستودع!'),
                                backgroundColor: AppTheme.wasteRed,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          } else if (willBeLowStock) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('⚠️ تم تسجيل البيع واستلام الكاش. إنذار: صنف "${prod.name}" قارب على النفاذ! المتبقي: ${_formatNumber(remainingAfterSale)} كجم فقط.'),
                                backgroundColor: const Color(0xFFD97706),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }

                          _showInvoiceSuccessDialog(order);
                        },
                  child: const Text('حفظ واستلام الكاش'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInvoiceSuccessDialog(SaleOrder order) {
    bool isSavingPdf = false;
    String? savedPdfPath;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppTheme.successGreen, size: 28),
              SizedBox(width: 10),
              Text('تم تسجيل البيع بنجاح!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رقم الفاتورة: ${order.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text('العميل: ${order.customerName}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text('المبلغ المحصل: ${_formatNumber(order.totalAmount)} ج.م (${_formatNumber(order.totalWeightKg)} كجم)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
              const Divider(height: 20),
              if (savedPdfPath != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: AppTheme.successGreen, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تم استخراج وحفظ ملف الفاتورة PDF بنجاح:\n$savedPdfPath',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ] else
                const Text('يمكنك الآن طباعة إيصال/فاتورة البيع أو استخراجها كملف PDF معتمد يحمل لوجو المصنع.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('إغلاق'),
            ),
            if (savedPdfPath != null) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('فتح مكان الملف'),
                onPressed: () {
                  Process.run('explorer.exe', ['/select,', savedPdfPath!]);
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('عرض الفاتورة PDF'),
                onPressed: () {
                  Process.run('explorer.exe', [savedPdfPath!]);
                },
              ),
            ] else ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                icon: isSavingPdf
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf, size: 16),
                label: Text(isSavingPdf ? 'جاري تجهيز وحفظ PDF...' : 'حفظ الفاتورة (PDF)'),
                onPressed: isSavingPdf
                    ? null
                    : () async {
                        setDialogState(() => isSavingPdf = true);
                        try {
                          final path = await PdfReportService.exportInvoicePdf(
                            store: widget.store,
                            order: order,
                          );
                          if (path != null) {
                            setDialogState(() {
                              isSavingPdf = false;
                              savedPdfPath = path;
                            });
                            Process.run('explorer.exe', ['/select,', path]);
                          } else {
                            setDialogState(() => isSavingPdf = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم إلغاء حفظ الفاتورة أو تعذر تحديد المسار.'), duration: Duration(seconds: 2)),
                              );
                            }
                          }
                        } catch (e) {
                          setDialogState(() => isSavingPdf = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('خطأ أثناء حفظ الفاتورة: $e'), backgroundColor: AppTheme.wasteRed),
                            );
                          }
                        }
                      },
              ),
            ],
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
              icon: const Icon(Icons.print, size: 16),
              label: const Text('طباعة فورية'),
              onPressed: () => _printInvoice(order),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportInvoicePdf(SaleOrder order) async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري إعداد فاتورة PDF مع لوجو المصنع...'),
          duration: Duration(seconds: 1),
        ),
      );

      final path = await PdfReportService.exportInvoicePdf(
        store: widget.store,
        order: order,
      );

      if (!mounted) return;
      if (path != null) {
        Process.run('explorer.exe', ['/select,', path]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ فاتورة PDF بنجاح في:\n$path'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'عرض الملف',
              textColor: Colors.white,
              onPressed: () {
                Process.run('explorer.exe', [path]);
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء حفظ الفاتورة أو تعذر تحديد المسار.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تصدير الفاتورة: $e'),
          backgroundColor: AppTheme.wasteRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _printInvoice(SaleOrder order) async {
    try {
      await PdfReportService.printInvoice(
        store: widget.store,
        order: order,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إرسال الفاتورة للطباعة: $e'),
          backgroundColor: AppTheme.wasteRed,
        ),
      );
    }
  }

  void _confirmDeleteOrder(BuildContext context, SaleOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppTheme.wasteRed, size: 24),
            SizedBox(width: 8),
            Text('تأكيد حذف الفاتورة'),
          ],
        ),
        content: Text(
          'هل تريد حذف الفاتورة رقم: ${order.invoiceNumber}؟\n'
          'العميل: ${order.customerName}\n'
          'إجمالي الوزن: ${_formatNumber(order.totalWeightKg)} كجم\n\n'
          '⚠️ تنبيه: سيتم إرجاع جميع الكميات المباعة تلقائياً إلى رصيد المخزن للصنف.',
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.wasteRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.store.deleteSaleOrder(order.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حذف الفاتورة رقم ${order.invoiceNumber} وإرجاع المخزون بنجاح!'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            child: const Text('نعم، حذف واسترجاع المخزون'),
          ),
        ],
      ),
    );
  }
}
