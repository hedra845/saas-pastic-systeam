import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../theme/app_theme.dart';
import '../state/factory_store.dart';
import '../models/material_supply_order.dart';
import '../models/supplier.dart';

class MaterialSuppliesView extends StatefulWidget {
  final FactoryStore store;

  const MaterialSuppliesView({super.key, required this.store});

  @override
  State<MaterialSuppliesView> createState() => _MaterialSuppliesViewState();
}

class _MaterialSuppliesViewState extends State<MaterialSuppliesView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedSupplierFilter;
  String? _selectedMaterialFilter;

  String _formatNumber(num val) {
    final formatter = NumberFormat('#,##0.##', 'en_US');
    return formatter.format(val);
  }

  String _formatCurrency(num val) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(val);
  }

  String _formatDate(DateTime dt) {
    return DateFormat('yyyy/MM/dd - hh:mm a', 'en_US').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final allOrders = store.materialSupplyOrders;

    // تصفية الأوامر حسب البحث والفلاتر
    final filteredOrders = allOrders.where((order) {
      final query = _searchCtrl.text.trim().toLowerCase();
      final matchQuery = query.isEmpty ||
          order.invoiceNumber.toLowerCase().contains(query) ||
          order.supplierName.toLowerCase().contains(query) ||
          order.supplierFactory.toLowerCase().contains(query) ||
          order.rawMaterialName.toLowerCase().contains(query);

      final matchSupplier = _selectedSupplierFilter == null || order.supplierId == _selectedSupplierFilter;
      final matchMaterial = _selectedMaterialFilter == null || order.rawMaterialId == _selectedMaterialFilter;

      return matchQuery && matchSupplier && matchMaterial;
    }).toList();

    // إحصائيات سريعة
    final totalWeightKg = allOrders.fold(0.0, (s, o) => s + o.quantityKg);
    final totalAmount = allOrders.fold(0.0, (s, o) => s + o.totalAmount);
    final updatedPricesCount = allOrders.where((o) => o.updatedBasePrice).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس الصفحة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'توريدات المواد الخام والبوليمر',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'تسجيل أذونات استلام المواد الخام، تحديث أسعار الكيلو الأساسية، ومتابعة مديونيات وحسابات الموردين',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add_shopping_cart_outlined, size: 20),
                label: const Text('إذن توريد خامة جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () => _showAddSupplyDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // كروت الإحصائيات الأربعة
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'إجمالي كميات التوريد',
                  totalWeightKg >= 1000
                      ? '${_formatNumber(totalWeightKg / 1000)} طن (${_formatNumber(totalWeightKg)} كجم)'
                      : '${_formatNumber(totalWeightKg)} كجم',
                  Icons.scale_outlined,
                  AppTheme.primaryBlue,
                  AppTheme.primaryBlueSoft,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard(
                  'إجمالي قيمة التوريدات',
                  '${_formatCurrency(totalAmount)} ج.م',
                  Icons.account_balance_wallet_outlined,
                  AppTheme.costPurple,
                  AppTheme.costPurpleSoft,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard(
                  'عدد أذونات التوريد',
                  '${allOrders.length} إذن',
                  Icons.receipt_long_outlined,
                  AppTheme.profitAmber,
                  AppTheme.profitAmberSoft,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard(
                  'تحديثات سعر الأساس',
                  '$updatedPricesCount خامات حدثت',
                  Icons.trending_up,
                  AppTheme.successGreen,
                  AppTheme.successGreenSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // شريط البحث والفلترة
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'بحث برقم الإذن، اسم المورد، المصنع، أو اسم الخامة...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // تصفية حسب المورد
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedSupplierFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'تصفية بالمورد',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('جميع الموردين', style: TextStyle(fontSize: 12.5))),
                        ...store.suppliers.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.name} (${s.companyName})', style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) => setState(() => _selectedSupplierFilter = v),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // تصفية حسب الخامة
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedMaterialFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'تصفية بالخامة',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('جميع الخامات', style: TextStyle(fontSize: 12.5))),
                        ...store.rawMaterials.map((r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(r.name, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) => setState(() => _selectedMaterialFilter = v),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty || _selectedSupplierFilter != null || _selectedMaterialFilter != null) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.filter_alt_off_outlined, color: AppTheme.wasteRed),
                      tooltip: 'إلغاء التصفية',
                      onPressed: () {
                        setState(() {
                          _searchCtrl.clear();
                          _selectedSupplierFilter = null;
                          _selectedMaterialFilter = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // جدول أذونات التوريد
          if (filteredOrders.isEmpty)
            Card(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlueSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inventory_2_outlined, size: 44, color: AppTheme.primaryBlue),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'لا توجد أذونات توريد مسجلة حتى الآن',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'سجل أذونات استلام المواد الخام لزيادة رصيد المستودع وتحديث أسعار التكلفة تلقائياً',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('تسجيل أول إذن توريد', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddSupplyDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'سجل أذونات توريد المواد الخام والبوليمر',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Text(
                          'العدد: ${filteredOrders.length} إذن',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.4), // رقم الإذن والتاريخ
                        1: FlexColumnWidth(1.9), // المورد والمصنع
                        2: FlexColumnWidth(1.8), // الخامة
                        3: FlexColumnWidth(1.3), // الكمية
                        4: FlexColumnWidth(1.7), // سعر الكيلو
                        5: FlexColumnWidth(1.5), // الإجمالي
                        6: FlexColumnWidth(1.3), // طريقة السداد
                        7: FlexColumnWidth(1.3), // إجراءات
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: AppTheme.background,
                            border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                          ),
                          children: [
                            _headerCell('رقم الإذن / التاريخ'),
                            _headerCell('المورد والمصنع التابع له'),
                            _headerCell('الخامة الموردة'),
                            _headerCell('الكمية (كجم)'),
                            _headerCell('سعر كيلو التوريد'),
                            _headerCell('إجمالي القيمة'),
                            _headerCell('طريقة السداد'),
                            _headerCell('إجراءات'),
                          ],
                        ),
                        ...filteredOrders.map((ord) {
                          return TableRow(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                            ),
                            children: [
                              // رقم الإذن والتاريخ
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(ord.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.primaryBlue)),
                                    const SizedBox(height: 2),
                                    Text(_formatDate(ord.date), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted), textAlign: TextAlign.center),
                                  ],
                                ),
                              ),

                              // المورد والمصنع
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(ord.supplierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.textPrimary)),
                                    if (ord.supplierFactory.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.costPurpleSoft,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            ord.supplierFactory,
                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.costPurple),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // الخامة الموردة
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                                child: Center(
                                  child: Text(
                                    ord.rawMaterialName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),

                              // الكمية الموردة
                              _textCell('${_formatNumber(ord.quantityKg)} كجم', isBold: true),

                              // سعر كيلو التوريد وتأثيره على سعر الأساس
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${_formatCurrency(ord.unitPrice)} ج.م',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                    if (ord.updatedBasePrice)
                                      Container(
                                        margin: const EdgeInsets.only(top: 3),
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreenSoft,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                                        ),
                                        child: const Text(
                                          '✓ حُدّث كسعر أساس',
                                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // إجمالي القيمة
                              _textCell('${_formatCurrency(ord.totalAmount)} ج.م', isBold: true, color: AppTheme.costPurple),

                              // طريقة السداد
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ord.remainingAmount == 0
                                          ? AppTheme.successGreenSoft
                                          : (ord.paidAmount == 0 ? AppTheme.wasteRedSoft : AppTheme.profitAmberSoft),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      ord.paymentMethod,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: ord.remainingAmount == 0
                                            ? AppTheme.successGreen
                                            : (ord.paidAmount == 0 ? AppTheme.wasteRed : AppTheme.profitAmber),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // إجراءات (عرض / تعديل / حذف)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 17, color: AppTheme.primaryBlue),
                                      tooltip: 'عرض تفاصيل الإذن',
                                      onPressed: () => _showOrderDetails(context, ord),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(5),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 17, color: AppTheme.profitAmber),
                                      tooltip: 'تعديل إذن التوريد',
                                      onPressed: () => _showEditSupplyDialog(context, ord),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(5),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 17, color: AppTheme.wasteRed),
                                      tooltip: 'إلغاء وحذف الإذن',
                                      onPressed: () => _confirmDeleteOrder(context, ord),
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
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // نافذة إضافة مورد سريعاً مباشرة من داخل نافذة التوريد
  // ----------------------------------------------------
  Future<Supplier?> _showQuickAddSupplierDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final customMatCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final selectedMaterials = <String>{};

    final availableMaterials = widget.store.products
        .map((p) => p.name.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();

    return showDialog<Supplier?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setQuickState) => Dialog(
          backgroundColor: AppTheme.surfaceWhite,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.costPurpleSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person_add_outlined, color: AppTheme.costPurple, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'إضافة مورد جديد سريعاً',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(null),
                          icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    const Text('اسم المورد / المسؤول *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'مثال: م/ محمود سامي',
                        prefixIcon: const Icon(Icons.person_outline, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل اسم المورد' : null,
                    ),
                    const SizedBox(height: 12),
                    const Text('المصنع التابع له (اختياري)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: companyCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'مثال: مصنع سابك، إيثيدكو...',
                        prefixIcon: const Icon(Icons.factory_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('الخامات أو الأصناف الموردة (اختياري)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 5),
                    if (availableMaterials.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: availableMaterials.map((item) {
                          final isSelected = selectedMaterials.contains(item);
                          return InkWell(
                            onTap: () {
                              setQuickState(() {
                                if (isSelected) {
                                  selectedMaterials.remove(item);
                                } else {
                                  selectedMaterials.add(item);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryBlue : AppTheme.background,
                                border: Border.all(color: isSelected ? AppTheme.primaryBlue : AppTheme.borderSubtle),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextFormField(
                      controller: customMatCtrl,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'أو اكتب خامة أخرى...',
                        prefixIcon: const Icon(Icons.edit_note_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('رقم الهاتف (اختياري)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'مثال: 01012345678',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: const Text('إلغاء'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.costPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('حفظ واختيار المورد', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              if (customMatCtrl.text.trim().isNotEmpty) {
                                selectedMaterials.add(customMatCtrl.text.trim());
                              }
                              if (selectedMaterials.isEmpty) {
                                selectedMaterials.add('مواد خام وبوليمر');
                              }
                              final sName = nameCtrl.text.trim();
                              final sCompany = companyCtrl.text.trim().isNotEmpty ? companyCtrl.text.trim() : sName;
                              final newSup = Supplier(
                                id: 'sup-${DateTime.now().millisecondsSinceEpoch}',
                                name: sName,
                                companyName: sCompany,
                                materialSupplied: selectedMaterials.join('، '),
                                materials: selectedMaterials.toList(),
                                phone: phoneCtrl.text.trim(),
                                address: '',
                                currentBalance: 0.0,
                                totalPurchasesKg: 0.0,
                              );
                              Navigator.of(ctx).pop(newSup);
                              widget.store.addSupplier(newSup);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // نافذة إضافة إذن توريد خامة جديد مع تحديث سعر الأساس
  // ----------------------------------------------------
  void _showAddSupplyDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final store = widget.store;

    Supplier? selectedSupplier = store.suppliers.isNotEmpty ? store.suppliers.first : null;

    // الخامات المرتبطة بالمورد المختار (بدون تكرار)
    List<String> getMaterialsForSupplier(Supplier? sup) {
      if (sup == null) return [];
      return sup.suppliedMaterials.map((m) => m.trim()).where((m) => m.isNotEmpty).toSet().toList();
    }

    double getBaseCost(String? matName) {
      if (matName == null || matName.trim().isEmpty) return 0.0;
      final clean = matName.trim().toLowerCase();
      // 1. البحث في قائمة الأصناف والمخزون أولاً
      for (final prod in store.products) {
        final cleanPName = prod.name.trim().toLowerCase();
        final cleanMat = prod.materialType.trim().toLowerCase();
        if (cleanPName == clean ||
            (cleanMat.isNotEmpty && cleanMat == clean) ||
            cleanPName.contains(clean) ||
            clean.contains(cleanPName)) {
          if (prod.rawMaterialCostPerKg > 0) return prod.rawMaterialCostPerKg;
          if (prod.totalProducedKg > 0 && prod.rawMaterialExpenses > 0) {
            return prod.rawMaterialExpenses / prod.totalProducedKg;
          }
          if (prod.costPerKg > 0) return prod.costPerKg;
        }
      }
      // 2. البحث في الخامات الأولية
      for (final rm in store.rawMaterials) {
        final cleanRm = rm.name.trim().toLowerCase();
        if (cleanRm == clean || cleanRm.contains(clean) || clean.contains(cleanRm)) {
          return rm.unitCost;
        }
      }
      return 0.0;
    }

    double getCurrentStock(String? matName) {
      if (matName == null || matName.trim().isEmpty) return 0.0;
      final clean = matName.trim().toLowerCase();
      for (final prod in store.products) {
        final cleanPName = prod.name.trim().toLowerCase();
        final cleanMat = prod.materialType.trim().toLowerCase();
        if (cleanPName == clean ||
            (cleanMat.isNotEmpty && cleanMat == clean) ||
            cleanPName.contains(clean) ||
            clean.contains(cleanPName)) {
          return prod.stockKg;
        }
      }
      for (final rm in store.rawMaterials) {
        final cleanRm = rm.name.trim().toLowerCase();
        if (cleanRm == clean || cleanRm.contains(clean) || clean.contains(cleanRm)) {
          return rm.currentStock;
        }
      }
      return 0.0;
    }

    List<String> currentSupplierMaterials = getMaterialsForSupplier(selectedSupplier);
    String? chosenMaterial = currentSupplierMaterials.isNotEmpty ? currentSupplierMaterials.first : null;
    final customMatCtrl = TextEditingController(text: chosenMaterial ?? '');

    final initialCost = getBaseCost(chosenMaterial);
    final invoiceCtrl = TextEditingController(text: 'SUP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final qtyCtrl = TextEditingController(text: '');
    final priceCtrl = TextEditingController(text: initialCost > 0 ? initialCost.toStringAsFixed(2) : '');
    final notesCtrl = TextEditingController();

    bool updateBasePrice = true;
    String paymentType = 'credit'; // 'credit': آجل بالكامل, 'cash': كاش كامل من الخزينة

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final double qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
          final double unitPrice = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
          final double totalAmount = qty * unitPrice;

          final double currentBaseCost = getBaseCost(chosenMaterial);
          final bool priceDiffers = (unitPrice - currentBaseCost).abs() > 0.001;

          // حساب المبالغ (إما آجل بالكامل أو كاش بالكامل)
          final double paidAmount = paymentType == 'cash' ? totalAmount : 0.0;
          final double remainingAmount = paymentType == 'cash' ? 0.0 : totalAmount;

          return Dialog(
            backgroundColor: AppTheme.surfaceWhite,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // رأس الحوار
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlueSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_shopping_cart_outlined, color: AppTheme.primaryBlue, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'تسجيل إذن توريد مواد خام جديد',
                                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'إضافة كميات للمخزن مع إمكانية تحديث سعر كيلو الخامة الأساسي تلقائياً',
                                  style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
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
                      const Divider(height: 24),

                      // اختيار المورد
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('المورد *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                ),
                                icon: const Icon(Icons.person_add_alt_1_outlined, size: 16, color: AppTheme.primaryBlue),
                                label: const Text('إضافة مورد جديد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                onPressed: () async {
                                  final added = await _showQuickAddSupplierDialog(context);
                                  if (added != null) {
                                    setDialogState(() {
                                      selectedSupplier = added;
                                      currentSupplierMaterials = getMaterialsForSupplier(added);
                                      chosenMaterial = currentSupplierMaterials.isNotEmpty ? currentSupplierMaterials.first : '';
                                      customMatCtrl.text = chosenMaterial ?? '';
                                      final cost = getBaseCost(chosenMaterial);
                                      if (cost > 0) {
                                        priceCtrl.text = cost.toStringAsFixed(2);
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          if (store.suppliers.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.profitAmberSoft,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.profitAmber.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: AppTheme.profitAmber, size: 18),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'لا يوجد موردون مسجلون بعد. اضغط على الزر لإضافة المورد أولاً.',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.costPurple,
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    icon: const Icon(Icons.add, size: 14),
                                    label: const Text('إضافة مورد', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    onPressed: () async {
                                      final added = await _showQuickAddSupplierDialog(context);
                                      if (added != null) {
                                        setDialogState(() {
                                          selectedSupplier = added;
                                          currentSupplierMaterials = getMaterialsForSupplier(added);
                                          chosenMaterial = currentSupplierMaterials.isNotEmpty ? currentSupplierMaterials.first : '';
                                          customMatCtrl.text = chosenMaterial ?? '';
                                          final cost = getBaseCost(chosenMaterial);
                                          if (cost > 0) {
                                            priceCtrl.text = cost.toStringAsFixed(2);
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<Supplier>(
                              value: selectedSupplier,
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.person_outline, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              items: store.suppliers.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    '${s.name} - ${s.companyName}',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              validator: (v) => v == null ? 'يرجى اختيار المورد' : null,
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() {
                                    selectedSupplier = v;
                                    currentSupplierMaterials = getMaterialsForSupplier(v);
                                    chosenMaterial = currentSupplierMaterials.isNotEmpty ? currentSupplierMaterials.first : '';
                                    customMatCtrl.text = chosenMaterial ?? '';
                                    final cost = getBaseCost(chosenMaterial);
                                    if (cost > 0) {
                                      priceCtrl.text = cost.toStringAsFixed(2);
                                    }
                                  });
                                }
                              },
                            ),
                        ],
                      ),
                      if (selectedSupplier != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.factory_outlined, size: 14, color: AppTheme.costPurple),
                              const SizedBox(width: 6),
                              Text('المصنع التابع له: ${selectedSupplier!.companyName}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(
                                'الرصيد: ${selectedSupplier!.currentBalance < 0 ? 'له: ${_formatNumber(selectedSupplier!.currentBalance.abs())} ج.م' : 'خالص'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: selectedSupplier!.currentBalance < 0 ? AppTheme.wasteRed : AppTheme.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // اختيار الخامة الموردة (علي حسب المورد)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('الخامة الموردة (حسب المورد المختار) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              if (currentSupplierMaterials.length > 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlueSoft,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'المورد يورد (${currentSupplierMaterials.length}) خامات',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // الحالة 1: المورد يورد خامة واحدة فقط -> معلومة تلقائياً من المورد!
                          if (currentSupplierMaterials.length == 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlueSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppTheme.primaryBlue),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          chosenMaterial ?? '',
                                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'معلومة ومحددة تلقائياً من بيانات المورد',
                                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successGreenSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check, size: 13, color: AppTheme.successGreen),
                                        SizedBox(width: 4),
                                        Text('معتمدة من المورد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          // الحالة 2: المورد يورد أكثر من خامة -> اختيار خامة من خامات هذا المورد فقط!
                          else if (currentSupplierMaterials.length > 1)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  value: currentSupplierMaterials.contains(chosenMaterial) ? chosenMaterial : currentSupplierMaterials.first,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.category_outlined, size: 18),
                                    hintText: 'اختر الخامة من خامات المورد...',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: currentSupplierMaterials.map((mat) {
                                    return DropdownMenuItem<String>(
                                      value: mat,
                                      child: Text(mat, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setDialogState(() {
                                        chosenMaterial = v;
                                        customMatCtrl.text = v;
                                        final cost = getBaseCost(v);
                                        if (cost > 0) {
                                          priceCtrl.text = cost.toStringAsFixed(2);
                                        }
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: currentSupplierMaterials.map((mat) {
                                    final isSel = chosenMaterial == mat;
                                    return InkWell(
                                      onTap: () {
                                        setDialogState(() {
                                          chosenMaterial = mat;
                                          customMatCtrl.text = mat;
                                          final cost = getBaseCost(mat);
                                          if (cost > 0) {
                                            priceCtrl.text = cost.toStringAsFixed(2);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSel ? AppTheme.primaryBlue : AppTheme.background,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: isSel ? AppTheme.primaryBlue : AppTheme.borderSubtle),
                                        ),
                                        child: Text(
                                          mat,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                            color: isSel ? Colors.white : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            )
                          // الحالة 3: لم يتم تسجيل خامات مسبقاً للمورد
                          else
                            TextFormField(
                              controller: customMatCtrl,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: 'أدخل اسم الخامة الموردة...',
                                prefixIcon: const Icon(Icons.edit_note_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل اسم الخامة الموردة' : null,
                              onChanged: (v) {
                                setDialogState(() {
                                  chosenMaterial = v.trim();
                                });
                              },
                            ),

                          // بطاقة رصيد وسعر الخامة
                          if (chosenMaterial != null && chosenMaterial!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlueSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 14, color: AppTheme.primaryBlue),
                                  const SizedBox(width: 6),
                                  Text(
                                    'الرصيد الحالي بالمخزن: ${_formatNumber(getCurrentStock(chosenMaterial))} كجم',
                                    style: const TextStyle(fontSize: 11.5, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Text(
                                    getBaseCost(chosenMaterial) > 0
                                        ? 'سعر الكيلو الأساسي المسجل: ${_formatCurrency(getBaseCost(chosenMaterial))} ج.م'
                                        : 'سعر الكيلو الأساسي: غير مسجل (صنف جديد)',
                                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // الكمية وسعر الكيلو
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الكمية بالكيلو
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الكمية الموردة (كجم) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: qtyCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.scale_outlined, size: 18),
                                    suffixText: 'كجم',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  validator: (v) {
                                    final val = double.tryParse(v ?? '');
                                    if (val == null || val <= 0) return 'أدخل كمية صحيحة';
                                    return null;
                                  },
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // سعر كيلو الخامة في التوريد
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('سعر كيلو التوريد (ج.م) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: priceCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                                    suffixText: 'ج.م/كجم',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  validator: (v) {
                                    final val = double.tryParse(v ?? '');
                                    if (val == null || val <= 0) return 'أدخل سعر الكيلو';
                                    return null;
                                  },
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // صندوق التنبيه الذكي لتحديث سعر الأساس
                      if (priceDiffers)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_graph_rounded, size: 18, color: AppTheme.successGreen),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'سعر التوريد الجديد (${_formatCurrency(unitPrice)} ج.م) يختلف عن سعر الأساس المسجل بالمخزن (${_formatCurrency(currentBaseCost)} ج.م).',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => setDialogState(() => updateBasePrice = !updateBasePrice),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: updateBasePrice,
                                      activeColor: AppTheme.successGreen,
                                      onChanged: (v) => setDialogState(() => updateBasePrice = v ?? true),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'تحديث سعر كيلو الخامة الأساسي في المخزن إلى السعر الجديد (${_formatCurrency(unitPrice)} ج.م) ليدخل في حسابات التكلفة والمنتجات تلقائياً',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),

                      // بطاقة إجمالي الفاتورة وطريقة السداد
                      Container(
                        padding: const EdgeInsets.all(14),
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
                                const Text('إجمالي قيمة التوريد:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text('${_formatCurrency(totalAmount)} ج.م', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.costPurple)),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              children: [
                                const Text('طريقة السداد:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                ChoiceChip(
                                  label: const Text('آجل بالكامل على الحساب', style: TextStyle(fontSize: 11.5)),
                                  selected: paymentType == 'credit',
                                  selectedColor: AppTheme.profitAmberSoft,
                                  onSelected: (s) => setDialogState(() => paymentType = 'credit'),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('نقدي كاش من الخزينة', style: TextStyle(fontSize: 11.5)),
                                  selected: paymentType == 'cash',
                                  selectedColor: const Color(0xFFDCFCE7),
                                  onSelected: (s) => setDialogState(() => paymentType = 'cash'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (paymentType == 'credit')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.profitAmberSoft,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.profitAmber.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.credit_score_rounded, size: 18, color: AppTheme.profitAmber),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'كامل قيمة التوريد (${_formatCurrency(totalAmount)} ج.م) ستُسجل كمديونية آجلة علينا للمورد، ويمكن سدادها بأي أجزاء في أي وقت من صفحة الآجل.',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, size: 18, color: AppTheme.successGreen),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'سيتم خصم كامل القيمة (${_formatCurrency(totalAmount)} ج.م) كاش نقداً من الخزينة وتثبيتها كمنصرف توريد مشتريات خامات.',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // رقم الإذن والملاحظات
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: invoiceCtrl,
                              style: const TextStyle(fontSize: 12.5),
                              decoration: InputDecoration(
                                labelText: 'رقم إذن التوريد / الفاتورة',
                                prefixIcon: const Icon(Icons.receipt_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: notesCtrl,
                              style: const TextStyle(fontSize: 12.5),
                              decoration: InputDecoration(
                                labelText: 'ملاحظات (رقم السيارة / السائق)',
                                prefixIcon: const Icon(Icons.notes_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // الأزرار السفلية
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('إلغاء'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('حفظ إذن التوريد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            onPressed: () {
                              if (selectedSupplier == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('يرجى اختيار المورد أولاً'), backgroundColor: AppTheme.wasteRed),
                                );
                                return;
                              }
                              final finalMatName = (chosenMaterial != null && chosenMaterial!.trim().isNotEmpty)
                                  ? chosenMaterial!.trim()
                                  : customMatCtrl.text.trim();

                              if (finalMatName.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('يرجى اختيار أو تحديد الخامة الموردة أولاً'), backgroundColor: AppTheme.wasteRed),
                                );
                                return;
                              }

                              if (formKey.currentState!.validate()) {
                                String finalPaymentMethod = paymentType == 'cash'
                                    ? 'نقدي كاش من الخزينة'
                                    : 'آجل على الحساب';

                                final cleanFinalMat = finalMatName.trim().toLowerCase();
                                final matchedProd = store.products.where((p) =>
                                    p.name.trim().toLowerCase() == cleanFinalMat ||
                                    (p.materialType.trim().isNotEmpty && p.materialType.trim().toLowerCase() == cleanFinalMat) ||
                                    p.name.trim().toLowerCase().contains(cleanFinalMat) ||
                                    cleanFinalMat.contains(p.name.trim().toLowerCase())).firstOrNull;
                                final matchedRm = store.rawMaterials.where((r) =>
                                    r.name.trim().toLowerCase() == cleanFinalMat ||
                                    r.name.trim().toLowerCase().contains(cleanFinalMat) ||
                                    cleanFinalMat.contains(r.name.trim().toLowerCase())).firstOrNull;
                                final rawMatId = matchedProd?.id ?? matchedRm?.id ?? 'rm-${finalMatName.hashCode.abs()}';

                                final order = MaterialSupplyOrder(
                                  id: 'sup-ord-${DateTime.now().millisecondsSinceEpoch}',
                                  invoiceNumber: invoiceCtrl.text.trim().isNotEmpty ? invoiceCtrl.text.trim() : 'SUP-000',
                                  date: DateTime.now(),
                                  supplierId: selectedSupplier!.id,
                                  supplierName: selectedSupplier!.name,
                                  supplierFactory: selectedSupplier!.companyName,
                                  rawMaterialId: rawMatId,
                                  rawMaterialName: finalMatName,
                                  quantityKg: qty,
                                  unitPrice: unitPrice,
                                  previousBasePrice: currentBaseCost,
                                  updatedBasePrice: updateBasePrice,
                                  totalAmount: totalAmount,
                                  paidAmount: paidAmount,
                                  remainingAmount: remainingAmount,
                                  paymentMethod: finalPaymentMethod,
                                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                );

                                 Navigator.of(ctx).pop();

                                store.addMaterialSupplyOrder(
                                  order: order,
                                  updateBaseCost: updateBasePrice,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم تسجيل إذن التوريد بنجاح! تم إضافة ${_formatNumber(qty)} كجم لرصيد ($finalMatName)${updateBasePrice && priceDiffers ? ' وتحديث سعر الأساس إلى ${_formatCurrency(unitPrice)} ج.م' : ''}'),
                                    backgroundColor: AppTheme.successGreen,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // تعديل إذن توريد مسجل
  // ----------------------------------------------------
  void _showEditSupplyDialog(BuildContext context, MaterialSupplyOrder ord) {
    final formKey = GlobalKey<FormState>();
    final store = widget.store;

    Supplier? selectedSupplier = store.suppliers.where((s) => s.id == ord.supplierId).firstOrNull;
    if (selectedSupplier == null && store.suppliers.isNotEmpty) {
      selectedSupplier = store.suppliers.where((s) => s.name.trim() == ord.supplierName.trim()).firstOrNull ?? store.suppliers.first;
    }

    List<String> getMaterialsForSupplier(Supplier? sup) {
      if (sup == null) return [];
      final Set<String> mats = {};
      mats.addAll(sup.suppliedMaterials.map((m) => m.trim()).where((m) => m.isNotEmpty));
      for (final p in store.products) {
        if (p.notes != null && p.notes!.contains(sup.name)) {
          if (p.name.trim().isNotEmpty) mats.add(p.name.trim());
          if (p.materialType.trim().isNotEmpty) mats.add(p.materialType.trim());
        }
      }
      for (final o in store.materialSupplyOrders) {
        if (o.supplierId == sup.id || o.supplierName == sup.name) {
          if (o.rawMaterialName.trim().isNotEmpty) mats.add(o.rawMaterialName.trim());
        }
      }
      return mats.toList();
    }

    double getBaseCost(String? matName) {
      if (matName == null || matName.trim().isEmpty) return 0.0;
      final clean = matName.trim().toLowerCase();
      for (final prod in store.products) {
        final cleanPName = prod.name.trim().toLowerCase();
        final cleanMat = prod.materialType.trim().toLowerCase();
        if (cleanPName == clean ||
            (cleanMat.isNotEmpty && cleanMat == clean) ||
            cleanPName.contains(clean) ||
            clean.contains(cleanPName)) {
          if (prod.rawMaterialCostPerKg > 0) return prod.rawMaterialCostPerKg;
          if (prod.totalProducedKg > 0 && prod.rawMaterialExpenses > 0) {
            return prod.rawMaterialExpenses / prod.totalProducedKg;
          }
          if (prod.costPerKg > 0) return prod.costPerKg;
        }
      }
      for (final rm in store.rawMaterials) {
        final cleanRm = rm.name.trim().toLowerCase();
        if (cleanRm == clean || cleanRm.contains(clean) || clean.contains(cleanRm)) {
          return rm.unitCost;
        }
      }
      return 0.0;
    }

    double getCurrentStock(String? matName) {
      if (matName == null || matName.trim().isEmpty) return 0.0;
      final clean = matName.trim().toLowerCase();
      for (final prod in store.products) {
        final cleanPName = prod.name.trim().toLowerCase();
        final cleanMat = prod.materialType.trim().toLowerCase();
        if (cleanPName == clean ||
            (cleanMat.isNotEmpty && cleanMat == clean) ||
            cleanPName.contains(clean) ||
            clean.contains(cleanPName)) {
          return prod.stockKg;
        }
      }
      for (final rm in store.rawMaterials) {
        final cleanRm = rm.name.trim().toLowerCase();
        if (cleanRm == clean || cleanRm.contains(clean) || clean.contains(cleanRm)) {
          return rm.currentStock;
        }
      }
      return 0.0;
    }

    List<String> currentSupplierMaterials = getMaterialsForSupplier(selectedSupplier);
    if (!currentSupplierMaterials.contains(ord.rawMaterialName)) {
      currentSupplierMaterials.add(ord.rawMaterialName);
    }
    String? chosenMaterial = ord.rawMaterialName;
    final customMatCtrl = TextEditingController(text: ord.rawMaterialName);

    final invoiceCtrl = TextEditingController(text: ord.invoiceNumber);
    final qtyCtrl = TextEditingController(
      text: ord.quantityKg == ord.quantityKg.roundToDouble()
          ? ord.quantityKg.toInt().toString()
          : ord.quantityKg.toString(),
    );
    final priceCtrl = TextEditingController(
      text: ord.unitPrice == ord.unitPrice.roundToDouble()
          ? ord.unitPrice.toInt().toString()
          : ord.unitPrice.toStringAsFixed(2),
    );
    final notesCtrl = TextEditingController(text: ord.notes ?? '');

    bool updateBasePrice = ord.updatedBasePrice;
    String paymentType = ord.remainingAmount <= 0.01 && ord.paidAmount > 0 ? 'cash' : 'credit';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final double qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
          final double unitPrice = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
          final double totalAmount = qty * unitPrice;

          final double currentBaseCost = getBaseCost(chosenMaterial);
          final bool priceDiffers = (unitPrice - currentBaseCost).abs() > 0.001;

          final double paidAmount = paymentType == 'cash' ? totalAmount : 0.0;
          final double remainingAmount = paymentType == 'cash' ? 0.0 : totalAmount;

          return Dialog(
            backgroundColor: AppTheme.surfaceWhite,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // رأس الحوار
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppTheme.profitAmberSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit_note_outlined, color: AppTheme.profitAmber, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تعديل إذن توريد: ${ord.invoiceNumber}',
                                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'تعديل المورد، الصنف، الكمية، أو السعر وضبط المخزن تلقائياً',
                                  style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
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
                      const Divider(height: 24),

                      // اختيار المورد
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('المورد *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                ),
                                icon: const Icon(Icons.person_add_alt_1_outlined, size: 16, color: AppTheme.primaryBlue),
                                label: const Text('إضافة مورد جديد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                onPressed: () async {
                                  final added = await _showQuickAddSupplierDialog(context);
                                  if (added != null) {
                                    setDialogState(() {
                                      selectedSupplier = added;
                                      currentSupplierMaterials = getMaterialsForSupplier(added);
                                      if (!currentSupplierMaterials.contains(chosenMaterial)) {
                                        chosenMaterial = currentSupplierMaterials.isNotEmpty ? currentSupplierMaterials.first : '';
                                        customMatCtrl.text = chosenMaterial ?? '';
                                      }
                                      final cost = getBaseCost(chosenMaterial);
                                      if (cost > 0) {
                                        priceCtrl.text = cost.toStringAsFixed(2);
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          if (store.suppliers.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.profitAmberSoft,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.profitAmber.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: AppTheme.profitAmber, size: 18),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'لا يوجد موردون مسجلون بعد. اضغط على الزر لإضافة المورد أولاً.',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.costPurple,
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    icon: const Icon(Icons.add, size: 14),
                                    label: const Text('إضافة مورد', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    onPressed: () async {
                                      final added = await _showQuickAddSupplierDialog(context);
                                      if (added != null) {
                                        setDialogState(() {
                                          selectedSupplier = added;
                                          currentSupplierMaterials = getMaterialsForSupplier(added);
                                          if (!currentSupplierMaterials.contains(chosenMaterial)) {
                                            chosenMaterial = currentSupplierMaterials.isNotEmpty ? currentSupplierMaterials.first : '';
                                            customMatCtrl.text = chosenMaterial ?? '';
                                          }
                                          final cost = getBaseCost(chosenMaterial);
                                          if (cost > 0) {
                                            priceCtrl.text = cost.toStringAsFixed(2);
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<Supplier>(
                              value: selectedSupplier,
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.person_outline, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              items: store.suppliers.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    '${s.name} - ${s.companyName}',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              validator: (v) => v == null ? 'يرجى اختيار المورد' : null,
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() {
                                    selectedSupplier = v;
                                    currentSupplierMaterials = getMaterialsForSupplier(v);
                                    if (!currentSupplierMaterials.contains(chosenMaterial)) {
                                      chosenMaterial = currentSupplierMaterials.isNotEmpty ? currentSupplierMaterials.first : '';
                                      customMatCtrl.text = chosenMaterial ?? '';
                                    }
                                    final cost = getBaseCost(chosenMaterial);
                                    if (cost > 0) {
                                      priceCtrl.text = cost.toStringAsFixed(2);
                                    }
                                  });
                                }
                              },
                            ),
                        ],
                      ),
                      if (selectedSupplier != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.factory_outlined, size: 14, color: AppTheme.costPurple),
                              const SizedBox(width: 6),
                              Text('المصنع التابع له: ${selectedSupplier!.companyName}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(
                                'الرصيد: ${selectedSupplier!.currentBalance < 0 ? 'له: ${_formatNumber(selectedSupplier!.currentBalance.abs())} ج.م' : 'خالص'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: selectedSupplier!.currentBalance < 0 ? AppTheme.wasteRed : AppTheme.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // اختيار الخامة الموردة (علي حسب المورد)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('الخامة الموردة (حسب المورد المختار) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              if (currentSupplierMaterials.length > 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlueSoft,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'المورد يورد (${currentSupplierMaterials.length}) خامات',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          if (currentSupplierMaterials.length == 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlueSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppTheme.primaryBlue),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          chosenMaterial ?? '',
                                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'معلومة ومحددة تلقائياً من بيانات المورد',
                                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successGreenSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check, size: 13, color: AppTheme.successGreen),
                                        SizedBox(width: 4),
                                        Text('معتمدة من المورد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (currentSupplierMaterials.length > 1)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  value: currentSupplierMaterials.contains(chosenMaterial) ? chosenMaterial : currentSupplierMaterials.first,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.category_outlined, size: 18),
                                    hintText: 'اختر الخامة من خامات المورد...',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: currentSupplierMaterials.map((mat) {
                                    return DropdownMenuItem<String>(
                                      value: mat,
                                      child: Text(mat, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setDialogState(() {
                                        chosenMaterial = v;
                                        customMatCtrl.text = v;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: currentSupplierMaterials.map((mat) {
                                    final isSel = chosenMaterial == mat;
                                    return InkWell(
                                      onTap: () {
                                        setDialogState(() {
                                          chosenMaterial = mat;
                                          customMatCtrl.text = mat;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSel ? AppTheme.primaryBlue : AppTheme.background,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: isSel ? AppTheme.primaryBlue : AppTheme.borderSubtle),
                                        ),
                                        child: Text(
                                          mat,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                            color: isSel ? Colors.white : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            )
                          else
                            TextFormField(
                              controller: customMatCtrl,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: 'أدخل اسم الخامة الموردة...',
                                prefixIcon: const Icon(Icons.edit_note_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل اسم الخامة الموردة' : null,
                              onChanged: (v) {
                                setDialogState(() {
                                  chosenMaterial = v.trim();
                                });
                              },
                            ),

                          // بطاقة رصيد وسعر الخامة
                          if (chosenMaterial != null && chosenMaterial!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlueSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 14, color: AppTheme.primaryBlue),
                                  const SizedBox(width: 6),
                                  Text(
                                    'الرصيد الحالي بالمخزن: ${_formatNumber(getCurrentStock(chosenMaterial))} كجم',
                                    style: const TextStyle(fontSize: 11.5, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Text(
                                    getBaseCost(chosenMaterial) > 0
                                        ? 'سعر الكيلو الأساسي المسجل: ${_formatCurrency(getBaseCost(chosenMaterial))} ج.م'
                                        : 'سعر الكيلو الأساسي: غير مسجل (صنف جديد)',
                                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // الكمية وسعر الكيلو
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الكمية بالكيلو
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الكمية الموردة (كجم) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: qtyCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.scale_outlined, size: 18),
                                    suffixText: 'كجم',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  validator: (v) {
                                    final val = double.tryParse(v ?? '');
                                    if (val == null || val <= 0) return 'أدخل كمية صحيحة';
                                    return null;
                                  },
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // سعر كيلو الخامة في التوريد
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('سعر كيلو التوريد (ج.م) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: priceCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                                    suffixText: 'ج.م/كجم',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  validator: (v) {
                                    final val = double.tryParse(v ?? '');
                                    if (val == null || val <= 0) return 'أدخل سعر الكيلو';
                                    return null;
                                  },
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // صندوق التنبيه الذكي لتحديث سعر الأساس
                      if (priceDiffers)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_graph_rounded, size: 18, color: AppTheme.successGreen),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'سعر التوريد الجديد (${_formatCurrency(unitPrice)} ج.م) يختلف عن سعر الأساس المسجل بالمخزن (${_formatCurrency(currentBaseCost)} ج.م).',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => setDialogState(() => updateBasePrice = !updateBasePrice),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: updateBasePrice,
                                      activeColor: AppTheme.successGreen,
                                      onChanged: (v) => setDialogState(() => updateBasePrice = v ?? true),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'تحديث سعر كيلو الخامة الأساسي في المخزن إلى السعر الجديد (${_formatCurrency(unitPrice)} ج.م) ليدخل في حسابات التكلفة والمنتجات تلقائياً',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),

                      // بطاقة إجمالي الفاتورة وطريقة السداد
                      Container(
                        padding: const EdgeInsets.all(14),
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
                                const Text('إجمالي قيمة التوريد:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text('${_formatCurrency(totalAmount)} ج.م', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.costPurple)),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              children: [
                                const Text('طريقة السداد:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                ChoiceChip(
                                  label: const Text('آجل بالكامل على الحساب', style: TextStyle(fontSize: 11.5)),
                                  selected: paymentType == 'credit',
                                  selectedColor: AppTheme.profitAmberSoft,
                                  onSelected: (s) => setDialogState(() => paymentType = 'credit'),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('نقدي كاش من الخزينة', style: TextStyle(fontSize: 11.5)),
                                  selected: paymentType == 'cash',
                                  selectedColor: const Color(0xFFDCFCE7),
                                  onSelected: (s) => setDialogState(() => paymentType = 'cash'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (paymentType == 'credit')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.profitAmberSoft,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.profitAmber.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.credit_score_rounded, size: 18, color: AppTheme.profitAmber),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'كامل قيمة التوريد (${_formatCurrency(totalAmount)} ج.م) مسجلة كمديونية آجلة علينا للمورد، ويمكن سدادها بالأجزاء من صفحة الآجل.',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, size: 18, color: AppTheme.successGreen),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'سيتم خصم كامل القيمة (${_formatCurrency(totalAmount)} ج.م) كاش نقداً من الخزينة وتثبيتها كمنصرف توريد مشتريات خامات.',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // رقم الإذن والملاحظات
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: invoiceCtrl,
                              style: const TextStyle(fontSize: 12.5),
                              decoration: InputDecoration(
                                labelText: 'رقم إذن التوريد / الفاتورة',
                                prefixIcon: const Icon(Icons.receipt_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: notesCtrl,
                              style: const TextStyle(fontSize: 12.5),
                              decoration: InputDecoration(
                                labelText: 'ملاحظات (رقم السيارة / السائق)',
                                prefixIcon: const Icon(Icons.notes_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // الأزرار السفلية
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('إلغاء'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.profitAmber,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.save_outlined, size: 18),
                            label: const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            onPressed: () {
                              if (selectedSupplier == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('يرجى اختيار المورد أولاً'), backgroundColor: AppTheme.wasteRed),
                                );
                                return;
                              }
                              final finalMatName = (chosenMaterial != null && chosenMaterial!.trim().isNotEmpty)
                                  ? chosenMaterial!.trim()
                                  : customMatCtrl.text.trim();

                              if (finalMatName.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('يرجى اختيار أو تحديد الخامة الموردة أولاً'), backgroundColor: AppTheme.wasteRed),
                                );
                                return;
                              }

                              if (formKey.currentState!.validate()) {
                                String finalPaymentMethod = paymentType == 'cash'
                                    ? 'نقدي كاش من الخزينة'
                                    : 'آجل على الحساب';

                                final cleanFinalMat = finalMatName.trim().toLowerCase();
                                final matchedProd = store.products.where((p) =>
                                    p.name.trim().toLowerCase() == cleanFinalMat ||
                                    (p.materialType.trim().isNotEmpty && p.materialType.trim().toLowerCase() == cleanFinalMat) ||
                                    p.name.trim().toLowerCase().contains(cleanFinalMat) ||
                                    cleanFinalMat.contains(p.name.trim().toLowerCase())).firstOrNull;
                                final matchedRm = store.rawMaterials.where((r) =>
                                    r.name.trim().toLowerCase() == cleanFinalMat ||
                                    r.name.trim().toLowerCase().contains(cleanFinalMat) ||
                                    cleanFinalMat.contains(r.name.trim().toLowerCase())).firstOrNull;
                                final rawMatId = matchedProd?.id ?? matchedRm?.id ?? ord.rawMaterialId;

                                final updatedOrder = ord.copyWith(
                                  invoiceNumber: invoiceCtrl.text.trim().isNotEmpty ? invoiceCtrl.text.trim() : ord.invoiceNumber,
                                  supplierId: selectedSupplier!.id,
                                  supplierName: selectedSupplier!.name,
                                  supplierFactory: selectedSupplier!.companyName,
                                  rawMaterialId: rawMatId,
                                  rawMaterialName: finalMatName,
                                  quantityKg: qty,
                                  unitPrice: unitPrice,
                                  previousBasePrice: ord.previousBasePrice > 0 ? ord.previousBasePrice : currentBaseCost,
                                  updatedBasePrice: updateBasePrice,
                                  totalAmount: totalAmount,
                                  paidAmount: paidAmount,
                                  remainingAmount: remainingAmount,
                                  paymentMethod: finalPaymentMethod,
                                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                );

                                Navigator.of(ctx).pop();

                                store.updateMaterialSupplyOrder(
                                  oldOrder: ord,
                                  newOrder: updatedOrder,
                                  updateBaseCost: updateBasePrice,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم حفظ تعديلات إذن التوريد (${updatedOrder.invoiceNumber}) وضبط الأرصدة بنجاح!'),
                                    backgroundColor: AppTheme.successGreen,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // عرض تفاصيل إذن التوريد
  // ----------------------------------------------------
  void _showOrderDetails(BuildContext context, MaterialSupplyOrder ord) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text('تفاصيل إذن توريد: ${ord.invoiceNumber}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('التاريخ والوقت:', _formatDate(ord.date)),
              _detailRow('اسم المورد:', ord.supplierName),
              _detailRow('المصنع التابع له:', ord.supplierFactory),
              _detailRow('الخامة الموردة:', ord.rawMaterialName),
              _detailRow('الكمية الموردة:', '${_formatNumber(ord.quantityKg)} كجم'),
              _detailRow('سعر كيلو التوريد:', '${_formatCurrency(ord.unitPrice)} ج.م'),
              _detailRow('سعر الأساس السابق:', '${_formatCurrency(ord.previousBasePrice)} ج.م'),
              _detailRow('تحديث سعر الأساس:', ord.updatedBasePrice ? 'نعم (تم تحديث الأساس)' : 'لا (بقي كما هو)'),
              const Divider(height: 16),
              _detailRow('إجمالي قيمة التوريد:', '${_formatCurrency(ord.totalAmount)} ج.م', isBold: true, color: AppTheme.costPurple),
              _detailRow('المدفوع نقداً:', '${_formatCurrency(ord.paidAmount)} ج.م'),
              _detailRow('المتبقي على الحساب:', '${_formatCurrency(ord.remainingAmount)} ج.م', color: ord.remainingAmount > 0 ? AppTheme.wasteRed : AppTheme.successGreen),
              _detailRow('طريقة السداد:', ord.paymentMethod),
              if (ord.notes != null && ord.notes!.isNotEmpty)
                _detailRow('ملاحظات:', ord.notes!),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.profitAmber),
            label: const Text('تعديل الإذن', style: TextStyle(color: AppTheme.profitAmber, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _showEditSupplyDialog(context, ord);
            },
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // تأكيد حذف إذن التوريد مع استرجاع الرصيد
  // ----------------------------------------------------
  void _confirmDeleteOrder(BuildContext context, MaterialSupplyOrder ord) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppTheme.wasteRed, size: 24),
            SizedBox(width: 8),
            Text('تأكيد إلغاء وحذف إذن التوريد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف إذن التوريد رقم "${ord.invoiceNumber}"؟\n\n'
          '⚠️ سيتم استرجاع ${_formatNumber(ord.quantityKg)} كجم من رصيد خامة (${ord.rawMaterialName}) بالمخزن، وضبط رصيد المورد (${ord.supplierName}) تلقائياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.wasteRed, foregroundColor: Colors.white),
            onPressed: () {
              widget.store.deleteMaterialSupplyOrder(ord.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف إذن التوريد واسترجاع الأرصدة بنجاح'), backgroundColor: AppTheme.wasteRed),
              );
            },
            child: const Text('حذف واسترجاع الأرصدة'),
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
                  Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
