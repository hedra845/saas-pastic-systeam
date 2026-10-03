import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/salary_payment.dart';
import '../../state/factory_store.dart';
import '../../theme/app_theme.dart';

class SalaryReceiptDialog extends StatelessWidget {
  final SalaryPayment payment;
  final FactoryStore store;

  const SalaryReceiptDialog({
    super.key,
    required this.payment,
    required this.store,
  });

  String _formatNumber(num value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a');

    return Dialog(
      backgroundColor: AppTheme.surfaceWhite,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreenSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long, color: AppTheme.successGreen, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.factoryName.isNotEmpty ? store.factoryName : 'النجمة بلاست',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const Text(
                            'سند صرف راتب ومسير معتمد',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Text(
                      payment.voucherNumber,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Employee Info Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _infoField('اسم الموظف المستلم', payment.employeeName, isBold: true),
                        ),
                        Expanded(
                          child: _infoField('المسمى الوظيفي', payment.role),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _infoField('القسم', payment.department),
                        ),
                        Expanded(
                          child: _infoField('راتب شهر مستحق', payment.monthYear, isBold: true, color: AppTheme.primaryBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _infoField('تاريخ ووقت الصرف', dateFormat.format(payment.paymentDate)),
                        ),
                        Expanded(
                          child: _infoField('طريقة الدفع', payment.paymentMethod),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Detailed Salary Breakdown Table
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _breakdownRow('الراتب الأساسي الشهري', '+ ${_formatNumber(payment.baseSalary)} ج.م', isPositive: true),
                    if (payment.incentives > 0)
                      _breakdownRow('حوافز وبدلات وإضافي تشغيل', '+ ${_formatNumber(payment.incentives)} ج.م', isPositive: true),
                    if (payment.advancesDeducted > 0)
                      _breakdownRow('استقطاع سلف مستردة', '- ${_formatNumber(payment.advancesDeducted)} ج.م', isNegative: true),
                    if (payment.deductions > 0)
                      _breakdownRow('خصومات وجزاءات وغياب', '- ${_formatNumber(payment.deductions)} ج.م', isNegative: true),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppTheme.successGreenSoft,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(9),
                          bottomRight: Radius.circular(9),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'صافي الراتب المستلم',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                          ),
                          Text(
                            '${_formatNumber(payment.netSalary)} جنيه مصري',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (payment.notes != null && payment.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('ملاحظات: ${payment.notes}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ),

              const SizedBox(height: 20),

              // Signatures
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _signatureBox('توقيع الموظف المستلم'),
                  _signatureBox('أمين الخزنة / الصراف'),
                  _signatureBox('اعتماد الإدارة المالية'),
                ],
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('طباعة السند'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إرسال السند إلى أمر الطباعة'), backgroundColor: AppTheme.primaryBlue),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoField(String title, String val, {bool isBold = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _breakdownRow(String title, String amount, {bool isPositive = false, bool isNegative = false}) {
    Color col = AppTheme.textPrimary;
    if (isPositive) col = const Color(0xFF1E40AF);
    if (isNegative) col = AppTheme.wasteRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12.5)),
          Text(amount, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: col)),
        ],
      ),
    );
  }

  Widget _signatureBox(String label) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 32),
        Container(width: 110, height: 1, color: AppTheme.borderSubtle),
      ],
    );
  }
}
