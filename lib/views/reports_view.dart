import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../state/factory_store.dart';
import '../models/sale_order.dart';
import '../models/product_item.dart';
import '../services/pdf_report_service.dart';

class ReportsView extends StatefulWidget {
  final FactoryStore store;

  const ReportsView({super.key, required this.store});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'الكل'; // 'الكل', 'اليوم', 'آخر 7 أيام', 'هذا الشهر'
  String _selectedSaleType = 'الكل'; // 'الكل', 'جملة', 'قطاعي'
  String _selectedProduct = 'الكل'; // 'الكل' or product name

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  final NumberFormat _numberFormat = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // فلترة الطلبيات حسب التاريخ والنوع والصنف
  List<SaleOrder> _getFilteredOrders() {
    final now = DateTime.now();
    return widget.store.saleOrders.where((order) {
      // فلترة الفترة
      if (_selectedPeriod == 'اليوم') {
        if (order.date.year != now.year || order.date.month != now.month || order.date.day != now.day) {
          return false;
        }
      } else if (_selectedPeriod == 'آخر 7 أيام') {
        if (now.difference(order.date).inDays > 7) return false;
      } else if (_selectedPeriod == 'هذا الشهر') {
        if (order.date.year != now.year || order.date.month != now.month) return false;
      }

      // فلترة نوع البيع
      if (_selectedSaleType != 'الكل') {
        if (order.saleType != _selectedSaleType) return false;
      }

      // فلترة الصنف
      if (_selectedProduct != 'الكل') {
        final hasProduct = order.items.any((item) => item.productName == _selectedProduct);
        if (!hasProduct) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final filteredOrders = _getFilteredOrders();

    // الحسابات الميدانية للفترة المفلترة
    final totalSalesRevenue = filteredOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final totalSalesWeightKg = filteredOrders.fold(0.0, (sum, o) => sum + o.totalWeightKg);
    final totalSalesCost = filteredOrders.fold(0.0, (sum, o) => sum + o.totalCost);
    final totalSalesProfit = totalSalesRevenue - totalSalesCost;
    final profitMargin = totalSalesRevenue > 0 ? (totalSalesProfit / totalSalesRevenue) * 100 : 0.0;

    // تفصيل مبيعات الآجل ومبيعات الكاش
    final creditOrdersInFilter = filteredOrders.where((o) => o.isCredit).toList();
    final cashOrdersInFilter = filteredOrders.where((o) => !o.isCredit).toList();

    final creditRevenue = creditOrdersInFilter.fold(0.0, (sum, o) => sum + o.totalAmount);
    final creditCollected = creditOrdersInFilter.fold(0.0, (sum, o) => sum + o.paidAmount);
    final creditOutstanding = creditOrdersInFilter.fold(0.0, (sum, o) => sum + o.remainingAmount);
    final creditProfit = creditOrdersInFilter.fold(0.0, (sum, o) => sum + o.totalProfit);

    final cashRevenue = cashOrdersInFilter.fold(0.0, (sum, o) => sum + o.totalAmount);
    final cashProfit = cashOrdersInFilter.fold(0.0, (sum, o) => sum + o.totalProfit);
    
    // حساب تكلفة كهرباء وعمالة المبيعات المفلترة بناءً على معدل كل صنف
    double laborElectricityOnSales = 0.0;
    for (final o in filteredOrders) {
      for (final item in o.items) {
        final prod = store.products.cast<ProductItem?>().firstWhere(
          (p) => p?.id == item.productId || p?.name == item.productName,
          orElse: () => null,
        );
        final rate = prod != null && prod.totalProducedKg > 0
            ? prod.laborAndElectricityCostPerKg
            : 2.0;
        laborElectricityOnSales += item.quantityKg * rate;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------
          // 1. الترويسة الرئيسية وزر الطباعة والتصدير
          // -------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlueSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.analytics_outlined, color: AppTheme.primaryBlue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'التقارير الشاملة وتحليلات الأرباح والمبيعات',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'كشوفات تفصيلية لحجم المبيعات (جملة وقطاعي)، تكاليف الكهرباء والعمالة (2 ج/كجم ثابتاً)، والمخزون وصافي الأرباح',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626), // أحمر مميز لـ PDF
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('استخراج PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _exportPdfReport(
                      context,
                      filteredOrders,
                      totalSalesRevenue,
                      totalSalesWeightKg,
                      totalSalesProfit,
                      laborElectricityOnSales,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('معاينة وطباعة التقرير', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showPrintPreviewDialog(
                      context,
                      filteredOrders,
                      totalSalesRevenue,
                      totalSalesWeightKg,
                      totalSalesProfit,
                      laborElectricityOnSales,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // -------------------------------------------------------------
          // 2. شريط أدوات الفلترة الذكية
          // -------------------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // فلتر الفترة
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      const Text('الفترة:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(8),
                        items: const [
                          DropdownMenuItem(value: 'الكل', child: Text('جميع الفترات')),
                          DropdownMenuItem(value: 'اليوم', child: Text('اليوم فقط')),
                          DropdownMenuItem(value: 'آخر 7 أيام', child: Text('آخر 7 أيام')),
                          DropdownMenuItem(value: 'هذا الشهر', child: Text('هذا الشهر')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPeriod = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // فلتر نوع البيع
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      const Text('نوع البيع:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedSaleType,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(8),
                        items: const [
                          DropdownMenuItem(value: 'الكل', child: Text('جملة وقطاعي معاً')),
                          DropdownMenuItem(value: 'جملة', child: Text('مبيعات جملة فقط')),
                          DropdownMenuItem(value: 'قطاعي', child: Text('مبيعات قطاعي فقط')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSaleType = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // فلتر الصنف
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_outlined, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      const Text('الصنف:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedProduct,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(8),
                        items: [
                          const DropdownMenuItem(value: 'الكل', child: Text('جميع الأصناف')),
                          ...store.products.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedProduct = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // زر إعادة ضبط الفلاتر
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedPeriod = 'الكل';
                        _selectedSaleType = 'الكل';
                        _selectedProduct = 'الكل';
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('إعادة ضبط الفلاتر'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // -------------------------------------------------------------
          // 3. كروت مؤشرات الأداء الحية (KPIs)
          // -------------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'إجمالي المبيعات',
                  value: '${_currencyFormat.format(totalSalesRevenue)} ج.م',
                  subtitle: '${filteredOrders.length} فواتير مسجلة',
                  icon: Icons.payments_outlined,
                  color: AppTheme.primaryBlue,
                  bg: AppTheme.primaryBlueSoft,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricCard(
                  title: 'وزن المبيعات المباعة',
                  value: '${_numberFormat.format(totalSalesWeightKg)} كجم',
                  subtitle: totalSalesWeightKg > 0 ? '${(totalSalesWeightKg / 1000).toStringAsFixed(2)} طن بلاستيك' : '0 طن',
                  icon: Icons.scale_outlined,
                  color: const Color(0xFF0284C7),
                  bg: const Color(0xFFF0F9FF),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricCard(
                  title: 'مصروفات الكهرباء والعمالة',
                  value: '${_currencyFormat.format(laborElectricityOnSales)} ج.م',
                  subtitle: 'محملة على مبيعات الأصناف',
                  icon: Icons.bolt,
                  color: const Color(0xFF6D28D9),
                  bg: const Color(0xFFF5F3FF),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricCard(
                  title: 'صافي الأرباح المحققة',
                  value: '${_currencyFormat.format(totalSalesProfit)} ج.م',
                  subtitle: 'هامش الربح: ${profitMargin.toStringAsFixed(1)}%',
                  icon: Icons.trending_up_rounded,
                  color: AppTheme.successGreen,
                  bg: AppTheme.successGreenSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // صف إحصائيات الآجل والكاش
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'المبيعات النقدية (الكاش)',
                  value: '${_currencyFormat.format(cashRevenue)} ج.م',
                  subtitle: 'أرباح نقدية: +${_currencyFormat.format(cashProfit)} ج',
                  icon: Icons.point_of_sale_rounded,
                  color: const Color(0xFF059669),
                  bg: const Color(0xFFECFDF5),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricCard(
                  title: 'إجمالي المبيعات الآجلة',
                  value: '${_currencyFormat.format(creditRevenue)} ج.م',
                  subtitle: '${creditOrdersInFilter.length} فواتير آجل مسجلة',
                  icon: Icons.receipt_long_rounded,
                  color: AppTheme.primaryBlue,
                  bg: AppTheme.primaryBlueSoft,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricCard(
                  title: 'المديونيات المتبقية للتحصيل',
                  value: '${_currencyFormat.format(creditOutstanding)} ج.م',
                  subtitle: 'محصل: ${_currencyFormat.format(creditCollected)} ج.م',
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFDC2626),
                  bg: const Color(0xFFFEF2F2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricCard(
                  title: 'أرباح المبيعات الآجلة',
                  value: '+${_currencyFormat.format(creditProfit)} ج.م',
                  subtitle: creditRevenue > 0 ? 'هامش: ${((creditProfit / creditRevenue) * 100).toStringAsFixed(1)}%' : '0%',
                  icon: Icons.monetization_on_outlined,
                  color: const Color(0xFFB45309),
                  bg: const Color(0xFFFFFBEB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // -------------------------------------------------------------
          // 4. تبويبات التقارير المتخصصة
          // -------------------------------------------------------------
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryBlue,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.primaryBlue,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(icon: Icon(Icons.point_of_sale_outlined, size: 20), text: 'تقرير المبيعات التفصيلي'),
                    Tab(icon: Icon(Icons.receipt_long_outlined, size: 20), text: 'تقرير التكاليف ومصروفات التشغيل'),
                    Tab(icon: Icon(Icons.inventory_2_outlined, size: 20), text: 'تقرير المخزون والأصناف'),
                    Tab(icon: Icon(Icons.account_balance_outlined, size: 20), text: 'قائمة الأرباح والخسائر (P&L)'),
                  ],
                ),
                Container(
                  height: 520,
                  padding: const EdgeInsets.all(16),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSalesReportTab(filteredOrders),
                      _buildCostsReportTab(store, filteredOrders, laborElectricityOnSales),
                      _buildInventoryReportTab(store),
                      _buildPnlReportTab(store, filteredOrders, totalSalesRevenue, totalSalesCost, totalSalesProfit, laborElectricityOnSales),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // تبويب 1: تقرير المبيعات
  // -------------------------------------------------------------
  Widget _buildSalesReportTab(List<SaleOrder> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState(
        title: 'لا توجد فواتير مبيعات مسجلة في هذه الفترة',
        description: 'عند تسجيل فواتير بيع جملة أو قطاعي، سيظهر هنا كشف تفصيلي بالأوزان والأسعار والأرباح لكل فاتورة وعميل.',
        icon: Icons.receipt_long_outlined,
      );
    }

    final wholesaleOrders = orders.where((o) => o.saleType == 'جملة').toList();
    final retailOrders = orders.where((o) => o.saleType == 'قطاعي').toList();

    final wholesaleRevenue = wholesaleOrders.fold(0.0, (s, o) => s + o.totalAmount);
    final wholesaleKg = wholesaleOrders.fold(0.0, (s, o) => s + o.totalWeightKg);
    final wholesaleProfit = wholesaleOrders.fold(0.0, (s, o) => s + o.totalProfit);

    final retailRevenue = retailOrders.fold(0.0, (s, o) => s + o.totalAmount);
    final retailKg = retailOrders.fold(0.0, (s, o) => s + o.totalWeightKg);
    final retailProfit = retailOrders.fold(0.0, (s, o) => s + o.totalProfit);

    final creditOrders = orders.where((o) => o.isCredit).toList();
    final cashOrders = orders.where((o) => !o.isCredit).toList();

    final creditRevenue = creditOrders.fold(0.0, (s, o) => s + o.totalAmount);
    final creditKg = creditOrders.fold(0.0, (s, o) => s + o.totalWeightKg);
    final creditProfit = creditOrders.fold(0.0, (s, o) => s + o.totalProfit);
    final creditRemaining = creditOrders.fold(0.0, (s, o) => s + o.remainingAmount);
    final creditCollected = creditOrders.fold(0.0, (s, o) => s + o.paidAmount);

    final cashRevenue = cashOrders.fold(0.0, (s, o) => s + o.totalAmount);
    final cashKg = cashOrders.fold(0.0, (s, o) => s + o.totalWeightKg);
    final cashProfit = cashOrders.fold(0.0, (s, o) => s + o.totalProfit);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // مقارنة سريعة بين الجملة والقطاعي
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('مبيعات الجملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                          const SizedBox(height: 4),
                          Text('${_numberFormat.format(wholesaleKg)} كجم | ${_currencyFormat.format(wholesaleRevenue)} ج.م', style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                        ],
                      ),
                      Text('ربح: +${_currencyFormat.format(wholesaleProfit)} ج', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreenSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('مبيعات القطاعي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.successGreen)),
                          const SizedBox(height: 4),
                          Text('${_numberFormat.format(retailKg)} كجم | ${_currencyFormat.format(retailRevenue)} ج.م', style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                        ],
                      ),
                      Text('ربح: +${_currencyFormat.format(retailProfit)} ج', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.successGreen)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // مقارنة سريعة بين الكاش والآجل
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('مبيعات الكاش (نقدية مسددة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF047857))),
                          const SizedBox(height: 4),
                          Text('${_numberFormat.format(cashKg)} كجم | ${_currencyFormat.format(cashRevenue)} ج.م', style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                        ],
                      ),
                      Text('ربح كاش: +${_currencyFormat.format(cashProfit)} ج', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF047857))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('المبيعات الآجلة (ذمم مدينة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309))),
                          const SizedBox(height: 4),
                          Text('${_numberFormat.format(creditKg)} كجم | إجمالي: ${_currencyFormat.format(creditRevenue)} ج | محصل: ${_currencyFormat.format(creditCollected)} ج | متبقي: ${_currencyFormat.format(creditRemaining)} ج', style: const TextStyle(fontSize: 11.5, color: AppTheme.textPrimary)),
                        ],
                      ),
                      Text('ربح آجل: +${_currencyFormat.format(creditProfit)} ج', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // جدول الفواتير
          Table(
            border: TableBorder.all(color: AppTheme.borderLight, width: 1),
            columnWidths: const {
              0: FlexColumnWidth(1.2), // رقم الفاتورة
              1: FlexColumnWidth(1.1), // التاريخ
              2: FlexColumnWidth(1.8), // العميل
              3: FlexColumnWidth(0.9), // النوع
              4: FlexColumnWidth(1.1), // الوزن
              5: FlexColumnWidth(1.2), // الإجمالي
              6: FlexColumnWidth(1.1), // المحصل
              7: FlexColumnWidth(1.2), // المتبقي (آجل)
              8: FlexColumnWidth(1.2), // الربح
              9: FlexColumnWidth(1.1), // الدفع
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.background),
                children: [
                  _tableHead('الفاتورة'),
                  _tableHead('التاريخ'),
                  _tableHead('العميل'),
                  _tableHead('النوع'),
                  _tableHead('الوزن (كجم)'),
                  _tableHead('الإجمالي'),
                  _tableHead('المحصل'),
                  _tableHead('المتبقي (آجل)'),
                  _tableHead('صافي الربح'),
                  _tableHead('حالة الدفع'),
                ],
              ),
              ...orders.map((o) => TableRow(
                    children: [
                      _tableCell(o.invoiceNumber, isBold: true),
                      _tableCell(DateFormat('yyyy/MM/dd').format(o.date)),
                      _tableCell(o.customerName),
                      _tableCell(
                        o.saleType,
                        textColor: o.saleType == 'جملة' ? AppTheme.primaryBlue : AppTheme.successGreen,
                        isBold: true,
                      ),
                      _tableCell('${_numberFormat.format(o.totalWeightKg)} كجم'),
                      _tableCell('${_currencyFormat.format(o.totalAmount)} ج'),
                      _tableCell('${_currencyFormat.format(o.paidAmount)} ج', textColor: o.paidAmount > 0 ? AppTheme.successGreen : AppTheme.textMuted),
                      _tableCell(
                        o.isFullyPaid ? '0.00 ج' : '${_currencyFormat.format(o.remainingAmount)} ج',
                        textColor: o.isFullyPaid ? AppTheme.successGreen : const Color(0xFFDC2626),
                        isBold: !o.isFullyPaid,
                      ),
                      _tableCell('+${_currencyFormat.format(o.totalProfit)} ج', textColor: AppTheme.primaryBlue, isBold: true),
                      _tableCell(o.paymentStatus, isBold: o.paymentStatus.contains('آجل') || o.paymentStatus.contains('جزئي')),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // تبويب 2: تقرير التكاليف ومصروفات التشغيل
  // -------------------------------------------------------------
  Widget _buildCostsReportTab(FactoryStore store, List<SaleOrder> orders, double laborElecOnSales) {
    final expenses = store.expenses;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // كرت توضيح معادلة الكهرباء والعمالة
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF6D28D9), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مصروفات الكهرباء والعمالة المحملة على الأصناف:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6D28D9)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'إجمالي كهرباء وعمالة المبيعات المفلترة = ${_currencyFormat.format(laborElecOnSales)} ج.م (محسوبة ومحملة على أسعار الجملة والقطاعي وفقاً لمعدل كل صنف).',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (expenses.isEmpty)
            _buildEmptyState(
              title: 'لا توجد مصروفات إضافية مسجلة',
              description: 'يمكنك تسجيل فواتير الكهرباء أو قطع الغيار ومشتريات الخامات من صفحة التكاليف والمصروفات.',
              icon: Icons.receipt_long_outlined,
            )
          else ...[
            const Text('سجل المصروفات العامة والتشغيلية المباشرة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            Table(
              border: TableBorder.all(color: AppTheme.borderLight, width: 1),
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(2.5),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(2.0),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: AppTheme.background),
                  children: [
                    _tableHead('التاريخ'),
                    _tableHead('بيان المصروف'),
                    _tableHead('التصنيف'),
                    _tableHead('المبلغ (ج.م)'),
                    _tableHead('ملاحظات'),
                  ],
                ),
                ...expenses.map((e) => TableRow(
                      children: [
                        _tableCell(DateFormat('yyyy/MM/dd').format(e.date)),
                        _tableCell(e.title, isBold: true),
                        _tableCell(e.category),
                        _tableCell('${_currencyFormat.format(e.amount)} ج', textColor: AppTheme.costPurple, isBold: true),
                        _tableCell(e.notes ?? '-'),
                      ],
                    )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // تبويب 3: تقرير المخزون والأصناف
  // -------------------------------------------------------------
  Widget _buildInventoryReportTab(FactoryStore store) {
    final products = store.products;
    if (products.isEmpty) {
      return _buildEmptyState(
        title: 'لا توجد أصناف في المخزن بعد',
        description: 'ابدأ بإضافة أصناف جديدة من صفحة "المخزون والأصناف" لتتبع أرصدة الكيلوات وقيمة البضاعة والأرباح المتوقعة.',
        icon: Icons.inventory_2_outlined,
      );
    }

    final totalStockKg = products.fold(0.0, (s, p) => s + p.stockKg);
    final totalInventoryCostValue = products.fold(0.0, (s, p) => s + (p.stockKg * p.costPerKg));
    final totalInventoryWholesaleValue = products.fold(0.0, (s, p) => s + (p.stockKg * p.wholesalePricePerKg));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ملخص المخزون
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إجمالي وزن المخزون الجاهز', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          const SizedBox(height: 2),
                          Text('${_numberFormat.format(totalStockKg)} كجم', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                        ],
                      ),
                      const Icon(Icons.scale, color: AppTheme.successGreen, size: 28),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('قيمة المخزون (سعر التكلفة)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          const SizedBox(height: 2),
                          Text('${_currencyFormat.format(totalInventoryCostValue)} ج.م', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                        ],
                      ),
                      const Icon(Icons.account_balance_wallet, color: AppTheme.primaryBlue, size: 28),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('القيمة البيعية المتوقعة (جملة)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          const SizedBox(height: 2),
                          Text('${_currencyFormat.format(totalInventoryWholesaleValue)} ج.م', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9))),
                        ],
                      ),
                      const Icon(Icons.storefront, color: Color(0xFF6D28D9), size: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // جدول كشف المخزون
          Table(
            border: TableBorder.all(color: AppTheme.borderLight, width: 1),
            columnWidths: const {
              0: FlexColumnWidth(2.5), // اسم الصنف
              1: FlexColumnWidth(1.2), // الكمية المدخلة
              2: FlexColumnWidth(1.2), // الرصيد الحالي
              3: FlexColumnWidth(1.4), // تكلفة الكيلو
              4: FlexColumnWidth(1.2), // سعر جملة
              5: FlexColumnWidth(1.2), // سعر قطاعي
              6: FlexColumnWidth(1.4), // مكسب جملة
              7: FlexColumnWidth(1.4), // مكسب قطاعي
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.background),
                children: [
                  _tableHead('الصنف / المقاس'),
                  _tableHead('الكمية (كجم)'),
                  _tableHead('المخزون الحالي'),
                  _tableHead('إجمالي تكلفة الكيلو'),
                  _tableHead('سعر الجملة'),
                  _tableHead('سعر القطاعي'),
                  _tableHead('مكسب كجم جملة'),
                  _tableHead('مكسب كجم قطاعي'),
                ],
              ),
              ...products.map((p) => TableRow(
                    children: [
                      _tableCell(p.name, isBold: true),
                      _tableCell('${_numberFormat.format(p.totalProducedKg)} كجم'),
                      _tableCell('${_numberFormat.format(p.stockKg)} كجم', textColor: AppTheme.primaryBlue, isBold: true),
                      _tableCell('${p.costPerKg.toStringAsFixed(2)} ج'),
                      _tableCell('${p.wholesalePricePerKg.toStringAsFixed(2)} ج'),
                      _tableCell('${p.retailPricePerKg.toStringAsFixed(2)} ج'),
                      _tableCell('+${p.wholesaleProfitPerKg.toStringAsFixed(2)} ج', textColor: AppTheme.primaryBlue, isBold: true),
                      _tableCell('+${p.retailProfitPerKg.toStringAsFixed(2)} ج', textColor: AppTheme.successGreen, isBold: true),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // تبويب 4: قائمة الدخل والأرباح والخسائر (P&L)
  // -------------------------------------------------------------
  Widget _buildPnlReportTab(
    FactoryStore store,
    List<SaleOrder> orders,
    double totalRevenue,
    double totalCost,
    double totalProfit,
    double laborElecOnSales,
  ) {
    final rawMaterialsCostOnSales = totalCost - laborElecOnSales;

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('قائمة الدخل والأرباح التشغيلية (P&L Statement)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlueSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('فترة التقرير: $_selectedPeriod', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  ),
                ],
              ),
              const Divider(height: 24),
              _pnlRow('1. إجمالي إيرادات المبيعات (جملة + قطاعي)', totalRevenue, isPositive: true, isBold: true),
              const SizedBox(height: 10),
              const Text('تكاليف البضاعة المباعة المباشرة (COGS):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    _pnlRow('• تكلفة المواد الخام المحملة على المباع', rawMaterialsCostOnSales > 0 ? rawMaterialsCostOnSales : 0.0, isNegative: true),
                    const SizedBox(height: 4),
                    _pnlRow('• مصروفات الكهرباء والعمالة (2.00 ج/كجم ثابتاً)', laborElecOnSales, isNegative: true),
                  ],
                ),
              ),
              const Divider(height: 20),
              _pnlRow('2. إجمالي تكلفة البضاعة المباعة', totalCost, isNegative: true, isBold: true),
              const Divider(height: 20),
              _pnlRow(
                '3. مجمل الربح التشغيلي (Gross Profit)',
                totalProfit,
                isPositive: totalProfit >= 0,
                isNegative: totalProfit < 0,
                isBold: true,
                fontSize: 15,
                highlightColor: totalProfit >= 0 ? AppTheme.successGreenSoft : AppTheme.wasteRedSoft,
              ),
              const SizedBox(height: 14),
              const Text('تحليل وتوزيع الأرباح التشغيلية (كاش وآجل):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    _pnlRow('• صافي أرباح المبيعات النقدية المحصلة (كاش)', orders.where((o) => !o.isCredit).fold(0.0, (s, o) => s + o.totalProfit), isPositive: true),
                    const SizedBox(height: 4),
                    _pnlRow('• أرباح المبيعات الآجلة (المستحقة بالذمم)', orders.where((o) => o.isCredit).fold(0.0, (s, o) => s + o.totalProfit), isPositive: true),
                    const SizedBox(height: 4),
                    _pnlRow('• رصيد المديونيات الآجلة المعلقة للتحصيل بالسوق', orders.where((o) => o.isCredit).fold(0.0, (s, o) => s + o.remainingAmount), isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('هامش صافي الربح للفترة المحددة:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    Text(
                      totalRevenue > 0 ? '${((totalProfit / totalRevenue) * 100).toStringAsFixed(1)}%' : '0.0%',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pnlRow(String title, double amount, {bool isPositive = false, bool isNegative = false, bool isBold = false, double fontSize = 13, Color? highlightColor}) {
    final formatted = '${_currencyFormat.format(amount)} ج.م';
    Color textColor = AppTheme.textPrimary;
    if (isPositive) textColor = AppTheme.successGreen;
    if (isNegative) textColor = AppTheme.wasteRed;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: AppTheme.textPrimary)),
        Text(
          isNegative ? '- $formatted' : formatted,
          style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: textColor),
        ),
      ],
    );

    if (highlightColor != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: highlightColor, borderRadius: BorderRadius.circular(6)),
        child: content,
      );
    }
    return content;
  }

  // -------------------------------------------------------------
  // نافذة معاينة وطباعة التقرير (Print Preview)
  // -------------------------------------------------------------
  void _showPrintPreviewDialog(
    BuildContext context,
    List<SaleOrder> orders,
    double totalRevenue,
    double totalWeight,
    double totalProfit,
    double laborElec,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.print, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('تقرير النجمة بلاست الجاهز للطباعة والتصدير'),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(widget.store.factoryName.isNotEmpty ? widget.store.factoryName : 'النجمة بلاست', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('تقرير الأداء المالي والمبيعات - تاريخ الطباعة: ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      Text('نطاق الفترة: $_selectedPeriod | نوع البيع: $_selectedSaleType', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    ],
                  ),
                ),
                const Divider(height: 24),
                _printRow('إجمالي وزن المبيعات:', '${_numberFormat.format(totalWeight)} كجم'),
                _printRow('إجمالي إيرادات المبيعات:', '${_currencyFormat.format(totalRevenue)} ج.م'),
                _printRow('مصروفات الكهرباء والعمالة المحملة:', '${_currencyFormat.format(laborElec)} ج.م'),
                _printRow('صافي الأرباح المحققة:', '${_currencyFormat.format(totalProfit)} ج.م', isBold: true, color: AppTheme.successGreen),
                const Divider(height: 20),
                const Text('أحدث فواتير المبيعات المدرجة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                ...orders.take(5).map((o) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${o.invoiceNumber} - ${o.customerName} (${o.saleType})', style: const TextStyle(fontSize: 11.5)),
                          Text('${_currencyFormat.format(o.totalAmount)} ج', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إغلاق')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('حفظ كملف PDF'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _exportPdfReport(context, orders, totalRevenue, totalWeight, totalProfit, laborElec);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.print, size: 16),
            label: const Text('طباعة فورية'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _printDirectPdf(context, orders, totalRevenue, totalWeight, totalProfit, laborElec);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdfReport(
    BuildContext context,
    List<SaleOrder> orders,
    double totalRevenue,
    double totalWeight,
    double totalProfit,
    double laborElec,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 12),
              Text('جاري إعداد وتصدير ملف الـ PDF...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      final path = await PdfReportService.exportAndSavePdf(
        store: widget.store,
        orders: orders,
        period: _selectedPeriod,
        saleType: _selectedSaleType,
        productName: _selectedProduct,
        totalRevenue: totalRevenue,
        totalWeightKg: totalWeight,
        totalProfit: totalProfit,
        laborElectricityCost: laborElec,
      );

      if (context.mounted) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم استخراج وحفظ تقرير PDF بنجاح في:\n$path'),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء استخراج ملف الـ PDF: $e'),
            backgroundColor: AppTheme.wasteRed,
          ),
        );
      }
    }
  }

  Future<void> _printDirectPdf(
    BuildContext context,
    List<SaleOrder> orders,
    double totalRevenue,
    double totalWeight,
    double totalProfit,
    double laborElec,
  ) async {
    try {
      await PdfReportService.printReport(
        store: widget.store,
        orders: orders,
        period: _selectedPeriod,
        saleType: _selectedSaleType,
        productName: _selectedProduct,
        totalRevenue: totalRevenue,
        totalWeightKg: totalWeight,
        totalProfit: totalProfit,
        laborElectricityCost: laborElec,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تجهيز الطباعة: $e'),
            backgroundColor: AppTheme.wasteRed,
          ),
        );
      }
    }
  }

  Widget _printRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required String title, required String description, required IconData icon}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHead(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _tableCell(String text, {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: textColor ?? AppTheme.textPrimary,
        ),
      ),
    );
  }
}
