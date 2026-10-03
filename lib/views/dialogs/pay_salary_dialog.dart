import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../models/salary_payment.dart';
import '../../state/factory_store.dart';
import '../../theme/app_theme.dart';
import 'salary_receipt_dialog.dart';

class PaySalaryDialog extends StatefulWidget {
  final FactoryStore store;
  final Employee? preselectedEmployee;
  final String? initialMonthYear;

  const PaySalaryDialog({
    super.key,
    required this.store,
    this.preselectedEmployee,
    this.initialMonthYear,
  });

  @override
  State<PaySalaryDialog> createState() => _PaySalaryDialogState();
}

class _PaySalaryDialogState extends State<PaySalaryDialog> {
  final _formKey = GlobalKey<FormState>();

  Employee? _selectedEmployee;
  late String _selectedMonthYear;

  final _baseSalaryCtrl = TextEditingController();
  final _incentivesCtrl = TextEditingController(text: '0');
  final _deductionsCtrl = TextEditingController(text: '0');
  final _advancesDeductCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  bool _deductAdvances = false;
  String _paymentMethod = 'نقدي كاش';
  bool _payFromTreasury = true;

  final NumberFormat _fmt = NumberFormat('#,###');

  final List<String> _availableMonths = [
    'يناير 2026',
    'فبراير 2026',
    'مارس 2026',
    'إبريل 2026',
    'مايو 2026',
    'يونيو 2026',
    'يوليو 2026',
    'أغسطس 2026',
    'سبتمبر 2026',
    'أكتوبر 2026',
    'نوفمبر 2026',
    'ديسمبر 2026',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonthYear = widget.initialMonthYear ?? 'سبتمبر 2026';
    if (widget.preselectedEmployee != null) {
      _selectEmployee(widget.preselectedEmployee!);
    } else if (widget.store.employees.isNotEmpty) {
      _selectEmployee(widget.store.employees.first);
    }
  }

  void _selectEmployee(Employee emp) {
    _selectedEmployee = emp;
    _baseSalaryCtrl.text = emp.monthlySalary.toStringAsFixed(0);

    final pending = widget.store.getEmployeePendingAdvances(emp.id);
    if (pending > 0) {
      _deductAdvances = true;
      // Propose deducting either all or up to half base salary
      final proposed = pending <= emp.monthlySalary ? pending : emp.monthlySalary * 0.5;
      _advancesDeductCtrl.text = proposed.toStringAsFixed(0);
    } else {
      _deductAdvances = false;
      _advancesDeductCtrl.text = '0';
    }
  }

  @override
  void dispose() {
    _baseSalaryCtrl.dispose();
    _incentivesCtrl.dispose();
    _deductionsCtrl.dispose();
    _advancesDeductCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _baseSalary => double.tryParse(_baseSalaryCtrl.text.trim()) ?? 0.0;
  double get _incentives => double.tryParse(_incentivesCtrl.text.trim()) ?? 0.0;
  double get _deductions => double.tryParse(_deductionsCtrl.text.trim()) ?? 0.0;
  double get _advancesDeducted => _deductAdvances ? (double.tryParse(_advancesDeductCtrl.text.trim()) ?? 0.0) : 0.0;
  double get _netSalary => (_baseSalary + _incentives - _deductions - _advancesDeducted).clamp(0.0, double.infinity);

  void _submitPayment() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) return;

    final voucherNumber = 'PAY-SAL-2026-${(widget.store.salaryPayments.length + 1).toString().padLeft(3, '0')}';

    final payment = SalaryPayment(
      id: 'sal-${DateTime.now().millisecondsSinceEpoch}',
      voucherNumber: voucherNumber,
      employeeId: _selectedEmployee!.id,
      employeeName: _selectedEmployee!.name,
      role: _selectedEmployee!.role,
      department: _selectedEmployee!.department,
      monthYear: _selectedMonthYear,
      baseSalary: _baseSalary,
      incentives: _incentives,
      deductions: _deductions,
      advancesDeducted: _advancesDeducted,
      netSalary: _netSalary,
      paymentDate: DateTime.now(),
      paymentMethod: _paymentMethod,
      paidFromTreasury: _payFromTreasury,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    );

    widget.store.addSalaryPayment(
      payment,
      payFromTreasury: _payFromTreasury,
      person: 'مسؤول الخزنة',
    );

    Navigator.of(context).pop(true);

    // Show voucher receipt
    showDialog(
      context: context,
      builder: (_) => SalaryReceiptDialog(payment: payment, store: widget.store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingAdvances = _selectedEmployee != null
        ? widget.store.getEmployeePendingAdvances(_selectedEmployee!.id)
        : 0.0;

    final isAlreadyPaid = _selectedEmployee != null &&
        widget.store.isEmployeeSalaryPaidForMonth(_selectedEmployee!.id, _selectedMonthYear);

    return Dialog(
      backgroundColor: AppTheme.surfaceWhite,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
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
                        color: AppTheme.successGreenSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.payments_outlined, color: AppTheme.successGreen, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'صرف وقبض راتب موظف',
                            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'احتساب البدلات والإضافي وخصم السلف والجزاءات وصرف الصافي نقدياً',
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
                const Divider(height: 22),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // شهر الاستحقاق والموظف
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('الموظف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                  const SizedBox(height: 5),
                                  DropdownButtonFormField<Employee>(
                                    value: _selectedEmployee,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.person_outline, size: 18),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    items: widget.store.employees.map((emp) {
                                      return DropdownMenuItem<Employee>(
                                        value: emp,
                                        child: Text('${emp.name} (${emp.role})', style: const TextStyle(fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectEmployee(val);
                                        });
                                      }
                                    },
                                    validator: (val) => val == null ? 'مطلوب' : null,
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
                                  const Text('شهر الاستحقاق', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                  const SizedBox(height: 5),
                                  DropdownButtonFormField<String>(
                                    value: _selectedMonthYear,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    items: _availableMonths.map((m) {
                                      return DropdownMenuItem<String>(
                                        value: m,
                                        child: Text(m, style: const TextStyle(fontSize: 12.5)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedMonthYear = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // تحذير إذا كان الموظف تم صرف راتبه مسبقاً لهذا الشهر
                        if (isAlreadyPaid)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: AppTheme.wasteRed, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'تنبيه: تم تسجيل صرف راتب هذا الشهر مسبقاً لهذا الموظف! يمكنك المتابعة إن كان صرفاً إضافياً.',
                                    style: TextStyle(fontSize: 11.5, color: AppTheme.wasteRed, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // بنود الراتب والحوافز
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('الراتب الأساسي (جنيه)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                  const SizedBox(height: 5),
                                  TextFormField(
                                    controller: _baseSalaryCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      suffixText: 'ج.م',
                                    ),
                                    onChanged: (val) => setState(() {}),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return 'مطلوب';
                                      if (double.tryParse(val) == null) return 'غير صالح';
                                      return null;
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
                                  const Text('حوافز / إضافي / مكافآت', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF1E40AF))),
                                  const SizedBox(height: 5),
                                  TextFormField(
                                    controller: _incentivesCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF1E40AF)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      suffixText: 'ج.م',
                                    ),
                                    onChanged: (val) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // الخصومات واستقطاع السلف
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('خصومات / جزاءات / غياب', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppTheme.wasteRed)),
                                  const SizedBox(height: 5),
                                  TextFormField(
                                    controller: _deductionsCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.wasteRed),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.remove_circle_outline, size: 18, color: AppTheme.wasteRed),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      suffixText: 'ج.م',
                                    ),
                                    onChanged: (val) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('استقطاع سلف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppTheme.costPurple)),
                                      if (pendingAdvances > 0)
                                        Text('قائم: ${_fmt.format(pendingAdvances)} ج.م', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  TextFormField(
                                    controller: _advancesDeductCtrl,
                                    enabled: _deductAdvances,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.costPurple),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.request_quote_outlined, size: 18, color: AppTheme.costPurple),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      suffixText: 'ج.م',
                                      filled: !_deductAdvances,
                                      fillColor: _deductAdvances ? null : AppTheme.background,
                                    ),
                                    onChanged: (val) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // خيار استقطاع السلف
                        if (pendingAdvances > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _deductAdvances,
                                  activeColor: AppTheme.costPurple,
                                  onChanged: (val) {
                                    setState(() {
                                      _deductAdvances = val ?? false;
                                      if (_deductAdvances) {
                                        final proposed = pendingAdvances <= _baseSalary ? pendingAdvances : _baseSalary * 0.5;
                                        _advancesDeductCtrl.text = proposed.toStringAsFixed(0);
                                      } else {
                                        _advancesDeductCtrl.text = '0';
                                      }
                                    });
                                  },
                                ),
                                Text(
                                  'تفعيل خصم السلفة من راتب هذا الشهر (المتبقي بذمته ${_fmt.format(pendingAdvances)} ج.م)',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                                const Spacer(),
                                if (_deductAdvances)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _advancesDeductCtrl.text = pendingAdvances.toStringAsFixed(0);
                                      });
                                    },
                                    child: const Text('خصم كامل السلفة', style: TextStyle(fontSize: 11.5)),
                                  ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 12),

                        // طريقة الدفع والخصم من الخزنة
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('طريقة الصرف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                  const SizedBox(height: 5),
                                  DropdownButtonFormField<String>(
                                    value: _paymentMethod,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'نقدي كاش', child: Text('نقدي كاش من الخزنة')),
                                      DropdownMenuItem(value: 'تحويل بنكي', child: Text('تحويل بنكي / محفظة')),
                                      DropdownMenuItem(value: 'شيك', child: Text('شيك مصرفي')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _paymentMethod = val;
                                          _payFromTreasury = val == 'نقدي كاش';
                                        });
                                      }
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
                                  const Text('ملاحظات الصرف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                  const SizedBox(height: 5),
                                  TextFormField(
                                    controller: _notesCtrl,
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'ملاحظات اختيارية...',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // بطاقة ملخص صافي الراتب المستحق
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreenSoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('الراتب الأساسي:', style: TextStyle(fontSize: 12)),
                                  Text('+ ${_fmt.format(_baseSalary)} ج.م', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              if (_incentives > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('إجمالي الحوافز والإضافي:', style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF))),
                                      Text('+ ${_fmt.format(_incentives)} ج.م', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                                    ],
                                  ),
                                ),
                              if (_advancesDeducted > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('استقطاع سلف:', style: TextStyle(fontSize: 12, color: AppTheme.costPurple)),
                                      Text('- ${_fmt.format(_advancesDeducted)} ج.م', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.costPurple)),
                                    ],
                                  ),
                                ),
                              if (_deductions > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('خصومات وجزاءات:', style: TextStyle(fontSize: 12, color: AppTheme.wasteRed)),
                                      Text('- ${_fmt.format(_deductions)} ج.م', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.wasteRed)),
                                    ],
                                  ),
                                ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'صافي المبلغ المستحق للصرف:',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                  ),
                                  Text(
                                    '${_fmt.format(_netSalary)} ج.م',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

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
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('اعتماد وصرف الراتب', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _submitPayment,
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
