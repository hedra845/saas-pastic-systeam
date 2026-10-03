import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee_advance.dart';
import '../../state/factory_store.dart';
import '../../theme/app_theme.dart';

class SettleAdvanceDialog extends StatefulWidget {
  final FactoryStore store;
  final EmployeeAdvance advance;

  const SettleAdvanceDialog({
    super.key,
    required this.store,
    required this.advance,
  });

  @override
  State<SettleAdvanceDialog> createState() => _SettleAdvanceDialogState();
}

class _SettleAdvanceDialogState extends State<SettleAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  bool _depositInTreasury = true;
  final NumberFormat _fmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.advance.remainingAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    widget.store.settleEmployeeAdvanceManually(widget.advance.id, amount);

    if (_depositInTreasury) {
      widget.store.addTreasuryTransaction(
        type: 'وارد / إيداع',
        title: 'سداد سلفة نقداً من الموظف: ${widget.advance.employeeName}',
        category: 'سلف موظفين',
        amount: amount,
        person: 'مسؤول الخزنة',
        notes: 'سداد يدوي لسلفة تاريخ ${DateFormat('yyyy/MM/dd').format(widget.advance.date)}',
      );
    }

    Navigator.of(context).pop(true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تسجيل سداد بمبلغ ${_fmt.format(amount)} ج.م بنجاح!'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.payments, color: AppTheme.successGreen, size: 22),
                        SizedBox(width: 8),
                        Text('سداد سلفة نقداً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                Text('الموظف: ${widget.advance.employeeName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 6),
                Text('إجمالي السلفة: ${_fmt.format(widget.advance.amount)} ج.م', style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
                Text('المسدد حتى الآن: ${_fmt.format(widget.advance.settledAmount)} ج.م', style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
                Text('المتبقي بذمته: ${_fmt.format(widget.advance.remainingAmount)} ج.م', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.wasteRed)),
                const SizedBox(height: 16),

                const Text('المبلغ المسدد الآن (جنيه)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixText: 'ج.م',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'مطلوب';
                    final v = double.tryParse(val);
                    if (v == null || v <= 0) return 'مبلغ غير صالح';
                    if (v > widget.advance.remainingAmount + 0.01) return 'المبلغ أكبر من المتبقي للسداد';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('إيداع المبلغ في خزنة المصنع نقدياً (سند قبض)', style: TextStyle(fontSize: 12.5)),
                  value: _depositInTreasury,
                  activeColor: AppTheme.successGreen,
                  onChanged: (val) => setState(() => _depositInTreasury = val ?? true),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white),
                      onPressed: _submit,
                      child: const Text('تأكيد السداد'),
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
}
