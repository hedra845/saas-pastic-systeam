import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../state/factory_store.dart';
import '../models/expense_item.dart';
import 'widgets/custom_charts.dart';
import 'dialogs/add_expense_dialog.dart';

class ExpensesView extends StatefulWidget {
  final FactoryStore store;

  const ExpensesView({super.key, required this.store});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  // 0: الكل, 1: تكلفة الخامات, 2: مصروفات إدارية وتشغيلية
  int _filterType = 0;

  String _formatNumber(num value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  bool _isRawMaterial(ExpenseItem e) {
    return e.category.contains('خام');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final totalExp = widget.store.totalExpenses;
        final rawExpenses = widget.store.expenses.where(_isRawMaterial).toList();
        final adminExpenses = widget.store.expenses.where((e) => !_isRawMaterial(e)).toList();

        final rawExp = rawExpenses.fold(0.0, (s, e) => s + e.amount);
        final adminExp = adminExpenses.fold(0.0, (s, e) => s + e.amount);

        final laborExp = widget.store.expenses.where((e) => e.category == 'العمالة' || e.category.contains('رواتب') || e.category.contains('أجور') || e.category.contains('عمال')).fold(0.0, (s, e) => s + e.amount);
        final powerExp = widget.store.expenses.where((e) => e.category.contains('كهرباء') || e.category.contains('طاقة') || e.category.contains('مرافق')).fold(0.0, (s, e) => s + e.amount);
        final maintExp = widget.store.expenses.where((e) => e.category.contains('صيان') || e.category.contains('إصلاح')).fold(0.0, (s, e) => s + e.amount);
        final otherExp = (totalExp - (rawExp + laborExp + powerExp + maintExp)).clamp(0.0, double.infinity);

        // تصفية الجدول حسب التبويب المختار
        List<ExpenseItem> displayedExpenses = widget.store.expenses;
        if (_filterType == 1) {
          displayedExpenses = rawExpenses;
        } else if (_filterType == 2) {
          displayedExpenses = adminExpenses;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس الصفحة مع زر إضافة مصروف
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'التكاليف والمصروفات التشغيلية',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'فصل وتحليل دقيق بين تكلفة الخامات والمصروفات الإدارية والتشغيلية',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.costPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('تسجيل مصروف جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddExpenseDialog(store: widget.store),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // خانتان رئيسيتان: خانة تكلفة خامات + خانة مصروفات إدارية
              // -------------------------------------------------------------
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 800;
                  final rawPercent = totalExp > 0 ? (rawExp / totalExp * 100) : 0.0;
                  final adminPercent = totalExp > 0 ? (adminExp / totalExp * 100) : 0.0;

                  final rawSection = _mainPillarCard(
                    title: 'خانة تكلفة الخامات (المباشرة)',
                    subtitle: 'مشتريات خامات البوليمر، الماستر باتش، ومستلزمات الإنتاج',
                    amount: rawExp,
                    percent: rawPercent,
                    count: rawExpenses.length,
                    icon: Icons.grain,
                    color: AppTheme.primaryBlue,
                    bgColor: AppTheme.primaryBlueSoft,
                    isSelected: _filterType == 1,
                    onTap: () => setState(() => _filterType = _filterType == 1 ? 0 : 1),
                  );

                  final adminSection = _mainPillarCard(
                    title: 'خانة المصروفات الإدارية والتشغيلية',
                    subtitle: 'الرواتب والعمالة، الكهرباء، الصيانة، والمصاريف الإدارية والعمومية',
                    amount: adminExp,
                    percent: adminPercent,
                    count: adminExpenses.length,
                    icon: Icons.business_outlined,
                    color: AppTheme.costPurple,
                    bgColor: AppTheme.costPurpleSoft,
                    isSelected: _filterType == 2,
                    onTap: () => setState(() => _filterType = _filterType == 2 ? 0 : 2),
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        rawSection,
                        const SizedBox(height: 12),
                        adminSection,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: rawSection),
                      const SizedBox(width: 14),
                      Expanded(child: adminSection),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // كروت ملخص التصنيفات الفرعية
              LayoutBuilder(
                builder: (context, constraints) {
                  final cards = [
                    _statCard('إجمالي المصروفات', '${_formatNumber(totalExp)} ج.م', Icons.account_balance_wallet_outlined, const Color(0xFF1E293B), const Color(0xFFF1F5F9)),
                    _statCard('تكلفة المواد الخام', '${_formatNumber(rawExp)} ج.م', Icons.grain, AppTheme.primaryBlue, AppTheme.primaryBlueSoft),
                    _statCard('العمالة والرواتب', '${_formatNumber(laborExp)} ج.م', Icons.people_outline, AppTheme.successGreen, AppTheme.successGreenSoft),
                    _statCard('الكهرباء والطاقة', '${_formatNumber(powerExp)} ج.م', Icons.bolt, AppTheme.profitAmber, AppTheme.profitAmberSoft),
                    _statCard('الصيانة وقطع الغيار', '${_formatNumber(maintExp)} ج.م', Icons.build_outlined, const Color(0xFF6366F1), const Color(0xFFEEF2FF)),
                    _statCard('مصروفات إدارية وأخرى', '${_formatNumber(otherExp)} ج.م', Icons.category_outlined, const Color(0xFF64748B), const Color(0xFFF8FAFC)),
                  ];

                  if (constraints.maxWidth < 1150) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: Row(
                          children: [
                            for (int i = 0; i < cards.length; i++) ...[
                              cards[i],
                              if (i < cards.length - 1) const SizedBox(width: 12),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  return Row(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        Expanded(child: cards[i]),
                        if (i < cards.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // صف الرسم البياني وجدول المصروفات
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 1050;

                  final chartWidget = SizedBox(
                    width: isCompact ? double.infinity : 360,
                    height: 340,
                    child: CostDonutChartWidget(slices: widget.store.costDistribution),
                  );

                  final tableWidget = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // شريط التبويب لتصفية القيود
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'سجل قيود المصروفات',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'عرض ${displayedExpenses.length} من أصل ${widget.store.expenses.length} قيود',
                                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                              // أزرار التصفية
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.borderLight),
                                ),
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    _filterTabButton(0, 'الكل (${widget.store.expenses.length})', Icons.list_alt),
                                    _filterTabButton(1, 'تكلفة الخامات (${rawExpenses.length})', Icons.grain),
                                    _filterTabButton(2, 'مصروفات إدارية (${adminExpenses.length})', Icons.business_outlined),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: isCompact ? constraints.maxWidth - 40 : constraints.maxWidth - 420,
                              ),
                              child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2.6), // البيان
                                1: FlexColumnWidth(1.8), // النوع والتصنيف
                                2: FlexColumnWidth(1.5), // المبلغ
                                3: FlexColumnWidth(2.0), // ملاحظات
                                4: FlexColumnWidth(1.3), // التاريخ
                                5: FlexColumnWidth(0.8), // حذف
                              },
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(
                                    color: AppTheme.background,
                                    border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                                  ),
                                  children: [
                                    _headerCell('بيان المصروف'),
                                    _headerCell('الخانة / التصنيف'),
                                    _headerCell('المبلغ'),
                                    _headerCell('ملاحظات'),
                                    _headerCell('التاريخ'),
                                    _headerCell('إجراء'),
                                  ],
                                ),
                                ...displayedExpenses.map((e) {
                                  final isRaw = _isRawMaterial(e);
                                  return TableRow(
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                                    ),
                                    children: [
                                      _textCell(e.title, isBold: true),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isRaw ? AppTheme.primaryBlueSoft : AppTheme.costPurpleSoft,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isRaw ? AppTheme.primaryBlue.withValues(alpha: 0.3) : AppTheme.costPurple.withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isRaw ? Icons.grain : Icons.business_outlined,
                                                  size: 12,
                                                  color: isRaw ? AppTheme.primaryBlue : AppTheme.costPurple,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  e.category,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isRaw ? AppTheme.primaryBlue : AppTheme.costPurple,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      _textCell('${_formatNumber(e.amount)} ج.م', isBold: true),
                                      _textCell(e.notes ?? '—'),
                                      _textCell('${e.date.day}/${e.date.month}/${e.date.year}'),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Center(
                                          child: IconButton(
                                            icon: const Icon(Icons.delete_outline, color: AppTheme.wasteRed, size: 18),
                                            tooltip: 'حذف المصروف',
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('تأكيد حذف المصروف'),
                                                  content: Text('هل أنت متأكد من حذف مصروف "${e.title}" بقيمة ${_formatNumber(e.amount)} ج.م؟'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.wasteRed, foregroundColor: Colors.white),
                                                      onPressed: () {
                                                        Navigator.of(ctx).pop();
                                                        widget.store.deleteExpense(e.id);
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('تم حذف المصروف "${e.title}" بنجاح!'), backgroundColor: AppTheme.successGreen),
                                                        );
                                                      },
                                                      child: const Text('حذف'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        if (displayedExpenses.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36.0),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textMuted),
                                  const SizedBox(height: 12),
                                  Text(
                                    _filterType == 1
                                        ? 'لا توجد قيود مسجلة في خانة تكلفة الخامات'
                                        : (_filterType == 2
                                            ? 'لا توجد قيود مسجلة في خانة المصروفات الإدارية'
                                            : 'لا توجد أي قيود مصروفات مسجلة حتى الآن'),
                                    style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'اضغط على زر "تسجيل مصروف جديد" في الأعلى لإضافة تكاليف الإنتاج والتشغيل',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );

              if (isCompact) {
                return Column(
                  children: [
                    chartWidget,
                    const SizedBox(height: 16),
                    tableWidget,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  chartWidget,
                  const SizedBox(width: 18),
                  Expanded(child: tableWidget),
                ],
              );
            },
          ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterTabButton(int index, String label, IconData icon) {
    final isSelected = _filterType == index;
    return InkWell(
      onTap: () => setState(() => _filterType = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppTheme.costPurple : AppTheme.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.costPurple : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainPillarCard({
    required String title,
    required String subtitle,
    required double amount,
    required double percent,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderLight,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? color : AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${percent.toStringAsFixed(1)}% من التكاليف',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إجمالي الخانة', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatNumber(amount)} ج.م',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.receipt_outlined, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text('$count فواتير/قيود', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(width: 10),
                    Text(
                      isSelected ? 'انقر لإلغاء التصفية' : 'انقر لتصفية الجدول',
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _textCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: AppTheme.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
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
                  Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
