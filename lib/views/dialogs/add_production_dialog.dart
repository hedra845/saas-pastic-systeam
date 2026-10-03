import 'package:flutter/material.dart';
import '../../widgets/styled_dialog.dart';
import '../../state/factory_store.dart';
import '../../theme/app_theme.dart';

class AddProductionDialog extends StatefulWidget {
  final FactoryStore store;

  const AddProductionDialog({super.key, required this.store});

  @override
  State<AddProductionDialog> createState() => _AddProductionDialogState();
}

class _AddProductionDialogState extends State<AddProductionDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedProductId;
  final _wasteKgController = TextEditingController();
  final _machineController = TextEditingController();
  final _operatorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.store.products.isNotEmpty) {
      _selectedProductId = widget.store.products.first.id;
    } else {
      _selectedProductId = '';
    }
    _wasteKgController.text = '0';
  }

  @override
  void dispose() {
    _wasteKgController.dispose();
    _machineController.dispose();
    _operatorController.dispose();
    super.dispose();
  }

  double _calculateBatchCost(String productId, double batchKg) {
    return widget.store.calculateProductionBatchCost(productId, batchKg);
  }

  void _saveProduction() {
    final product = widget.store.products.firstWhere((p) => p.id == _selectedProductId);
    final netKg = product.defaultBatchKg;
    final wasteKg = double.tryParse(_wasteKgController.text) ?? 0.0;
    final cost = _calculateBatchCost(_selectedProductId, netKg);

    widget.store.addProductionBatch(
      productId: _selectedProductId,
      netKg: netKg,
      wasteKg: wasteKg,
      cost: cost,
      machine: _machineController.text.trim(),
      operator: _operatorController.text.trim(),
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تسجيل تشغيلة "${product.name}" - إنتاج ${netKg.toStringAsFixed(0)} كجم، تكلفة ${cost.toStringAsFixed(0)} ج.م'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _selectedProductId.isNotEmpty
        ? widget.store.products.firstWhere((p) => p.id == _selectedProductId)
        : null;

    final netKg = product?.defaultBatchKg ?? 0.0;
    final cost = product != null ? _calculateBatchCost(_selectedProductId, netKg) : 0.0;
    final rawMaterials = product != null ? widget.store.getRawMaterialDetailsForProduct(_selectedProductId) : [];

    return StyledDialog(
      title: 'إضافة تشغيلة إنتاج جديدة',
      hasUnsavedChanges: true,
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 24),
              // اختيار الصنف
              const Text('الصنف المراد إنتاجه', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedProductId.isNotEmpty ? _selectedProductId : null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: widget.store.products.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.name} (${p.category})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedProductId = val;
                    });
                  }
                },
              ),

              if (product != null) ...[
                const SizedBox(height: 20),
                // معلومات الصنف المختارة
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('معلومات الصنف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryBlue)),
                      const SizedBox(height: 8),
                      _buildInfoRow('اسم الصنف', product.name),
                      _buildInfoRow('الفئة', product.category),
                      _buildInfoRow('نوع المادة', product.materialType),
                      _buildInfoRow('حجم التشغيلة الافتراضي', '${product.defaultBatchKg.toStringAsFixed(0)} كجم'),
                      _buildInfoRow('سعر المبيعات الجملية', '${product.wholesalePricePerKg.toStringAsFixed(2)} ج.م/كجم'),
                      _buildInfoRow('سعر المبيعات القطاعية', '${product.retailPricePerKg.toStringAsFixed(2)} ج.م/كجم'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // تكلفة التشغيلة المحسوبة
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.costPurpleSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.costPurple.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('تكلفة التشغيلة المحسوبة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.costPurple)),
                      const SizedBox(height: 6),
                      Text(
                        '${cost.toStringAsFixed(2)} ج.م',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.costPurple),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'مبنية على ${rawMaterials.length} مادة خام',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      if (rawMaterials.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...rawMaterials.map((rm) => _buildRawMaterialRow(rm)),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // مدخلات التشغيلة
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('هالك التشغيل (كجم)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _wasteKgController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              suffixText: 'كجم',
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
                          const Text('الماكينة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _machineController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              hintText: 'اختياري',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('العامل', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _operatorController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              hintText: 'اختياري',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                // ملخص العملية
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreenSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ملخص العملية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.successGreen)),
                      const SizedBox(height: 6),
                      _buildInfoRow('الكمية المنتجة', '${netKg.toStringAsFixed(0)} كجم'),
                      _buildInfoRow('الهالك', '${double.tryParse(_wasteKgController.text) ?? 0.0} كجم'),
                      _buildInfoRow('المخزن بعد الإنتاج', '${(product.stockKg + netKg).toStringAsFixed(0)} كجم'),
                      _buildInfoRow('إجمالي الإنتاج', '${(product.totalProducedKg + netKg).toStringAsFixed(0)} كجم'),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              // أزرار الحفظ والإلغاء
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
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('تسجيل التشغيلة وتحديث النظام', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _selectedProductId.isEmpty ? null : _saveProduction,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildRawMaterialRow(Map<String, dynamic> rm) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${rm['name']} (×${rm['quantity']})', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          Text('${rm['totalCost']?.toStringAsFixed(2) ?? '0'} ج.م', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
