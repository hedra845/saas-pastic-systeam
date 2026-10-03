import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';
import '../state/factory_store.dart';
import '../models/sale_order.dart';
import '../models/material_supply_order.dart';
import '../services/pdf_report_service.dart';

class CreditSalesView extends StatefulWidget {
  final FactoryStore store;

  const CreditSalesView({super.key, required this.store});

  @override
  State<CreditSalesView> createState() => _CreditSalesViewState();
}

class _CreditSalesViewState extends State<CreditSalesView> {
  int _currentTab = 0; // 0: الآجل علينا للموردين (توريد خامات), 1: الآجل لنا للعملاء (مبيعات)
  final TextEditingController _searchCtrlSuppliers = TextEditingController();
  String _selectedFilterSuppliers = 'معلق ومتبقي'; // 'معلق ومتبقي', 'الكل', 'مسدد جزئياً', 'مسدد بالكامل'

  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'معلق ومتبقي'; // 'معلق ومتبقي', 'الكل', 'مسدد جزئياً', 'مسدد بالكامل', 'جملة', 'قطاعي'

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  final NumberFormat _numberFormat = NumberFormat('#,###');

  @override
  void dispose() {
    _searchController.dispose();
    _searchCtrlSuppliers.dispose();
    super.dispose();
  }

  List<MaterialSupplyOrder> _getFilteredSupplierOrders() {
    final query = _searchCtrlSuppliers.text.trim().toLowerCase();
    final allSuppliers = widget.store.creditSupplyOrders;

    return allSuppliers.where((order) {
      if (_selectedFilterSuppliers == 'معلق ومتبقي') {
        if (order.isFullyPaid) return false;
      } else if (_selectedFilterSuppliers == 'مسدد جزئياً') {
        if (order.paidAmount <= 0.01 || order.isFullyPaid) return false;
      } else if (_selectedFilterSuppliers == 'مسدد بالكامل') {
        if (!order.isFullyPaid) return false;
      }

      if (query.isNotEmpty) {
        final matchInvoice = order.invoiceNumber.toLowerCase().contains(query);
        final matchSupplier = order.supplierName.toLowerCase().contains(query);
        final matchFactory = order.supplierFactory.toLowerCase().contains(query);
        final matchMaterial = order.rawMaterialName.toLowerCase().contains(query);
        if (!matchInvoice && !matchSupplier && !matchFactory && !matchMaterial) return false;
      }

      return true;
    }).toList();
  }

  List<SaleOrder> _getFilteredCreditOrders() {
    final query = _searchController.text.trim().toLowerCase();
    final allCredit = widget.store.creditOrders;

    return allCredit.where((order) {
      // فلترة الحالة
      if (_selectedFilter == 'معلق ومتبقي') {
        if (order.isFullyPaid) return false;
      } else if (_selectedFilter == 'مسدد جزئياً') {
        if (order.paidAmount <= 0.01 || order.isFullyPaid) return false;
      } else if (_selectedFilter == 'مسدد بالكامل') {
        if (!order.isFullyPaid) return false;
      } else if (_selectedFilter == 'جملة') {
        if (order.saleType != 'جملة') return false;
      } else if (_selectedFilter == 'قطاعي') {
        if (order.saleType != 'قطاعي') return false;
      }

      // البحث بالنص
      if (query.isNotEmpty) {
        final matchInvoice = order.invoiceNumber.toLowerCase().contains(query);
        final matchCustomer = order.customerName.toLowerCase().contains(query);
        final matchPhone = order.customerPhone?.toLowerCase().contains(query) ?? false;
        if (!matchInvoice && !matchCustomer && !matchPhone) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final filteredSalesOrders = _getFilteredCreditOrders();
    final filteredSupplierOrders = _getFilteredSupplierOrders();

    final pendingSuppliersCount = store.materialSupplyOrders.where((o) => o.remainingAmount > 0.01).length;
    final pendingSalesCount = store.creditOrders.where((o) => !o.isFullyPaid).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------
          // 0. شريط التبديل بين الآجل علينا للموردين والآجل لنا للعملاء
          // -------------------------------------------------------------
          _buildTabsSwitcher(pendingSuppliersCount, pendingSalesCount),
          const SizedBox(height: 18),

          if (_currentTab == 0)
            _buildSupplierDebtsView(context, store, filteredSupplierOrders)
          else
            _buildCustomerCreditsView(context, store, filteredSalesOrders),
        ],
      ),
    );
  }

  Widget _buildCustomerCreditsView(BuildContext context, FactoryStore store, List<SaleOrder> filteredOrders) {
    final allCreditOrders = store.creditOrders;
    final totalVolume = store.totalCreditSalesVolume;
    final totalOutstanding = store.totalCreditOutstanding;
    final totalCollected = store.totalCreditCollected;
    final totalProfit = store.totalCreditProfit;
    final collectionRate = totalVolume > 0 ? (totalCollected / totalVolume) * 100 : 0.0;
    final pendingCount = allCreditOrders.where((o) => !o.isFullyPaid).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // -------------------------------------------------------------
          // 1. الترويسة الرئيسية وأزرار الإجراءات
          // -------------------------------------------------------------
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isNarrow = headerConstraints.maxWidth < 850;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.credit_score_rounded, color: Color(0xFFB45309), size: 24),
                                ),
                                const SizedBox(width: 12),
                                const Flexible(
                                  child: Text(
                                    'إدارة المبيعات الآجلة وكشوف المديونيات',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'متابعة فواتير البيع الآجل (جملة وقطاعي)، تحصيل الدفعات، جرد المديونيات المعلقة، وتحليلات أرباح الآجل',
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 16),
                        _buildHeaderActions(context, filteredOrders),
                      ],
                    ],
                  ),
                  if (isNarrow) ...[
                    const SizedBox(height: 12),
                    _buildHeaderActions(context, filteredOrders),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // -------------------------------------------------------------
          // 2. كروت المؤشرات المالية للآجل (5 KPIs)
          // -------------------------------------------------------------
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final int count;
              final double ratio;
              if (width >= 1250) {
                count = 5;
                ratio = 1.45;
              } else if (width >= 850) {
                count = 3;
                ratio = 1.65;
              } else if (width >= 550) {
                count = 2;
                ratio = 1.6;
              } else {
                count = 1;
                ratio = 2.4;
              }

              return GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: ratio,
                children: [
                  _buildKpiCard(
                    title: 'إجمالي مبيعات الآجل',
                    value: '${_currencyFormat.format(totalVolume)} ج.م',
                    subtitle: '${allCreditOrders.length} فاتورة مسجلة',
                    icon: Icons.receipt_long_outlined,
                    color: AppTheme.primaryBlue,
                    bg: AppTheme.primaryBlueSoft,
                  ),
                  _buildKpiCard(
                    title: 'المديونيات المتبقية للتحصيل',
                    value: '${_currencyFormat.format(totalOutstanding)} ج.م',
                    subtitle: '$pendingCount فواتير معلقة بالسوق',
                    icon: Icons.pending_actions_rounded,
                    color: const Color(0xFFDC2626),
                    bg: const Color(0xFFFEF2F2),
                    badge: pendingCount > 0 ? '$pendingCount معلقة' : null,
                  ),
                  _buildKpiCard(
                    title: 'إجمالي المبالغ المحصلة',
                    value: '${_currencyFormat.format(totalCollected)} ج.م',
                    subtitle: 'تم إيداعها في الخزينة',
                    icon: Icons.task_alt_rounded,
                    color: AppTheme.successGreen,
                    bg: AppTheme.successGreenSoft,
                  ),
                  _buildKpiCard(
                    title: 'أرباح مبيعات الآجل',
                    value: '+${_currencyFormat.format(totalProfit)} ج.م',
                    subtitle: totalVolume > 0 ? 'هامش: ${((totalProfit / totalVolume) * 100).toStringAsFixed(1)}%' : '0%',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFFB45309),
                    bg: const Color(0xFFFFFBEB),
                  ),
                  _buildKpiCard(
                    title: 'نسبة التحصيل والسداد',
                    value: '${collectionRate.toStringAsFixed(1)}%',
                    subtitle: 'من إجمالي المبيعات الآجلة',
                    icon: Icons.pie_chart_outline_rounded,
                    color: const Color(0xFF6D28D9),
                    bg: const Color(0xFFF5F3FF),
                    progress: (collectionRate / 100).clamp(0.0, 1.0),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // -------------------------------------------------------------
          // 3. شريط البحث والفلترة السريعة
          // -------------------------------------------------------------
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // حقل البحث
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'بحث برقم الفاتورة، اسم العميل، أو رقم الهاتف...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppTheme.borderSubtle),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Text(
                          'المطابق: ${filteredOrders.length} فاتورة',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // فلتر الشرائح السريعة
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('معلق ومتبقي', count: pendingCount, isAlert: pendingCount > 0),
                        const SizedBox(width: 8),
                        _buildFilterChip('الكل', count: allCreditOrders.length),
                        const SizedBox(width: 8),
                        _buildFilterChip('مسدد جزئياً', count: allCreditOrders.where((o) => o.paidAmount > 0.01 && !o.isFullyPaid).length),
                        const SizedBox(width: 8),
                        _buildFilterChip('مسدد بالكامل', count: allCreditOrders.where((o) => o.isFullyPaid).length),
                        const SizedBox(width: 8),
                        _buildFilterChip('جملة', count: allCreditOrders.where((o) => o.saleType == 'جملة').length),
                        const SizedBox(width: 8),
                        _buildFilterChip('قطاعي', count: allCreditOrders.where((o) => o.saleType == 'قطاعي').length),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // -------------------------------------------------------------
          // 4. جدول فواتير الآجل
          // -------------------------------------------------------------
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.table_rows_rounded, color: AppTheme.primaryBlue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'كشف فواتير المبيعات الآجلة (${filteredOrders.length} فاتورة)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      Text(
                        'إجمالي المتبقي بالقائمة: ${_currencyFormat.format(filteredOrders.fold(0.0, (s, o) => s + o.remainingAmount))} ج.م',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (filteredOrders.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          allCreditOrders.isEmpty ? Icons.check_circle_outline : Icons.search_off_rounded,
                          size: 48,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          allCreditOrders.isEmpty
                              ? 'لا توجد فواتير بيع آجل مسجلة في النظام حتى الآن'
                              : 'لا توجد فواتير تطابق شروط الفلترة الحالية',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'تظهر هنا تلقائياً أي فاتورة بيع يتم تحديد طريقة سدادها كـ (آجل) مع إمكانية تحصيل الدفعات وتسويتها في الخزنة.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    child: LayoutBuilder(
                      builder: (context, tableConstraints) {
                        const minTableWidth = 1100.0;
                        final tableWidth = tableConstraints.maxWidth < minTableWidth
                            ? minTableWidth
                            : tableConstraints.maxWidth;

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            child: Table(
                              border: TableBorder.all(color: AppTheme.borderLight, width: 0.8),
                              columnWidths: const {
                                0: FlexColumnWidth(1.4), // رقم الفاتورة
                                1: FlexColumnWidth(1.1), // التاريخ
                                2: FlexColumnWidth(2.0), // العميل / الموزع
                                3: FlexColumnWidth(0.9), // النوع
                                4: FlexColumnWidth(1.3), // الإجمالي
                                5: FlexColumnWidth(1.2), // المحصل
                                6: FlexColumnWidth(1.3), // المتبقي
                                7: FlexColumnWidth(1.1), // الربح
                                8: FlexColumnWidth(1.3), // حالة السداد
                                9: FlexColumnWidth(2.0), // الإجراءات
                              },
                              children: [
                                // رأس الجدول
                                TableRow(
                                  decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                                  children: [
                                    _tableHead('رقم الفاتورة'),
                                    _tableHead('التاريخ'),
                                    _tableHead('العميل / الموزع'),
                                    _tableHead('النوع'),
                                    _tableHead('قيمة الفاتورة'),
                                    _tableHead('المحصل'),
                                    _tableHead('المتبقي (المديونية)'),
                                    _tableHead('أرباح الفاتورة'),
                                    _tableHead('حالة السداد'),
                                    _tableHead('الإجراءات'),
                                  ],
                                ),
                                // صفوف الفواتير
                                ...filteredOrders.map((order) {
                                  final isPaid = order.isFullyPaid;
                                  final isPartial = order.paidAmount > 0.01 && !isPaid;

                                  return TableRow(
                                    decoration: BoxDecoration(
                                      color: isPaid
                                          ? const Color(0xFFF9FAFB)
                                          : (isPartial ? const Color(0xFFFEFCE8) : Colors.white),
                                    ),
                                    children: [
                                      // رقم الفاتورة
                                      _tableCellWidget(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              order.invoiceNumber,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.primaryBlue),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_numberFormat.format(order.totalWeightKg)} كجم',
                                              style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // التاريخ
                                      _tableCell(DateFormat('yyyy/MM/dd').format(order.date)),
                                      // العميل
                                      _tableCellWidget(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              order.customerName,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppTheme.textPrimary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (order.customerPhone != null && order.customerPhone!.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                order.customerPhone!,
                                                style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // نوع البيع
                                      _tableCellWidget(
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: order.saleType == 'جملة' ? AppTheme.primaryBlueSoft : AppTheme.successGreenSoft,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              order.saleType,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: order.saleType == 'جملة' ? AppTheme.primaryBlue : AppTheme.successGreen,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // قيمة الفاتورة
                                      _tableCell('${_currencyFormat.format(order.totalAmount)} ج', isBold: true),
                                      // المحصل
                                      _tableCell(
                                        '${_currencyFormat.format(order.paidAmount)} ج',
                                        textColor: order.paidAmount > 0 ? AppTheme.successGreen : AppTheme.textMuted,
                                        isBold: order.paidAmount > 0,
                                      ),
                                      // المتبقي (المديونية)
                                      _tableCellWidget(
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.center,
                                          child: Text(
                                            isPaid ? '0.00 ج (مسدد)' : '${_currencyFormat.format(order.remainingAmount)} ج',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                              color: isPaid ? AppTheme.successGreen : const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // ربح الفاتورة
                                      _tableCell(
                                        '+${_currencyFormat.format(order.totalProfit)} ج',
                                        textColor: AppTheme.primaryBlue,
                                        isBold: true,
                                      ),
                                      // حالة السداد
                                      _tableCellWidget(
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isPaid
                                                  ? const Color(0xFFECFDF5)
                                                  : (isPartial ? const Color(0xFFFEF3C7) : const Color(0xFFFEF2F2)),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isPaid
                                                    ? const Color(0xFFA7F3D0)
                                                    : (isPartial ? const Color(0xFFFDE68A) : const Color(0xFFFECACA)),
                                              ),
                                            ),
                                            child: Text(
                                              isPaid ? 'مسدد بالكامل' : (isPartial ? 'دفع جزئي' : 'معلق / آجل'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isPaid
                                                    ? const Color(0xFF047857)
                                                    : (isPartial ? const Color(0xFFB45309) : const Color(0xFFB91C1C)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // الإجراءات
                                      _tableCellWidget(
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // زر تحصيل دفعة
                                            if (!isPaid)
                                              IconButton(
                                                icon: const Icon(Icons.payments_rounded, color: AppTheme.successGreen, size: 19),
                                                tooltip: 'تسجيل تحصيل دفعة',
                                                padding: const EdgeInsets.all(4),
                                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                splashRadius: 18,
                                                onPressed: () => _showCollectPaymentDialog(context, order),
                                              ),
                                            // زر حفظ PDF
                                            IconButton(
                                              icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primaryBlue, size: 19),
                                              tooltip: 'حفظ الفاتورة (PDF)',
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              splashRadius: 18,
                                              onPressed: () => _saveInvoicePdf(context, order),
                                            ),
                                            // زر الطباعة
                                            IconButton(
                                              icon: const Icon(Icons.print_outlined, color: Colors.blueGrey, size: 19),
                                              tooltip: 'طباعة الفاتورة',
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              splashRadius: 18,
                                              onPressed: () => _printInvoice(context, order),
                                            ),
                                            // زر الحذف
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: AppTheme.wasteRed, size: 19),
                                              tooltip: 'حذف الفاتورة',
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              splashRadius: 18,
                                              onPressed: () => _showDeleteOrderDialog(context, order),
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
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
  }

  // -------------------------------------------------------------
  // شريط التبديل بين تبويب الآجل علينا (للموردين) والآجل لنا (للعملاء)
  // -------------------------------------------------------------
  Widget _buildTabsSwitcher(int pendingSuppliersCount, int pendingSalesCount) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => setState(() => _currentTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _currentTab == 0 ? const Color(0xFFFEF2F2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: _currentTab == 0 ? const Color(0xFFFCA5A5) : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_circle_down_rounded,
                      size: 20,
                      color: _currentTab == 0 ? const Color(0xFFDC2626) : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الآجل علينا للموردين (توريد الخامات - علينا فلوس)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: _currentTab == 0 ? FontWeight.bold : FontWeight.w600,
                        color: _currentTab == 0 ? const Color(0xFFDC2626) : AppTheme.textSecondary,
                      ),
                    ),
                    if (pendingSuppliersCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pendingSuppliersCount معلق',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => setState(() => _currentTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _currentTab == 1 ? AppTheme.primaryBlueSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: _currentTab == 1 ? AppTheme.primaryBlue.withValues(alpha: 0.4) : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_circle_up_rounded,
                      size: 20,
                      color: _currentTab == 1 ? AppTheme.primaryBlue : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الآجل لنا عند العملاء (فواتير المبيعات - لنا فلوس)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: _currentTab == 1 ? FontWeight.bold : FontWeight.w600,
                        color: _currentTab == 1 ? AppTheme.primaryBlue : AppTheme.textSecondary,
                      ),
                    ),
                    if (pendingSalesCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.profitAmber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pendingSalesCount معلق',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // واجهة الآجل علينا للموردين (توريدات الخامات)
  // -------------------------------------------------------------
  Widget _buildSupplierDebtsView(BuildContext context, FactoryStore store, List<MaterialSupplyOrder> filteredOrders) {
    final allSupplierOrders = store.creditSupplyOrders;
    final totalVolume = store.totalSupplierDebtVolume;
    final totalOutstanding = store.totalSupplierDebtOutstanding;
    final totalPaid = store.totalSupplierDebtPaid;
    final pendingCount = allSupplierOrders.where((o) => !o.isFullyPaid).length;
    final partialCount = allSupplierOrders.where((o) => o.paidAmount > 0.01 && !o.isFullyPaid).length;
    final fullyPaidCount = allSupplierOrders.where((o) => o.isFullyPaid).length;
    final paymentRate = totalVolume > 0 ? (totalPaid / totalVolume) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. الترويسة الرئيسية
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.outbox_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'مديونيات توريدات الخامات للموردين (علينا فلوس)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'متابعة أذونات التوريد الآجلة، المبالغ المستحقة علينا للموردين، وسداد الدفعات النقدية بالأجزاء مع الخصم التلقائي من الخزينة',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. كروت المؤشرات المالية لمديونيات الموردين (5 KPIs)
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final int count;
            final double ratio;
            if (width >= 1250) {
              count = 5;
              ratio = 1.45;
            } else if (width >= 850) {
              count = 3;
              ratio = 1.65;
            } else if (width >= 550) {
              count = 2;
              ratio = 1.6;
            } else {
              count = 1;
              ratio = 2.4;
            }

            return GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: ratio,
              children: [
                _buildKpiCard(
                  title: 'إجمالي الآجل علينا للموردين',
                  value: '${_currencyFormat.format(totalOutstanding)} ج.م',
                  subtitle: '$pendingCount أذونات توريد معلقة بالسوق',
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFDC2626),
                  bg: const Color(0xFFFEF2F2),
                  badge: pendingCount > 0 ? '$pendingCount معلقة' : null,
                ),
                _buildKpiCard(
                  title: 'إجمالي المبالغ المسددة',
                  value: '${_currencyFormat.format(totalPaid)} ج.م',
                  subtitle: 'تم سدادها وخصمها من الخزينة',
                  icon: Icons.task_alt_rounded,
                  color: AppTheme.successGreen,
                  bg: AppTheme.successGreenSoft,
                ),
                _buildKpiCard(
                  title: 'إجمالي قيمة التوريدات الآجلة',
                  value: '${_currencyFormat.format(totalVolume)} ج.م',
                  subtitle: '${allSupplierOrders.length} إذن توريد مسجل',
                  icon: Icons.inventory_2_outlined,
                  color: AppTheme.costPurple,
                  bg: AppTheme.costPurpleSoft,
                ),
                _buildKpiCard(
                  title: 'أذونات التوريد المعلقة',
                  value: '$pendingCount إذن توريد',
                  subtitle: 'بها متبقي مستحق واجب السداد',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFFB45309),
                  bg: const Color(0xFFFFFBEB),
                ),
                _buildKpiCard(
                  title: 'نسبة السداد للموردين',
                  value: '${paymentRate.toStringAsFixed(1)}%',
                  subtitle: 'من إجمالي المديونيات الآجلة',
                  icon: Icons.pie_chart_outline_rounded,
                  color: const Color(0xFF6D28D9),
                  bg: const Color(0xFFF5F3FF),
                  progress: (paymentRate / 100).clamp(0.0, 1.0),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // 3. شريط البحث والفلترة السريعة للموردين
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrlSuppliers,
                        decoration: InputDecoration(
                          hintText: 'بحث برقم الإذن، اسم المورد، المصنع التابع له، أو الخامة الموردة...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchCtrlSuppliers.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrlSuppliers.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.borderSubtle),
                          ),
                          filled: true,
                          fillColor: AppTheme.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSupplierFilterChip('معلق ومتبقي', count: pendingCount, isAlert: true),
                      const SizedBox(width: 8),
                      _buildSupplierFilterChip('مسدد جزئياً', count: partialCount),
                      const SizedBox(width: 8),
                      _buildSupplierFilterChip('مسدد بالكامل', count: fullyPaidCount),
                      const SizedBox(width: 8),
                      _buildSupplierFilterChip('الكل', count: allSupplierOrders.length),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 4. جدول أذونات توريد الخامات الآجلة
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Row(
                  children: [
                    const Icon(Icons.table_chart_outlined, size: 20, color: AppTheme.wasteRed),
                    const SizedBox(width: 8),
                    Text(
                      'أذونات توريد الخامات الآجلة (${filteredOrders.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.wasteRedSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'إجمالي المتبقي علينا: ${_currencyFormat.format(filteredOrders.fold(0.0, (s, o) => s + o.remainingAmount))} ج.م',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.wasteRed),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (filteredOrders.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_outline, size: 48, color: AppTheme.successGreen),
                      SizedBox(height: 12),
                      Text('لا توجد أذونات توريد مطابقة للفلتر المحدد أو لا توجد مديونيات معلقة', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, tableConstraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: tableConstraints.maxWidth.clamp(980.0, double.infinity)),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.2), // رقم الإذن
                            1: FlexColumnWidth(1.0), // التاريخ
                            2: FlexColumnWidth(1.6), // المورد والمصنع
                            3: FlexColumnWidth(1.6), // الخامة والكمية
                            4: FlexColumnWidth(1.2), // إجمالي التوريد
                            5: FlexColumnWidth(1.1), // المسدد
                            6: FlexColumnWidth(1.4), // المتبقي (علينا)
                            7: FlexColumnWidth(1.1), // حالة السداد
                            8: FlexColumnWidth(1.4), // الإجراءات
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                              children: [
                                _tableHead('رقم الإذن'),
                                _tableHead('التاريخ'),
                                _tableHead('المورد والمصنع'),
                                _tableHead('الخامة والكمية'),
                                _tableHead('إجمالي التوريد'),
                                _tableHead('المسدد نقداً'),
                                _tableHead('المتبقي (علينا للمورد)'),
                                _tableHead('حالة السداد'),
                                _tableHead('الإجراءات'),
                              ],
                            ),
                            ...filteredOrders.map((ord) {
                              return TableRow(
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                ),
                                children: [
                                  // رقم الإذن
                                  _tableCellWidget(
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.receipt_long_outlined, size: 16, color: AppTheme.costPurple),
                                        const SizedBox(width: 4),
                                        Text(ord.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  // التاريخ
                                  _tableCell(DateFormat('yyyy/MM/dd').format(ord.date)),
                                  // المورد والمصنع
                                  _tableCellWidget(
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(ord.supplierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        if (ord.supplierFactory.isNotEmpty)
                                          Text(ord.supplierFactory, style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                                      ],
                                    ),
                                  ),
                                  // الخامة والكمية
                                  _tableCellWidget(
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(ord.rawMaterialName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryBlue)),
                                        Text(
                                          '${_numberFormat.format(ord.quantityKg)} كجم × ${_currencyFormat.format(ord.unitPrice)} ج.م',
                                          style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // إجمالي التوريد
                                  _tableCell('${_currencyFormat.format(ord.totalAmount)} ج.م', isBold: true, textColor: AppTheme.costPurple),
                                  // المسدد
                                  _tableCell('${_currencyFormat.format(ord.paidAmount)} ج.م', isBold: true, textColor: AppTheme.successGreen),
                                  // المتبقي (علينا للمورد)
                                  _tableCellWidget(
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: ord.remainingAmount > 0.01 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: ord.remainingAmount > 0.01 ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                                          ),
                                        ),
                                        child: Text(
                                          ord.remainingAmount > 0.01
                                              ? 'علينا: ${_currencyFormat.format(ord.remainingAmount)} ج.م'
                                              : 'خالص بالكامل',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: ord.remainingAmount > 0.01 ? const Color(0xFFDC2626) : const Color(0xFF166534),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // حالة السداد
                                  _tableCellWidget(
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: ord.isFullyPaid
                                              ? AppTheme.successGreenSoft
                                              : (ord.paidAmount > 0.01 ? AppTheme.profitAmberSoft : AppTheme.wasteRedSoft),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          ord.isFullyPaid
                                              ? '✓ مسدد بالكامل'
                                              : (ord.paidAmount > 0.01 ? '🔄 مسدد جزئياً' : '⏳ معلق بالكامل'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: ord.isFullyPaid
                                                ? AppTheme.successGreen
                                                : (ord.paidAmount > 0.01 ? AppTheme.profitAmber : AppTheme.wasteRed),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // الإجراءات
                                  _tableCellWidget(
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (!ord.isFullyPaid)
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.wasteRed,
                                              foregroundColor: Colors.white,
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              elevation: 1,
                                            ),
                                            icon: const Icon(Icons.payments_rounded, size: 14),
                                            label: const Text('سداد دفعة', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                            onPressed: () => _showPaySupplierDebtDialog(context, ord),
                                          ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primaryBlue),
                                          tooltip: 'تفاصيل إذن التوريد',
                                          onPressed: () => _showSupplierOrderDetailsDialog(context, ord),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(5),
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
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // نافذة تسجيل سداد دفعة نقدية (كاملة أو مجزأة) لمورد خامات
  // -------------------------------------------------------------
  void _showPaySupplierDebtDialog(BuildContext context, MaterialSupplyOrder order) {
    final amountCtrl = TextEditingController(text: order.remainingAmount.toStringAsFixed(2));
    final notesCtrl = TextEditingController();
    final personCtrl = TextEditingController(text: 'أمين الخزينة');
    String paymentMethod = 'نقدي كاش';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final enteredAmount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
          final isZero = enteredAmount <= 0;
          final isOverDebt = enteredAmount > (order.remainingAmount + 0.01);
          final newRemaining = (order.remainingAmount - enteredAmount).clamp(0.0, double.infinity);
          final willBeFullyPaid = newRemaining <= 0.01;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.wasteRedSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payments_rounded, color: AppTheme.wasteRed, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تسجيل سداد دفعة للمورد (خامات)',
                        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'إذن توريد رقم: ${order.invoiceNumber} - مورد: ${order.supplierName}',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 16),
                    // بطاقة بيانات إذن التوريد والمبالغ
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('المورد / الشركة:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              Text('${order.supplierName} (${order.supplierFactory})', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('الخامة الموردة والكمية:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              Text('${order.rawMaterialName} - ${_numberFormat.format(order.quantityKg)} كجم', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                            ],
                          ),
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('إجمالي قيمة التوريد:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              Text('${_currencyFormat.format(order.totalAmount)} ج.م', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('المسدد حتى الآن:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              Text('${_currencyFormat.format(order.paidAmount)} ج.م', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.wasteRedSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المتبقي علينا للمورد حالياً:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.wasteRed)),
                                Text(
                                  '${_currencyFormat.format(order.remainingAmount)} ج.م',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.wasteRed),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // إدخال مبلغ السداد
                    const Text('المبلغ المراد سداده الآن (ج.م) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.wasteRed),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.attach_money_rounded, color: AppTheme.wasteRed),
                        suffixText: 'ج.م',
                        hintText: 'أدخل المبلغ المسدد بالأجزاء أو كاملاً...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        errorText: isOverDebt
                            ? 'المبلغ يتجاوز المتبقي علينا (${_currencyFormat.format(order.remainingAmount)} ج.م)'
                            : (isZero ? 'يرجى إدخال مبلغ أكبر من الصفر' : null),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),

                    // أزرار سريعة للمبالغ
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.done_all, size: 14, color: AppTheme.successGreen),
                          label: const Text('سداد المتبقي كاملاً', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            amountCtrl.text = order.remainingAmount.toStringAsFixed(2);
                            setDialogState(() {});
                          },
                        ),
                        if (order.remainingAmount > 1000)
                          ActionChip(
                            label: const Text('سداد 50%', style: TextStyle(fontSize: 11)),
                            onPressed: () {
                              amountCtrl.text = (order.remainingAmount * 0.5).toStringAsFixed(2);
                              setDialogState(() {});
                            },
                          ),
                        if (order.remainingAmount > 2000)
                          ActionChip(
                            label: const Text('سداد 25%', style: TextStyle(fontSize: 11)),
                            onPressed: () {
                              amountCtrl.text = (order.remainingAmount * 0.25).toStringAsFixed(2);
                              setDialogState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // مؤشر ما بعد السداد
                    if (!isZero && !isOverDebt)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: willBeFullyPaid ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: willBeFullyPaid ? AppTheme.successGreen.withValues(alpha: 0.4) : AppTheme.profitAmber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              willBeFullyPaid ? Icons.check_circle_outline : Icons.pending_outlined,
                              size: 16,
                              color: willBeFullyPaid ? AppTheme.successGreen : AppTheme.profitAmber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                willBeFullyPaid
                                    ? '✓ سيتم تسديد كامل مديونية هذا التوريد وخلوص حسابه بالكامل.'
                                    : 'سيتبقى علينا للمورد بعد هذه الدفعة: ${_currencyFormat.format(newRemaining)} ج.م',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: willBeFullyPaid ? const Color(0xFF166534) : const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // طريقة السداد ومسؤول الصرف
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('طريقة السداد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: paymentMethod,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                items: const [
                                  DropdownMenuItem(value: 'نقدي كاش', child: Text('نقدي كاش من الخزينة', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'تحويل بنكي', child: Text('تحويل بنكي', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'شيك مصرفي', child: Text('شيك مصرفي', style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (v) {
                                  if (v != null) setDialogState(() => paymentMethod = v);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('المسؤول عن الصرف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: personCtrl,
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ملاحظات السداد
                    const Text('ملاحظات السداد (اختياري)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: notesCtrl,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'مثال: سداد بشيك رقم 4022 أو دفعة أسبوعية متفق عليها...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.wasteRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('تأكيد الصرف وسداد الدفعة', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: isOverDebt || isZero
                    ? null
                    : () {
                        widget.store.recordMaterialSupplyPayment(
                          order.id,
                          enteredAmount,
                          paymentMethod: paymentMethod,
                          person: personCtrl.text.trim().isNotEmpty ? personCtrl.text.trim() : 'أمين الخزينة',
                          notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                        );
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✓ تم تسجيل سداد دفعة بقيمة ${_currencyFormat.format(enteredAmount)} ج.م للمورد (${order.supplierName}) وخصمها من الخزينة بنجاح.'),
                            backgroundColor: AppTheme.successGreen,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // نافذة تفاصيل إذن التوريد
  // -------------------------------------------------------------
  void _showSupplierOrderDetailsDialog(BuildContext context, MaterialSupplyOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryBlue, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل إذن التوريد: ${order.invoiceNumber}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'تاريخ التوريد: ${DateFormat('yyyy/MM/dd hh:mm a').format(order.date)}',
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('المورد:', order.supplierName),
              _detailRow('المصنع التابع له:', order.supplierFactory),
              _detailRow('الخامة الموردة:', order.rawMaterialName),
              _detailRow('الكمية الموردة:', '${_numberFormat.format(order.quantityKg)} كجم'),
              _detailRow('سعر كيلو التوريد:', '${_currencyFormat.format(order.unitPrice)} ج.م'),
              const Divider(height: 16),
              _detailRow('إجمالي قيمة الفاتورة:', '${_currencyFormat.format(order.totalAmount)} ج.م', isBold: true),
              _detailRow('المبلغ المسدد:', '${_currencyFormat.format(order.paidAmount)} ج.م', color: AppTheme.successGreen),
              _detailRow(
                'المتبقي المستحق علينا للمورد:',
                '${_currencyFormat.format(order.remainingAmount)} ج.م',
                color: order.remainingAmount > 0.01 ? AppTheme.wasteRed : AppTheme.successGreen,
                isBold: true,
              ),
              _detailRow('طريقة السداد المسجلة:', order.paymentMethod),
              if (order.notes != null && order.notes!.isNotEmpty)
                _detailRow('ملاحظات:', order.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق'),
          ),
          if (!order.isFullyPaid)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.wasteRed,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.payments_rounded, size: 16),
              label: const Text('سداد دفعة للمورد'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _showPaySupplierDebtDialog(context, order);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSupplierFilterChip(String label, {required int count, bool isAlert = false}) {
    final isSelected = _selectedFilterSuppliers == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilterSuppliers = label),
      selectedColor: isAlert ? const Color(0xFFFEE2E2) : AppTheme.wasteRedSoft,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? (isAlert ? AppTheme.wasteRed : AppTheme.costPurple) : AppTheme.textPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _detailRow(String title, String val, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
          Text(
            val,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // نافذة تسجيل تحصيل دفعة نقدية
  // -------------------------------------------------------------
  void _showCollectPaymentDialog(BuildContext context, SaleOrder order) {
    final amountCtrl = TextEditingController(text: order.remainingAmount.toStringAsFixed(2));
    final notesCtrl = TextEditingController();
    final personCtrl = TextEditingController(text: 'مسؤول المبيعات');
    String paymentMethod = 'نقدي كاش';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final enteredAmount = double.tryParse(amountCtrl.text) ?? 0.0;
          final remainingAfter = (order.remainingAmount - enteredAmount).clamp(0.0, double.infinity);
          final isOverDebt = enteredAmount > order.remainingAmount + 0.01;
          final isZero = enteredAmount <= 0.0;

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreenSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.payments_rounded, color: AppTheme.successGreen, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'تسجيل تحصيل دفعة من الفاتورة الآجلة',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات الفاتورة
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'رقم الفاتورة: ${order.invoiceNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(order.saleType, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'العميل: ${order.customerName}',
                                  style: const TextStyle(fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('قيمة الفاتورة: ${_currencyFormat.format(order.totalAmount)} ج.م', style: const TextStyle(fontSize: 12.5)),
                            ],
                          ),
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'المحصل سابقاً: ${_currencyFormat.format(order.paidAmount)} ج.م',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.successGreen),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'المديونية المتبقية: ${_currencyFormat.format(order.remainingAmount)} ج.م',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // إدخال مبلغ التحصيل
                    const Text('المبلغ المحصل الآن (ج.م) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        suffixText: 'ج.م',
                        errorText: isOverDebt ? 'المبلغ أكبر من إجمالي المديونية المتبقية!' : null,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),

                    // أزرار الاختيار السريع للنسب
                    Row(
                      children: [
                        _quickAmountButton(
                          'كامل المتبقي (100%)',
                          order.remainingAmount,
                          amountCtrl,
                          setDialogState,
                        ),
                        const SizedBox(width: 8),
                        _quickAmountButton(
                          'نصف المتبقي (50%)',
                          order.remainingAmount * 0.5,
                          amountCtrl,
                          setDialogState,
                        ),
                        const SizedBox(width: 8),
                        _quickAmountButton(
                          'ربع المتبقي (25%)',
                          order.remainingAmount * 0.25,
                          amountCtrl,
                          setDialogState,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // طريقة التحصيل
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('طريقة الاستلام *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: paymentMethod,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                                items: const [
                                  DropdownMenuItem(value: 'نقدي كاش', child: Text('نقدي كاش (الخزنة)')),
                                  DropdownMenuItem(value: 'شيك مصرفي', child: Text('شيك مصرفي')),
                                  DropdownMenuItem(value: 'تحويل بنكي', child: Text('تحويل بنكي')),
                                  DropdownMenuItem(value: 'فودافون كاش / إنستاباي', child: Text('إنستاباي / محفظة')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setDialogState(() => paymentMethod = v);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('المستلم / أمين الخزنة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: personCtrl,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ملاحظات السداد
                    const Text('ملاحظات التحصيل (اختياري)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'مثال: سداد بشيك رقم 4022 أو دفعة أسبوعية متفق عليها',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // الرصيد بعد العملية
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: remainingAfter <= 0.01 ? const Color(0xFFF0FDF4) : const Color(0xFFFEFCE8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: remainingAfter <= 0.01 ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              remainingAfter <= 0.01 ? 'ستصبح الفاتورة مسددة بالكامل (0 متبقي) ✓' : 'المتبقي على العميل بعد هذه الدفعة:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: remainingAfter <= 0.01 ? const Color(0xFF15803D) : const Color(0xFF92400E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_currencyFormat.format(remainingAfter)} ج.م',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: remainingAfter <= 0.01 ? const Color(0xFF15803D) : const Color(0xFF92400E),
                            ),
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
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOverDebt || isZero ? Colors.grey : AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('تأكيد التحصيل وإيداع الخزنة', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: isOverDebt || isZero
                    ? null
                    : () {
                        widget.store.recordOrderPayment(
                          order.id,
                          enteredAmount,
                          paymentMethod: paymentMethod,
                          person: personCtrl.text.trim().isNotEmpty ? personCtrl.text.trim() : 'مسؤول المبيعات',
                          notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                        );
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✓ تم تسجيل تحصيل دفعة بقيمة ${_currencyFormat.format(enteredAmount)} ج.م بنجاح وإيداعها في الخزينة.'),
                            backgroundColor: AppTheme.successGreen,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quickAmountButton(String label, double amount, TextEditingController ctrl, StateSetter setDialogState) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () {
          setDialogState(() {
            ctrl.text = amount.toStringAsFixed(2);
          });
        },
        child: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ),
    );
  }

  // -------------------------------------------------------------
  // نافذة تأكيد حذف الفاتورة مع استرجاع المخزون
  // -------------------------------------------------------------
  void _showDeleteOrderDialog(BuildContext context, SaleOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppTheme.wasteRed, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'تأكيد حذف فاتورة الآجل',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من رغبتك في حذف الفاتورة رقم: "${order.invoiceNumber}"؟'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• العميل: ${order.customerName}', style: const TextStyle(fontSize: 12)),
                  Text('• إجمالي الفاتورة: ${_currencyFormat.format(order.totalAmount)} ج.م', style: const TextStyle(fontSize: 12)),
                  Text('• المديونية المتبقية الملغاة: ${_currencyFormat.format(order.remainingAmount)} ج.م', style: const TextStyle(fontSize: 12, color: AppTheme.wasteRed, fontWeight: FontWeight.bold)),
                  Text('• إجمالي الوزن المسترجع للمخزن: ${_numberFormat.format(order.totalWeightKg)} كجم', style: const TextStyle(fontSize: 12, color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '⚠️ تنبيه: سيتم تلقائياً إرجاع كافة الكميات المباعة إلى رصيد المخزون، وخصم المديونية المتبقية من حساب العميل/الموزع.',
              style: TextStyle(fontSize: 11.5, color: AppTheme.wasteRed),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.wasteRed, foregroundColor: Colors.white),
            onPressed: () {
              widget.store.deleteSaleOrder(order.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ تم حذف الفاتورة بنجاح وإرجاع البضاعة للمخزن وتعديل الرصيد.'), backgroundColor: AppTheme.wasteRed),
              );
            },
            child: const Text('نعم، احذف الفاتورة'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // حفظ الفاتورة كـ PDF
  // -------------------------------------------------------------
  Future<void> _saveInvoicePdf(BuildContext context, SaleOrder order) async {
    try {
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

      if (context.mounted) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حفظ فاتورة PDF بنجاح في:\n$path'),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم حفظ الملف أو تم الإلغاء.'),
              backgroundColor: AppTheme.profitAmber,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء حفظ الفاتورة: $e'),
            backgroundColor: AppTheme.wasteRed,
          ),
        );
      }
    }
  }

  // -------------------------------------------------------------
  // طباعة الفاتورة
  // -------------------------------------------------------------
  Future<void> _printInvoice(BuildContext context, SaleOrder order) async {
    await PdfReportService.printInvoice(store: widget.store, order: order);
  }

  // -------------------------------------------------------------
  // تصدير كشف الآجل إلى PDF
  // -------------------------------------------------------------
  Future<void> _exportCreditPdf(BuildContext context, List<SaleOrder> orders) async {
    final totalRev = orders.fold(0.0, (s, o) => s + o.totalAmount);
    final totalKg = orders.fold(0.0, (s, o) => s + o.totalWeightKg);
    final totalProfit = orders.fold(0.0, (s, o) => s + o.totalProfit);

    final doc = await PdfReportService.generateComprehensiveReport(
      store: widget.store,
      orders: orders,
      period: 'فواتير الآجل والمديونيات',
      saleType: _selectedFilter,
      productName: 'كافة الأصناف',
      totalRevenue: totalRev,
      totalWeightKg: totalKg,
      totalProfit: totalProfit,
      laborElectricityCost: orders.fold(0.0, (s, o) => s + (o.totalWeightKg * 2.0)),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: 'كشف_المبيعات_الآجلة_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
  }

  // -------------------------------------------------------------
  // أزرار الترويسة الرئيسية
  // -------------------------------------------------------------
  Widget _buildHeaderActions(BuildContext context, List<SaleOrder> filteredOrders) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
          ),
          icon: const Icon(Icons.picture_as_pdf, size: 18),
          label: const Text('تصدير كشف الآجل (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _exportCreditPdf(context, filteredOrders),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('تحديث القائمة'),
          onPressed: () => setState(() {}),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // بناء كارت مؤشر أداء
  // -------------------------------------------------------------
  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
    String? badge,
    double? progress,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (badge != null)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        badge,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      value,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: bg,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // فلتر الشريحة
  // -------------------------------------------------------------
  Widget _buildFilterChip(String label, {required int count, bool isAlert = false}) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = label),
      selectedColor: isAlert ? const Color(0xFFFEE2E2) : AppTheme.primaryBlueSoft,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? (isAlert ? AppTheme.wasteRed : AppTheme.primaryBlue) : AppTheme.textPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  // -------------------------------------------------------------
  // أدوات مساعدة للجدول
  // -------------------------------------------------------------
  Widget _tableHead(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _tableCell(String text, {Color textColor = AppTheme.textPrimary, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, color: textColor, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _tableCellWidget(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: child,
    );
  }
}
