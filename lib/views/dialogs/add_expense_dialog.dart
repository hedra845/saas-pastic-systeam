import 'package:flutter/material.dart';
import '../../models/expense_item.dart';
import '../../state/factory_store.dart';
import '../../theme/app_theme.dart';

class AddExpenseDialog extends StatefulWidget {
  final FactoryStore store;

  const AddExpenseDialog({super.key, required this.store});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'المواد الخام';
  bool _deductFromTreasury = true;

  final FocusNode _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto‑focus on the title field after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _titleFocusNode.requestFocus());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى إدخال مبلغ صحيح أكبر من الصفر!'),
            backgroundColor: AppTheme.wasteRed,
          ),
        );
        return;
      }

      widget.store.addExpense(
        ExpenseItem(
          id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
          title: _titleController.text.trim(),
          category: _selectedCategory,
          amount: amount,
          date: DateTime.now(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ),
        deductFromTreasury: _deductFromTreasury,
      );

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل المصروف وتحديث إجمالي التكاليف بنجاح!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceWhite,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // رأس الحوار الأنيق الموحد
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.costPurpleSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.attach_money, color: AppTheme.costPurple, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إضافة بند مصروفات وتكاليف',
                        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'تسجيل تكلفة خامات أو مصروفات إدارية وتشغيلية',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                    ],
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
              const Divider(height: 22),

              // جسم النموذج القابل للتمرير لمنع أي Overflow
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('بيان المصروف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _titleController,
                          focusNode: _titleFocusNode,
                          decoration: InputDecoration(
                            hintText: 'مثال: فاتورة كهرباء، صيانة سكاكين، خامات بوليمر...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال بيان المصروف' : null,
                        ),
                        const SizedBox(height: 14),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // الفئة / التصنيف
                            Expanded(
                              flex: 11,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('الخانة / التصنيف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    isDense: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'المواد الخام',
                                        child: Text(
                                          'المواد الخام (خامات)',
                                          style: TextStyle(fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'مصروفات إدارية',
                                        child: Text(
                                          'مصروفات إدارية',
                                          style: TextStyle(fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'العمالة',
                                        child: Text(
                                          'العمالة والرواتب',
                                          style: TextStyle(fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'الكهرباء',
                                        child: Text(
                                          'الكهرباء والمرافق',
                                          style: TextStyle(fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'الصيانة',
                                        child: Text(
                                          'الصيانة وقطع الغيار',
                                          style: TextStyle(fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'تكاليف أخرى',
                                        child: Text(
                                          'تكاليف ومصروفات أخرى',
                                          style: TextStyle(fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedCategory = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // المبلغ
                            Expanded(
                              flex: 9,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('المبلغ (ج.م)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _amountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _saveExpense(),
                                    decoration: InputDecoration(
                                      hintText: '0.00',
                                      suffixText: 'ج.م',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'أدخل المبلغ';
                                      final n = double.tryParse(v.trim());
                                      if (n == null || n <= 0) return 'مبلغ أكبر من 0';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        const Text('ملاحظات إضافية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'أي تفاصيل عن الفاتورة أو المورد أو الفني...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // خيار الخصم المباشر من الخزنة
                        Container(
                          decoration: BoxDecoration(
                            color: _deductFromTreasury ? AppTheme.costPurpleSoft.withValues(alpha: 0.4) : AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _deductFromTreasury ? AppTheme.costPurple.withValues(alpha: 0.3) : AppTheme.borderLight,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: _deductFromTreasury,
                            activeColor: AppTheme.costPurple,
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            title: const Text(
                              'تسجيل خصم نقدي من الخزينة تلقائياً',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.textPrimary),
                            ),
                            subtitle: const Text(
                              'إدراج حركة منصرف كاش فورية في دفتر حركة خزنة المصنع',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                            onChanged: (val) => setState(() => _deductFromTreasury = val ?? true),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // أزرار التحكم في أسفل الحوار
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: const Text('إلغاء', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.costPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('تسجيل المصروف', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _saveExpense,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
