import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product_item.dart';
import '../../state/factory_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/styled_dialog.dart';

class AddProductStockDialog extends StatefulWidget {
  final FactoryStore store;
  final ProductItem? initialProduct;

  const AddProductStockDialog({
    super.key,
    required this.store,
    this.initialProduct,
  });

  @override
  State<AddProductStockDialog> createState() => _AddProductStockDialogState();
}

class _AddProductStockDialogState extends State<AddProductStockDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedProductId;
  late TextEditingController _quantityController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;

  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd - hh:mm a');

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _selectedProductId = widget.initialProduct!.id;
    } else if (widget.store.products.isNotEmpty) {
      _selectedProductId = widget.store.products.first.id;
    } else {
      _selectedProductId = '';
    }

    _quantityController = TextEditingController();
    _notesController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  ProductItem? get _currentProduct {
    if (_selectedProductId.isEmpty) return null;
    return widget.store.products.firstWhere(
      (p) => p.id == _selectedProductId,
      orElse: () => widget.store.products.first,
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _selectedDate.hour,
            _selectedDate.minute,
          );
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final qty = double.parse(_quantityController.text.trim());
      final prod = _currentProduct;
      if (prod == null) return;

      widget.store.addProductStock(
        productId: prod.id,
        additionalStockKg: qty,
        date: _selectedDate,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة ${qty.toStringAsFixed(1)} كجم بنجاح إلى مخزون صنف "${prod.name}"!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prod = _currentProduct;
    if (prod == null) {
      return AlertDialog(
        title: const Text('لا توجد أصناف'),
        content: const Text('يرجى إضافة أصناف أولاً قبل تسجيل إضافة مخزون.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      );
    }

    final double addedQty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final double projectedStock = prod.stockKg + addedQty;

    return StyledDialog(
      title: 'إضافة مخزون لصنف وسجل التواريخ',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. اختيار الصنف ومعلوماته الحالية
            if (widget.initialProduct == null) ...[
              const Text('اختر الصنف المراد زيادة مخزونه:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedProductId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: widget.store.products.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.name} (المخزون الحالي: ${p.stockKg.toStringAsFixed(0)} كجم)'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedProductId = val);
                },
              ),
              const SizedBox(height: 14),
            ],

            // 2. بطاقة معلومات الصنف وتاريخ الإضافة الأولى
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prod.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'التصنيف: ${prod.category} | الخامة: ${prod.materialType}',
                              style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: prod.stockKg < 10 ? const Color(0xFFFEF3C7) : AppTheme.primaryBlueSoft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: prod.stockKg < 10 ? const Color(0xFFF59E0B) : AppTheme.primaryBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('المخزون الحالي', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                            Text(
                              '${prod.stockKg.toStringAsFixed(1)} كجم',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: prod.stockKg < 10 ? const Color(0xFFB45309) : AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  // تاريخ الإضافة الأولى
                  Row(
                    children: [
                      const Icon(Icons.event_available_rounded, size: 18, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      const Text(
                        'تاريخ الإضافة الأولى للصنف: ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                      Text(
                        _dateFormat.format(prod.createdAt),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. خانة إضافة مخزون جديد
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.add_circle_outline_rounded, color: AppTheme.successGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'تسجيل إضافة مخزون جديدة',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // كمية الإضافة بالكيلو
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('الكمية المضافة (كجم) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'مثال: 500',
                                suffixText: 'كجم',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'أدخل الكمية';
                                final numVal = double.tryParse(val.trim());
                                if (numVal == null || numVal <= 0) return 'كمية غير صحيحة';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // تاريخ الإضافة
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تاريخ ووقت الإضافة *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.borderSubtle),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _dateFormat.format(_selectedDate),
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryBlue),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ملاحظات الإضافة
                  const Text('ملاحظات الإضافة (اختياري)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'مثال: تشغيلة جديدة ماكينة 2 / توريد إضافي / رصيد مخزن',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  if (addedQty > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreenSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الرصيد بعد هذه الإضافة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(
                            '${projectedStock.toStringAsFixed(1)} كجم',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 6),
                          Text(
                            'نسبة الكهرباء والعمالة ثابتة: ${prod.laborAndElectricityCostPerKg.toStringAsFixed(2)} ج/كجم (محفوظة دون تخفيض)',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. سجل تواريخ إضافات المخزون السابقة
            const Text(
              'سجل تواريخ إضافات المخزون السابقة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: prod.stockAdditions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'لا توجد إضافات مخزون مسجلة بعد. الرصيد الحالي: ${prod.stockKg.toStringAsFixed(1)} كجم',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: prod.stockAdditions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        // Display newest first
                        final item = prod.stockAdditions[prod.stockAdditions.length - 1 - idx];
                        final isInitial = item.notes?.contains('الإضافة الأولى') ?? false;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: isInitial ? const Color(0xFFF8FAFC) : Colors.white,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isInitial ? AppTheme.primaryBlueSoft : AppTheme.successGreenSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isInitial ? Icons.flag_rounded : Icons.arrow_downward_rounded,
                                  size: 14,
                                  color: isInitial ? AppTheme.primaryBlue : AppTheme.successGreen,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '+${item.quantityKg.toStringAsFixed(1)} كجم',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.successGreen),
                                        ),
                                        if (isInitial) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryBlueSoft,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('الإضافة الأولى', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      item.notes ?? 'إضافة رصيد مستودع',
                                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _dateFormat.format(item.date),
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                  ),
                                  Text(
                                    'الرصيد: ${item.newStockKg.toStringAsFixed(1)} كجم',
                                    style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // أزرار التحكم
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إغلاق'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('حفظ إضافة المخزون', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
