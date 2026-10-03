import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../state/factory_store.dart';

class TreasuryView extends StatefulWidget {
  final FactoryStore store;

  const TreasuryView({super.key, required this.store});

  @override
  State<TreasuryView> createState() => _TreasuryViewState();
}

class _TreasuryViewState extends State<TreasuryView> {
  String _filterType = 'الكل';

  String _formatNumber(num value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final transactions = store.treasuryTransactions.where((t) {
      if (_filterType == 'وارد') return t.isIncome;
      if (_filterType == 'منصرف') return !t.isIncome;
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // -------------------------------------------------------------
          // 1. ترويسة الخزنة والأزرار السريعة
          // -------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'خزنة المصنع النقدية ودفتر اليومية',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'إدارة السيولة النقدية، تتبع المقبوضات والمدفوعات، وإصدار سندات القبض والصرف بدقة',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('إيداع نقدي (سند قبض)', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showAddTransactionDialog(context, isIncome: true),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.wasteRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: const Text('صرف نقدي (سند صرف)', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showAddTransactionDialog(context, isIncome: false),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // -------------------------------------------------------------
          // 2. كارت رأس المال (منفصل تماماً - قابل للإضافة والتعديل)
          // -------------------------------------------------------------
          _buildCapitalCard(context),
          const SizedBox(height: 18),

          // -------------------------------------------------------------
          // 3. كروت المؤشرات النقدية للخزنة
          // -------------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: _statCard('رصيد الخزنة الكاش الحالي', '${_formatNumber(store.currentVaultBalance)} ج.م', Icons.account_balance_wallet, const Color(0xFF0D9488), const Color(0xFFF0FDFA)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('إجمالي المقبوضات (الوارد)', '${_formatNumber(store.totalTreasuryIncome)} ج.م', Icons.arrow_circle_down_rounded, AppTheme.successGreen, AppTheme.successGreenSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('إجمالي المدفوعات (المنصرف)', '${_formatNumber(store.totalTreasuryExpense)} ج.م', Icons.arrow_circle_up_rounded, AppTheme.wasteRed, AppTheme.wasteRedSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('إجمالي حركات الخزنة', '${transactions.length} حركة مسجلة', Icons.receipt_long_outlined, AppTheme.primaryBlue, AppTheme.primaryBlueSoft),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // -------------------------------------------------------------
          // 3. سجل حركات الخزنة وسندات القبض والصرف والمصروفات
          // -------------------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'دفتر يومية الخزنة النقدية (${transactions.length} حركة)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Row(
                        children: [
                          const Text('تصفية الحركة: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _filterType,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'الكل', child: Text('جميع الحركات')),
                              DropdownMenuItem(value: 'وارد', child: Text('وارد / مقبوضات فقط')),
                              DropdownMenuItem(value: 'منصرف', child: Text('منصرف / مصروفات فقط')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _filterType = v);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.6), // رقم السند
                      1: FlexColumnWidth(1.4), // نوع الحركة
                      2: FlexColumnWidth(3.0), // البيان والتفاصيل
                      3: FlexColumnWidth(1.6), // التصنيف
                      4: FlexColumnWidth(1.6), // المبلغ
                      5: FlexColumnWidth(1.8), // الرصيد بعد الحركة
                      6: FlexColumnWidth(1.8), // المسؤول
                      7: FlexColumnWidth(1.8), // التاريخ
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: AppTheme.background,
                          border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                        ),
                        children: [
                          _headerCell('رقم السند'),
                          _headerCell('نوع الحركة'),
                          _headerCell('البيان وتفاصيل العملية'),
                          _headerCell('التصنيف'),
                          _headerCell('المبلغ'),
                          _headerCell('رصيد الخزنة بعد الحركة'),
                          _headerCell('أمين الخزنة / المستلم'),
                          _headerCell('التاريخ'),
                        ],
                      ),
                      ...transactions.map((t) {
                        return TableRow(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                          ),
                          children: [
                            _textCell(t.voucherNumber, isBold: true),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: t.isIncome ? AppTheme.successGreenSoft : AppTheme.wasteRedSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t.type,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: t.isIncome ? AppTheme.successGreen : AppTheme.wasteRed,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _textCell(t.title, isBold: true),
                            _textCell(t.category),
                            _textCell(
                              '${t.isIncome ? "+" : "-"}${_formatNumber(t.amount)} ج.م',
                              isBold: true,
                              color: t.isIncome ? AppTheme.successGreen : AppTheme.wasteRed,
                            ),
                            _textCell('${_formatNumber(t.balanceAfter)} ج.م', isBold: true),
                            _textCell(t.personInCharge),
                            _textCell('${t.date.day}/${t.date.month} - ${t.date.hour}:${t.date.minute.toString().padLeft(2, '0')}'),
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


  Widget _headerCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary), textAlign: TextAlign.right),
    );
  }

  Widget _textCell(String text, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
      child: Text(text, style: TextStyle(fontSize: 12.5, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? AppTheme.textPrimary), textAlign: TextAlign.right),
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
                  Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // كارت رأس المال المنفصل
  // -------------------------------------------------------------
  Widget _buildCapitalCard(BuildContext context) {
    final store = widget.store;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
        child: Row(
          children: [
            // أيقونة رأس المال
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.savings_outlined, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 18),
            // بيان رأس المال
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رأس مال المصنع',
                    style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.capitalAmount > 0
                        ? '${_formatNumber(store.capitalAmount)} ج.م'
                        : 'لم يتم تحديد رأس المال بعد',
                    style: TextStyle(
                      fontSize: store.capitalAmount > 0 ? 24 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (store.capitalAmount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'رصيد الخزنة: ${_formatNumber(store.currentVaultBalance)} ج.م  |  '
                      'الفرق: ${_formatNumber(store.currentVaultBalance - store.capitalAmount)} ج.م',
                      style: const TextStyle(fontSize: 11.5, color: Colors.white60),
                    ),
                  ],
                ],
              ),
            ),
            // زر التعديل
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(store.capitalAmount > 0 ? 'تعديل' : 'تحديد رأس المال'),
              onPressed: () => _showCapitalDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showCapitalDialog(BuildContext context) {
    final store = widget.store;
    final ctrl = TextEditingController(
      text: store.capitalAmount > 0 ? store.capitalAmount.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.savings_outlined, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('تحديد / تعديل رأس مال المصنع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'أدخل قيمة رأس المال الأساسي للمصنع (بالجنيه المصري)',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'رأس المال (جنيه)',
                  border: OutlineInputBorder(),
                  suffixText: 'ج.م',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
              ),
              if (store.capitalAmount > 0) ...[
                const SizedBox(height: 10),
                Text(
                  'القيمة الحالية: ${_formatNumber(store.capitalAmount)} ج.م',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = double.tryParse(ctrl.text.replaceAll(',', ''));
              if (val != null && val >= 0) {
                store.updateCapitalAmount(val);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حفظ رأس المال بنجاح!'),
                    backgroundColor: Color(0xFF2563EB),
                  ),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, {required bool isIncome}) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final personCtrl = TextEditingController(text: 'أمين الخزنة: عماد عاطف');
    final notesCtrl = TextEditingController();
    String category = isIncome ? 'مبيعات نقدية' : 'المواد الخام';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(isIncome ? Icons.add_circle : Icons.remove_circle, color: isIncome ? AppTheme.successGreen : AppTheme.wasteRed),
                  const SizedBox(width: 8),
                  Text(
                    isIncome ? 'تسجيل إيداع نقدي في الخزنة (سند قبض)' : 'تسجيل صرف نقدي من الخزنة (سند صرف ومصروفات)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('البيان / سبب ${isIncome ? "الإيداع" : "الصرف"}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: isIncome ? 'مثال: تحصيل مبيعات نقدية من تاجر...' : 'مثال: سداد فاتورة صيانة ماكينات...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('التصنيف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: category,
                                decoration: const InputDecoration(border: OutlineInputBorder()),
                                items: (isIncome
                                        ? const ['مبيعات نقدية', 'مبيعات جملة', 'مبيعات قطاعي', 'تحصيل مديونية', 'بيع راجع وسكراب', 'إيداع رأس مال']
                                        : const ['المواد الخام', 'العمالة', 'الكهرباء', 'الصيانة', 'تكاليف أخرى'])
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setDialogState(() => category = v);
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
                              const Text('المبلغ (جنيه)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: amountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: 'جنيه'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    const Text('المستلم / القائم بالعملية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: personCtrl,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),

                    const Text('ملاحظات إضافية أو رقم الإيصال', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isIncome ? AppTheme.successGreen : AppTheme.wasteRed,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (titleCtrl.text.isNotEmpty && amount > 0) {
                      widget.store.addTreasuryTransaction(
                        type: isIncome ? 'وارد / إيداع' : 'منصرف / سحب',
                        title: titleCtrl.text.trim(),
                        category: category,
                        amount: amount,
                        person: personCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                        logHistory: true,
                      );
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isIncome ? 'تم تسجيل الإيداع وتحديث رصيد الخزنة!' : 'تم تسجيل الصند والمصروف وخصمه من الخزنة!'),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                    }
                  },
                  child: Text(isIncome ? 'تأكيد الإيداع' : 'تأكيد الصرف'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
