import 'package:flutter/material.dart';
import '../../models/product_item.dart';
import '../../state/factory_store.dart';
import '../../theme/app_theme.dart';

class AddProductDialog extends StatefulWidget {
  final FactoryStore store;
  final ProductItem? productToEdit;

  const AddProductDialog({super.key, required this.store, this.productToEdit});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _materialController;
  late TextEditingController _producedKgController;
  late TextEditingController _rawCostPerKgController;
  late TextEditingController _rawExpensesController;
  late TextEditingController _laborCostPerKgController;
  late TextEditingController _laborExpensesController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _retailPriceController;
  late TextEditingController _notesController;

  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _categoryController = TextEditingController(text: p?.category ?? '');
    _materialController = TextEditingController(text: p?.materialType ?? '');

    final initialProduced = p != null ? p.totalProducedKg : 10000.0;
    _producedKgController = TextEditingController(text: initialProduced.toStringAsFixed(0));

    // مصروفات الكهرباء والعمالة (قابلة للتعديل والافتراضي 2.0 ج/كجم)
    final initialLaborCostPerKg = p != null
        ? (p.totalProducedKg > 0 ? p.laborAndElectricityCostPerKg : 2.0)
        : 2.0;
    final initialLaborExpenses = p != null
        ? p.laborAndElectricityExpenses
        : (initialProduced * initialLaborCostPerKg);

    _laborCostPerKgController = TextEditingController(text: initialLaborCostPerKg.toStringAsFixed(2));
    _laborExpensesController = TextEditingController(text: initialLaborExpenses.toStringAsFixed(0));

    // تكلفة الخامات
    final initialRaw = p != null
        ? (p.rawMaterialExpenses > 0 ? p.rawMaterialExpenses : (p.totalExpenses - initialLaborExpenses).clamp(0.0, double.infinity))
        : 65000.0;
    final initialRawPerKg = initialProduced > 0 ? initialRaw / initialProduced : 6.5;

    _rawCostPerKgController = TextEditingController(text: initialRawPerKg.toStringAsFixed(2));
    _rawExpensesController = TextEditingController(text: initialRaw.toStringAsFixed(0));

    _wholesalePriceController = TextEditingController(text: p != null ? p.wholesalePricePerKg.toStringAsFixed(2) : '10.50');
    _retailPriceController = TextEditingController(text: p != null ? p.retailPricePerKg.toStringAsFixed(2) : '14.00');
    _notesController = TextEditingController(text: p?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _materialController.dispose();
    _producedKgController.dispose();
    _rawCostPerKgController.dispose();
    _rawExpensesController.dispose();
    _laborCostPerKgController.dispose();
    _laborExpensesController.dispose();
    _wholesalePriceController.dispose();
    _retailPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    final produced = double.tryParse(_producedKgController.text) ?? 0.0;
    final rawExp = double.tryParse(_rawExpensesController.text) ?? 0.0;
    final laborExp = double.tryParse(_laborExpensesController.text) ?? 0.0;

    final wPrice = double.tryParse(_wholesalePriceController.text) ?? 0.0;
    final rPrice = double.tryParse(_retailPriceController.text) ?? 0.0;

    final rawPerKg = produced > 0 ? rawExp / produced : 0.0;
    final laborPerKg = produced > 0 ? laborExp / produced : 0.0;
    final totalCostPerKg = rawPerKg + laborPerKg;

    final grossWholesaleProfitPerKg = wPrice - rawPerKg;
    final grossRetailProfitPerKg = rPrice - rawPerKg;

    final wholesaleProfitPerKg = wPrice - totalCostPerKg;
    final retailProfitPerKg = rPrice - totalCostPerKg;

    return Dialog(
      backgroundColor: AppTheme.surfaceWhite,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // رأس الحوار الأنيق الموحد
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlueSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2, color: AppTheme.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'تعديل بيانات الصنف' : 'إضافة صنف جديد',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(height: 20),

              // محتوى النموذج القابل للتمرير
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اسم الصنف والمقاس
                        const Text('اسم الصنف / المقاس', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'مثال: أكياس تسوق هاي دي 40×50 سم',
                            hintStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل اسم الصنف' : null,
                        ),
                        const SizedBox(height: 12),

                        // أسعار البيع: جملة وقطاعي
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('تسعير البيع (جملة مقابل قطاعي):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('سعر بيع الجملة (للتجار)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: AppTheme.primaryBlue)),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _wholesalePriceController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            suffixText: 'ج/كجم',
                                            suffixStyle: const TextStyle(fontSize: 11),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            isDense: true,
                                          ),
                                          onChanged: (_) => setState(() {}),
                                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'مطلوب' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('سعر بيع القطاعي (للمحلات)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: AppTheme.successGreen)),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _retailPriceController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            suffixText: 'ج/كجم',
                                            suffixStyle: const TextStyle(fontSize: 11),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            isDense: true,
                                          ),
                                          onChanged: (_) => setState(() {}),
                                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'مطلوب' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // قسم تفاصيل الكمية والتكاليف (خامات + كهرباء وعمالة)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBFBFE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calculate_outlined, size: 16, color: AppTheme.costPurple),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'تفاصيل الكمية والتكاليف:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F3FF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFDDD6FE)),
                                    ),
                                    child: Text(
                                      'كهرباء وعمالة: ${laborPerKg.toStringAsFixed(2)} ج/كجم',
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // 1. إدخال الكمية
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('الكمية المنتجة (معايا كام كيلو)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: AppTheme.primaryBlue)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _producedKgController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      suffixText: 'كجم',
                                      suffixStyle: const TextStyle(fontSize: 11),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      isDense: true,
                                    ),
                                    onChanged: (_) {
                                      if (!_isSyncing) {
                                        _isSyncing = true;
                                        final pKg = double.tryParse(_producedKgController.text) ?? 0.0;
                                        final cPerKg = double.tryParse(_rawCostPerKgController.text) ?? 0.0;
                                        final lPerKg = double.tryParse(_laborCostPerKgController.text) ?? 0.0;
                                        if (pKg > 0) {
                                          if (cPerKg > 0) _rawExpensesController.text = (cPerKg * pKg).toStringAsFixed(0);
                                          if (lPerKg > 0) _laborExpensesController.text = (lPerKg * pKg).toStringAsFixed(0);
                                        }
                                        _isSyncing = false;
                                      }
                                      setState(() {});
                                    },
                                    validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل رقم' : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // 2. تكاليف الخامات
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('سعر خامة الكيلو', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF0F766E))),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _rawCostPerKgController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            suffixText: 'ج/كجم',
                                            suffixStyle: const TextStyle(fontSize: 11),
                                            hintText: '50',
                                            hintStyle: const TextStyle(fontSize: 12),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            isDense: true,
                                          ),
                                          onChanged: (_) {
                                            if (!_isSyncing) {
                                              _isSyncing = true;
                                              final cPerKg = double.tryParse(_rawCostPerKgController.text) ?? 0.0;
                                              final pKg = double.tryParse(_producedKgController.text) ?? 0.0;
                                              _rawExpensesController.text = (cPerKg * pKg).toStringAsFixed(0);
                                              _isSyncing = false;
                                            }
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('إجمالي تكلفة الخامات', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF0F766E))),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _rawExpensesController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            suffixText: 'جنيه',
                                            suffixStyle: const TextStyle(fontSize: 11),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            isDense: true,
                                          ),
                                          onChanged: (_) {
                                            if (!_isSyncing) {
                                              _isSyncing = true;
                                              final rExp = double.tryParse(_rawExpensesController.text) ?? 0.0;
                                              final pKg = double.tryParse(_producedKgController.text) ?? 0.0;
                                              if (pKg > 0) {
                                                _rawCostPerKgController.text = (rExp / pKg).toStringAsFixed(2);
                                              }
                                              _isSyncing = false;
                                            }
                                            setState(() {});
                                          },
                                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل رقم' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // 3. مصروفات الكهرباء والعمالة
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('كهرباء وعمالة الكيلو', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF6D28D9))),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _laborCostPerKgController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            suffixText: 'ج/كجم',
                                            suffixStyle: const TextStyle(fontSize: 11),
                                            hintText: '2.00',
                                            hintStyle: const TextStyle(fontSize: 12),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            isDense: true,
                                          ),
                                          onChanged: (_) {
                                            if (!_isSyncing) {
                                              _isSyncing = true;
                                              final lPerKg = double.tryParse(_laborCostPerKgController.text) ?? 0.0;
                                              final pKg = double.tryParse(_producedKgController.text) ?? 0.0;
                                              _laborExpensesController.text = (lPerKg * pKg).toStringAsFixed(0);
                                              _isSyncing = false;
                                            }
                                            setState(() {});
                                          },
                                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل رقم' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('إجمالي الكهرباء والعمالة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF6D28D9))),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _laborExpensesController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            suffixText: 'جنيه',
                                            suffixStyle: const TextStyle(fontSize: 11),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            isDense: true,
                                          ),
                                          onChanged: (_) {
                                            if (!_isSyncing) {
                                              _isSyncing = true;
                                              final lExp = double.tryParse(_laborExpensesController.text) ?? 0.0;
                                              final pKg = double.tryParse(_producedKgController.text) ?? 0.0;
                                              if (pKg > 0) {
                                                _laborCostPerKgController.text = (lExp / pKg).toStringAsFixed(2);
                                              }
                                              _isSyncing = false;
                                            }
                                            setState(() {});
                                          },
                                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل رقم' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // 4. شريط ملخص إجمالي تكلفة الكيلو الواحدة
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.borderSubtle),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('إجمالي تكلفة الكيلو الواحدة', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                        const SizedBox(height: 2),
                                        Text(
                                          'خامة: ${rawPerKg.toStringAsFixed(2)} ج + عمالة وكهرباء: ${laborPerKg.toStringAsFixed(2)} ج',
                                          style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${totalCostPerKg.toStringAsFixed(2)} ج/كجم',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.primaryBlue),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ملخص الحسابات التلقائية
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMiniStat(
                                'ربح الجملة (خامة)',
                                '+${grossWholesaleProfitPerKg.toStringAsFixed(2)} ج.م',
                                AppTheme.primaryBlue,
                                subtitle: 'صافي بعد العمالة: ${wholesaleProfitPerKg.toStringAsFixed(2)} ج',
                              ),
                              _buildMiniStat(
                                'ربح القطاعي (خامة)',
                                '+${grossRetailProfitPerKg.toStringAsFixed(2)} ج.م',
                                AppTheme.successGreen,
                                subtitle: 'صافي بعد العمالة: ${retailProfitPerKg.toStringAsFixed(2)} ج',
                              ),
                              _buildMiniStat(
                                '⚡ كهرباء وعمالة',
                                '${laborPerKg.toStringAsFixed(2)} ج/كجم',
                                const Color(0xFF6D28D9),
                                subtitle: 'إجمالي: ${laborExp.toStringAsFixed(0)} ج.م (منفصلة)',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ملاحظات ومواصفات الصنف
                        const Text('ملاحظات ومواصفات الصنف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _notesController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'مثال: سمك 25 ميكرون، يد معززة، لون أحمر...',
                            hintStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),
              // أزرار التحكم السفلية
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      isEditing ? 'حفظ التعديلات' : 'إضافة الصنف للنظام',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final rawAmount = double.tryParse(_rawExpensesController.text) ?? 0.0;
                        final producedAmount = double.tryParse(_producedKgController.text) ?? 0.0;
                        final laborCostPerKg = double.tryParse(_laborCostPerKgController.text) ?? 2.0;
                        final laborAmount = double.tryParse(_laborExpensesController.text) ??
                            (producedAmount * laborCostPerKg);
                        final stockAmount = widget.productToEdit != null
                            ? (widget.productToEdit!.stockKg + (producedAmount - widget.productToEdit!.totalProducedKg)).clamp(0.0, double.infinity)
                            : producedAmount;
                        final item = ProductItem(
                          id: widget.productToEdit?.id ?? 'prod-${DateTime.now().millisecondsSinceEpoch}',
                          name: _nameController.text.trim(),
                          category: _categoryController.text.trim(),
                          materialType: _materialController.text.trim(),
                          totalProducedKg: producedAmount,
                          defaultBatchKg: producedAmount,
                          totalWasteKg: widget.productToEdit?.totalWasteKg ?? 0.0,
                          rawMaterialExpenses: rawAmount,
                          laborAndElectricityExpenses: laborAmount,
                          laborCostPerKg: laborCostPerKg,
                          totalExpenses: rawAmount + laborAmount,
                          wholesalePricePerKg: double.parse(_wholesalePriceController.text),
                          retailPricePerKg: double.parse(_retailPriceController.text),
                          stockKg: stockAmount,
                          notes: _notesController.text.trim(),
                          createdAt: widget.productToEdit?.createdAt,
                          stockAdditions: widget.productToEdit?.stockAdditions,
                        );
                        if (isEditing) {
                          widget.store.updateProduct(item);
                        } else {
                          widget.store.addProduct(item);
                        }
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'تم تعديل بيانات الصنف بنجاح!' : 'تمت إضافة الصنف وحفظه بنجاح!'),
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
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary)),
        ],
      ],
    );
  }
}
