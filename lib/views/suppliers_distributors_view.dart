import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/supplier.dart';
import '../models/distributor.dart';
import '../state/factory_store.dart';
import 'material_supplies_view.dart';

class SuppliersDistributorsView extends StatefulWidget {
  final FactoryStore store;

  const SuppliersDistributorsView({super.key, required this.store});

  @override
  State<SuppliersDistributorsView> createState() => _SuppliersDistributorsViewState();
}

class _SuppliersDistributorsViewState extends State<SuppliersDistributorsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _formatNumber(num value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس الصفحة والأزرار العلوية
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'إدارة الموردين والموزعين وكشوف الحساب',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'متابعة توريدات البوليمر والماستر باتش، وحسابات ومديونيات وكلاء وتجار الجملة',
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                    label: const Text('إذن توريد خامة جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: const Text('توريدات المواد الخام والبوليمر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              backgroundColor: AppTheme.surfaceWhite,
                            ),
                            body: MaterialSuppliesView(store: widget.store),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.costPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.add_business_outlined, size: 18),
                    label: const Text('إضافة مورد خام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => _showAddSupplierDialog(context),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('إضافة موزع / تاجر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => _showAddDistributorDialog(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // كروت الإحصاءات العلوية (KPIs)
          Row(
            children: [
              Expanded(
                child: _statCard('إجمالي الموردين', '${store.suppliers.length} موردين', Icons.local_shipping_outlined, AppTheme.costPurple, AppTheme.costPurpleSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('إجمالي الموزعين والوكلاء', '${store.distributors.length} موزع', Icons.storefront_outlined, AppTheme.primaryBlue, AppTheme.primaryBlueSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('إجمالي مديونيات الموزعين', '${_formatNumber(store.distributors.fold(0.0, (s, d) => s + d.currentDebt))} ج.م', Icons.account_balance_wallet_outlined, AppTheme.wasteRed, AppTheme.wasteRedSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('حجم مسحوبات الموزعين', '${_formatNumber(store.distributors.fold(0.0, (s, d) => s + d.totalSalesVolumeKg))} كجم', Icons.trending_up, AppTheme.successGreen, AppTheme.successGreenSoft),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // شريط التبويب الأنيق
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryBlue,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.fire_truck_outlined, size: 20), text: 'الموردين (المواد الخام والبوليمر)'),
                Tab(icon: Icon(Icons.groups_outlined, size: 20), text: 'الموزعين وتجار الجملة والعملاء'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // محتوى التبويبات
          SizedBox(
            height: 480,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSuppliersTab(store),
                _buildDistributorsTab(store),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliersTab(FactoryStore store) {
    if (store.suppliers.isEmpty) {
      return Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.costPurpleSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fire_truck_outlined, size: 40, color: AppTheme.costPurple),
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا يوجد موردون مسجلون حالياً',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'قم بإضافة بيانات شركات توريد البوليمر والماستر باتش ومستلزمات الإنتاج لمتابعة التوريدات والمدفوعات',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.costPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_business_outlined, size: 18),
                  label: const Text('إضافة أول مورد خام', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showAddSupplierDialog(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'قائمة موردي حبيبات البوليمر والمواد الخام والصبغات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Text(
                  'العدد: ${store.suppliers.length} مورد',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.costPurple),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.0), // اسم المورد
                1: FlexColumnWidth(1.8), // المصنع التابع له
                2: FlexColumnWidth(2.0), // الصنف المورد
                3: FlexColumnWidth(2.0), // تفاصيل الاتصال
                4: FlexColumnWidth(1.4), // إجمالي المشتريات
                5: FlexColumnWidth(1.5), // الرصيد المالي
                6: FlexColumnWidth(1.1), // إجراءات
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                  ),
                  children: [
                    _headerCell('اسم المورد'),
                    _headerCell('المصنع التابع له'),
                    _headerCell('الصنف المورد'),
                    _headerCell('تفاصيل الاتصال'),
                    _headerCell('إجمالي المشتريات'),
                    _headerCell('الرصيد المالي'),
                    _headerCell('إجراءات'),
                  ],
                ),
                ...store.suppliers.map((sup) {
                  return TableRow(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              sup.name.isNotEmpty ? sup.name : sup.companyName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                              textAlign: TextAlign.center,
                            ),
                            if (sup.notes != null && sup.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  sup.notes!,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.costPurpleSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.factory_outlined, size: 13, color: AppTheme.costPurple),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    sup.companyName.isNotEmpty ? sup.companyName : 'غير محدد',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.costPurple),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _textCell(sup.materialSupplied),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (sup.phone.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone_outlined, size: 12, color: AppTheme.textMuted),
                                  const SizedBox(width: 4),
                                  Text(sup.phone, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            if (sup.address.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textMuted),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        sup.address,
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      _textCell('${_formatNumber(sup.totalPurchasesKg)} كجم', isBold: true),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Center(
                          child: Text(
                            sup.currentBalance < 0
                                ? 'له: ${_formatNumber(sup.currentBalance.abs())} ج.م'
                                : (sup.currentBalance > 0 ? 'لنا: ${_formatNumber(sup.currentBalance)} ج.م' : 'خالص 0 ج.م'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: sup.currentBalance < 0 ? AppTheme.wasteRed : AppTheme.successGreen,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 17, color: AppTheme.primaryBlue),
                              tooltip: 'تعديل بيانات المورد',
                              onPressed: () => _showEditSupplierDialog(context, sup),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 17, color: AppTheme.wasteRed),
                              tooltip: 'حذف المورد',
                              onPressed: () => _confirmDeleteSupplier(context, sup),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
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
    );
  }

  Widget _buildDistributorsTab(FactoryStore store) {
    if (store.distributors.isEmpty) {
      return Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_outlined, size: 40, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا يوجد موزعون أو تجار جملة مسجلون حالياً',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'قم بإضافة وكلاء التوزيع وتجار الجملة لمتابعة مسحوباتهم وفواتيرهم ومديونياتهم',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('إضافة أول موزع / تاجر', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showAddDistributorDialog(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'قائمة الموزعين وتجار الجملة المعتمدين والمنافذ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Text(
                  'العدد: ${store.distributors.length} موزع',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.4), // الاسم التجاري
                1: FlexColumnWidth(1.6), // التاجر
                2: FlexColumnWidth(1.3), // التصنيف
                3: FlexColumnWidth(1.6), // المنطقة
                4: FlexColumnWidth(1.4), // المسحوبات (كجم)
                5: FlexColumnWidth(1.6), // المديونية الحالية
                6: FlexColumnWidth(1.1), // إجراءات
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                  ),
                  children: [
                    _headerCell('الاسم التجاري'),
                    _headerCell('اسم التاجر / الوكيل'),
                    _headerCell('التصنيف'),
                    _headerCell('المنطقة'),
                    _headerCell('حجم المسحوبات'),
                    _headerCell('المديونية الحالية'),
                    _headerCell('إجراءات'),
                  ],
                ),
                ...store.distributors.map((dist) {
                  return TableRow(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                    ),
                    children: [
                      _textCell(dist.tradeName, isBold: true),
                      _textCell(dist.name),
                      _textCell(dist.type),
                      _textCell(dist.region),
                      _textCell('${_formatNumber(dist.totalSalesVolumeKg)} كجم', isBold: true, color: AppTheme.primaryBlue),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Center(
                          child: Text(
                            dist.currentDebt > 0 ? '${_formatNumber(dist.currentDebt)} ج.م' : 'خالص 0 ج.م',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: dist.currentDebt > 0 ? AppTheme.wasteRed : AppTheme.successGreen,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 17, color: AppTheme.primaryBlue),
                              tooltip: 'تعديل بيانات الموزع',
                              onPressed: () => _showEditDistributorDialog(context, dist),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 17, color: AppTheme.wasteRed),
                              tooltip: 'حذف الموزع',
                              onPressed: () => _confirmDeleteDistributor(context, dist),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
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
    );
  }

  Widget _headerCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary), textAlign: TextAlign.center),
    );
  }

  Widget _textCell(String text, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
      child: Text(text, style: TextStyle(fontSize: 12.5, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? AppTheme.textPrimary), textAlign: TextAlign.center),
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

  // ----------------------------------------------------
  // نافذة إضافة مورد جديد بتصميم حديث وتفصيلي
  // ----------------------------------------------------
  void _showAddSupplierDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final customMatCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '0');
    String balanceType = 'creditor'; // creditor = له (دائن), debtor = عليه (مدين)

    final commonFactories = [
      'سابك SABIC',
      'إيثيدكو ETHYDCO',
      'سيدبك SIDPEC',
      'بروج Borouge',
      'الشرقيون OPC',
      'المصرية للبتروكيماويات',
    ];

    // جلب الأصناف المدخلة فعلياً في شاشة "المخزون والأصناف" فقط بدون أي خامات افتراضية
    final availableMaterials = widget.store.products
        .map((p) => p.name.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();

    final selectedMaterials = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: AppTheme.surfaceWhite,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // رأس الحوار الأنيق
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppTheme.costPurpleSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_business_outlined, color: AppTheme.costPurple, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'إضافة مورد مواد خام جديد',
                                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'تسجيل بيانات المورد، المصنع التابع له، الصنف المورد، وبيانات التواصل',
                                style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // اسم المورد والمصنع التابع له
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اسم المورد
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('اسم المورد *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: nameCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'مثال: م/ محمود سامي',
                                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل اسم المورد' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // المصنع التابع له
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('المصنع التابع له (اختياري)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: companyCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'مثال: مصنع سابك، إيثيدكو...',
                                  prefixIcon: const Icon(Icons.factory_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // اختيارات سريعة للمصانع
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: commonFactories.map((factoryName) {
                        final isSelected = companyCtrl.text.trim() == factoryName;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              companyCtrl.text = factoryName;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.costPurple : AppTheme.background,
                              border: Border.all(color: isSelected ? AppTheme.costPurple : AppTheme.borderSubtle),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              factoryName,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // اختيار الخامات / الأصناف الموردة
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'الخامات / الأصناف الموردة (يمكن اختيار أكثر من صنف) *',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            if (selectedMaterials.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlueSoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${selectedMaterials.length} محددة',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        if (availableMaterials.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.profitAmberSoft,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.profitAmber.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, size: 15, color: AppTheme.profitAmber),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'لا توجد أصناف مدخلة بالمخزون حالياً. اكتب اسم الصنف يدوياً أدناه.',
                                    style: TextStyle(fontSize: 11, color: AppTheme.profitAmber),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ] else ...[
                          const Text(
                            'انقر على الصنف لتحديده للمورد (يمكن اختيار أكثر من صنف):',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: availableMaterials.map((item) {
                              final isSelected = selectedMaterials.contains(item);
                              return InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    if (isSelected) {
                                      selectedMaterials.remove(item);
                                    } else {
                                      selectedMaterials.add(item);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primaryBlue : AppTheme.background,
                                    border: Border.all(
                                      color: isSelected ? AppTheme.primaryBlue : AppTheme.borderSubtle,
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline,
                                        size: 14,
                                        color: isSelected ? Colors.white : AppTheme.primaryBlue,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // إضافة صنف مخصص يدوياً
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: customMatCtrl,
                                style: const TextStyle(fontSize: 12.5),
                                decoration: InputDecoration(
                                  hintText: 'إضافة صنف أو خامة أخرى يدوياً...',
                                  prefixIcon: const Icon(Icons.edit_note_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onFieldSubmitted: (v) {
                                  final text = v.trim();
                                  if (text.isNotEmpty) {
                                    setDialogState(() {
                                      selectedMaterials.add(text);
                                      customMatCtrl.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlueSoft,
                                foregroundColor: AppTheme.primaryBlue,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () {
                                final text = customMatCtrl.text.trim();
                                if (text.isNotEmpty) {
                                  setDialogState(() {
                                    selectedMaterials.add(text);
                                    customMatCtrl.clear();
                                  });
                                }
                              },
                            ),
                          ],
                        ),

                        // شريط عرض الخامات المحددة حالياً للمورد
                        if (selectedMaterials.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text('الخامات المعتمدة للمورد:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                                ...selectedMaterials.map((mat) => Chip(
                                  label: Text(mat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  deleteIcon: const Icon(Icons.close, size: 13),
                                  onDeleted: () => setDialogState(() => selectedMaterials.remove(mat)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                )),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // رقم الهاتف والعنوان
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('رقم الهاتف والتواصل', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'مثال: 01012345678',
                                  prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              const Text('العنوان / المقر', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: addrCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'مثال: العاشر من رمضان، برج العرب...',
                                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ملاحظات وتفاصيل إضافية + الرصيد الافتتاحي
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('تفاصيل وملاحظات إضافية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: notesCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'مثال: شروط الدفع، فترات السماح، مواعيد التوريد...',
                                  prefixIcon: const Icon(Icons.notes_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
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
                              const Text('الرصيد المبدئي (ج.م)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: balanceCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  DropdownButton<String>(
                                    value: balanceType,
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(value: 'creditor', child: Text('له (دائن)', style: TextStyle(fontSize: 11.5, color: AppTheme.wasteRed))),
                                      DropdownMenuItem(value: 'debtor', child: Text('لنا (مدين)', style: TextStyle(fontSize: 11.5, color: AppTheme.successGreen))),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) setDialogState(() => balanceType = v);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // الأزرار السفلية
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('إلغاء'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.costPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 1,
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('حفظ المورد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              if (customMatCtrl.text.trim().isNotEmpty) {
                                selectedMaterials.add(customMatCtrl.text.trim());
                              }
                              if (selectedMaterials.isEmpty) {
                                selectedMaterials.add('مواد خام وبوليمر');
                              }

                              final finalMaterials = selectedMaterials.toList();
                              final rawBal = double.tryParse(balanceCtrl.text.trim()) ?? 0.0;
                              // إذا كان "له" دائن فنحسبه بالسالب (مستحقات للمورد علينا)
                              final finalBal = balanceType == 'creditor' ? -rawBal.abs() : rawBal.abs();

                              final sName = nameCtrl.text.trim();
                              final sCompany = companyCtrl.text.trim().isNotEmpty ? companyCtrl.text.trim() : sName;

                              final newSupplier = Supplier(
                                id: 'sup-${DateTime.now().millisecondsSinceEpoch}',
                                name: sName,
                                companyName: sCompany,
                                materialSupplied: finalMaterials.join('، '),
                                materials: finalMaterials,
                                phone: phoneCtrl.text.trim(),
                                address: addrCtrl.text.trim(),
                                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                currentBalance: rawBal == 0 ? 0.0 : finalBal,
                                totalPurchasesKg: 0,
                              );

                              Navigator.of(ctx).pop();
                              widget.store.addSupplier(newSupplier);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تمت إضافة المورد بنجاح!'),
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
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // نافذة تعديل بيانات المورد
  // ----------------------------------------------------
  void _showEditSupplierDialog(BuildContext context, Supplier sup) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: sup.name);
    final companyCtrl = TextEditingController(text: sup.companyName);
    final phoneCtrl = TextEditingController(text: sup.phone);
    final addrCtrl = TextEditingController(text: sup.address);
    final notesCtrl = TextEditingController(text: sup.notes ?? '');

    // جلب الأصناف المدخلة فعلياً في شاشة "المخزون والأصناف" فقط بدون أي خامات افتراضية
    final availableMaterials = <String>{
      ...widget.store.products
          .map((p) => p.name.trim())
          .where((n) => n.isNotEmpty),
      ...sup.suppliedMaterials,
    }.toList();

    final selectedMaterials = <String>{
      ...sup.suppliedMaterials,
    };
    if (selectedMaterials.isEmpty && availableMaterials.isNotEmpty) {
      selectedMaterials.add(availableMaterials.first);
    }
    final customMatCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlueSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تعديل بيانات المورد', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            const SizedBox(height: 2),
                            Text('تعديل بيانات المورد (${sup.name})', style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('اسم المورد *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: nameCtrl,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.person_outline, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل اسم المورد' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('المصنع التابع له *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: companyCtrl,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.factory_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل المصنع التابع له' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                    // اختيار الخامات / الأصناف الموردة
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'الخامات / الأصناف الموردة (يمكن اختيار أكثر من صنف) *',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            if (selectedMaterials.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlueSoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${selectedMaterials.length} محددة',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        if (availableMaterials.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.profitAmberSoft,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.profitAmber.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, size: 15, color: AppTheme.profitAmber),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'لا توجد أصناف مدخلة بالمخزون حالياً. اكتب اسم الصنف يدوياً أدناه.',
                                    style: TextStyle(fontSize: 11, color: AppTheme.profitAmber),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ] else ...[
                          const Text(
                            'انقر على الصنف لتحديده للمورد (يمكن اختيار أكثر من صنف):',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: availableMaterials.map((item) {
                              final isSelected = selectedMaterials.contains(item);
                              return InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    if (isSelected) {
                                      if (selectedMaterials.length > 1) {
                                        selectedMaterials.remove(item);
                                      }
                                    } else {
                                      selectedMaterials.add(item);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primaryBlue : AppTheme.background,
                                    border: Border.all(
                                      color: isSelected ? AppTheme.primaryBlue : AppTheme.borderSubtle,
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline,
                                        size: 14,
                                        color: isSelected ? Colors.white : AppTheme.primaryBlue,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // إضافة صنف مخصص يدوياً
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: customMatCtrl,
                                style: const TextStyle(fontSize: 12.5),
                                decoration: InputDecoration(
                                  hintText: 'إضافة صنف أو خامة أخرى يدوياً...',
                                  prefixIcon: const Icon(Icons.edit_note_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onFieldSubmitted: (v) {
                                  final text = v.trim();
                                  if (text.isNotEmpty) {
                                    setDialogState(() {
                                      selectedMaterials.add(text);
                                      customMatCtrl.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlueSoft,
                                foregroundColor: AppTheme.primaryBlue,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () {
                                final text = customMatCtrl.text.trim();
                                if (text.isNotEmpty) {
                                  setDialogState(() {
                                    selectedMaterials.add(text);
                                    customMatCtrl.clear();
                                  });
                                }
                              },
                            ),
                          ],
                        ),

                        // شريط عرض الخامات المحددة حالياً للمورد
                        if (selectedMaterials.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text('الخامات المعتمدة للمورد:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                                ...selectedMaterials.map((mat) => Chip(
                                  label: Text(mat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  deleteIcon: selectedMaterials.length > 1 ? const Icon(Icons.close, size: 13) : null,
                                  onDeleted: selectedMaterials.length > 1
                                      ? () => setDialogState(() => selectedMaterials.remove(mat))
                                      : null,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                )),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('رقم الهاتف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                            const Text('العنوان / المقر', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: addrCtrl,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('تفاصيل وملاحظات إضافية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: notesCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.notes_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            if (customMatCtrl.text.trim().isNotEmpty) {
                              selectedMaterials.add(customMatCtrl.text.trim());
                            }
                            if (selectedMaterials.isEmpty) {
                              selectedMaterials.add('مواد خام وبوليمر');
                            }

                            final finalMaterials = selectedMaterials.toList();
                            final sName = nameCtrl.text.trim();
                            final sCompany = companyCtrl.text.trim().isNotEmpty ? companyCtrl.text.trim() : sName;

                            Navigator.of(ctx).pop();
                            widget.store.updateSupplier(sup.copyWith(
                              name: sName,
                              companyName: sCompany,
                              materialSupplied: finalMaterials.join('، '),
                              materials: finalMaterials,
                              phone: phoneCtrl.text.trim(),
                              address: addrCtrl.text.trim(),
                              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تحديث بيانات المورد بنجاح!'),
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
        ),
      ),
    ),
  );
}

  // ----------------------------------------------------
  // تأكيد حذف مورد
  // ----------------------------------------------------
  void _confirmDeleteSupplier(BuildContext context, Supplier sup) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppTheme.wasteRed, size: 24),
            SizedBox(width: 8),
            Text('تأكيد حذف المورد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('هل أنت متأكد من حذف المورد "${sup.name.isNotEmpty ? sup.name : sup.companyName}"؟\nالمصنع: ${sup.companyName}\nالصنف: ${sup.materialSupplied}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.wasteRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              widget.store.deleteSupplier(sup.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف المورد بنجاح'),
                  backgroundColor: AppTheme.wasteRed,
                ),
              );
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // نافذة إضافة موزع / تاجر جديد بتصميم عصري وأنيق
  // ----------------------------------------------------
  void _showAddDistributorDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final tradeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final regionCtrl = TextEditingController(text: 'القاهرة');
    final phoneCtrl = TextEditingController();
    String type = 'تاجر جملة';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppTheme.surfaceWhite,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // رأس الحوار الأنيق
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlueSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_add_alt_1, color: AppTheme.primaryBlue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('إضافة موزع / تاجر جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            SizedBox(height: 2),
                            Text('تسجيل بيانات العميل أو الوكيل أو تاجر الجملة', style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // الاسم التجاري أو اسم المحل
                    const Text('الاسم التجاري / اسم المحل أو الشركة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: tradeCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'مثال: شركة الأمل لتجارة وتوزيع البلاستيك',
                        prefixIcon: const Icon(Icons.storefront_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الاسم التجاري' : null,
                    ),
                    const SizedBox(height: 12),

                    // اسم التاجر والتصنيف
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('اسم التاجر / المسؤول', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: nameCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'مثال: أ/ محمد علي',
                                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              const Text('التصنيف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              const SizedBox(height: 5),
                              DropdownButtonFormField<String>(
                                value: type,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                  prefixIcon: const Icon(Icons.category_outlined, size: 18),
                                ),
                                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                items: const [
                                  DropdownMenuItem(value: 'تاجر جملة', child: Text('تاجر جملة')),
                                  DropdownMenuItem(value: 'موزع معتمد', child: Text('موزع معتمد')),
                                  DropdownMenuItem(value: 'سوبرماركت وقطاعي', child: Text('سوبرماركت وقطاعي')),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setDialogState(() => type = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // المنطقة ورقم الهاتف
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('المنطقة / المحافظة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: regionCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'مثال: القاهرة - العتبة',
                                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              TextFormField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: '01012345678',
                                  prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // الأزرار السفلية
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('إلغاء'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 1,
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('حفظ الموزع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              widget.store.addDistributor(Distributor(
                                id: 'dist-${DateTime.now().millisecondsSinceEpoch}',
                                tradeName: tradeCtrl.text.trim(),
                                name: nameCtrl.text.trim(),
                                type: type,
                                region: regionCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                currentDebt: 0,
                                creditLimit: 50000,
                                totalSalesVolumeKg: 0,
                              ));
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تمت إضافة الموزع بنجاح!'),
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
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // نافذة تعديل بيانات موزع / تاجر قائم
  // ----------------------------------------------------
  void _showEditDistributorDialog(BuildContext context, Distributor dist) {
    final formKey = GlobalKey<FormState>();
    final tradeCtrl = TextEditingController(text: dist.tradeName);
    final nameCtrl = TextEditingController(text: dist.name);
    final regionCtrl = TextEditingController(text: dist.region);
    final phoneCtrl = TextEditingController(text: dist.phone);
    final creditLimitCtrl = TextEditingController(text: dist.creditLimit > 0 ? dist.creditLimit.toStringAsFixed(0) : '50000');
    final notesCtrl = TextEditingController(text: dist.notes ?? '');
    String type = ['تاجر جملة', 'موزع معتمد', 'سوبرماركت وقطاعي'].contains(dist.type) ? dist.type : 'تاجر جملة';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppTheme.surfaceWhite,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // رأس الحوار الأنيق
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlueSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تعديل بيانات الموزع / التاجر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            const SizedBox(height: 2),
                            Text('تحديث بيانات ${dist.tradeName}', style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // الاسم التجاري
                    const Text('الاسم التجاري / اسم المحل أو الشركة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: tradeCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'مثال: شركة الأمل لتجارة وتوزيع البلاستيك',
                        prefixIcon: const Icon(Icons.storefront_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الاسم التجاري' : null,
                    ),
                    const SizedBox(height: 12),

                    // اسم التاجر والتصنيف
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('اسم التاجر / المسؤول', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: nameCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'مثال: أ/ محمد علي',
                                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              const Text('التصنيف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              const SizedBox(height: 5),
                              DropdownButtonFormField<String>(
                                value: type,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                  prefixIcon: const Icon(Icons.category_outlined, size: 18),
                                ),
                                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                items: const [
                                  DropdownMenuItem(value: 'تاجر جملة', child: Text('تاجر جملة')),
                                  DropdownMenuItem(value: 'موزع معتمد', child: Text('موزع معتمد')),
                                  DropdownMenuItem(value: 'سوبرماركت وقطاعي', child: Text('سوبرماركت وقطاعي')),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setDialogState(() => type = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // المنطقة ورقم الهاتف
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('المنطقة / المحافظة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: regionCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'مثال: القاهرة - العتبة',
                                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              TextFormField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: '01012345678',
                                  prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // الحد الائتماني
                    const Text('الحد الائتماني المسموح به (ج.م)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: creditLimitCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '50000',
                        prefixIcon: const Icon(Icons.credit_card_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ملاحظات
                    const Text('ملاحظات إضافية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'شروط السداد، مواعيد التسليم، أو أي ملاحظات هامة...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // الأزرار السفلية
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('إلغاء'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 1,
                          ),
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final updatedDist = Distributor(
                                id: dist.id,
                                tradeName: tradeCtrl.text.trim(),
                                name: nameCtrl.text.trim(),
                                type: type,
                                region: regionCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                currentDebt: dist.currentDebt,
                                creditLimit: double.tryParse(creditLimitCtrl.text.trim()) ?? dist.creditLimit,
                                totalSalesVolumeKg: dist.totalSalesVolumeKg,
                                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                              );
                              widget.store.updateDistributor(updatedDist);
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم تعديل بيانات الموزع بنجاح!'),
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
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // تأكيد حذف موزع
  // ----------------------------------------------------
  void _confirmDeleteDistributor(BuildContext context, Distributor dist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppTheme.wasteRed, size: 24),
            SizedBox(width: 8),
            Text('تأكيد حذف الموزع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('هل أنت متأكد من حذف الموزع "${dist.tradeName}" (${dist.name})؟\nالمنطقة: ${dist.region}\nالمديونية: ${_formatNumber(dist.currentDebt)} ج.م'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.wasteRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              widget.store.deleteDistributor(dist.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف الموزع بنجاح'),
                  backgroundColor: AppTheme.wasteRed,
                ),
              );
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
