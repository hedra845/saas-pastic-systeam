import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../state/factory_store.dart';
import 'widgets/kpi_card.dart';
import 'widgets/custom_charts.dart';
import 'widgets/quick_actions.dart';
import 'dialogs/add_product_dialog.dart';
import 'dialogs/add_expense_dialog.dart';

class DashboardView extends StatelessWidget {
  final FactoryStore store;
  final Function(int)? onNavigateTab;

  const DashboardView({super.key, required this.store, this.onNavigateTab});

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
          // تنبيهات الأصناف التي قاربت على النفاذ أو نفذت
          if (store.stockAlertCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تنبيه مخزون: يوجد ${store.stockAlertCount} صنف قارب على النفاذ من المستودع!',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          store.stockAlertProducts.map((p) => '${p.name} (${_formatNumber(p.stockKg)} كجم متبقي)').join(' • '),
                          style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB45309),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      if (onNavigateTab != null) onNavigateTab!(1); // الذهاب لصفحة الأصناف والمخزون
                    },
                    child: const Text('عرض الأصناف', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // -------------------------------------------------------------
          // 1. بطاقات المؤشرات الرئيسية الـ 4 (Top KPI Cards)
          // -------------------------------------------------------------
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1100;
              final count = isWide ? 4 : 2;
              return GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: isWide ? 2.2 : 1.85,
                children: [
                  KpiCard(
                    title: 'إجمالي المخزون (كجم)',
                    value: _formatNumber(store.totalStockKg),
                    changeText: 'الرصيد الفعلي المتوفر بالمستودع',
                    isPositive: true,
                    icon: Icons.inventory_2_rounded,
                    iconColor: AppTheme.primaryBlue,
                    iconBgColor: AppTheme.primaryBlueSoft,
                  ),
                  KpiCard(
                    title: 'إجمالي المبيعات (جنيه)',
                    value: _formatNumber(store.totalSalesRevenue),
                    changeText: '+8.7% عن الشهر الماضي',
                    isPositive: true,
                    icon: Icons.attach_money_rounded,
                    iconColor: AppTheme.successGreen,
                    iconBgColor: AppTheme.successGreenSoft,
                  ),
                  KpiCard(
                    title: 'إجمالي التكاليف (جنيه)',
                    value: _formatNumber(store.totalExpenses),
                    changeText: '+6.1% عن الشهر الماضي',
                    isPositive: true,
                    icon: Icons.pie_chart_outline_rounded,
                    iconColor: AppTheme.costPurple,
                    iconBgColor: AppTheme.costPurpleSoft,
                  ),
                  KpiCard(
                    title: 'صافي الربح (جنيه)',
                    value: _formatNumber(store.netProfit),
                    changeText: '+15.3% عن الشهر الماضي',
                    isPositive: true,
                    icon: Icons.monetization_on_outlined,
                    iconColor: AppTheme.profitAmber,
                    iconBgColor: AppTheme.profitAmberSoft,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // -------------------------------------------------------------
          // 2. المنطقة الوسطى (الرسومات + الجدول في جهة، والإحصاءات السريعة في جهة)
          // -------------------------------------------------------------
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 1050;

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // القسم الرئيسي العريض (الرسوم والجدول)
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          _buildChartsRow(),
                          const SizedBox(height: 18),
                          _buildRecentSalesTable(context),
                          const SizedBox(height: 18),
                          _buildBottomKpiBanner(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    // العمود الجانبي (المؤشرات الجانبية والإجراءات السريعة)
                    Expanded(
                      flex: 3,
                      child: _buildSideColumn(context),
                    ),
                  ],
                );
              } else {
                // شاشات أصغر (Stack vertically)
                return Column(
                  children: [
                    _buildChartsRow(),
                    const SizedBox(height: 18),
                    _buildSideColumn(context),
                    const SizedBox(height: 18),
                    _buildRecentSalesTable(context),
                    const SizedBox(height: 18),
                    _buildBottomKpiBanner(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // صف الرسوم البيانية (الإنتاج + توزيع التكاليف)
  Widget _buildChartsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            children: [
              SizedBox(
                height: 260,
                child: ProductionLineChartWidget(data: store.production7Days),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 250,
                child: CostDonutChartWidget(slices: store.costDistribution),
              ),
            ],
          );
        }
        return SizedBox(
          height: 290,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ProductionLineChartWidget(data: store.production7Days),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: CostDonutChartWidget(slices: store.costDistribution),
              ),
            ],
          ),
        );
      },
    );
  }

  // جدول أحدث فواتير المبيعات
  Widget _buildRecentSalesTable(BuildContext context) {
    final recentOrders = store.saleOrders.take(5).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'أحدث فواتير المبيعات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (onNavigateTab != null) onNavigateTab!(2); // انتقال للمبيعات
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('عرض الكل'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text('لا توجد فواتير مبيعات مسجلة حتى الآن', style: TextStyle(color: AppTheme.textMuted)),
                ),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2), // الحالة
                  1: FlexColumnWidth(1.5), // القيمة
                  2: FlexColumnWidth(1.3), // نوع البيع
                  3: FlexColumnWidth(1.5), // الوزن المباع
                  4: FlexColumnWidth(2.2), // العميل / الفاتورة
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      color: AppTheme.background,
                      border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                    ),
                    children: [
                      _tableHeaderCell('حالة السداد'),
                      _tableHeaderCell('إجمالي القيمة'),
                      _tableHeaderCell('النوع'),
                      _tableHeaderCell('الكمية (كجم)'),
                      _tableHeaderCell('العميل والفاتورة'),
                    ],
                  ),
                  ...recentOrders.map((order) {
                    return TableRow(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: order.paymentStatus == 'مدفوع بالكامل' ? AppTheme.successGreenSoft : AppTheme.profitAmberSoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.paymentStatus,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: order.paymentStatus == 'مدفوع بالكامل' ? AppTheme.successGreen : AppTheme.profitAmber,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _tableDataCell('${_formatNumber(order.totalAmount)} ج.م', isBold: true),
                        _tableDataCell(order.saleType),
                        _tableDataCell('${_formatNumber(order.totalWeightKg)} كجم', isBold: true),
                        _tableDataCell(order.customerName.isNotEmpty ? order.customerName : order.invoiceNumber),
                      ],
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _tableDataCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: AppTheme.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // الشريط السفلي للمؤشرات المستمرة (مطابق للصورة)
  Widget _buildBottomKpiBanner() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomStatItem('إجمالي المواد الخام المستهلكة', _formatNumber(store.totalRawConsumedKg), 'كجم'),
                    _buildDivider(),
                    _buildBottomStatItem('متوسط تكلفة الكجم', store.averageCostPerKg.toStringAsFixed(2), 'جنيه'),
                    _buildDivider(),
                    _buildBottomStatItem('نسبة الربح', '${store.overallProfitMargin.toStringAsFixed(1)}%', 'من المبيعات', isSuccess: true),
                    _buildDivider(),
                    _buildBottomStatItem('عدد الموظفين', '${store.employeesCount}', 'موظف'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomStatItem(String label, String value, String unit, {bool isSuccess = false, bool isWarning = false}) {
    Color valueColor = AppTheme.textPrimary;
    if (isSuccess) valueColor = AppTheme.successGreen;
    if (isWarning) valueColor = AppTheme.wasteRed;

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor),
        ),
        Text(
          unit,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 38,
      color: AppTheme.borderSubtle,
    );
  }

  // العمود الجانبي (رأس المال، سعر الطن، المخزون، الطلبات، الإجراءات السريعة)
  Widget _buildSideColumn(BuildContext context) {
    return Column(
      children: [
        // ---- كارت رأس المال (منفصل ومميز) ----
        _buildCapitalSideCard(context),
        const SizedBox(height: 10),
        SideStatCard(
          title: 'سعر طن البلاستيك',
          value: _formatNumber(store.plasticTonPrice),
          subtitle: 'جنيه / طن',
          badgeText: '+2.3% عن الأسبوع الماضي',
          icon: Icons.sell_outlined,
          iconColor: AppTheme.costPurple,
          iconBgColor: AppTheme.costPurpleSoft,
          onEdit: () => _showEditPlasticTonPriceDialog(context),
        ),
        const SizedBox(height: 10),
        SideStatCard(
          title: 'إجمالي المخزون',
          value: _formatNumber(store.totalStockKg),
          subtitle: 'كجم',
          icon: Icons.inventory_2_outlined,
          iconColor: AppTheme.primaryBlue,
          iconBgColor: AppTheme.primaryBlueSoft,
        ),
        const SizedBox(height: 10),
        SideStatCard(
          title: 'طلبات اليوم',
          value: '${store.todayOrdersCount}',
          subtitle: 'طلبات',
          icon: Icons.assignment_outlined,
          iconColor: AppTheme.primaryBlue,
          iconBgColor: AppTheme.primaryBlueSoft,
        ),
        const SizedBox(height: 16),

        // بطاقة الإجراءات السريعة
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إجراءات سريعة',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                // شبكة 2 × 2
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.3,
                  children: [
                    QuickActionTile(
                      label: 'إضافة صنف',
                      icon: Icons.add_box_outlined,
                      color: AppTheme.primaryBlue,
                      bgColor: AppTheme.primaryBlueSoft,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddProductDialog(store: store),
                        );
                      },
                    ),
                    QuickActionTile(
                      label: 'إضافة مصروف',
                      icon: Icons.receipt_long_outlined,
                      color: AppTheme.costPurple,
                      bgColor: AppTheme.costPurpleSoft,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddExpenseDialog(store: store),
                        );
                      },
                    ),
                    QuickActionTile(
                      label: 'مبيعات الجملة',
                      icon: Icons.storefront_outlined,
                      color: AppTheme.successGreen,
                      bgColor: AppTheme.successGreenSoft,
                      onTap: () {
                        if (onNavigateTab != null) onNavigateTab!(2); // مبيعات جملة
                      },
                    ),
                    QuickActionTile(
                      label: 'التقارير الشاملة',
                      icon: Icons.analytics_outlined,
                      color: AppTheme.cyanAccent,
                      bgColor: AppTheme.cyanSoft,
                      onTap: () {
                        if (onNavigateTab != null) {
                          onNavigateTab!(9);
                        } else {
                          _showDailyReportDialog(context);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // كارت رأس المال في العمود الجانبي
  Widget _buildCapitalSideCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.savings_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'رأس مال المصنع',
                      style: TextStyle(fontSize: 11.5, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      store.capitalAmount > 0
                          ? '${_formatNumber(store.capitalAmount)} ج.م'
                          : 'غير محدد',
                      style: TextStyle(
                        fontSize: store.capitalAmount > 0 ? 17 : 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'تعديل رأس المال',
                icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                onPressed: () => _showEditCapitalDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCapitalDialog(BuildContext context) {
    final controller = TextEditingController(
      text: store.capitalAmount > 0 ? store.capitalAmount.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.savings_outlined, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('تحديد / تعديل رأس مال المصنع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'رأس المال (جنيه)',
                  border: OutlineInputBorder(),
                  suffixText: 'ج.م',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
              ),
              if (store.capitalAmount > 0) ...[
                const SizedBox(height: 12),
                Text(
                  'القيمة الحالية: ${_formatNumber(store.capitalAmount)} جنيه',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newCapital = double.tryParse(controller.text.replaceAll(',', ''));
              if (newCapital != null && newCapital >= 0) {
                store.updateCapitalAmount(newCapital);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حفظ رأس المال بنجاح!'),
                    backgroundColor: Color(0xFF2563EB),
                  ),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showDailyReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.description, color: AppTheme.primaryBlue),
              SizedBox(width: 8),
              Text('التقرير اليومي للمصنع (30 يوليو 2026)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reportRow('إجمالي مبيعات اليوم:', '${_formatNumber(20800)} كجم'),
                _reportRow('تكلفة ومصروفات اليوم:', '48,600 جنيه'),
                _reportRow('قيمة مبيعات اليوم:', '68,200 جنيه'),
                _reportRow('صافي ربح اليوم المحقق:', '19,600 جنيه'),
                const Divider(height: 24),
                const Text('حالة الماكينات: جميع خطوط الفيلم والمقصات تعمل بكفاءة 96%', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تصدير التقرير اليومي بنجاح!'), backgroundColor: AppTheme.successGreen),
                );
              },
              icon: const Icon(Icons.print, size: 16),
              label: const Text('طباعة التقرير'),
            ),
          ],
        );
      },
    );
  }

  Widget _reportRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  void _showEditPlasticTonPriceDialog(BuildContext context) {
    final controller = TextEditingController(text: store.plasticTonPrice.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تحديث سعر طن البلاستيك'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'سعر طن البلاستيك (جنيه)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'السعر الحالي: ${_formatNumber(store.plasticTonPrice)} جنيه',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null && newPrice > 0) {
                store.updatePlasticTonPrice(newPrice);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث سعر طن البلاستيك'), backgroundColor: AppTheme.successGreen),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
