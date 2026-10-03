import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/employee.dart';
import '../models/employee_advance.dart';
import '../models/salary_payment.dart';
import '../state/factory_store.dart';
import 'dialogs/add_advance_dialog.dart';
import 'dialogs/pay_salary_dialog.dart';
import 'dialogs/salary_receipt_dialog.dart';
import 'dialogs/settle_advance_dialog.dart';

class EmployeesView extends StatefulWidget {
  final FactoryStore store;

  const EmployeesView({super.key, required this.store});

  @override
  State<EmployeesView> createState() => _EmployeesViewState();
}

class _EmployeesViewState extends State<EmployeesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filters for Tab 1 (Employees)
  String _employeeSearch = '';
  String _selectedShift = 'الكل';

  // Search & Filters for Tab 2 (Advances)
  String _advanceSearch = '';
  String _advanceStatusFilter = 'الكل';

  // Search & Filters for Tab 3 (Payroll)
  String _payrollSearch = '';
  String _selectedMonthYear = 'سبتمبر 2026';
  String _payrollStatusFilter = 'الكل';

  // State for Tab 4 (Statement)
  Employee? _selectedStatementEmployee;

  final NumberFormat _fmt = NumberFormat('#,###');

  final List<String> _monthsList = [
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
    _tabController = TabController(length: 4, vsync: this);
    if (widget.store.employees.isNotEmpty) {
      _selectedStatementEmployee = widget.store.employees.first;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    return Column(
      children: [
        // Custom Tab Bar Header
        Container(
          color: AppTheme.surfaceWhite,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppTheme.primaryBlue,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.primaryBlue,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.people_alt_outlined, size: 20),
                      text: 'طاقم العمل والورديات (${store.employees.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.request_quote_outlined, size: 20),
                      text: 'سلف الموظفين (${store.employeeAdvances.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.payments_outlined, size: 20),
                      text: 'قبض الموظفين والرواتب (${store.salaryPayments.length})',
                    ),
                    const Tab(
                      icon: Icon(Icons.receipt_long_outlined, size: 20),
                      text: 'كشوف الحسابات وسجل الموظف',
                    ),
                  ],
                ),
              ),
              // Action Buttons in Header
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.costPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.request_quote, size: 16),
                label: const Text('تسجيل سلفة', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddAdvanceDialog(store: store),
                  );
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.payments, size: 16),
                label: const Text('صرف راتب', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PaySalaryDialog(store: store, initialMonthYear: _selectedMonthYear),
                  );
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text('إضافة موظف', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                onPressed: () => _showAddOrEditEmployeeDialog(context),
              ),
            ],
          ),
        ),

        // Tabs Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildEmployeesTab(store),
              _buildAdvancesTab(store),
              _buildPayrollTab(store),
              _buildStatementTab(store),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 1: طاقم العمل والورديات
  // ===========================================================================
  Widget _buildEmployeesTab(FactoryStore store) {
    final filteredEmployees = store.employees.where((e) {
      final matchesSearch = e.name.contains(_employeeSearch) ||
          e.role.contains(_employeeSearch) ||
          e.department.contains(_employeeSearch);
      final matchesShift = _selectedShift == 'الكل' || e.shift == _selectedShift;
      return matchesSearch && matchesShift;
    }).toList();

    final totalSalaries = store.employees.fold(0.0, (s, e) => s + e.monthlySalary);
    final totalPendingAdvances = store.totalAdvancesOutstanding;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Cards
          Row(
            children: [
              Expanded(
                child: _statCard('إجمالي طاقم المصنع', '${store.employees.length} موظف', Icons.groups_outlined, AppTheme.primaryBlue, AppTheme.primaryBlueSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('الوردية الصباحية (8ص - 4م)', '${store.employees.where((e) => e.shift == 'صباحية').length} موظف', Icons.wb_sunny_outlined, AppTheme.profitAmber, AppTheme.profitAmberSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('الوردية المسائية (4م - 12ص)', '${store.employees.where((e) => e.shift == 'مسائية').length} موظف', Icons.nights_stay_outlined, AppTheme.costPurple, AppTheme.costPurpleSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('إجمالي مسيرات الرواتب', '${_fmt.format(totalSalaries)} ج.م', Icons.payments_outlined, AppTheme.successGreen, AppTheme.successGreenSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('سلف الموظفين القائمة', '${_fmt.format(totalPendingAdvances)} ج.م', Icons.request_quote_outlined, const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Filters Bar
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'بحث باسم الموظف، المسمى، أو القسم...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) => setState(() => _employeeSearch = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('الوردية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedShift,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'الكل', child: Text('جميع الورديات')),
                      DropdownMenuItem(value: 'صباحية', child: Text('وردية صباحية')),
                      DropdownMenuItem(value: 'مسائية', child: Text('وردية مسائية')),
                      DropdownMenuItem(value: 'ليلية', child: Text('وردية ليلية')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedShift = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Employees Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'قائمة الموظفين والمهندسين (${filteredEmployees.length} موظف)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'اضغط على أزرار الإجراءات السريعة لصرف سلفة أو راتب الموظف فوراً',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2.0), // الاسم
                      1: FlexColumnWidth(2.0), // المسمى والقسم
                      2: FlexColumnWidth(1.2), // الوردية
                      3: FlexColumnWidth(1.4), // الراتب الشهري
                      4: FlexColumnWidth(1.5), // السلف القائمة
                      5: FlexColumnWidth(1.3), // الهاتف
                      6: FlexColumnWidth(2.6), // الإجراءات السريعة
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: AppTheme.background,
                          border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                        ),
                        children: [
                          _headerCell('الاسم'),
                          _headerCell('المسمى الوظيفي والقسم'),
                          _headerCell('الوردية'),
                          _headerCell('الراتب الشهري'),
                          _headerCell('سلف قائمة'),
                          _headerCell('الهاتف'),
                          _headerCell('إجراءات سريعة'),
                        ],
                      ),
                      ...filteredEmployees.map((emp) {
                        final pending = store.getEmployeePendingAdvances(emp.id);

                        return TableRow(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                          ),
                          children: [
                            _textCell(emp.name, isBold: true),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(emp.role, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                  Text(emp.department, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: emp.shift == 'صباحية'
                                        ? AppTheme.profitAmberSoft
                                        : (emp.shift == 'مسائية' ? AppTheme.costPurpleSoft : const Color(0xFFF0F9FF)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    emp.shift,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: emp.shift == 'صباحية'
                                          ? AppTheme.profitAmber
                                          : (emp.shift == 'مسائية' ? AppTheme.costPurple : const Color(0xFF0284C7)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _textCell('${_fmt.format(emp.monthlySalary)} ج.م', isBold: true, color: AppTheme.successGreen),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: pending > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    pending > 0 ? '${_fmt.format(pending)} ج.م' : 'لا يوجد',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: pending > 0 ? AppTheme.wasteRed : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _textCell(emp.phone ?? '—'),
                            // Action Buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // صرف سلفة
                                  IconButton(
                                    tooltip: 'صرف سلفة نقدية للموظف',
                                    icon: const Icon(Icons.request_quote_outlined, size: 19, color: AppTheme.costPurple),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AddAdvanceDialog(store: store, preselectedEmployee: emp),
                                      );
                                    },
                                  ),
                                  // صرف راتب
                                  IconButton(
                                    tooltip: 'قبض وصرف راتب الموظف',
                                    icon: const Icon(Icons.payments_outlined, size: 19, color: AppTheme.successGreen),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => PaySalaryDialog(store: store, preselectedEmployee: emp, initialMonthYear: _selectedMonthYear),
                                      );
                                    },
                                  ),
                                  // كشف حساب
                                  IconButton(
                                    tooltip: 'كشف حساب الموظف',
                                    icon: const Icon(Icons.receipt_long_outlined, size: 19, color: AppTheme.primaryBlue),
                                    onPressed: () {
                                      setState(() {
                                        _selectedStatementEmployee = emp;
                                        _tabController.animateTo(3);
                                      });
                                    },
                                  ),
                                  // تعديل الموظف
                                  IconButton(
                                    tooltip: 'تعديل بيانات الموظف',
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted),
                                    onPressed: () => _showAddOrEditEmployeeDialog(context, employeeToEdit: emp),
                                  ),
                                  // حذف الموظف
                                  IconButton(
                                    tooltip: 'حذف الموظف',
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.wasteRed),
                                    onPressed: () => _confirmDeleteEmployee(context, emp),
                                  ),
                                ],
                              ),
                            ),
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

  // ===========================================================================
  // TAB 2: سلف الموظفين
  // ===========================================================================
  Widget _buildAdvancesTab(FactoryStore store) {
    final filteredAdvances = store.employeeAdvances.where((adv) {
      final matchesSearch = adv.employeeName.contains(_advanceSearch) || (adv.notes ?? '').contains(_advanceSearch);
      final matchesStatus = _advanceStatusFilter == 'الكل' || adv.status == _advanceStatusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    final totalGiven = store.totalAdvancesGiven;
    final totalSettled = store.totalAdvancesSettled;
    final totalPending = store.totalAdvancesOutstanding;
    final activeBorrowersCount = store.employeeAdvances.where((a) => !a.isFullySettled).map((a) => a.employeeId).toSet().length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Cards
          Row(
            children: [
              Expanded(
                child: _statCard('إجمالي السلف المنصرفة', '${_fmt.format(totalGiven)} ج.م', Icons.request_quote_outlined, AppTheme.costPurple, AppTheme.costPurpleSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('إجمالي السلف المستردة / المسددة', '${_fmt.format(totalSettled)} ج.م', Icons.check_circle_outline, AppTheme.successGreen, AppTheme.successGreenSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('رصيد السلف القائمة المعلقة', '${_fmt.format(totalPending)} ج.م', Icons.hourglass_top_outlined, AppTheme.profitAmber, AppTheme.profitAmberSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('عدد الموظفين المستلفين', '$activeBorrowersCount موظف', Icons.person_search_outlined, AppTheme.primaryBlue, AppTheme.primaryBlueSoft),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Filters Bar & New Advance Button
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'بحث باسم الموظف أو سبب السلفة...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) => setState(() => _advanceSearch = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('حالة السلفة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _advanceStatusFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'الكل', child: Text('جميع الحالات')),
                      DropdownMenuItem(value: 'معلقة', child: Text('معلقة بالكامل')),
                      DropdownMenuItem(value: 'مسددة جزئياً', child: Text('مسددة جزئياً')),
                      DropdownMenuItem(value: 'مسددة بالكامل', child: Text('مسددة بالكامل')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _advanceStatusFilter = val);
                    },
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.costPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('تسجيل سلفة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddAdvanceDialog(store: store),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Advances Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سجل سلف الموظفين (${filteredAdvances.length} سلفة)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  if (filteredAdvances.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text('لا توجد سلف مسجلة حالياً تطابق معايير البحث.', style: TextStyle(color: AppTheme.textMuted)),
                      ),
                    )
                  else
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.2), // التاريخ
                        1: FlexColumnWidth(2.0), // الموظف
                        2: FlexColumnWidth(1.3), // مبلغ السلفة
                        3: FlexColumnWidth(1.2), // المسدد
                        4: FlexColumnWidth(1.3), // المتبقي
                        5: FlexColumnWidth(1.4), // الحالة
                        6: FlexColumnWidth(2.2), // السبب / الملاحظات
                        7: FlexColumnWidth(1.4), // الإجراءات
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: AppTheme.background,
                            border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                          ),
                          children: [
                            _headerCell('تاريخ السلفة'),
                            _headerCell('اسم الموظف'),
                            _headerCell('مبلغ السلفة'),
                            _headerCell('المسدد منها'),
                            _headerCell('المتبقي للسداد'),
                            _headerCell('الحالة'),
                            _headerCell('السبب / ملاحظات'),
                            _headerCell('إجراءات'),
                          ],
                        ),
                        ...filteredAdvances.map((adv) {
                          Color statusColor = AppTheme.wasteRed;
                          Color statusBg = const Color(0xFFFEF2F2);
                          if (adv.isFullySettled) {
                            statusColor = AppTheme.successGreen;
                            statusBg = AppTheme.successGreenSoft;
                          } else if (adv.settledAmount > 0) {
                            statusColor = AppTheme.profitAmber;
                            statusBg = AppTheme.profitAmberSoft;
                          }

                          return TableRow(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                            ),
                            children: [
                              _textCell(DateFormat('yyyy/MM/dd').format(adv.date)),
                              _textCell(adv.employeeName, isBold: true),
                              _textCell('${_fmt.format(adv.amount)} ج.م', isBold: true, color: AppTheme.costPurple),
                              _textCell('${_fmt.format(adv.settledAmount)} ج.م', color: AppTheme.successGreen),
                              _textCell(
                                '${_fmt.format(adv.remainingAmount)} ج.م',
                                isBold: true,
                                color: adv.remainingAmount > 0 ? AppTheme.wasteRed : AppTheme.textMuted,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      adv.status,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                    ),
                                  ),
                                ),
                              ),
                              _textCell(adv.notes ?? 'سلفة شخصية'),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!adv.isFullySettled)
                                      IconButton(
                                        tooltip: 'سداد السلفة نقداً خارج مسير الراتب',
                                        icon: const Icon(Icons.attach_money, color: AppTheme.successGreen, size: 20),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => SettleAdvanceDialog(store: store, advance: adv),
                                          );
                                        },
                                      ),
                                    IconButton(
                                      tooltip: 'حذف السلفة',
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.wasteRed, size: 18),
                                      onPressed: () {
                                        _confirmDeleteAdvance(context, adv);
                                      },
                                    ),
                                  ],
                                ),
                              ),
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

  // ===========================================================================
  // TAB 3: قبض الموظفين والرواتب
  // ===========================================================================
  Widget _buildPayrollTab(FactoryStore store) {
    final paymentsForMonth = store.salaryPayments.where((p) => p.monthYear == _selectedMonthYear).toList();
    final paidEmployeeIds = paymentsForMonth.map((p) => p.employeeId).toSet();

    final filteredPayments = paymentsForMonth.where((p) {
      final matchesSearch = p.employeeName.contains(_payrollSearch) || p.role.contains(_payrollSearch);
      final matchesMethod = _payrollStatusFilter == 'الكل' || p.paymentMethod == _payrollStatusFilter;
      return matchesSearch && matchesMethod;
    }).toList();

    final unpaidEmployees = store.employees.where((e) => !paidEmployeeIds.contains(e.id)).toList();

    final totalNetPaidForMonth = paymentsForMonth.fold(0.0, (s, p) => s + p.netSalary);
    final totalAdvancesDeducted = paymentsForMonth.fold(0.0, (s, p) => s + p.advancesDeducted);
    final totalIncentives = paymentsForMonth.fold(0.0, (s, p) => s + p.incentives);
    final totalDeductions = paymentsForMonth.fold(0.0, (s, p) => s + p.deductions);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector Bar & Action Buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: AppTheme.primaryBlue, size: 24),
                  const SizedBox(width: 10),
                  const Text('شهر مسير الرواتب المستحق:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedMonthYear,
                    underline: const SizedBox(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.primaryBlue),
                    items: _monthsList.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMonthYear = val);
                    },
                  ),
                  const Spacer(),
                  // Quick Bulk Payroll Button
                  if (unpaidEmployees.isNotEmpty)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.flash_on, size: 18, color: AppTheme.profitAmber),
                      label: Text('مسير سريع للمتبقين (${unpaidEmployees.length} موظف)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      onPressed: () => _confirmBulkPayroll(context, unpaidEmployees),
                    ),
                  const SizedBox(width: 10),
                  // New Individual Salary Payment Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('صرف راتب موظف', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => PaySalaryDialog(store: store, initialMonthYear: _selectedMonthYear),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Stat Cards for Selected Month
          Row(
            children: [
              Expanded(
                child: _statCard('صافي الرواتب المصروفة لشهر $_selectedMonthYear', '${_fmt.format(totalNetPaidForMonth)} ج.م', Icons.payments_outlined, AppTheme.successGreen, AppTheme.successGreenSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('الموظفون المقبوض لهم', '${paidEmployeeIds.length} من ${store.employees.length} موظف', Icons.check_circle_outline, AppTheme.primaryBlue, AppTheme.primaryBlueSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('سلف مستقطعة من رواتب الشهر', '${_fmt.format(totalAdvancesDeducted)} ج.م', Icons.request_quote_outlined, AppTheme.costPurple, AppTheme.costPurpleSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('إجمالي الحوافز والإضافي', '${_fmt.format(totalIncentives)} ج.م', Icons.trending_up, const Color(0xFF1E40AF), const Color(0xFFEFF6FF)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('إجمالي الجزاءات والخصومات', '${_fmt.format(totalDeductions)} ج.م', Icons.trending_down, AppTheme.wasteRed, const Color(0xFFFEF2F2)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Search in payroll
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'بحث في مسيرات رواتب الشهر بالاسم أو الوظيفة...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) => setState(() => _payrollSearch = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('طريقة الصرف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _payrollStatusFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'الكل', child: Text('جميع الطرق')),
                      DropdownMenuItem(value: 'نقدي كاش', child: Text('نقدي كاش')),
                      DropdownMenuItem(value: 'تحويل بنكي', child: Text('تحويل بنكي')),
                      DropdownMenuItem(value: 'شيك', child: Text('شيك')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _payrollStatusFilter = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Payroll Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'مسيرات الرواتب المصروفة لشهر $_selectedMonthYear (${filteredPayments.length} سند)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      if (unpaidEmployees.isNotEmpty)
                        Text(
                          'يتبقى ${unpaidEmployees.length} موظف لم يتم صرف رواتبهم لهذا الشهر بعد',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.profitAmber),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (filteredPayments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.payments_outlined, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 8),
                            Text('لم يتم تسجيل صرف رواتب لشهر $_selectedMonthYear بعد.', style: const TextStyle(color: AppTheme.textMuted)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('صرف راتب أول موظف'),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => PaySalaryDialog(store: store, initialMonthYear: _selectedMonthYear),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.2), // السند
                        1: FlexColumnWidth(1.2), // تاريخ الصرف
                        2: FlexColumnWidth(2.0), // الموظف والوظيفة
                        3: FlexColumnWidth(1.2), // الأساسي
                        4: FlexColumnWidth(1.0), // الحوافز
                        5: FlexColumnWidth(1.1), // خصم سلف
                        6: FlexColumnWidth(1.0), // خصومات
                        7: FlexColumnWidth(1.3), // صافي المنصرف
                        8: FlexColumnWidth(1.1), // الطريقة
                        9: FlexColumnWidth(1.3), // الإجراءات
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: AppTheme.background,
                            border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                          ),
                          children: [
                            _headerCell('رقم السند'),
                            _headerCell('تاريخ الصرف'),
                            _headerCell('اسم الموظف'),
                            _headerCell('الأساسي'),
                            _headerCell('حوافز'),
                            _headerCell('استقطاع سلف'),
                            _headerCell('جزاءات'),
                            _headerCell('صافي المقبوض'),
                            _headerCell('الطريقة'),
                            _headerCell('إجراءات'),
                          ],
                        ),
                        ...filteredPayments.map((p) {
                          return TableRow(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                            ),
                            children: [
                              _textCell(p.voucherNumber, isBold: true, color: AppTheme.primaryBlue),
                              _textCell(DateFormat('yyyy/MM/dd').format(p.paymentDate)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(p.employeeName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                    Text('${p.role} - ${p.department}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                              _textCell('${_fmt.format(p.baseSalary)} ج.م'),
                              _textCell(p.incentives > 0 ? '+${_fmt.format(p.incentives)}' : '—', color: const Color(0xFF1E40AF)),
                              _textCell(p.advancesDeducted > 0 ? '-${_fmt.format(p.advancesDeducted)}' : '—', color: AppTheme.costPurple, isBold: p.advancesDeducted > 0),
                              _textCell(p.deductions > 0 ? '-${_fmt.format(p.deductions)}' : '—', color: AppTheme.wasteRed),
                              _textCell('${_fmt.format(p.netSalary)} ج.م', isBold: true, color: AppTheme.successGreen),
                              _textCell(p.paymentMethod),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      tooltip: 'عرض وطباعة سند الصرف',
                                      icon: const Icon(Icons.receipt_long, color: AppTheme.primaryBlue, size: 20),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => SalaryReceiptDialog(payment: p, store: store),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'حذف السند والتراجع',
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.wasteRed, size: 18),
                                      onPressed: () => _confirmDeleteSalary(context, p),
                                    ),
                                  ],
                                ),
                              ),
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

  // ===========================================================================
  // TAB 4: كشف حساب وسجل الموظف
  // ===========================================================================
  Widget _buildStatementTab(FactoryStore store) {
    if (store.employees.isEmpty) {
      return const Center(child: Text('لا يوجد موظفون مسجلون بالمصنع'));
    }

    final emp = _selectedStatementEmployee ?? store.employees.first;
    final advances = store.getEmployeeAdvancesList(emp.id);
    final payments = store.getEmployeeSalaryPayments(emp.id);
    final pendingAdvances = store.getEmployeePendingAdvances(emp.id);

    final totalSalariesReceived = payments.fold(0.0, (s, p) => s + p.netSalary);
    final totalAdvancesTaken = advances.fold(0.0, (s, a) => s + a.amount);
    final totalAdvancesSettled = advances.fold(0.0, (s, a) => s + a.settledAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Selector Bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.badge, color: AppTheme.primaryBlue, size: 24),
                  const SizedBox(width: 12),
                  const Text('اختر الموظف لعرض كشف حسابه:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DropdownButtonFormField<Employee>(
                      value: emp,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      ),
                      items: store.employees.map((e) {
                        return DropdownMenuItem(value: e, child: Text('${e.name} (${e.role} - ${e.department})'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatementEmployee = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.costPurple, foregroundColor: Colors.white),
                    icon: const Icon(Icons.request_quote, size: 16),
                    label: const Text('صرف سلفة'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddAdvanceDialog(store: store, preselectedEmployee: emp),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white),
                    icon: const Icon(Icons.payments, size: 16),
                    label: const Text('صرف راتب'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => PaySalaryDialog(store: store, preselectedEmployee: emp, initialMonthYear: _selectedMonthYear),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Employee Profile and Metrics Summary
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primaryBlueSoft,
                              child: Text(emp.name.isNotEmpty ? emp.name.substring(0, 1) : 'م', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(emp.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('${emp.role} • ${emp.department}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('الوردية:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            Text(emp.shift, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('الراتب الشهري الأساسي:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            Text('${_fmt.format(emp.monthlySalary)} ج.م', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('رقم الهاتف:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            Text(emp.phone ?? '—', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: _statCard('إجمالي الرواتب المستلمة', '${_fmt.format(totalSalariesReceived)} ج.م', Icons.payments, AppTheme.successGreen, AppTheme.successGreenSoft),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard('إجمالي السلف المأخوذة', '${_fmt.format(totalAdvancesTaken)} ج.م', Icons.request_quote, AppTheme.costPurple, AppTheme.costPurpleSoft),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard('السلف المسددة', '${_fmt.format(totalAdvancesSettled)} ج.م', Icons.check_circle, const Color(0xFF1E40AF), const Color(0xFFEFF6FF)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard('المتبقي بذمته (سلف معلقة)', '${_fmt.format(pendingAdvances)} ج.م', Icons.warning_amber_rounded, AppTheme.wasteRed, const Color(0xFFFEF2F2)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Ledger Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سجل الحركات المالية للموظف: ${emp.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  if (payments.isEmpty && advances.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('لا توجد حركات سلف أو رواتب مسجلة لهذا الموظف حتى الآن.', style: TextStyle(color: AppTheme.textMuted))),
                    )
                  else
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.2), // التاريخ
                        1: FlexColumnWidth(1.4), // نوع الحركة
                        2: FlexColumnWidth(1.4), // البيان
                        3: FlexColumnWidth(1.4), // المبلغ
                        4: FlexColumnWidth(1.2), // طريقة الدفع
                        5: FlexColumnWidth(2.0), // ملاحظات
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: AppTheme.background,
                            border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                          ),
                          children: [
                            _headerCell('التاريخ'),
                            _headerCell('نوع الحركة'),
                            _headerCell('البيان / الشهر'),
                            _headerCell('المبلغ'),
                            _headerCell('طريقة الصرف'),
                            _headerCell('ملاحظات'),
                          ],
                        ),
                        ...payments.map((p) => TableRow(
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderLight))),
                          children: [
                            _textCell(DateFormat('yyyy/MM/dd').format(p.paymentDate)),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppTheme.successGreenSoft, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('صرف راتب', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                                ),
                              ),
                            ),
                            _textCell('راتب ${p.monthYear} (${p.voucherNumber})'),
                            _textCell('${_fmt.format(p.netSalary)} ج.م', isBold: true, color: AppTheme.successGreen),
                            _textCell(p.paymentMethod),
                            _textCell(p.notes ?? 'تم الصرف بنجاح'),
                          ],
                        )),
                        ...advances.map((a) => TableRow(
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderLight))),
                          children: [
                            _textCell(DateFormat('yyyy/MM/dd').format(a.date)),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppTheme.costPurpleSoft, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('سلفة نقدية', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.costPurple)),
                                ),
                              ),
                            ),
                            _textCell('سلفة شخصية (${a.status})'),
                            _textCell('${_fmt.format(a.amount)} ج.م', isBold: true, color: AppTheme.costPurple),
                            _textCell(a.deductedFromTreasury ? 'كاش من الخزنة' : 'أخرى'),
                            _textCell(a.notes ?? '—'),
                          ],
                        )),
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

  // ===========================================================================
  // Helpers & Dialogs
  // ===========================================================================

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

  Widget _textCell(String text, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? AppTheme.textPrimary,
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
                  Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOrEditEmployeeDialog(BuildContext context, {Employee? employeeToEdit}) {
    final nameCtrl = TextEditingController(text: employeeToEdit?.name ?? '');
    final roleCtrl = TextEditingController(text: employeeToEdit?.role ?? 'فني ماكينة فيلم');
    final deptCtrl = TextEditingController(text: employeeToEdit?.department ?? 'خطوط الفيلم');
    final salaryCtrl = TextEditingController(text: employeeToEdit != null ? employeeToEdit.monthlySalary.toStringAsFixed(0) : '7500');
    final phoneCtrl = TextEditingController(text: employeeToEdit?.phone ?? '');
    final machineCtrl = TextEditingController(text: employeeToEdit?.machineAssigned ?? 'ماكينة فيلم 2');
    String shift = employeeToEdit?.shift ?? 'صباحية';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppTheme.surfaceWhite,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppTheme.primaryBlueSoft, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.badge_outlined, color: AppTheme.primaryBlue, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employeeToEdit == null ? 'إضافة موظف جديد بالمصنع' : 'تعديل بيانات الموظف',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              const Text('تسجيل بيانات العامل أو الفني والوردية والراتب', style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('اسم الموظف بالكامل', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              const SizedBox(height: 5),
                              TextField(
                                controller: nameCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'مثال: محمود أحمد حسن',
                                  prefixIcon: Icon(Icons.person_outline, size: 18),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('المسمى الوظيفي', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                        const SizedBox(height: 5),
                                        TextField(
                                          controller: roleCtrl,
                                          style: const TextStyle(fontSize: 13),
                                          decoration: const InputDecoration(
                                            hintText: 'فني تشغيل / عامل',
                                            prefixIcon: Icon(Icons.work_outline, size: 18),
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
                                        const Text('القسم', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                        const SizedBox(height: 5),
                                        TextField(
                                          controller: deptCtrl,
                                          style: const TextStyle(fontSize: 13),
                                          decoration: const InputDecoration(
                                            hintText: 'الفيلم / التقطيع',
                                            prefixIcon: Icon(Icons.domain_outlined, size: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('الوردية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                        const SizedBox(height: 5),
                                        DropdownButtonFormField<String>(
                                          value: shift,
                                          decoration: const InputDecoration(
                                            prefixIcon: Icon(Icons.schedule_outlined, size: 18),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: 'صباحية', child: Text('صباحية')),
                                            DropdownMenuItem(value: 'مسائية', child: Text('مسائية')),
                                            DropdownMenuItem(value: 'ليلية', child: Text('ليلية')),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) setDialogState(() => shift = val);
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
                                        const Text('الراتب الشهري (جنيه)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                        const SizedBox(height: 5),
                                        TextField(
                                          controller: salaryCtrl,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(fontSize: 13),
                                          decoration: const InputDecoration(
                                            hintText: '7000',
                                            suffixText: 'جنيه',
                                            prefixIcon: Icon(Icons.payments_outlined, size: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('الماكينة المخصصة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                        const SizedBox(height: 5),
                                        TextField(
                                          controller: machineCtrl,
                                          style: const TextStyle(fontSize: 13),
                                          decoration: const InputDecoration(
                                            hintText: 'ماكينة فيلم 1',
                                            prefixIcon: Icon(Icons.precision_manufacturing_outlined, size: 18),
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
                                        const Text('رقم الهاتف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                        const SizedBox(height: 5),
                                        TextField(
                                          controller: phoneCtrl,
                                          keyboardType: TextInputType.phone,
                                          style: const TextStyle(fontSize: 13),
                                          decoration: const InputDecoration(
                                            hintText: '010...',
                                            prefixIcon: Icon(Icons.phone_outlined, size: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(employeeToEdit == null ? 'حفظ الموظف' : 'تحديث البيانات', style: const TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              if (nameCtrl.text.trim().isNotEmpty) {
                                if (employeeToEdit == null) {
                                  widget.store.addEmployee(
                                    Employee(
                                      id: 'emp-${DateTime.now().millisecondsSinceEpoch}',
                                      name: nameCtrl.text.trim(),
                                      role: roleCtrl.text.trim(),
                                      department: deptCtrl.text.trim(),
                                      shift: shift,
                                      monthlySalary: double.tryParse(salaryCtrl.text) ?? 7000,
                                      phone: phoneCtrl.text.trim(),
                                      machineAssigned: machineCtrl.text.trim(),
                                    ),
                                  );
                                } else {
                                  widget.store.updateEmployee(
                                    Employee(
                                      id: employeeToEdit.id,
                                      name: nameCtrl.text.trim(),
                                      role: roleCtrl.text.trim(),
                                      department: deptCtrl.text.trim(),
                                      shift: shift,
                                      monthlySalary: double.tryParse(salaryCtrl.text) ?? employeeToEdit.monthlySalary,
                                      phone: phoneCtrl.text.trim(),
                                      machineAssigned: machineCtrl.text.trim(),
                                      status: employeeToEdit.status,
                                      hireDate: employeeToEdit.hireDate,
                                    ),
                                  );
                                }
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(employeeToEdit == null ? 'تمت إضافة الموظف بنجاح!' : 'تم تحديث بيانات الموظف!'),
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
            );
          },
        );
      },
    );
  }

  void _confirmDeleteEmployee(BuildContext context, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الموظف'),
        content: Text('هل أنت متأكد من حذف الموظف "${emp.name}" من سجلات المصنع؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.wasteRed, foregroundColor: Colors.white),
            onPressed: () {
              widget.store.deleteEmployee(emp.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف الموظف بنجاح'), backgroundColor: AppTheme.wasteRed),
              );
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAdvance(BuildContext context, EmployeeAdvance adv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف السلفة'),
        content: Text('هل أنت متأكد من حذف سلفة الموظف "${adv.employeeName}" بمبلغ ${_fmt.format(adv.amount)} ج.م؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.wasteRed, foregroundColor: Colors.white),
            onPressed: () {
              widget.store.deleteEmployeeAdvance(adv.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف السلفة بنجاح'), backgroundColor: AppTheme.wasteRed),
              );
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSalary(BuildContext context, SalaryPayment p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد التراجع وحذف سند الراتب'),
        content: Text('هل أنت متأكد من حذف سند صرف راتب "${p.employeeName}" لشهر ${p.monthYear} بمبلغ ${_fmt.format(p.netSalary)} ج.م؟\nسيتم استرجاع مبالغ السلف المخصومة تلقائياً إلى رصيد الموظف.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.wasteRed, foregroundColor: Colors.white),
            onPressed: () {
              widget.store.deleteSalaryPayment(p.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم التراجع وحذف سند الراتب بنجاح'), backgroundColor: AppTheme.wasteRed),
              );
            },
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }

  void _confirmBulkPayroll(BuildContext context, List<Employee> unpaidEmployees) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('مسير رواتب سريع لشهر $_selectedMonthYear'),
        content: Text('سيتم اعتماد صرف الرواتب الأساسية لجميع الموظفين المتبقين وعددهم (${unpaidEmployees.length} موظف) مع استقطاع السلف القائمة لكل موظف وخصم الصافي من الخزنة.\n\nهل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white),
            icon: const Icon(Icons.flash_on, size: 16),
            label: const Text('تأكيد الصرف الجماعي'),
            onPressed: () {
              Navigator.of(ctx).pop();
              for (final emp in unpaidEmployees) {
                final pending = widget.store.getEmployeePendingAdvances(emp.id);
                final toDeduct = pending <= emp.monthlySalary ? pending : emp.monthlySalary * 0.5;
                final net = (emp.monthlySalary - toDeduct).clamp(0.0, double.infinity);

                final voucherNumber = 'PAY-SAL-2026-${(widget.store.salaryPayments.length + 1).toString().padLeft(3, '0')}';
                final payment = SalaryPayment(
                  id: 'sal-${DateTime.now().millisecondsSinceEpoch}-${emp.id}',
                  voucherNumber: voucherNumber,
                  employeeId: emp.id,
                  employeeName: emp.name,
                  role: emp.role,
                  department: emp.department,
                  monthYear: _selectedMonthYear,
                  baseSalary: emp.monthlySalary,
                  advancesDeducted: toDeduct,
                  netSalary: net,
                  paymentDate: DateTime.now(),
                  paymentMethod: 'نقدي كاش',
                  paidFromTreasury: true,
                  notes: 'مسير رواتب جماعي معتمد',
                );
                widget.store.addSalaryPayment(payment, payFromTreasury: true);
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم إتمام مسير الرواتب لعدد ${unpaidEmployees.length} موظف بنجاح!'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
