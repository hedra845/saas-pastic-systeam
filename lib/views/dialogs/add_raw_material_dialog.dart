import 'package:flutter/material.dart';
import '../../widgets/styled_dialog.dart';
import '../../models/raw_material.dart';
import '../../state/factory_store.dart';
import '../../theme/app_theme.dart';

class AddRawMaterialDialog extends StatefulWidget {
  final FactoryStore store;
  final RawMaterial? rawMaterialToEdit;

  const AddRawMaterialDialog({super.key, required this.store, this.rawMaterialToEdit});

  @override
  State<AddRawMaterialDialog> createState() => _AddRawMaterialDialogState();
}

class _AddRawMaterialDialogState extends State<AddRawMaterialDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _unitController;
  late TextEditingController _currentStockController;
  late TextEditingController _minStockAlertController;
  late TextEditingController _unitCostController;
  late TextEditingController _supplierController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final rm = widget.rawMaterialToEdit;
    _nameController = TextEditingController(text: rm?.name ?? '');
    _categoryController = TextEditingController(text: rm?.category ?? 'خامات بوليمر');
    _unitController = TextEditingController(text: rm?.unit ?? 'كجم');
    _currentStockController = TextEditingController(text: rm != null ? rm.currentStock.toStringAsFixed(0) : '0');
    _minStockAlertController = TextEditingController(text: rm != null ? rm.minStockAlert.toStringAsFixed(0) : '10');
    _unitCostController = TextEditingController(text: rm != null ? rm.unitCost.toStringAsFixed(2) : '0.00');
    _supplierController = TextEditingController(text: rm?.supplierId ?? '');
    _notesController = TextEditingController(text: rm?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _currentStockController.dispose();
    _minStockAlertController.dispose();
    _unitCostController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.rawMaterialToEdit != null;

    return StyledDialog(
      title: isEditing ? 'تعديل مادة خام' : 'إضافة مادة خام جديدة',
      hasUnsavedChanges: true,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreenSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: AppTheme.successGreen),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'تعديل مادة خام' : 'إضافة مادة خام جديدة',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // الاسم والفئة
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('اسم المادة الخام', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'مثال: خام HDPE (سابك 218W)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل اسم المادة' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الفئة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _categoryController.text.isNotEmpty ? _categoryController.text : 'خامات بوليمر',
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'خامات بوليمر', child: Text('خامات بوليمر')),
                              DropdownMenuItem(value: 'ماستر باتش', child: Text('ماستر باتش')),
                              DropdownMenuItem(value: 'إضافات', child: Text('إضافات')),
                              DropdownMenuItem(value: 'مواد تعبئة', child: Text('مواد تعبئة')),
                              DropdownMenuItem(value: 'مواد راجعة', child: Text('مواد راجعة')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _categoryController.text = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // الوحدة والمورد
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('وحدة القياس', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _unitController.text.isNotEmpty ? _unitController.text : 'كجم',
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'كجم', child: Text('كجم')),
                              DropdownMenuItem(value: 'طن', child: Text('طن')),
                              DropdownMenuItem(value: 'لتر', child: Text('لتر')),
                              DropdownMenuItem(value: 'كيس', child: Text('كيس')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _unitController.text = val);
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
                          const Text('المورد (اختياري)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _supplierController.text.isNotEmpty ? _supplierController.text : null,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: [
                              const DropdownMenuItem(value: '', child: Text('بدون مورد')),
                              ...widget.store.suppliers.map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text('${s.name} - ${s.companyName}'),
                              )),
                            ],
                            onChanged: (val) {
                              setState(() => _supplierController.text = val ?? '');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // المخزون الحالي، حد التنبيه، التكلفة
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('المخزون الحالي', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryBlue)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _currentStockController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffixText: 'الوحدة',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل رقم' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('حد التنبيه (الحد الأدنى)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.wasteRed)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _minStockAlertController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffixText: 'الوحدة',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل رقم' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('تكلفة الوحدة (جنيه)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.costPurple)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _unitCostController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffixText: 'جنيه',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل رقم' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // قيمة المخزون الإجمالية
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('قيمة المخزون', '${(double.tryParse(_currentStockController.text) ?? 0) * (double.tryParse(_unitCostController.text) ?? 0)} ج.م', AppTheme.successGreen),
                      _buildMiniStat('حالة المخزون', (double.tryParse(_currentStockController.text) ?? 0) < (double.tryParse(_minStockAlertController.text) ?? 0) ? 'منخفض ⚠️' : 'طبيعي ✓', (double.tryParse(_currentStockController.text) ?? 0) < (double.tryParse(_minStockAlertController.text) ?? 0) ? AppTheme.wasteRed : AppTheme.successGreen),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ملاحظات
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'أي ملاحظات إضافية...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(isEditing ? 'حفظ التعديلات' : 'إضافة المادة الخام', style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final material = RawMaterial(
                            id: widget.rawMaterialToEdit?.id ?? 'rm-${DateTime.now().millisecondsSinceEpoch}',
                            name: _nameController.text.trim(),
                            category: _categoryController.text.trim(),
                            unit: _unitController.text.trim(),
                            currentStock: double.parse(_currentStockController.text),
                            minStockAlert: double.parse(_minStockAlertController.text),
                            unitCost: double.parse(_unitCostController.text),
                            supplierId: _supplierController.text.isNotEmpty ? _supplierController.text : null,
                            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
                          );
                          if (isEditing) {
                            widget.store.updateRawMaterial(material);
                          } else {
                            widget.store.addRawMaterial(material);
                          }
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEditing ? 'تم تعديل المادة الخام بنجاح!' : 'تمت إضافة المادة الخام وحفظها محلياً بنجاح!'),
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
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}