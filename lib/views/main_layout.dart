import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../state/factory_store.dart';
import 'dashboard_view.dart';
import 'products_view.dart';
import 'expenses_view.dart';
import 'employees_view.dart';
import 'wholesale_sales_view.dart';
import 'retail_sales_view.dart';
import 'suppliers_distributors_view.dart';
import 'stocktake_view.dart';
import 'database_settings_view.dart';
import 'treasury_view.dart';
import 'reports_view.dart';
import 'credit_sales_view.dart';
import 'material_supplies_view.dart';
import 'history_view.dart';
import 'dialogs/change_password_dialog.dart';

class MainLayout extends StatefulWidget {
  final FactoryStore store;

  const MainLayout({super.key, required this.store});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;

  final List<String> _pageTitles = [
    'لوحة التحكم',
    'المخزون والأصناف',
    'البيع بالجملة (كبار الموزعين والتجار)',
    'البيع بالقطاعي (منافذ بيع المصنع والكاش)',
    'إدارة الآجل والمديونيات (علينا ولنا)',
    'الموردين والموزعين وكشوف الحساب',
    'إدارة الموظفين والسلف وصرف الرواتب والورديات',
    'الجرد الدوري (يومي / أسبوعي / شهري)',
    'خزنة المصنع وحسابات الأرباح والخسائر (P&L)',
    'التكاليف والمصروفات التشغيلية',
    'التقارير الشاملة وتحليلات الأرباح (P&L)',
    'قاعدة البيانات الداخلية وإعدادات النظام',
    'توريدات المواد الخام والبوليمر',
    'سجل العمليات والتاريخ',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // واجهة عربية بالكامل
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Row(
          children: [
            // -------------------------------------------------------------
            // القائمة الجانبية (Sidebar في اليمين)
            // -------------------------------------------------------------
            _buildSidebar(),

            // -------------------------------------------------------------
            // محتوى الصفحة الرئيسي والشريط العلوي
            // -------------------------------------------------------------
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: _buildCurrentView(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return DashboardView(
          store: widget.store,
          onNavigateTab: (idx) => setState(() => _selectedIndex = idx),
        );
      case 1:
        return ProductsView(store: widget.store);
      case 2:
        return WholesaleSalesView(store: widget.store);
      case 3:
        return RetailSalesView(store: widget.store);
      case 4:
        return CreditSalesView(store: widget.store);
      case 5:
        return SuppliersDistributorsView(store: widget.store);
      case 6:
        return EmployeesView(store: widget.store);
      case 7:
        return StocktakeView(store: widget.store);
      case 8:
        return TreasuryView(store: widget.store);
      case 9:
        return ExpensesView(store: widget.store);
      case 10:
        return ReportsView(store: widget.store);
      case 11:
        return DatabaseSettingsView(store: widget.store);
      case 12:
        return MaterialSuppliesView(store: widget.store);
      case 13:
        return const HistoryView();
      default:
        return DashboardView(store: widget.store);
    }
  }

  // -------------------------------------------------------------
  // الشريط العلوي (TopBar)
  // -------------------------------------------------------------
  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Row(
        children: [
          // زر طي القائمة وعنوان الشاشة الحالية
          IconButton(
            icon: const Icon(Icons.menu, color: AppTheme.textSecondary),
            onPressed: () {
              setState(() => _sidebarCollapsed = !_sidebarCollapsed);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _pageTitles[_selectedIndex],
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 14),

          // زر حالة قاعدة البيانات الداخلية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successGreenSoft,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.storage, size: 14, color: AppTheme.successGreen),
                SizedBox(width: 6),
                Text('قاعدة بيانات داخلية', style: TextStyle(fontSize: 11.5, color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // زر التاريخ (مطابق للصورة: 30 يوليو 2026)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  DateFormat('d MMMM yyyy', 'ar').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // أيقونة الإشعارات المرتبطة بتنبيهات المخزون اللحظية
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'تنبيهات المخزون والنظام',
                icon: Icon(
                  widget.store.stockAlertCount > 0 ? Icons.notifications_active_outlined : Icons.notifications_none_rounded,
                  color: widget.store.stockAlertCount > 0 ? const Color(0xFFD97706) : AppTheme.textSecondary,
                ),
                onPressed: () => _showStockAlertsDialog(context),
              ),
              if (widget.store.stockAlertCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.wasteRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        '${widget.store.stockAlertCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),

          // زر تغيير كلمة مرور المدير
          IconButton(
            tooltip: 'تغيير كلمة مرور المدير',
            icon: const Icon(Icons.key_rounded, color: AppTheme.primaryBlue, size: 20),
            onPressed: () => ChangePasswordDialog.show(context),
          ),
          const SizedBox(width: 4),

          // زر تسجيل الخروج
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout, color: AppTheme.wasteRed),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج من النظام؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.wasteRed),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('خروج', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
              if (confirm == true && mounted) {
                Provider.of<AuthProvider>(context, listen: false).signOut();
              }
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // القائمة الجانبية باللون الكحلي الداكن (مطابقة تماماً للصورة في اليمين)
  // -------------------------------------------------------------
  Widget _buildSidebar() {
    final width = _sidebarCollapsed ? 76.0 : 255.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: const BoxDecoration(
        color: AppTheme.sidebarNavy,
      ),
      child: Column(
        children: [
          // رأس السايدبار (شعار واسم المصنع)
          Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F), width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: _sidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.star_rounded,
                        color: AppTheme.primaryBlue,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.store.factoryName.isNotEmpty ? widget.store.factoryName : 'النجمة بلاست',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'نظام إدارة وتشغيل المصنع',
                          style: TextStyle(
                            color: AppTheme.sidebarTextMuted,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // عناصر القائمة الجانبية
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              children: [
                _sidebarItem(
                  index: 0,
                  title: 'لوحة التحكم',
                  icon: Icons.dashboard_outlined,
                ),
                _sidebarItem(
                  index: 1,
                  title: 'المخزون والأصناف',
                  icon: Icons.inventory_2_outlined,
                ),
                _sidebarItem(
                  index: 2,
                  title: 'البيع بالجملة',
                  icon: Icons.local_shipping_outlined,
                  badgeText: 'جملة',
                  badgeColor: AppTheme.primaryBlue,
                ),
                _sidebarItem(
                  index: 3,
                  title: 'البيع بالقطاعي',
                  icon: Icons.point_of_sale_outlined,
                  badgeText: 'كاش',
                  badgeColor: AppTheme.successGreen,
                ),
                _sidebarItem(
                  index: 4,
                  title: 'الآجل والمديونيات',
                  icon: Icons.credit_score_rounded,
                  badgeText: (widget.store.creditOrders.any((o) => !o.isFullyPaid) ||
                          widget.store.materialSupplyOrders.any((o) => o.remainingAmount > 0.01))
                      ? '${widget.store.creditOrders.where((o) => !o.isFullyPaid).length + widget.store.materialSupplyOrders.where((o) => o.remainingAmount > 0.01).length} معلق'
                      : null,
                  badgeColor: const Color(0xFFDC2626),
                ),
                _sidebarItem(
                  index: 5,
                  title: 'الموردين والموزعين',
                  icon: Icons.storefront_outlined,
                ),
                _sidebarItem(
                  index: 12,
                  title: 'توريدات المواد الخام',
                  icon: Icons.add_shopping_cart_outlined,
                  badgeText: widget.store.materialSupplyOrders.isNotEmpty
                      ? '${widget.store.materialSupplyOrders.length}'
                      : null,
                  badgeColor: AppTheme.successGreen,
                ),
                _sidebarItem(
                  index: 6,
                  title: 'الموظفين والسلف والرواتب',
                  icon: Icons.groups_outlined,
                  badgeText: '${widget.store.employees.length}',
                  badgeColor: AppTheme.costPurple,
                ),
                _sidebarItem(
                  index: 7,
                  title: 'الجرد الدوري',
                  icon: Icons.fact_check_outlined,
                  badgeText: 'يومي/شهري',
                  badgeColor: AppTheme.profitAmber,
                ),
                _sidebarItem(
                  index: 8,
                  title: 'الخزنة والأرباح (P&L)',
                  icon: Icons.account_balance_wallet_outlined,
                  badgeText: 'كاش',
                  badgeColor: const Color(0xFF0D9488),
                ),
                _sidebarItem(
                  index: 9,
                  title: 'التكاليف والمصروفات',
                  icon: Icons.attach_money_rounded,
                ),
                _sidebarItem(
                  index: 10,
                  title: 'التقارير الشاملة',
                  icon: Icons.analytics_outlined,
                  badgeText: 'تحليلات',
                  badgeColor: AppTheme.primaryBlue,
                ),
                _sidebarItem(
                  index: 11,
                  title: 'قاعدة البيانات والإعدادات',
                  icon: Icons.storage_outlined,
                ),
                _sidebarItem(
                  index: 13,
                  title: 'سجل العمليات',
                  icon: Icons.history_rounded,
                  badgeText: 'LOG',
                  badgeColor: const Color(0xFF7C3AED),
                ),
              ],
            ),
          ),

          // بطاقة ملف مدير النظام في الأسفل
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppTheme.sidebarNavyDark,
              border: Border(top: BorderSide(color: Color(0xFF1E3A5F), width: 0.8)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.sidebarHover,
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'مدير النظام',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'admin',
                          style: TextStyle(
                            color: AppTheme.sidebarTextMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: AppTheme.sidebarTextMuted, size: 18),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required int index,
    required String title,
    required IconData icon,
    String? badgeText,
    Color? badgeColor,
  }) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedIndex = index);
          },
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppTheme.sidebarHover,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.sidebarActiveBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: _sidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : AppTheme.sidebarTextMuted,
                  size: 20,
                ),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.sidebarTextMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor ?? AppTheme.successGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStockAlertsDialog(BuildContext context) {
    final alertProducts = widget.store.stockAlertProducts;
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: alertProducts.isNotEmpty ? const Color(0xFFFEF3C7) : AppTheme.primaryBlueSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  alertProducts.isNotEmpty ? Icons.warning_amber_rounded : Icons.notifications_none_rounded,
                  color: alertProducts.isNotEmpty ? const Color(0xFFB45309) : AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              const Text('مركز إشعارات وتنبيهات المخزون', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: alertProducts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'كافة أرصدة المخزون آمنة ومستقرة',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'لا توجد أصناف قاربت على النفاذ في الوقت الحالي.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'يوجد ${alertProducts.length} صنف يحتاج انتباهك وإعادة إنتاج لتفادي تعطل المبيعات:',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: alertProducts.length,
                          separatorBuilder: (_, __) => const Divider(height: 10),
                          itemBuilder: (context, i) {
                            final p = alertProducts[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: p.isOutOfStock ? AppTheme.wasteRedSoft : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  p.isOutOfStock ? Icons.error_outline : Icons.warning_amber_rounded,
                                  color: p.isOutOfStock ? AppTheme.wasteRed : const Color(0xFFB45309),
                                  size: 20,
                                ),
                              ),
                              title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                p.isOutOfStock
                                    ? 'نفذ رصيد الصنف تماماً من المستودع (0 كجم)!'
                                    : 'المتبقي بالمستودع: ${p.stockKg.toStringAsFixed(0)} كجم فقط',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: p.isOutOfStock ? AppTheme.wasteRed : const Color(0xFFB45309),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: const Size(60, 32),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  setState(() => _selectedIndex = 1); // الانتقال للأصناف
                                },
                                child: const Text('عرض', style: TextStyle(fontSize: 11)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}
