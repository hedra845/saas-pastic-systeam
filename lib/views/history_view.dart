// lib/views/history_view.dart

import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../auth/auth_service.dart';
import '../theme/app_theme.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  List<HistoryEvent> _allEvents = [];
  List<HistoryEvent> _filtered = [];
  bool _loading = true;

  final TextEditingController _searchCtrl = TextEditingController();
  String _typeFilter = 'الكل';
  DateTimeRange? _dateRange;

  static const List<String> _typeOptions = [
    'الكل',
    'إضافة',
    'تعديل',
    'حذف',
    'مالي',
    'دخول / خروج',
    'قاعدة البيانات',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final events = await HistoryService.instance.loadHistory();
    if (mounted) {
      setState(() {
        _allEvents = events;
        _loading = false;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _allEvents.where((e) {
        // Text search
        final matchesText = query.isEmpty ||
            e.title.toLowerCase().contains(query) ||
            (e.details?.toLowerCase().contains(query) ?? false) ||
            e.type.toLowerCase().contains(query);

        // Type filter
        bool matchesType = true;
        if (_typeFilter != 'الكل') {
          final t = e.type;
          switch (_typeFilter) {
            case 'إضافة':
              matchesType = t.contains('_add') || t.contains('add_');
              break;
            case 'تعديل':
              matchesType = t.contains('_edit') || t.contains('_update') || t.contains('update_');
              break;
            case 'حذف':
              matchesType = t.contains('_delete') || t.contains('delete_');
              break;
            case 'مالي':
              matchesType = t.contains('sale') ||
                  t.contains('expense') ||
                  t.contains('treasury') ||
                  t.contains('salary') ||
                  t.contains('advance') ||
                  t.contains('supply');
              break;
            case 'دخول / خروج':
              matchesType = t == 'login' || t == 'logout';
              break;
            case 'قاعدة البيانات':
              matchesType = t == 'db_clear' || t == 'db_reset';
              break;
          }
        }

        // Date range filter
        bool matchesDate = true;
        if (_dateRange != null) {
          final d = e.timestamp;
          matchesDate = !d.isBefore(_dateRange!.start) &&
              d.isBefore(_dateRange!.end.add(const Duration(days: 1)));
        }

        return matchesText && matchesType && matchesDate;
      }).toList();
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      locale: const Locale('ar'),
      builder: (ctx, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _applyFilters();
    }
  }

  Future<void> _confirmClearHistory() async {
    final passCtrl = TextEditingController();
    bool wrongPass = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.wasteRedSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: AppTheme.wasteRed),
                  ),
                  const SizedBox(width: 10),
                  const Text('مسح سجل العمليات',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'سيتم حذف جميع سجلات العمليات والتاريخ نهائياً.\nهذا الإجراء لا يمكن التراجع عنه.',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'كلمة مرور المدير',
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: wrongPass ? 'كلمة المرور غير صحيحة' : null,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.wasteRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: const Text('مسح السجل'),
                  onPressed: () async {
                    if (AuthService.instance.verifyPassword(passCtrl.text)) {
                      await HistoryService.instance.clearHistory();
                      Navigator.pop(ctx);
                      await _loadHistory();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم مسح سجل العمليات بنجاح'),
                            backgroundColor: AppTheme.successGreen,
                          ),
                        );
                      }
                    } else {
                      setDialogState(() => wrongPass = true);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Color _eventColor(String type) {
    if (type == 'login' || type == 'logout') return AppTheme.sidebarNavy;
    if (type == 'db_clear' || type == 'db_reset') return AppTheme.profitAmber;
    if (type.contains('_delete') || type.contains('delete_')) return AppTheme.wasteRed;
    if (type.contains('_edit') || type.contains('_update') || type.contains('update_')) {
      return AppTheme.primaryBlue;
    }
    if (type.contains('sale') ||
        type.contains('expense') ||
        type.contains('treasury') ||
        type.contains('salary') ||
        type.contains('advance') ||
        type.contains('supply')) {
      return AppTheme.costPurple;
    }
    return AppTheme.successGreen; // add operations default
  }

  Color _eventBgColor(String type) {
    if (type == 'login' || type == 'logout') return const Color(0xFFEEF2FF);
    if (type == 'db_clear' || type == 'db_reset') return AppTheme.profitAmberSoft;
    if (type.contains('_delete') || type.contains('delete_')) return AppTheme.wasteRedSoft;
    if (type.contains('_edit') || type.contains('_update') || type.contains('update_')) {
      return AppTheme.primaryBlueSoft;
    }
    if (type.contains('sale') ||
        type.contains('expense') ||
        type.contains('treasury') ||
        type.contains('salary') ||
        type.contains('advance') ||
        type.contains('supply')) {
      return AppTheme.costPurpleSoft;
    }
    return AppTheme.successGreenSoft;
  }

  IconData _eventIcon(String type) {
    if (type == 'login') return Icons.login_rounded;
    if (type == 'logout') return Icons.logout_rounded;
    if (type == 'db_clear' || type == 'db_reset') return Icons.delete_sweep_rounded;
    if (type.contains('product_delete') || type.contains('delete_')) return Icons.delete_outline_rounded;
    if (type.contains('product_add')) return Icons.inventory_2_outlined;
    if (type.contains('product_edit') || type.contains('product_update')) return Icons.edit_outlined;
    if (type.contains('batch_add')) return Icons.precision_manufacturing_outlined;
    if (type.contains('stock_add')) return Icons.add_box_outlined;
    if (type.contains('expense_add')) return Icons.receipt_long_outlined;
    if (type.contains('waste_add')) return Icons.recycling_rounded;
    if (type.contains('employee_add')) return Icons.person_add_outlined;
    if (type.contains('employee_edit') || type.contains('employee_update')) return Icons.manage_accounts_outlined;
    if (type.contains('salary_add')) return Icons.payments_outlined;
    if (type.contains('advance_add')) return Icons.currency_exchange_rounded;
    if (type.contains('sale_add')) return Icons.point_of_sale_outlined;
    if (type.contains('sale_delete')) return Icons.remove_shopping_cart_outlined;
    if (type.contains('treasury')) return Icons.account_balance_wallet_outlined;
    if (type.contains('supply_add')) return Icons.add_shopping_cart_outlined;
    if (type.contains('supplier_add')) return Icons.storefront_outlined;
    if (type.contains('stocktake_add')) return Icons.fact_check_outlined;
    if (type.contains('_edit') || type.contains('_update')) return Icons.edit_outlined;
    if (type.contains('_add')) return Icons.add_circle_outline_rounded;
    return Icons.history_rounded;
  }

  String _formatDate(DateTime dt) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} - $h:$m';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilterBar(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                  : _filtered.isEmpty
                      ? _buildEmptyState()
                      : _buildEventList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      color: AppTheme.surfaceWhite,
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.history_rounded,
                color: AppTheme.primaryBlue, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'سجل العمليات والتاريخ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'إجمالي العمليات المسجلة: ${_allEvents.length} عملية',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.list_alt_rounded,
                    size: 14, color: AppTheme.primaryBlue),
                const SizedBox(width: 6),
                Text(
                  '${_filtered.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Clear button
          ElevatedButton.icon(
            onPressed: _confirmClearHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.wasteRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete_sweep_rounded, size: 18),
            label: const Text('مسح السجل',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border(
          top: BorderSide(color: AppTheme.borderSubtle),
          bottom: BorderSide(color: AppTheme.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'بحث في سجل العمليات...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyFilters();
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Type filter dropdown
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _typeFilter,
              decoration: const InputDecoration(
                labelText: 'نوع العملية',
                prefixIcon: Icon(Icons.filter_list, size: 18),
              ),
              items: _typeOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _typeFilter = val);
                  _applyFilters();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          // Date range picker
          OutlinedButton.icon(
            onPressed: _pickDateRange,
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              side: BorderSide(
                  color: _dateRange != null
                      ? AppTheme.primaryBlue
                      : AppTheme.borderSubtle),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: Icon(
              Icons.date_range_rounded,
              size: 18,
              color:
                  _dateRange != null ? AppTheme.primaryBlue : AppTheme.textSecondary,
            ),
            label: Text(
              _dateRange != null
                  ? '${_dateRange!.start.day}/${_dateRange!.start.month} – ${_dateRange!.end.day}/${_dateRange!.end.month}'
                  : 'نطاق التاريخ',
              style: TextStyle(
                fontSize: 12.5,
                color: _dateRange != null
                    ? AppTheme.primaryBlue
                    : AppTheme.textSecondary,
              ),
            ),
          ),
          if (_dateRange != null) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'إلغاء فلتر التاريخ',
              icon: const Icon(Icons.close, size: 16, color: AppTheme.textMuted),
              onPressed: () {
                setState(() => _dateRange = null);
                _applyFilters();
              },
            ),
          ],
          const SizedBox(width: 12),
          // Refresh
          IconButton(
            tooltip: 'تحديث السجل',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryBlue),
            onPressed: _loadHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final event = _filtered[index];
        return _EventCard(
          event: event,
          color: _eventColor(event.type),
          bgColor: _eventBgColor(event.type),
          icon: _eventIcon(event.type),
          formattedDate: _formatDate(event.timestamp),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_toggle_off_rounded,
                size: 56, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 20),
          const Text(
            'لا توجد عمليات مسجلة',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'ستظهر هنا جميع العمليات التي يتم تنفيذها في النظام',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual event card
// ---------------------------------------------------------------------------

class _EventCard extends StatelessWidget {
  final HistoryEvent event;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final String formattedDate;

  const _EventCard({
    required this.event,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon bubble
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _typeLabel(event.type),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color),
                        ),
                      ),
                    ],
                  ),
                  if (event.details != null && event.details!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.details!,
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                          height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Meta row
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.person_outline_rounded,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        event.user,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    if (type == 'login') return 'دخول';
    if (type == 'logout') return 'خروج';
    if (type == 'db_clear' || type == 'db_reset') return 'قاعدة البيانات';
    if (type.contains('_delete') || type.contains('delete_')) return 'حذف';
    if (type.contains('_edit') || type.contains('_update') || type.contains('update_')) return 'تعديل';
    if (type.contains('sale')) return 'مبيعات';
    if (type.contains('expense')) return 'مصروفات';
    if (type.contains('treasury')) return 'خزنة';
    if (type.contains('salary')) return 'رواتب';
    if (type.contains('advance')) return 'سلف';
    if (type.contains('supply')) return 'توريد';
    if (type.contains('employee')) return 'موظفين';
    if (type.contains('product')) return 'أصناف';
    if (type.contains('batch')) return 'إنتاج';
    if (type.contains('waste')) return 'هالك';
    if (type.contains('stock')) return 'مخزون';
    if (type.contains('supplier')) return 'موردين';
    if (type.contains('stocktake')) return 'جرد';
    if (type.contains('_add') || type.contains('add_')) return 'إضافة';
    return 'عملية';
  }
}
