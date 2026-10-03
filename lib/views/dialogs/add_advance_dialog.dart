import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../models/employee_advance.dart';
import '../../state/factory_store.dart';
import '../../theme/app_theme.dart';

class AddAdvanceDialog extends StatefulWidget {
  final FactoryStore store;
  final Employee? preselectedEmployee;

  const AddAdvanceDialog({
    super.key,
    required this.store,
    this.preselectedEmployee,
  });

  @override
  State<AddAdvanceDialog> createState() => _AddAdvanceDialogState();
}

class _AddAdvanceDialogState extends State<AddAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  Employee? _selectedEmployee;
  DateTime _advanceDate = DateTime.now();
  bool _deductFromTreasury = true;

  final NumberFormat _currencyFormat = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    if (widget.preselectedEmployee != null) {
      _selectedEmployee = widget.preselectedEmployee;
    } else if (widget.store.employees.isNotEmpty) {
      _selectedEmployee = widget.store.employees.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveAdvance() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الموظف أولاً'), backgroundColor: AppTheme.wasteRed),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال مبلغ صحيح للسلفة'), backgroundColor: AppTheme.wasteRed),
      );
      return;
    }

    final advance = EmployeeAdvance(
      id: 'adv-${DateTime.now().millisecondsSinceEpoch}',
      employeeId: _selectedEmployee!.id,
      employeeName: _selectedEmployee!.name,
      amount: amount,
      date: _advanceDate,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : 'سلفة شخصية',
      deductedFromTreasury: _deductFromTreasury,
    );

    widget.store.addEmployeeAdvance(
      advance,
      deductFromTreasury: _deductFromTreasury,
      person: 'مسؤول الخزنة',
    );

    Navigator.of(context).pop(true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تسجيل سلفة بمبلغ ${_currencyFormat.format(amount)} ج.م للموظف ${_selectedEmployee!.name} بنجاح!'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingAdvances = _selectedEmployee != null
        ? widget.store.getEmployeePendingAdvances(_selectedEmployee!.id)
        : 0.0;

    return Dialog(
      backgroundColor: AppTheme.surfaceWhite,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.costPurpleSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.request_quote_outlined, color: AppTheme.costPurple, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'تسجيل سلفة نقدية لموظف',
                            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'صرف سلفة شخصية وخصمها من خزنة المصنع ومتابعة استردادها',
                            style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اختيار الموظف
                        const Text('اختيار الموظف المستفيد', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<Employee>(
                          value: _selectedEmployee,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_outline, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: widget.store.employees.map((emp) {
                            return DropdownMenuItem<Employee>(
                              value: emp,
                              child: Text('${emp.name} (${emp.role} - ${emp.department})', style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedEmployee = val;
                            });
                          },
                          validator: (val) => val == null ? 'يرجى اختيار الموظف' : null,
                        ),
                        const SizedBox(height: 12),

                        // بطاقة ملخص الموظف
                        if (_selectedEmployee != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('الراتب الشهري الأساسي', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_currencyFormat.format(_selectedEmployee!.monthlySalary)} ج.م',
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 30, color: AppTheme.borderLight),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('رصيد السلف الحالية المعلقة', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_currencyFormat.format(pendingAdvances)} ج.م',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: pendingAdvances > 0 ? AppTheme.profitAmber : AppTheme.successGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 14),

                        // مبلغ السلفة وتاريخها
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('مبلغ السلفة (جنيه)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _amountController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      hintText: 'مثال: 1000',
                                      prefixIcon: const Icon(Icons.attach_money, size: 18),
                                      suffixText: 'ج.م',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'مطلوب';
                                      final numVal = double.tryParse(val.trim());
                                      if (numVal == null || numVal <= 0) return 'مبلغ غير صالح';
                                      return null;
                                    },
                                    onChanged: (val) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('تاريخ السلفة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _advanceDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setState(() => _advanceDate = picked);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppTheme.borderLight),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(DateFormat('yyyy/MM/dd').format(_advanceDate), style: const TextStyle(fontSize: 12.5)),
                                          const Icon(Icons.calendar_today, size: 16, color: AppTheme.textMuted),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // سبب السلفة / ملاحظات
                        const Text('سبب السلفة / ملاحظات إضافية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _notesController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'مثال: سلفة علاجية طارئة، سلفة أعياد ومناسبات...',
                            prefixIcon: const Icon(Icons.notes_outlined, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // خيار الخصم من الخزنة
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _deductFromTreasury ? const Color(0xFFEFF6FF) : AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _deductFromTreasury ? AppTheme.primaryBlue.withValues(alpha: 0.3) : AppTheme.borderLight),
                          ),
                          child: CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('صرف المبلغ كاش من خزنة المصنع تلقائياً', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            subtitle: const Text('سيتم تسجيل سند صرف نقدي بقيمة السلفة في حركة الخزنة فوراً', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            value: _deductFromTreasury,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) {
                              setState(() => _deductFromTreasury = val ?? true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.costPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('اعتماد وصرف السلفة', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _saveAdvance,
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
