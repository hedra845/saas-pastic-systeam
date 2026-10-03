import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/product_item.dart';
import '../state/factory_store.dart';
import 'dialogs/add_product_dialog.dart';
import 'dialogs/add_product_stock_dialog.dart';

class ProductsView extends StatefulWidget {
  final FactoryStore store;

  const ProductsView({super.key, required this.store});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  String _formatNumber(num value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    // فلترة الأصناف حسب البحث والتصنيف
    final filteredProducts = store.products.where((p) {
      final matchesSearch = p.name.contains(_searchQuery) ||
          p.materialType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.contains(_searchQuery);
      final matchesCat = _selectedCategory == 'الكل'
          ? true
          : (_selectedCategory == 'أصناف قاربت على النفاذ'
              ? p.hasStockAlert
              : p.category == _selectedCategory);
      return matchesSearch && matchesCat;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط تنبيه الأصناف التي قاربت على النفاذ
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
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تنبيه نفاذ المخزون: يوجد ${store.stockAlertCount} صنف قارب على النفاذ أو نفذ رصيده من المستودع!',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          store.stockAlertProducts.map((p) => '${p.name} (${_formatNumber(p.stockKg)} كجم متبقي)').join(' • '),
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // -------------------------------------------------------------
          // 1. ترويسة الشاشة وزر الإضافة
          // -------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'إدارة أصناف أكياس البلاستيك والمخزون',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'تتبع دقيق لكل صنف: إجمالي الكمية، المصروفات والتكاليف، وصافي المكسب والأرباح',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successGreen,
                      side: const BorderSide(color: AppTheme.successGreen),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_business_rounded, size: 18),
                    label: const Text('إضافة مخزون لصنف', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddProductStockDialog(store: store),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('إضافة صنف جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddProductDialog(store: store),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // -------------------------------------------------------------
          // 2. كروت ملخص عام للأصناف (إجمالي الكيلوات، تكلفة الخامات، مصروفات إدارية، المكسب)
          // -------------------------------------------------------------
          LayoutBuilder(
            builder: (context, constraints) {
              final rawCost = store.products.fold(0.0, (s, p) => s + p.rawMaterialExpenses);
              final adminCost = store.products.fold(0.0, (s, p) => s + p.laborAndElectricityExpenses);

              final cards = [
                _buildSummaryCard(
                  title: 'إجمالي الأصناف',
                  value: '${store.products.length} أصناف',
                  icon: Icons.category_outlined,
                  color: AppTheme.primaryBlue,
                  bg: AppTheme.primaryBlueSoft,
                ),
                _buildSummaryCard(
                  title: 'عدد المخزون',
                  value: '${_formatNumber(store.totalStockKg)} كجم',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF0284C7),
                  bg: const Color(0xFFF0F9FF),
                ),
                _buildSummaryCard(
                  title: 'تكلفة الخامات',
                  value: '${_formatNumber(rawCost)} ج.م',
                  icon: Icons.grain,
                  color: AppTheme.primaryBlue,
                  bg: AppTheme.primaryBlueSoft,
                ),
                _buildSummaryCard(
                  title: 'مصروفات إدارية',
                  value: '${_formatNumber(adminCost)} ج.م',
                  icon: Icons.business_outlined,
                  color: AppTheme.costPurple,
                  bg: AppTheme.costPurpleSoft,
                ),
                _buildSummaryCard(
                  title: 'صافي المكسب (المبيعات)',
                  value: '${_formatNumber(store.actualSalesGrossProfit)} ج.م',
                  icon: Icons.trending_up_rounded,
                  color: AppTheme.successGreen,
                  bg: AppTheme.successGreenSoft,
                ),
              ];

              return Row(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i < cards.length - 1) const SizedBox(width: 14),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // -------------------------------------------------------------
          // 3. شريط البحث والفلترة حسب الفئة
          // -------------------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'بحث باسم الصنف أو الخامة (مثال: أكياس تسوق، HDPE، قمامة...)',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.borderSubtle),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('الفئة:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  Builder(
                    builder: (context) {
                      final availableCategories = <String>{'الكل', 'أصناف قاربت على النفاذ'};
                      for (final p in store.products) {
                        if (p.category.trim().isNotEmpty) {
                          availableCategories.add(p.category.trim());
                        }
                      }
                      // إضافة فئات شائعة إضافية
                      availableCategories.addAll(['أكياس', 'شنط تسوق', 'أكياس قمامة', 'رولات تغليف', 'أكياس شفافة']);

                      final currentSelected = availableCategories.contains(_selectedCategory)
                          ? _selectedCategory
                          : 'الكل';

                      return DropdownButton<String>(
                        value: currentSelected,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(8),
                        items: availableCategories.map((cat) {
                          String label = cat;
                          if (cat == 'الكل') label = 'جميع الفئات';
                          if (cat == 'أصناف قاربت على النفاذ') label = '⚠️ أصناف قاربت على النفاذ';
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // -------------------------------------------------------------
          // 4. جدول وتفاصيل الأصناف الكاملة
          // -------------------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'قائمة الأصناف التفصيلية (${filteredProducts.length} صنف)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const Text(
                        '* الأرباح والمصروفات محسوبة بناءً على تكلفة الإنتاج وسعر بيع الكيلو',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // جدول الأصناف
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2.5), // الصنف والمقاس
                      1: FlexColumnWidth(1.0), // الخامة
                      2: FlexColumnWidth(1.5), // الكمية الإجمالية
                      3: FlexColumnWidth(1.6), // تكلفة الخامات
                      4: FlexColumnWidth(1.6), // مصروفات إدارية
                      5: FlexColumnWidth(1.3), // سعر الكيلو
                      6: FlexColumnWidth(1.7), // المكسب قد ايه
                      7: FlexColumnWidth(1.3), // المخزون
                      8: FlexColumnWidth(1.8), // إجراءات
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: AppTheme.background,
                          border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                        ),
                        children: [
                          _tableHeader('الصنف والمواصفات'),
                          _tableHeader('الخامة'),
                          _tableHeader('الكمية الإجمالية'),
                          _tableHeader('تكلفة الخامات'),
                          _tableHeader('مصروفات إدارية'),
                          _tableHeader('سعر الكيلو'),
                          _tableHeader('صافي المكسب'),
                          _tableHeader('المخزون'),
                          _tableHeader('إجراءات'),
                        ],
                      ),
                      ...filteredProducts.map((p) => _buildProductRow(p, store)),
                    ],
                  ),
                  if (filteredProducts.isEmpty) ...[
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlueSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.inventory_2_outlined, size: 32, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'لا توجد أصناف مسجلة حتى الآن',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'يمكنك إضافة صنف جديد مع تحديد كميات الإنتاج والمخزون والتكاليف وأسعار البيع',
                            style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('إضافة أول صنف الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AddProductDialog(store: store),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildProductRow(ProductItem p, FactoryStore store) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      children: [
        // اسم الصنف وتاريخ الإضافة الأولى
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                p.notes ?? p.category,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.event_available_rounded, size: 12, color: AppTheme.primaryBlue),
                  const SizedBox(width: 4),
                  Text(
                    'الإضافة الأولى: ${DateFormat('yyyy/MM/dd').format(p.createdAt)}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                ],
              ),
              if (p.stockAdditions.isNotEmpty && p.stockAdditions.length > 1) ...[
                const SizedBox(height: 1),
                Text(
                  'آخر إضافة مخزون: ${DateFormat('yyyy/MM/dd').format(p.stockAdditions.last.date)} (+${p.stockAdditions.last.quantityKg.toStringAsFixed(0)} كجم)',
                  style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary),
                ),
              ],
            ],
          ),
        ),

        // الخامة
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Center(
            child: p.materialType.trim().isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Text(
                      p.materialType,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  )
                : const Text('-', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ),
        ),

        // كم كيلو إنتاج
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${_formatNumber(p.totalProducedKg)} كجم',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 2),
              Builder(
                builder: (context) {
                  final sold = store.getSoldKgForProduct(p.id);
                  if (sold > 0) {
                    return Text(
                      'المباع: ${_formatNumber(sold)} كجم',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                    );
                  }
                  return Text(
                    'الكمية: ${_formatNumber(p.totalProducedKg)} كجم',
                    style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                  );
                },
              ),
            ],
          ),
        ),

        // خانة تكلفة الخامات
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${_formatNumber(p.rawMaterialExpenses)} ج.م',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 2),
              Text(
                'خامة: ${p.rawMaterialCostPerKg.toStringAsFixed(2)} ج/كجم',
                style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),

        // خانة مصروفات إدارية وتشغيلية
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${_formatNumber(p.laborAndElectricityExpenses)} ج.م',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.costPurple),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Text(
                  '${p.laborAndElectricityCostPerKg.toStringAsFixed(2)} ج/كجم',
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                ),
              ),
            ],
          ),
        ),

        // سعر الكيلو
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'جملة: ${p.wholesalePricePerKg.toStringAsFixed(2)} ج',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 2),
              Text(
                'قطاعي: ${p.retailPricePerKg.toStringAsFixed(2)} ج',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
              ),
            ],
          ),
        ),

        // صافي المكسب الذي تم بيعه (جملة أو قطاعي)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
          child: Builder(
            builder: (context) {
              final soldTotal = store.getSoldKgForProduct(p.id);
              final wholesaleSold = store.getWholesaleSoldKgForProduct(p.id);
              final retailSold = store.getRetailSoldKgForProduct(p.id);
              final wholesaleProfit = store.getRealizedWholesaleProfitForProduct(p.id);
              final retailProfit = store.getRealizedRetailProfitForProduct(p.id);
              final totalRealizedProfit = store.getRealizedProfitForProduct(p.id);

              if (soldTotal <= 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'لم يُباع منه بعد',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ربح كجم جملة: +${p.wholesaleProfitPerKg.toStringAsFixed(2)} ج',
                      style: const TextStyle(fontSize: 9.5, color: AppTheme.primaryBlue),
                    ),
                    Text(
                      'ربح كجم قطاعي: +${p.retailProfitPerKg.toStringAsFixed(2)} ج',
                      style: const TextStyle(fontSize: 9.5, color: AppTheme.successGreen),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (wholesaleSold > 0)
                    Text(
                      'مكسب جملة: +${_formatNumber(wholesaleProfit)} ج',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: wholesaleProfit >= 0 ? AppTheme.primaryBlue : AppTheme.wasteRed,
                      ),
                    ),
                  if (retailSold > 0) ...[
                    if (wholesaleSold > 0) const SizedBox(height: 2),
                    Text(
                      'مكسب قطاعي: +${_formatNumber(retailProfit)} ج',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: retailProfit >= 0 ? AppTheme.successGreen : AppTheme.wasteRed,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: totalRealizedProfit >= 0 ? AppTheme.successGreenSoft : AppTheme.wasteRedSoft,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: totalRealizedProfit >= 0
                            ? AppTheme.successGreen.withValues(alpha: 0.3)
                            : AppTheme.wasteRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'إجمالي المكسب: ${_formatNumber(totalRealizedProfit)} ج',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: totalRealizedProfit >= 0 ? AppTheme.successGreen : AppTheme.wasteRed,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // المخزون الفعلي بالمستودع
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_formatNumber(p.stockKg)} كجم',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: p.isOutOfStock
                      ? AppTheme.wasteRed
                      : (p.isLowStock ? const Color(0xFFB45309) : AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 3),
              if (p.isOutOfStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.wasteRedSoft,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.wasteRed.withValues(alpha: 0.3)),
                  ),
                  child: const Text('نافذ تماماً', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.wasteRed)),
                )
              else if (p.isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                  ),
                  child: const Text('قارب على النفاذ ⚠️', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreenSoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('متوفر', style: TextStyle(fontSize: 9.5, color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddProductStockDialog(store: store, initialProduct: p),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueSoft,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add, size: 10, color: AppTheme.primaryBlue),
                      SizedBox(width: 2),
                      Text('+ مخزون', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // إجراءات سريعة
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'إضافة مخزون وسجل التواريخ',
                icon: const Icon(Icons.playlist_add_rounded, color: AppTheme.primaryBlue, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddProductStockDialog(store: store, initialProduct: p),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
              IconButton(
                tooltip: 'تعديل الصنف',
                icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary, size: 18),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddProductDialog(store: store, productToEdit: p),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
              IconButton(
                tooltip: 'حذف الصنف',
                icon: const Icon(Icons.delete, color: AppTheme.wasteRed, size: 18),
                onPressed: () async {
                  final usage = store.getProductUsageReasons(p.id);
                  if (usage.isNotEmpty) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('تحذير: الصنف مستخدم'),
                        content: Text('هذا الصنف موجود في: ${usage.join(', ')}.\nهل تريد المتابعة بالحذف؟'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('إلغاء'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('متابعة'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      store.deleteProduct(p.id);
                    }
                  } else {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('تأكيد الحذف'),
                        content: const Text('هل أنت متأكد من حذف الصنف؟'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('إلغاء'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('نعم'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      store.deleteProduct(p.id);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
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
                  Text(
                    value,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                    overflow: TextOverflow.ellipsis,
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
