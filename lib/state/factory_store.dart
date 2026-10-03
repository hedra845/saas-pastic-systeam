import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../models/product_item.dart';
import '../models/stock_addition_record.dart';
import '../models/production_batch.dart';
import '../models/expense_item.dart';
import '../models/waste_record.dart';
import '../models/employee.dart';
import '../models/employee_advance.dart';
import '../models/salary_payment.dart';
import '../models/supplier.dart';
import '../models/distributor.dart';
import '../models/sale_order.dart';
import '../models/stocktake_record.dart';
import '../models/treasury_transaction.dart';
import '../models/raw_material.dart';
import '../models/product_raw_material.dart';
import '../models/material_supply_order.dart';
import '../services/local_database_service.dart';
import '../services/history_service.dart';

class FactoryStore extends ChangeNotifier {
  final LocalDatabaseService _db = LocalDatabaseService.instance;

  String factoryName = 'النجمة بلاست';
  double plasticTonPrice = 27500.0; // سعر طن البلاستيك بالجنيه
  double capitalAmount = 0.0; // رأس المال الأساسي للمصنع
  int todayOrdersCount = 8;
  DateTime lastDatabaseSaveTime = DateTime.now();
  String databasePath = '';
  int databaseSizeBytes = 0;

  // القوائم الأساسية
  List<ProductItem> _products = [];
  List<ProductionBatch> _batches = [];
  List<WasteRecord> _wasteRecords = [];
  List<ExpenseItem> _expenses = [];
  List<Employee> _employees = [];
  List<EmployeeAdvance> _employeeAdvances = [];
  List<SalaryPayment> _salaryPayments = [];
  List<Supplier> _suppliers = [];
  List<Distributor> _distributors = [];
  List<SaleOrder> _saleOrders = [];
  List<StocktakeRecord> _stocktakeRecords = [];
  List<TreasuryTransaction> _treasuryTransactions = [];
  List<RawMaterial> _rawMaterials = [];
  List<ProductRawMaterial> _productRawMaterials = [];
  List<MaterialSupplyOrder> _materialSupplyOrders = [];

  FactoryStore() {
    _loadInitialDefaultData();
    _initStore();
  }

  Future<void> _initStore() async {
    await _db.initialize();
    databasePath = await _db.getDatabasePath();
    final data = await _db.loadData();

    if (data != null && data.isNotEmpty) {
      final productsList = data['products'] as List?;
      final isOldMockData = productsList != null && productsList.any((p) => p['id'] == 'prod-1');
      if (isOldMockData) {
        await clearAllData();
      } else {
        _loadFromJson(data);
      }
    } else {
      final size = await _db.getDatabaseSizeBytes();
      if (size == 0) {
        await _persist();
      }
    }
    databaseSizeBytes = await _db.getDatabaseSizeBytes();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // تهيئة القوائم فارغة لبدء العمل ببيانات المصنع الحقيقية
  // -------------------------------------------------------------
  void _loadInitialDefaultData() {
    _products = [];
    _rawMaterials = [];
    _batches = [];
    _wasteRecords = [];
    _expenses = [];
    _employees = [];
    _employeeAdvances = [];
    _salaryPayments = [];
    _suppliers = [];
    _distributors = [];
    _saleOrders = [];
    _stocktakeRecords = [];
    _treasuryTransactions = [];
    _productRawMaterials = [];
    factoryName = 'النجمة بلاست';
    plasticTonPrice = 0.0;
    capitalAmount = 0.0;
    todayOrdersCount = 0;
  }

  // -------------------------------------------------------------
  // الحفظ والاسترجاع من قاعدة البيانات المحلية
  // -------------------------------------------------------------
  Map<String, dynamic> _toJson() => {
    'factoryName': factoryName,
    'plasticTonPrice': plasticTonPrice,
    'capitalAmount': capitalAmount,
    'todayOrdersCount': todayOrdersCount,
    'products': _products.map((p) => p.toJson()).toList(),
    'rawMaterials': _rawMaterials.map((r) => r.toJson()).toList(),
    'productRawMaterials': _productRawMaterials.map((prm) => prm.toJson()).toList(),
    'batches': _batches.map((b) => {
      'id': b.id,
      'dateText': b.dateText,
      'timestamp': b.timestamp.toIso8601String(),
      'productId': b.productId,
      'productName': b.productName,
      'rawMaterialType': b.rawMaterialType,
      'quantityKg': b.quantityKg,
      'wasteKg': b.wasteKg,
      'cost': b.cost,
      'status': b.status,
      'machineId': b.machineId,
      'operatorName': b.operatorName,
    }).toList(),
    'wasteRecords': _wasteRecords.map((w) => {
      'id': w.id,
      'productId': w.productId,
      'productName': w.productName,
      'wasteKg': w.wasteKg,
      'wasteType': w.wasteType,
      'date': w.date.toIso8601String(),
      'isRecycled': w.isRecycled,
      'notes': w.notes,
    }).toList(),
    'expenses': _expenses.map((e) => {
      'id': e.id,
      'title': e.title,
      'category': e.category,
      'amount': e.amount,
      'date': e.date.toIso8601String(),
      'notes': e.notes,
      'relatedProductId': e.relatedProductId,
    }).toList(),
    'employees': _employees.map((e) => e.toJson()).toList(),
    'employeeAdvances': _employeeAdvances.map((a) => a.toJson()).toList(),
    'salaryPayments': _salaryPayments.map((s) => s.toJson()).toList(),
    'suppliers': _suppliers.map((s) => s.toJson()).toList(),
    'distributors': _distributors.map((d) => d.toJson()).toList(),
    'saleOrders': _saleOrders.map((o) => o.toJson()).toList(),
    'stocktakeRecords': _stocktakeRecords.map((st) => st.toJson()).toList(),
    'treasuryTransactions': _treasuryTransactions.map((t) => t.toJson()).toList(),
    'materialSupplyOrders': _materialSupplyOrders.map((o) => o.toJson()).toList(),
  };

  void _loadFromJson(Map<String, dynamic> json) {
    try {
      factoryName = json['factoryName'] as String? ?? 'النجمة بلاست';
      if (factoryName.isEmpty ||
          factoryName.contains('المستقبل') ||
          factoryName == 'مصنع البلاستيك' ||
          factoryName == 'مصنع البلاستيك المتكامل') {
        factoryName = 'النجمة بلاست';
      }
      plasticTonPrice = (json['plasticTonPrice'] as num?)?.toDouble() ?? plasticTonPrice;
      capitalAmount = (json['capitalAmount'] as num?)?.toDouble() ?? 0.0;
      todayOrdersCount = json['todayOrdersCount'] as int? ?? todayOrdersCount;

      if (json['products'] != null) {
        _products = (json['products'] as List).map((i) => ProductItem.fromJson(i as Map<String, dynamic>)).toList();
      }
      if (json['rawMaterials'] != null) {
        _rawMaterials = (json['rawMaterials'] as List).map((i) => RawMaterial.fromJson(i as Map<String, dynamic>)).toList();
      }
      if (json['productRawMaterials'] != null) {
        _productRawMaterials = (json['productRawMaterials'] as List).map((i) => ProductRawMaterial.fromJson(i as Map<String, dynamic>)).toList();
      }
      if (json['batches'] != null) {
        _batches = (json['batches'] as List).map((i) {
          final m = i as Map<String, dynamic>;
          return ProductionBatch(
            id: m['id'] as String,
            dateText: m['dateText'] as String,
            timestamp: DateTime.parse(m['timestamp'] as String),
            productId: m['productId'] as String,
            productName: m['productName'] as String,
            rawMaterialType: m['rawMaterialType'] as String,
            quantityKg: (m['quantityKg'] as num).toDouble(),
            wasteKg: (m['wasteKg'] as num).toDouble(),
            cost: (m['cost'] as num).toDouble(),
            status: m['status'] as String? ?? 'مكتمل',
            machineId: m['machineId'] as String?,
            operatorName: m['operatorName'] as String?,
          );
        }).toList();
      }
      if (json['wasteRecords'] != null) {
        _wasteRecords = (json['wasteRecords'] as List).map((i) {
          final m = i as Map<String, dynamic>;
          return WasteRecord(
            id: m['id'] as String,
            productId: m['productId'] as String,
            productName: m['productName'] as String,
            wasteKg: (m['wasteKg'] as num).toDouble(),
            wasteType: m['wasteType'] as String,
            date: DateTime.parse(m['date'] as String),
            isRecycled: m['isRecycled'] as bool? ?? true,
            notes: m['notes'] as String?,
          );
        }).toList();
      }
      if (json['expenses'] != null) {
        _expenses = (json['expenses'] as List).map((i) {
          final m = i as Map<String, dynamic>;
          return ExpenseItem(
            id: m['id'] as String,
            title: m['title'] as String,
            category: m['category'] as String,
            amount: (m['amount'] as num).toDouble(),
            date: DateTime.parse(m['date'] as String),
            notes: m['notes'] as String?,
            relatedProductId: m['relatedProductId'] as String?,
          );
        }).where((e) => !e.category.contains('سلف') && !e.title.contains('سلفة')).toList();
      }
      if (json['employees'] != null) {
        _employees = (json['employees'] as List).map((i) => Employee.fromJson(i as Map<String, dynamic>)).toList();
      }
      if (json['employeeAdvances'] != null) {
        _employeeAdvances = (json['employeeAdvances'] as List).map((i) => EmployeeAdvance.fromJson(i as Map<String, dynamic>)).toList();
      }
      if (json['salaryPayments'] != null) {
        _salaryPayments = (json['salaryPayments'] as List).map((i) => SalaryPayment.fromJson(i as Map<String, dynamic>)).toList();
      }
      if (json['suppliers'] != null) {
        _suppliers = (json['suppliers'] as List).map((i) => Supplier.fromJson(i as Map<String, dynamic>)).toList();
      }
      if (json['distributors'] != null) {
        _distributors = (json['distributors'] as List).map((i) => Distributor.fromJson(i as Map<String, dynamic>)).toList();
      }
      if (json['saleOrders'] != null) {
        _saleOrders = (json['saleOrders'] as List).map((i) => SaleOrder.fromJson(i as Map<String, dynamic>)).toList();
      }
      if (json['stocktakeRecords'] != null) {
        _stocktakeRecords = (json['stocktakeRecords'] as List).map((i) => StocktakeRecord.fromJson(i as Map<String, dynamic>)).toList();
      }
      if (json['treasuryTransactions'] != null) {
        _treasuryTransactions = (json['treasuryTransactions'] as List).map((i) => TreasuryTransaction.fromJson(i as Map<String, dynamic>)).toList();
      }
      if (json['materialSupplyOrders'] != null) {
        _materialSupplyOrders = (json['materialSupplyOrders'] as List).map((i) => MaterialSupplyOrder.fromJson(i as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error deserializing database: $e');
      _loadInitialDefaultData();
    }
  }

  Future<void> _persist() async {
    final success = await _db.saveData(_toJson());
    if (success) {
      lastDatabaseSaveTime = DateTime.now();
      databaseSizeBytes = await _db.getDatabaseSizeBytes();
    }
  }

  // -------------------------------------------------------------
  // Getters
  // -------------------------------------------------------------
  List<ProductItem> get products => List.unmodifiable(_products);
  List<ProductionBatch> get batches => List.unmodifiable(_batches);
  List<WasteRecord> get wasteRecords => List.unmodifiable(_wasteRecords);
  List<ExpenseItem> get expenses => List.unmodifiable(_expenses);
  List<Employee> get employees => List.unmodifiable(_employees);
  List<EmployeeAdvance> get employeeAdvances => List.unmodifiable(_employeeAdvances);
  List<SalaryPayment> get salaryPayments => List.unmodifiable(_salaryPayments);
  List<Supplier> get suppliers => List.unmodifiable(_suppliers);
  List<Distributor> get distributors => List.unmodifiable(_distributors);
  List<SaleOrder> get saleOrders => List.unmodifiable(_saleOrders);
  List<SaleOrder> get wholesaleOrders => _saleOrders.where((o) => o.saleType == 'جملة').toList();
  List<SaleOrder> get retailOrders => _saleOrders.where((o) => o.saleType == 'قطاعي').toList();
  List<SaleOrder> get creditOrders => _saleOrders.where((o) => o.isCredit).toList();
  double get totalCreditSalesVolume => creditOrders.fold(0.0, (s, o) => s + o.totalAmount);
  double get totalCreditCollected => creditOrders.fold(0.0, (s, o) => s + o.paidAmount);
  double get totalCreditOutstanding => creditOrders.fold(0.0, (s, o) => s + o.remainingAmount);
  double get totalCreditProfit => creditOrders.fold(0.0, (s, o) => s + o.totalProfit);
  List<StocktakeRecord> get stocktakeRecords => List.unmodifiable(_stocktakeRecords);
  List<TreasuryTransaction> get treasuryTransactions => List.unmodifiable(_treasuryTransactions);
  List<RawMaterial> get rawMaterials => List.unmodifiable(_rawMaterials);
  List<ProductRawMaterial> get productRawMaterials => List.unmodifiable(_productRawMaterials);
  List<MaterialSupplyOrder> get materialSupplyOrders => List.unmodifiable(_materialSupplyOrders);
  List<MaterialSupplyOrder> get creditSupplyOrders => _materialSupplyOrders
      .where((o) => o.remainingAmount > 0.01 || o.paymentMethod.contains('آجل') || o.paymentMethod.contains('جزئي'))
      .toList();
  double get totalSupplierDebtVolume => creditSupplyOrders.fold(0.0, (s, o) => s + o.totalAmount);
  double get totalSupplierDebtPaid => creditSupplyOrders.fold(0.0, (s, o) => s + o.paidAmount);
  double get totalSupplierDebtOutstanding => creditSupplyOrders.fold(0.0, (s, o) => s + o.remainingAmount);

  void updatePlasticTonPrice(double newPrice) {
    plasticTonPrice = newPrice;
    _persist();
    notifyListeners();
  }

  void updateCapitalAmount(double newCapital) {
    capitalAmount = newCapital;
    _persist();
    notifyListeners();
  }

  // Get raw materials for a specific product
  List<ProductRawMaterial> getRawMaterialsForProduct(String productId) {
    return _productRawMaterials.where((prm) => prm.productId == productId).toList();
  }

  // Get raw material details for a product with full info
  List<Map<String, dynamic>> getRawMaterialDetailsForProduct(String productId) {
    final prms = getRawMaterialsForProduct(productId);
    return prms.map((prm) {
      final rm = _rawMaterials.firstWhere(
        (r) => r.id == prm.rawMaterialId,
        orElse: () => RawMaterial(
          id: '',
          name: 'غير معروف',
          category: '',
          unit: '',
          currentStock: 0,
          unitCost: 0,
        ),
      );
      return {
        'rawMaterialId': prm.rawMaterialId,
        'name': rm.name,
        'category': rm.category,
        'unit': rm.unit,
        'quantity': prm.quantity,
        'unitCost': rm.unitCost,
        'totalCost': prm.quantity * rm.unitCost,
        'currentStock': rm.currentStock,
        'isLowStock': rm.isLowStock,
      };
    }).toList();
  }

  // Get products using a specific raw material
  List<String> getProductIdsUsingRawMaterial(String rawMaterialId) {
    return _productRawMaterials
        .where((prm) => prm.rawMaterialId == rawMaterialId)
        .map((prm) => prm.productId)
        .toSet()
        .toList();
  }

  // Calculate the raw material cost for a production batch of a given product
  double calculateProductionBatchCost(String productId, double batchKg) {
    final product = _products.firstWhere((p) => p.id == productId, orElse: () => _emptyProduct());
    if (product.id == '') return 0.0;

    final prms = _productRawMaterials.where((prm) => prm.productId == productId).toList();
    double totalCost = 0.0;
    for (final prm in prms) {
      final rm = _rawMaterials.firstWhere((r) => r.id == prm.rawMaterialId, orElse: () => RawMaterial(
        id: '',
        name: '',
        category: '',
        unit: '',
        currentStock: 0,
        unitCost: 0,
      ));
      if (rm.id.isNotEmpty) {
        totalCost += (prm.quantity * batchKg) * rm.unitCost;
      } else {
        totalCost += (prm.quantity * batchKg) * (product.totalExpenses / (product.totalProducedKg > 0 ? product.totalProducedKg : 1));
      }
    }
    return totalCost;
  }

  ProductItem _emptyProduct() {
    return ProductItem(
      id: '',
      name: '',
      category: '',
      materialType: '',
      totalProducedKg: 0,
      defaultBatchKg: 0,
      totalWasteKg: 0,
      totalExpenses: 0,
      wholesalePricePerKg: 0,
      retailPricePerKg: 0,
      stockKg: 0,
    );
  }

  int get employeesCount => _employees.length;

  double get totalProductionKg => _products.fold(0.0, (sum, p) => sum + p.totalProducedKg);
  double get totalWasteKg => _products.fold(0.0, (sum, p) => sum + p.totalWasteKg);
  double get totalSalesRevenue => _products.fold(0.0, (sum, p) => sum + p.totalRevenue);
  double get totalExpenses => _expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get totalRawMaterialExpenses => _expenses.where((e) => e.category.contains('خام')).fold(0.0, (s, e) => s + e.amount);
  double get totalAdminOperatingExpenses => _expenses.where((e) => !e.category.contains('خام')).fold(0.0, (s, e) => s + e.amount);
  double get netProfit => totalSalesRevenue - totalExpenses;
  double get totalStockKg => _products.fold(0.0, (sum, p) => sum + p.stockKg);
  double get totalRecycledKg => _wasteRecords.where((w) => w.isRecycled).fold(0.0, (s, w) => s + w.wasteKg);
  double get totalRawConsumedKg => _batches.fold(0.0, (s, b) => s + b.quantityKg + b.wasteKg);
  double get averageCostPerKg => totalProductionKg > 0 ? (totalExpenses / totalProductionKg) : 0.0;

  double get overallWastePercentage {
    final totalRaw = totalProductionKg + totalWasteKg;
    return totalRaw > 0 ? (totalWasteKg / totalRaw) * 100 : 0.0;
  }

  double get overallProfitMargin {
    return totalSalesRevenue > 0 ? (netProfit / totalSalesRevenue) * 100 : 0.0;
  }

  // إحصائيات الجملة والقطاعي
  double get totalWholesaleRevenue => wholesaleOrders.fold(0.0, (s, o) => s + o.totalAmount);
  double get totalRetailRevenue => retailOrders.fold(0.0, (s, o) => s + o.totalAmount);
  double get totalWholesaleProfit => wholesaleOrders.fold(0.0, (s, o) => s + o.totalProfit);
  double get totalRetailProfit => retailOrders.fold(0.0, (s, o) => s + o.totalProfit);
  double get totalWholesaleWeightKg => wholesaleOrders.fold(0.0, (s, o) => s + o.totalWeightKg);
  double get totalRetailWeightKg => retailOrders.fold(0.0, (s, o) => s + o.totalWeightKg);

  // تنبيهات المخزون الحية (الأصناف التي قاربت على النفاذ أو نفذت)
  List<ProductItem> get lowStockProducts => _products.where((p) => p.isLowStock).toList();
  List<ProductItem> get outOfStockProducts => _products.where((p) => p.isOutOfStock).toList();
  List<ProductItem> get stockAlertProducts => _products.where((p) => p.hasStockAlert).toList();
  int get stockAlertCount => stockAlertProducts.length;

  // -------------------------------------------------------------
  // -------------------------------------------------------------
  // Data clearing method
  // -------------------------------------------------------------
  /// Clears all persisted data by deleting the local JSON database
  /// and resetting all in‑memory collections to empty lists.
  Future<void> clearData() async {
    await _db.resetDatabase();
    // Empty all stored collections
    _products = [];
    _batches = [];
    _expenses = [];
    _employees = [];
    _employeeAdvances = [];
    _salaryPayments = [];
    _wasteRecords = [];
    _suppliers = [];
    _distributors = [];
    _saleOrders = [];
    _stocktakeRecords = [];
    _treasuryTransactions = [];
    _materialSupplyOrders = [];
    todayOrdersCount = 0;
    lastDatabaseSaveTime = DateTime.now();
    databasePath = '';
    databaseSizeBytes = 0;
    await _persist();
    notifyListeners();
  }

  /// Imports backup data from a JSON file, replacing current store state.
  /// The file should contain the same structure as the local database JSON.
  Future<void> importBackup(File backupFile) async {
    try {
      final content = await backupFile.readAsString();
      final Map<String, dynamic>? data = jsonDecode(content) as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Backup file is empty or invalid');
      }
      // Replace current state with imported data
      _loadFromJson(data);
      // Persist the imported data to the local database
      await _persist();
      // Refresh metadata
      databasePath = await _db.getDatabasePath();
      databaseSizeBytes = await _db.getDatabaseSizeBytes();
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing backup: $e');
      rethrow;
    }
  }
  // إحصائيات الخزنة والمكسب والخسارة (P&L & Treasury Metrics)
  // -------------------------------------------------------------
  // إجمالي المقبوضات النقدية الواردة للخزنة
  double get totalTreasuryIncome => _treasuryTransactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

  // إجمالي المدفوعات والمصروفات النقدية الخارجة من الخزنة
  double get totalTreasuryExpense => _treasuryTransactions.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

  // رصيد الخزنة الكاش الفعلي الحالي المتوفر
  double get currentVaultBalance => totalTreasuryIncome - totalTreasuryExpense;

  // قائمة الدخل (الأرباح والخسائر):
  // 1. إجمالي المبيعات والإيرادات التقديرية لكامل الإنتاج
  double get pnlTotalRevenue => totalSalesRevenue;

  // 2. تكلفة الخامات المباشرة المستهلكة للإنتاج (COGS)
  double get pnlCostOfGoodsSold => _expenses.where((e) => e.category.contains('خام')).fold(0.0, (s, e) => s + e.amount);

  // 3. إجمالي الربح التشغيلي للإنتاج (Gross Profit)
  double get pnlGrossProfit => pnlTotalRevenue - pnlCostOfGoodsSold;

  // 4. المصروفات التشغيلية والعمومية (OpEx: عمالة، كهرباء، صيانة، نثريات - مستبعداً منها السلف لأنها ذمم مدينة وليست مصروفاً)
  double get pnlOperatingExpenses => _expenses
      .where((e) => !e.category.contains('خام') && !e.category.contains('سلف') && !e.title.contains('سلفة'))
      .fold(0.0, (s, e) => s + e.amount);

  // 5. صافي المكسب أو الخسارة (Net Profit / Loss)
  double get pnlNetProfit => pnlGrossProfit - pnlOperatingExpenses;

  // 6. هامش صافي الربح
  double get pnlNetProfitMargin => pnlTotalRevenue > 0 ? (pnlNetProfit / pnlTotalRevenue) * 100 : 0.0;

  // -------------------------------------------------------------
  // مؤشرات المبيعات الفعلية المحققة من واقع الفواتير المسجلة
  // -------------------------------------------------------------
  double get actualSalesRevenue => _saleOrders.fold(0.0, (s, o) => s + o.totalAmount);
  double get actualSalesCost => _saleOrders.fold(0.0, (s, o) => s + o.totalCost);
  double get actualSalesGrossProfit => actualSalesRevenue - actualSalesCost;
  double get actualSalesNetProfit => actualSalesGrossProfit - pnlOperatingExpenses;
  double get actualSalesNetProfitMargin => actualSalesRevenue > 0 ? (actualSalesNetProfit / actualSalesRevenue) * 100 : 0.0;

  List<Map<String, dynamic>> get production7Days {
    final Map<String, double> dayTotals = {};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = '${d.day}/${d.month}';
      dayTotals[key] = 0.0;
    }
    for (var b in _batches) {
      final key = '${b.timestamp.day}/${b.timestamp.month}';
      if (dayTotals.containsKey(key)) {
        dayTotals[key] = (dayTotals[key] ?? 0.0) + b.quantityKg;
      }
    }
    return dayTotals.entries.map((e) => {'date': e.key, 'kg': e.value.round()}).toList();
  }

  List<Map<String, dynamic>> get costDistribution {
    final raw = _expenses.where((e) => e.category.contains('خام')).fold(0.0, (s, e) => s + e.amount);
    final labor = _expenses.where((e) => e.category == 'العمالة' || e.category.contains('رواتب') || e.category.contains('أجور') || e.category.contains('عمال')).fold(0.0, (s, e) => s + e.amount);
    final power = _expenses.where((e) => e.category.contains('كهرباء') || e.category.contains('طاقة') || e.category.contains('مرافق')).fold(0.0, (s, e) => s + e.amount);
    final maint = _expenses.where((e) => e.category.contains('صيان') || e.category.contains('إصلاح')).fold(0.0, (s, e) => s + e.amount);
    final other = _expenses.where((e) {
      final isRaw = e.category.contains('خام');
      final isLabor = e.category == 'العمالة' || e.category.contains('رواتب') || e.category.contains('أجور') || e.category.contains('عمال');
      final isPower = e.category.contains('كهرباء') || e.category.contains('طاقة') || e.category.contains('مرافق');
      final isMaint = e.category.contains('صيان') || e.category.contains('إصلاح');
      return !isRaw && !isLabor && !isPower && !isMaint;
    }).fold(0.0, (s, e) => s + e.amount);
    final total = raw + labor + power + maint + other;

    double p(double val) => total > 0 ? (val / total) * 100 : 0.0;

    return [
      {'name': 'المواد الخام', 'percent': p(raw), 'amount': raw, 'color': const Color(0xFF2563EB)},
      {'name': 'العمالة والرواتب', 'percent': p(labor), 'amount': labor, 'color': const Color(0xFF10B981)},
      {'name': 'الكهرباء والمرافق', 'percent': p(power), 'amount': power, 'color': const Color(0xFFF59E0B)},
      {'name': 'الصيانة وقطع الغيار', 'percent': p(maint), 'amount': maint, 'color': const Color(0xFF8B5CF6)},
      {'name': 'تكاليف ومصروفات أخرى', 'percent': p(other), 'amount': other, 'color': const Color(0xFF64748B)},
    ];
  }

  // -------------------------------------------------------------
  // عمليات التعديل والإضافة والحفظ الفوري
  // -------------------------------------------------------------
  void addProductionBatch({
    required String productId,
    required double netKg,
    required double wasteKg,
    required double cost,
    required String machine,
    required String operator,
    String? status,
  }) {
    final now = DateTime.now();
    final dateText = '${now.day} يوليو 2026 - ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final index = _products.indexWhere((p) => p.id == productId);
    String prodName = 'منتج بلاستيك';
    String rawMaterialType = '';
    if (index != -1) {
      final current = _products[index];
      prodName = current.name;
      rawMaterialType = current.materialType;

      final laborRate = current.laborCostPerKg > 0 ? current.laborCostPerKg : current.laborAndElectricityCostPerKg;
      final batchLabor = netKg * laborRate;
      final totalBatchCost = cost + batchLabor;

      _products[index] = current.copyWith(
        totalProducedKg: current.totalProducedKg + netKg,
        totalWasteKg: current.totalWasteKg + wasteKg,
        laborCostPerKg: laborRate,
        laborAndElectricityExpenses: current.laborAndElectricityExpenses + batchLabor,
        rawMaterialExpenses: current.rawMaterialExpenses + cost,
        totalExpenses: current.totalExpenses + totalBatchCost,
        stockKg: current.stockKg + netKg,
      );
    }

    final newBatch = ProductionBatch(
      id: 'batch-${DateTime.now().millisecondsSinceEpoch}',
      dateText: dateText,
      timestamp: now,
      productId: productId,
      productName: prodName,
      rawMaterialType: rawMaterialType,
      quantityKg: netKg,
      wasteKg: wasteKg,
      cost: cost,
      status: status ?? 'مكتمل',
      machineId: machine,
      operatorName: operator,
    );

    _batches.insert(0, newBatch);

    if (wasteKg > 0) {
      _wasteRecords.insert(
        0,
        WasteRecord(
          id: 'waste-${DateTime.now().millisecondsSinceEpoch}',
          productId: productId,
          productName: prodName,
          wasteKg: wasteKg,
          wasteType: 'هالك تشغيل جديد',
          date: now,
        ),
      );
    }

    _expenses.insert(
      0,
      ExpenseItem(
        id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
        title: 'تكلفة تشغيلة: $prodName',
        category: 'المواد الخام',
        amount: cost,
        date: now,
        relatedProductId: productId,
      ),
    );

    HistoryService.instance.logEvent(
      type: 'batch_add',
      title: 'إضافة دفعة إنتاج: $prodName',
      details: 'الكمية: ${netKg.toStringAsFixed(1)} كجم | الهالك: ${wasteKg.toStringAsFixed(1)} كجم | التكلفة: ${cost.toStringAsFixed(2)} ج.م | المشغل: $operator',
      entityId: newBatch.id,
    );

    _persist();
    notifyListeners();
  }

  void addProduct(ProductItem product) {
    _products.add(product);

    final now = DateTime.now();

    // تسجيل تكلفة ومصروفات الصنف في سجل المصروفات
    if (product.totalExpenses > 0) {
      _expenses.insert(
        0,
        ExpenseItem(
          id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
          title: 'تكلفة ومصروفات إنتاج: ${product.name}',
          category: 'المواد الخام',
          amount: product.totalExpenses,
          date: now,
          relatedProductId: product.id,
        ),
      );
    }

    HistoryService.instance.logEvent(
      type: 'product_add',
      title: 'إضافة صنف: ${product.name}',
      details: 'الفئة: ${product.category} | نوع الخامة: ${product.materialType}',
      entityId: product.id,
    );

    _persist();
    notifyListeners();
  }

  void updateProduct(ProductItem product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      HistoryService.instance.logEvent(
        type: 'product_edit',
        title: 'تعديل صنف: ${product.name}',
        details: 'الفئة: ${product.category}',
        entityId: product.id,
      );
      _persist();
      notifyListeners();
    }
  }

  /// إضافة مخزون جديد لصنف مع تسجيل تاريخ وكمية الإضافة
  void addProductStock({
    required String productId,
    required double additionalStockKg,
    required DateTime date,
    String? notes,
  }) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final current = _products[index];
      final prevStock = current.stockKg;
      final newStock = prevStock + additionalStockKg;
      final newAddition = StockAdditionRecord(
        id: 'sa-${DateTime.now().millisecondsSinceEpoch}',
        date: date,
        quantityKg: additionalStockKg,
        previousStockKg: prevStock,
        newStockKg: newStock,
        notes: notes,
      );
      final updatedAdditions = List<StockAdditionRecord>.from(current.stockAdditions)..add(newAddition);

      final laborRate = current.laborCostPerKg > 0 ? current.laborCostPerKg : current.laborAndElectricityCostPerKg;
      final rawRate = current.rawMaterialCostPerKg;
      final addedLabor = additionalStockKg * laborRate;
      final addedRaw = additionalStockKg * rawRate;

      _products[index] = current.copyWith(
        stockKg: newStock,
        totalProducedKg: current.totalProducedKg + additionalStockKg,
        laborCostPerKg: laborRate,
        laborAndElectricityExpenses: current.laborAndElectricityExpenses + addedLabor,
        rawMaterialExpenses: current.rawMaterialExpenses + addedRaw,
        totalExpenses: current.totalExpenses + addedLabor + addedRaw,
        stockAdditions: updatedAdditions,
      );
      HistoryService.instance.logEvent(
        type: 'stock_add',
        title: 'إضافة مخزون: ${current.name}',
        details: 'الكمية المضافة: ${additionalStockKg.toStringAsFixed(1)} كجم | الرصيد الجديد: ${newStock.toStringAsFixed(1)} كجم',
        entityId: productId,
      );
      _persist();
      notifyListeners();
    }
  }

  /// Deletes a product after confirming it is not used elsewhere.
  /// Returns `true` if the product was removed, `false` otherwise.
  bool deleteProduct(String id) {
    final usage = getProductUsageReasons(id);
    if (usage.isNotEmpty) {
      // Caller should handle the warning UI.
      return false;
    }
    _products.removeWhere((p) => p.id == id);
    HistoryService.instance.logEvent(
      type: 'product_delete',
      title: 'حذف صنف',
      details: 'رمز الصنف: $id',
      entityId: id,
    );
    _persist();
    notifyListeners();
    return true;
  }

  /// Returns a list of reasons why the product with [id] is used in other data.
  List<String> getProductUsageReasons(String id) {
    final List<String> reasons = [];
    // Check production batches
    if (_batches.any((b) => b.productId == id)) {
      reasons.add('موجود في دفعات الإنتاج');
    }
    // Check sale orders
    if (_saleOrders.any((o) => o.items.any((i) => i.productId == id))) {
      reasons.add('موجود في سجل المبيعات');
    }
    // Check stocktake records
    if (_stocktakeRecords.any((s) => s.entries.any((e) => e.productId == id))) {
      reasons.add('موجود في جرد المخزون');
    }
    return reasons;
  }

  void addExpense(ExpenseItem expense, {bool deductFromTreasury = false}) {
    _expenses.insert(0, expense);
    if (deductFromTreasury && expense.amount > 0) {
      addTreasuryTransaction(
        type: 'منصرف / سحب',
        title: expense.title,
        category: expense.category,
        amount: expense.amount,
        person: 'إدارة المصنع',
        paymentMethod: 'نقدي كاش',
        notes: expense.notes,
        recordInExpenses: false,
        notify: false,
      );
    }
    HistoryService.instance.logEvent(
      type: 'expense_add',
      title: 'إضافة مصروف: ${expense.title}',
      details: 'المبلغ: ${expense.amount.toStringAsFixed(2)} ج.م | الفئة: ${expense.category}',
      entityId: expense.id,
    );
    _persist();
    notifyListeners();
  }

  void addWasteRecord(WasteRecord record, {bool updateProduct = true}) {
    _wasteRecords.insert(0, record);
    if (updateProduct) {
      final index = _products.indexWhere((p) => p.id == record.productId);
      if (index != -1) {
        final current = _products[index];
        _products[index] = current.copyWith(
          totalWasteKg: current.totalWasteKg + record.wasteKg,
        );
      }
    }
    HistoryService.instance.logEvent(
      type: 'waste_add',
      title: 'إضافة سجل هالك: ${record.productName}',
      details: 'الكمية: ${record.wasteKg.toStringAsFixed(1)} كجم | النوع: ${record.wasteType}',
      entityId: record.id,
    );
    _persist();
    notifyListeners();
  }

  // إدارة الموظفين
  void addEmployee(Employee emp) {
    _employees.add(emp);
    HistoryService.instance.logEvent(
      type: 'employee_add',
      title: 'إضافة موظف: ${emp.name}',
      details: 'المسمى: ${emp.role} | الراتب: ${emp.monthlySalary.toStringAsFixed(2)} ج.م',
      entityId: emp.id,
    );
    _persist();
    notifyListeners();
  }

  void updateEmployee(Employee emp) {
    final index = _employees.indexWhere((e) => e.id == emp.id);
    if (index != -1) {
      _employees[index] = emp;
      HistoryService.instance.logEvent(
        type: 'employee_edit',
        title: 'تعديل موظف: ${emp.name}',
        details: 'المسمى: ${emp.role}',
        entityId: emp.id,
      );
      _persist();
      notifyListeners();
    }
  }

  void deleteEmployee(String id) {
    final emp = _employees.firstWhere(
      (e) => e.id == id,
      orElse: () => Employee(id: id, name: id, role: '', department: '', shift: '', monthlySalary: 0, hireDate: DateTime.now()),
    );
    _employees.removeWhere((e) => e.id == id);
    HistoryService.instance.logEvent(
      type: 'employee_delete',
      title: 'حذف موظف: ${emp.name}',
      entityId: id,
    );
    _persist();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // إدارة سلف الموظفين
  // -------------------------------------------------------------
  void addEmployeeAdvance(
    EmployeeAdvance advance, {
    bool deductFromTreasury = true,
    String person = 'أمين الخزنة',
  }) {
    _employeeAdvances.insert(0, advance);
    if (deductFromTreasury && advance.amount > 0) {
      addTreasuryTransaction(
        type: 'منصرف / سحب',
        title: 'صرف سلفة للموظف: ${advance.employeeName}',
        category: 'سلف موظفين',
        amount: advance.amount,
        person: person,
        notes: advance.notes ?? 'سلفة شخصية',
      );
    }
    _persist();
    notifyListeners();
  }

  void updateEmployeeAdvance(EmployeeAdvance advance) {
    final index = _employeeAdvances.indexWhere((a) => a.id == advance.id);
    if (index != -1) {
      _employeeAdvances[index] = advance;
      _persist();
      notifyListeners();
    }
  }

  void deleteEmployeeAdvance(String id) {
    _employeeAdvances.removeWhere((a) => a.id == id);
    _persist();
    notifyListeners();
  }

  void settleEmployeeAdvanceManually(String advanceId, double settleAmount) {
    final index = _employeeAdvances.indexWhere((a) => a.id == advanceId);
    if (index != -1) {
      final current = _employeeAdvances[index];
      final newSettled = (current.settledAmount + settleAmount).clamp(0.0, current.amount);
      _employeeAdvances[index] = current.copyWith(settledAmount: newSettled);
      _persist();
      notifyListeners();
    }
  }

  double getEmployeePendingAdvances(String employeeId) {
    return _employeeAdvances
        .where((a) => a.employeeId == employeeId && !a.isFullySettled)
        .fold(0.0, (sum, a) => sum + a.remainingAmount);
  }

  List<EmployeeAdvance> getEmployeeAdvancesList(String employeeId) {
    return _employeeAdvances.where((a) => a.employeeId == employeeId).toList();
  }

  List<EmployeeAdvance> getEmployeePendingAdvancesList(String employeeId) {
    return _employeeAdvances
        .where((a) => a.employeeId == employeeId && !a.isFullySettled)
        .toList();
  }

  double get totalAdvancesGiven => _employeeAdvances.fold(0.0, (s, a) => s + a.amount);
  double get totalAdvancesSettled => _employeeAdvances.fold(0.0, (s, a) => s + a.settledAmount);
  double get totalAdvancesOutstanding => _employeeAdvances.fold(0.0, (s, a) => s + a.remainingAmount);

  // -------------------------------------------------------------
  // إدارة قبض الموظفين وصرف الرواتب
  // -------------------------------------------------------------
  void addSalaryPayment(
    SalaryPayment payment, {
    bool payFromTreasury = true,
    String person = 'أمين الخزنة',
  }) {
    _salaryPayments.insert(0, payment);

    // 1. استقطاع السلف آلياً من السلف المعلقة للموظف
    if (payment.advancesDeducted > 0) {
      double remainingToDeduct = payment.advancesDeducted;
      for (int i = 0; i < _employeeAdvances.length && remainingToDeduct > 0.001; i++) {
        final adv = _employeeAdvances[i];
        if (adv.employeeId == payment.employeeId && !adv.isFullySettled) {
          final unSettled = adv.remainingAmount;
          final deductionForThis = remainingToDeduct >= unSettled ? unSettled : remainingToDeduct;
          _employeeAdvances[i] = adv.copyWith(
            settledAmount: adv.settledAmount + deductionForThis,
          );
          remainingToDeduct -= deductionForThis;
        }
      }
    }

    // 2. إثبات الصرف في الخزنة والمصروفات
    if (payFromTreasury && payment.netSalary > 0) {
      addTreasuryTransaction(
        type: 'منصرف / سحب',
        title: 'صرف راتب ${payment.monthYear}: ${payment.employeeName}',
        category: 'رواتب وأجور',
        amount: payment.netSalary,
        paymentMethod: payment.paymentMethod,
        person: person,
        notes: 'سند راتب رقم: ${payment.voucherNumber}${payment.notes != null ? ' - ${payment.notes}' : ''}',
      );
    } else if (!payFromTreasury && payment.netSalary > 0) {
      addExpense(ExpenseItem(
        id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
        title: 'صرف راتب ${payment.monthYear}: ${payment.employeeName}',
        category: 'رواتب وأجور',
        amount: payment.netSalary,
        date: payment.paymentDate,
        notes: payment.notes,
      ));
    }

    _persist();
    HistoryService.instance.logEvent(
      type: 'salary_pay',
      title: 'صرف راتب: ${payment.employeeName}',
      details: 'شهر: ${payment.monthYear} | الراتب الصافي: ${payment.netSalary.toStringAsFixed(2)} ج.م | طريقة الدفع: ${payment.paymentMethod}',
      entityId: payment.id,
    );
    notifyListeners();
  }

  void deleteSalaryPayment(String id) {
    final pIndex = _salaryPayments.indexWhere((p) => p.id == id);
    if (pIndex != -1) {
      final payment = _salaryPayments[pIndex];
      // إعادة مبالغ السلف المخصومة إن وجدت
      if (payment.advancesDeducted > 0) {
        double toRevert = payment.advancesDeducted;
        for (int i = _employeeAdvances.length - 1; i >= 0 && toRevert > 0.001; i--) {
          final adv = _employeeAdvances[i];
          if (adv.employeeId == payment.employeeId && adv.settledAmount > 0) {
            final canRevert = adv.settledAmount;
            final revertForThis = toRevert >= canRevert ? canRevert : toRevert;
            _employeeAdvances[i] = adv.copyWith(
              settledAmount: adv.settledAmount - revertForThis,
            );
            toRevert -= revertForThis;
          }
        }
      }
      _salaryPayments.removeAt(pIndex);
      _persist();
      notifyListeners();
    }
  }

  List<SalaryPayment> getEmployeeSalaryPayments(String employeeId) {
    return _salaryPayments.where((p) => p.employeeId == employeeId).toList();
  }

  bool isEmployeeSalaryPaidForMonth(String employeeId, String monthYear) {
    return _salaryPayments.any((p) => p.employeeId == employeeId && p.monthYear == monthYear);
  }

  double getTotalSalariesPaidForMonth(String monthYear) {
    return _salaryPayments.where((p) => p.monthYear == monthYear).fold(0.0, (s, p) => s + p.netSalary);
  }

  double get totalSalariesPaidAllTime {
    return _salaryPayments.fold(0.0, (s, p) => s + p.netSalary);
  }

  // إدارة المواد الخام
  void addRawMaterial(RawMaterial material) {
    _rawMaterials.add(material);
    _persist();
    notifyListeners();
  }

  void updateRawMaterial(RawMaterial material) {
    final index = _rawMaterials.indexWhere((r) => r.id == material.id);
    if (index != -1) {
      _rawMaterials[index] = material;
      _persist();
      notifyListeners();
    }
  }

  /// Deletes a raw material if it's not used by any product.
  /// Returns true if deleted, false if it's in use.
  bool deleteRawMaterial(String id) {
    final usage = getProductIdsUsingRawMaterial(id);
    if (usage.isNotEmpty) {
      return false;
    }
    _rawMaterials.removeWhere((r) => r.id == id);
    _persist();
    notifyListeners();
    return true;
  }

  // إدارة علاقة المنتجات بالمواد الخام
  void addProductRawMaterial(ProductRawMaterial prm) {
    // Check if already exists
    final existingIndex = _productRawMaterials.indexWhere(
      (p) => p.productId == prm.productId && p.rawMaterialId == prm.rawMaterialId,
    );
    if (existingIndex != -1) {
      _productRawMaterials[existingIndex] = prm;
    } else {
      _productRawMaterials.add(prm);
    }
    _persist();
    notifyListeners();
  }

  void updateProductRawMaterial(ProductRawMaterial prm) {
    final index = _productRawMaterials.indexWhere(
      (p) => p.productId == prm.productId && p.rawMaterialId == prm.rawMaterialId,
    );
    if (index != -1) {
      _productRawMaterials[index] = prm;
      _persist();
      notifyListeners();
    }
  }

  void removeProductRawMaterial(String productId, String rawMaterialId) {
    _productRawMaterials.removeWhere(
      (p) => p.productId == productId && p.rawMaterialId == rawMaterialId,
    );
    _persist();
    notifyListeners();
  }

  // تحديث علاقة منتج بمواد خام متعددة (يستخدم عند تعديل المنتج)
  void setProductRawMaterials(String productId, List<ProductRawMaterial> materials) {
    // Remove existing relationships for this product
    _productRawMaterials.removeWhere((p) => p.productId == productId);
    // Add new ones
    _productRawMaterials.addAll(materials);
    _persist();
    notifyListeners();
  }

  // إدارة الموردين
  void addSupplier(Supplier sup) {
    _suppliers.add(sup);
    _persist();
    notifyListeners();
  }

  void updateSupplier(Supplier sup) {
    final index = _suppliers.indexWhere((s) => s.id == sup.id);
    if (index != -1) {
      _suppliers[index] = sup;
      _persist();
      notifyListeners();
    }
  }

  void deleteSupplier(String id) {
    _suppliers.removeWhere((s) => s.id == id);
    _persist();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // إدارة توريدات المواد الخام
  // -------------------------------------------------------------
  void addMaterialSupplyOrder({
    required MaterialSupplyOrder order,
    bool updateBaseCost = true,
    String personInCharge = 'أمين المخزن',
    bool notify = true,
  }) {
    _materialSupplyOrders.insert(0, order);

    // 1. زيادة رصيد وسعر الخامة وتحديث المصروفات في قائمة الأصناف والمخزون (_products)
    final cleanOrderMat = order.rawMaterialName.trim().toLowerCase();
    bool foundInProducts = false;

    bool matchesProduct(ProductItem p) {
      if (p.id == order.rawMaterialId) return true;
      final cleanName = p.name.trim().toLowerCase();
      final cleanMatType = p.materialType.trim().toLowerCase();

      if (cleanName == cleanOrderMat || (cleanMatType.isNotEmpty && cleanMatType == cleanOrderMat)) {
        return true;
      }

      String norm(String s) => s
          .replaceAll('خام', '')
          .replaceAll('مادة', '')
          .replaceAll('بوليمر', '')
          .replaceAll('أكياس', '')
          .replaceAll('شنط', '')
          .replaceAll(' ', '')
          .replaceAll('×', '*')
          .replaceAll('-', '')
          .replaceAll('_', '')
          .trim();

      final nMat = norm(cleanOrderMat);
      final nPName = norm(cleanName);
      final nMatType = norm(cleanMatType);

      if (nMat.isNotEmpty) {
        if (nPName == nMat || nMatType == nMat) return true;
        if (nPName.contains(nMat) || nMat.contains(nPName)) return true;
        if (nMatType.isNotEmpty && (nMatType.contains(nMat) || nMat.contains(nMatType))) return true;
      }
      return false;
    }

    for (int i = 0; i < _products.length; i++) {
      final p = _products[i];

      if (matchesProduct(p)) {
        foundInProducts = true;
        final prevStock = p.stockKg;
        final newStock = prevStock + order.quantityKg;
        final newTotalProduced = p.totalProducedKg + order.quantityKg;

        // تحديث مصروفات المواد الخام وتكلفة الكيلو
        double newRawExpenses;
        if (updateBaseCost) {
          // تحديث سعر الكيلو الأساسي للخامة إلى سعر التوريد الجديد
          newRawExpenses = newTotalProduced * order.unitPrice;
        } else {
          // إضافة قيمة التوريد إلى إجمالي المصروفات الحالية
          newRawExpenses = p.rawMaterialExpenses + (order.quantityKg * order.unitPrice);
        }

        final laborRate = p.laborCostPerKg > 0 ? p.laborCostPerKg : p.laborAndElectricityCostPerKg;
        final addedLabor = order.quantityKg * laborRate;
        final newLaborExpenses = p.laborAndElectricityExpenses + addedLabor;
        final newTotalExpenses = newRawExpenses + newLaborExpenses;

        final newAddition = StockAdditionRecord(
          id: 'sa-${DateTime.now().millisecondsSinceEpoch}-$i',
          date: order.date,
          quantityKg: order.quantityKg,
          previousStockKg: prevStock,
          newStockKg: newStock,
          notes: 'إذن توريد رقم: ${order.invoiceNumber} من مورد: ${order.supplierName} (${order.supplierFactory}) بسعر ${order.unitPrice.toStringAsFixed(2)} ج/كجم',
        );

        final updatedAdditions = List<StockAdditionRecord>.from(p.stockAdditions)..add(newAddition);

        _products[i] = p.copyWith(
          stockKg: newStock,
          totalProducedKg: newTotalProduced,
          rawMaterialExpenses: newRawExpenses,
          laborCostPerKg: laborRate,
          laborAndElectricityExpenses: newLaborExpenses,
          totalExpenses: newTotalExpenses,
          stockAdditions: updatedAdditions,
        );
      }
    }

    // إذا لم يتطابق مع أي صنف حالي في المخزون، يُضاف تلقائياً كصنف جديد في قائمة الأصناف والمخزون
    if (!foundInProducts) {
      final newProdId = order.rawMaterialId.isNotEmpty && !order.rawMaterialId.startsWith('rm-')
          ? order.rawMaterialId
          : 'prod-${DateTime.now().millisecondsSinceEpoch}';

      final initialAddition = StockAdditionRecord(
        id: 'sa-${DateTime.now().millisecondsSinceEpoch}',
        date: order.date,
        quantityKg: order.quantityKg,
        previousStockKg: 0.0,
        newStockKg: order.quantityKg,
        notes: 'توريد خامة من مورد: ${order.supplierName} (${order.supplierFactory}) بسعر ${order.unitPrice.toStringAsFixed(2)} ج/كجم',
      );

      _products.add(
        ProductItem(
          id: newProdId,
          name: order.rawMaterialName,
          category: 'خامات وبوليمر',
          materialType: order.rawMaterialName,
          totalProducedKg: order.quantityKg,
          defaultBatchKg: 1000.0,
          totalWasteKg: 0.0,
          rawMaterialExpenses: order.totalAmount,
          laborAndElectricityExpenses: order.quantityKg * 2.0,
          laborCostPerKg: 2.0,
          totalExpenses: order.totalAmount + (order.quantityKg * 2.0),
          wholesalePricePerKg: order.unitPrice > 0 ? order.unitPrice : 50.0,
          retailPricePerKg: (order.unitPrice > 0 ? order.unitPrice : 50.0) * 1.15,
          stockKg: order.quantityKg,
          notes: 'صنف مورد من: ${order.supplierName} - مصنع: ${order.supplierFactory}',
          stockAdditions: [initialAddition],
        ),
      );
    }

    // 2. تحديث رصيد وسعر الخامة في سجل الخامات (_rawMaterials)
    final rmIndex = _rawMaterials.indexWhere((r) =>
        r.id == order.rawMaterialId ||
        r.name.trim().toLowerCase() == cleanOrderMat ||
        cleanOrderMat.contains(r.name.trim().toLowerCase()));

    if (rmIndex != -1) {
      final currentRm = _rawMaterials[rmIndex];
      final newStock = currentRm.currentStock + order.quantityKg;
      final bool shouldUpdateCost = updateBaseCost || (order.unitPrice != currentRm.unitCost);
      final newCost = shouldUpdateCost ? order.unitPrice : currentRm.unitCost;

      _rawMaterials[rmIndex] = currentRm.copyWith(
        currentStock: newStock,
        unitCost: newCost,
      );
    } else if (!foundInProducts) {
      // إذا لم يكن الصنف مسجلاً كمنتج ولا كخامة، يُضاف لسجل الخامات
      _rawMaterials.add(
        RawMaterial(
          id: order.rawMaterialId,
          name: order.rawMaterialName,
          category: 'خامات أولية',
          unit: 'كجم',
          currentStock: order.quantityKg,
          unitCost: order.unitPrice,
          minStockAlert: 100,
        ),
      );
    }

    // 3. تحديث حساب المورد (الأوزان المشتراة ورصيد المورد)
    final supIndex = _suppliers.indexWhere((s) => s.id == order.supplierId);
    if (supIndex != -1) {
      final curSup = _suppliers[supIndex];
      final newTotalPurchases = curSup.totalPurchasesKg + order.quantityKg;
      // المتبقي غير المسدد يضاف لمديونية المصنع للمورد (دائن "له" بالسالب)
      final newBalance = curSup.currentBalance - order.remainingAmount;

      _suppliers[supIndex] = curSup.copyWith(
        totalPurchasesKg: newTotalPurchases,
        currentBalance: newBalance,
      );
    }

    // 4. خصم المبلغ المدفوع نقداً من خزينة المصنع إن وجد
    if (order.paidAmount > 0) {
      addTreasuryTransaction(
        type: 'منصرف / سحب',
        title: 'سداد توريد خامة (${order.rawMaterialName}) - مورد: ${order.supplierName}',
        category: 'مشتريات خامات',
        amount: order.paidAmount,
        person: personInCharge,
        paymentMethod: order.paymentMethod.contains('بنكي') ? 'تحويل بنكي' : 'نقدي كاش',
        notes: 'إذن توريد رقم: ${order.invoiceNumber} - كمية: ${order.quantityKg} كجم بسعر ${order.unitPrice} ج.م',
        notify: notify,
      );
    }

    if (notify) {
      _persist();
      notifyListeners();
    }
  }

  void deleteMaterialSupplyOrder(String id, {String actionTitle = 'استرجاع إلغاء إذن توريد', bool notify = true}) {
    final index = _materialSupplyOrders.indexWhere((o) => o.id == id);
    if (index != -1) {
      final order = _materialSupplyOrders[index];
      final cleanOrderMat = order.rawMaterialName.trim().toLowerCase();

      // استرجاع رصيد وتكاليف الأصناف في قائمة المنتجات
      for (int i = 0; i < _products.length; i++) {
        final p = _products[i];
        final cleanName = p.name.trim().toLowerCase();
        final cleanMatType = p.materialType.trim().toLowerCase();

        final bool isMatch = p.id == order.rawMaterialId ||
            cleanName == cleanOrderMat ||
            (cleanMatType.isNotEmpty && cleanMatType == cleanOrderMat) ||
            cleanName.contains(cleanOrderMat) ||
            cleanOrderMat.contains(cleanName);

        if (isMatch) {
          final revertedStock = (p.stockKg - order.quantityKg).clamp(0.0, double.infinity);
          final revertedProduced = (p.totalProducedKg - order.quantityKg).clamp(0.0, double.infinity);
          final basePrice = order.updatedBasePrice ? order.previousBasePrice : p.rawMaterialCostPerKg;
          final revertedRawExp = (revertedProduced * basePrice).clamp(0.0, double.infinity);
          final laborRate = p.laborCostPerKg > 0 ? p.laborCostPerKg : p.laborAndElectricityCostPerKg;
          final revertedLaborExp = (revertedProduced * laborRate).clamp(0.0, double.infinity);
          final revertedTotalExp = revertedRawExp + revertedLaborExp;

          _products[i] = p.copyWith(
            stockKg: revertedStock,
            totalProducedKg: revertedProduced,
            rawMaterialExpenses: revertedRawExp,
            laborAndElectricityExpenses: revertedLaborExp,
            totalExpenses: revertedTotalExp,
          );
        }
      }

      // استرجاع رصيد وسعر الخامة بالمخزن
      final rmIndex = _rawMaterials.indexWhere((r) =>
          r.id == order.rawMaterialId ||
          r.name.trim().toLowerCase() == cleanOrderMat ||
          cleanOrderMat.contains(r.name.trim().toLowerCase()));

      if (rmIndex != -1) {
        final currentRm = _rawMaterials[rmIndex];
        final revertedStock = (currentRm.currentStock - order.quantityKg).clamp(0.0, double.infinity);
        _rawMaterials[rmIndex] = currentRm.copyWith(
          currentStock: revertedStock,
          unitCost: order.updatedBasePrice ? order.previousBasePrice : currentRm.unitCost,
        );
      }

      // استرجاع رصيد المورد
      final supIndex = _suppliers.indexWhere((s) => s.id == order.supplierId);
      if (supIndex != -1) {
        final curSup = _suppliers[supIndex];
        final revertedPurchases = (curSup.totalPurchasesKg - order.quantityKg).clamp(0.0, double.infinity);
        final revertedBalance = curSup.currentBalance + order.remainingAmount;
        _suppliers[supIndex] = curSup.copyWith(
          totalPurchasesKg: revertedPurchases,
          currentBalance: revertedBalance,
        );
      }

      // إشعار أو استرجاع الخزنة
      if (order.paidAmount > 0) {
        addTreasuryTransaction(
          type: 'وارد / إيداع',
          title: '$actionTitle: ${order.invoiceNumber} (${order.rawMaterialName})',
          category: 'مشتريات خامات',
          amount: order.paidAmount,
          person: 'مدير النظام',
          notes: '$actionTitle مسجل مسبقاً',
          notify: notify,
        );
      }

      _materialSupplyOrders.removeAt(index);
      if (notify) {
        _persist();
        notifyListeners();
      }
    }
  }

  void updateMaterialSupplyOrder({
    required MaterialSupplyOrder oldOrder,
    required MaterialSupplyOrder newOrder,
    bool updateBaseCost = true,
    String personInCharge = 'أمين المخزن',
  }) {
    final index = _materialSupplyOrders.indexWhere((o) => o.id == oldOrder.id);
    deleteMaterialSupplyOrder(oldOrder.id, actionTitle: 'تسوية تعديل إذن توريد', notify: false);
    addMaterialSupplyOrder(
      order: newOrder,
      updateBaseCost: updateBaseCost,
      personInCharge: personInCharge,
      notify: false,
    );
    if (index != -1 && _materialSupplyOrders.isNotEmpty && index < _materialSupplyOrders.length) {
      final item = _materialSupplyOrders.removeAt(0);
      _materialSupplyOrders.insert(index, item);
    }
    _persist();
    notifyListeners();
  }

  // إدارة الموزعين
  void addDistributor(Distributor dist) {
    _distributors.add(dist);
    _persist();
    notifyListeners();
  }

  void updateDistributor(Distributor dist) {
    final index = _distributors.indexWhere((d) => d.id == dist.id);
    if (index != -1) {
      _distributors[index] = dist;
      _persist();
      notifyListeners();
    }
  }

  // إضافة فاتورة بيع (جملة أو قطاعي)
  void addSaleOrder(SaleOrder order) {
    _saleOrders.insert(0, order);
    todayOrdersCount++;

    // خصم الكميات المباعة من رصيد المخزون الفعلي بالمستودع
    for (var item in order.items) {
      final pIndex = _products.indexWhere((p) => p.id == item.productId);
      if (pIndex != -1) {
        final current = _products[pIndex];
        final newStock = (current.stockKg - item.quantityKg).clamp(0.0, double.infinity);
        _products[pIndex] = current.copyWith(
          stockKg: newStock,
        );
      }
    }

    // تحديث مديونية الموزع إذا كان بيع جملة آجل
    if (order.saleType == 'جملة' && order.customerId != null) {
      final dIndex = _distributors.indexWhere((d) => d.id == order.customerId);
      if (dIndex != -1) {
        final currentD = _distributors[dIndex];
        final double debtIncrease = order.remainingAmount;
        _distributors[dIndex] = Distributor(
          id: currentD.id,
          name: currentD.name,
          tradeName: currentD.tradeName,
          type: currentD.type,
          region: currentD.region,
          phone: currentD.phone,
          currentDebt: currentD.currentDebt + debtIncrease,
          creditLimit: currentD.creditLimit,
          totalSalesVolumeKg: currentD.totalSalesVolumeKg + order.totalWeightKg,
          notes: currentD.notes,
        );
      }
    }

    // إيداع نقدي تلقائي في الخزنة إذا تم سداد مبلغ نقدي في الفاتورة (كامل أو دفعة)
    if (order.paidAmount > 0) {
      _treasuryTransactions.insert(
        0,
        TreasuryTransaction(
          id: 'tt-${DateTime.now().millisecondsSinceEpoch}',
          voucherNumber: 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          type: 'وارد / إيداع',
          title: 'تحصيل ${order.isFullyPaid ? "كامل" : "دفعة من"} فاتورة بيع ${order.saleType}: ${order.customerName.isNotEmpty ? order.customerName : 'عميل'}',
          category: 'مبيعات ${order.saleType}',
          amount: order.paidAmount,
          balanceAfter: currentVaultBalance + order.paidAmount,
          date: DateTime.now(),
          paymentMethod: order.paymentMethod,
          personInCharge: 'مسؤول المبيعات',
          notes: 'فاتورة رقم: ${order.invoiceNumber}',
        ),
      );
    }

    _persist();
    HistoryService.instance.logEvent(
      type: 'sale_add',
      title: 'إضافة فاتورة بيع ${order.saleType}: ${order.customerName.isNotEmpty ? order.customerName : "عميل"}',
      details: 'رقم الفاتورة: ${order.invoiceNumber} | الإجمالي: ${order.totalAmount.toStringAsFixed(2)} ج.م | الوزن: ${order.totalWeightKg.toStringAsFixed(1)} كجم',
      entityId: order.id,
    );
    notifyListeners();
  }

  /// تسجيل تحصيل دفعة من فاتورة بيع آجلة
  void recordOrderPayment(
    String orderId,
    double paymentAmount, {
    String paymentMethod = 'نقدي كاش',
    String? notes,
    String person = 'مسؤول المبيعات',
  }) {
    if (paymentAmount <= 0) return;

    final oIndex = _saleOrders.indexWhere((o) => o.id == orderId);
    if (oIndex == -1) return;

    final order = _saleOrders[oIndex];
    final double actualPayment = paymentAmount > order.remainingAmount ? order.remainingAmount : paymentAmount;
    final double newPaid = (order.paidAmount + actualPayment).clamp(0.0, order.totalAmount);
    final double newRemaining = (order.totalAmount - newPaid).clamp(0.0, double.infinity);
    final String newStatus = newRemaining <= 0.01 ? 'مدفوع بالكامل' : 'دفع جزئي';

    _saleOrders[oIndex] = order.copyWith(
      paidAmount: newPaid,
      paymentStatus: newStatus,
    );

    // تخفيض مديونية الموزع المرتبط إذا كان البيع جملة
    if (order.customerId != null) {
      final dIndex = _distributors.indexWhere((d) => d.id == order.customerId);
      if (dIndex != -1) {
        final currentD = _distributors[dIndex];
        _distributors[dIndex] = Distributor(
          id: currentD.id,
          name: currentD.name,
          tradeName: currentD.tradeName,
          type: currentD.type,
          region: currentD.region,
          phone: currentD.phone,
          currentDebt: (currentD.currentDebt - actualPayment).clamp(0.0, double.infinity),
          creditLimit: currentD.creditLimit,
          totalSalesVolumeKg: currentD.totalSalesVolumeKg,
          notes: currentD.notes,
        );
      }
    }

    // إيداع نقدي في الخزنة بمبلغ الدفعة المحصلة
    addTreasuryTransaction(
      type: 'وارد / إيداع',
      title: 'تحصيل دفعة آجل: ${order.customerName}',
      category: 'تحصيل آجل / مديونيات',
      amount: actualPayment,
      paymentMethod: paymentMethod,
      person: person,
      notes: 'سداد دفعة من فاتورة: ${order.invoiceNumber}${notes != null && notes.isNotEmpty ? ' - $notes' : ''}',
    );

    _persist();
    notifyListeners();
  }

  /// تسجيل سداد دفعة نقدية (كاملة أو مجزأة) لمورد عن إذن توريد مواد خام آجل
  void recordMaterialSupplyPayment(
    String orderId,
    double paymentAmount, {
    String paymentMethod = 'نقدي كاش',
    String? notes,
    String person = 'أمين المخزن',
  }) {
    if (paymentAmount <= 0) return;

    final oIndex = _materialSupplyOrders.indexWhere((o) => o.id == orderId);
    if (oIndex == -1) return;

    final order = _materialSupplyOrders[oIndex];
    final double actualPayment = paymentAmount > order.remainingAmount ? order.remainingAmount : paymentAmount;
    final double newPaid = (order.paidAmount + actualPayment).clamp(0.0, order.totalAmount);
    final double newRemaining = (order.totalAmount - newPaid).clamp(0.0, double.infinity);
    final String newMethod = newRemaining <= 0.01
        ? 'تم السداد بالكامل (${newPaid.toStringAsFixed(2)} ج.م)'
        : 'مسدد جزئياً ($newPaid ج.م كاش - متبقي $newRemaining ج.م آجل)';

    _materialSupplyOrders[oIndex] = order.copyWith(
      paidAmount: newPaid,
      remainingAmount: newRemaining,
      paymentMethod: newMethod,
    );

    // تحديث رصيد المورد: تخفيض المديونية المستحقة له
    final supIndex = _suppliers.indexWhere((s) => s.id == order.supplierId || s.name.trim() == order.supplierName.trim());
    if (supIndex != -1) {
      final curSup = _suppliers[supIndex];
      _suppliers[supIndex] = curSup.copyWith(
        currentBalance: curSup.currentBalance + actualPayment,
      );
    }

    // إثبات حركة خروج نقدية من الخزينة تلقائياً
    addTreasuryTransaction(
      type: 'منصرف / سحب',
      title: 'سداد دفعة للمورد: ${order.supplierName} (${order.rawMaterialName})',
      category: 'مشتريات خامات',
      amount: actualPayment,
      paymentMethod: paymentMethod,
      person: person,
      notes: 'سداد دفعة من إذن توريد خامة: ${order.invoiceNumber}${notes != null && notes.isNotEmpty ? ' - $notes' : ''}',
    );

    _persist();
    notifyListeners();
  }

  /// حساب إجمالي الكيلوات المباعة لصنف معين من واقع الفواتير
  double getSoldKgForProduct(String productId) {
    double total = 0.0;
    for (final order in _saleOrders) {
      for (final item in order.items) {
        if (item.productId == productId) {
          total += item.quantityKg;
        }
      }
    }
    return total;
  }

  /// حساب الكيلوات المباعة جملة لصنف معين
  double getWholesaleSoldKgForProduct(String productId) {
    double total = 0.0;
    for (final order in _saleOrders.where((o) => o.saleType == 'جملة')) {
      for (final item in order.items) {
        if (item.productId == productId) {
          total += item.quantityKg;
        }
      }
    }
    return total;
  }

  /// حساب الكيلوات المباعة قطاعي لصنف معين
  double getRetailSoldKgForProduct(String productId) {
    double total = 0.0;
    for (final order in _saleOrders.where((o) => o.saleType == 'قطاعي')) {
      for (final item in order.items) {
        if (item.productId == productId) {
          total += item.quantityKg;
        }
      }
    }
    return total;
  }

  /// حساب صافي ربح المبيعات الفعلية لصنف معين (جملة + قطاعي)
  double getRealizedProfitForProduct(String productId) {
    double profit = 0.0;
    for (final order in _saleOrders) {
      for (final item in order.items) {
        if (item.productId == productId) {
          profit += item.profit;
        }
      }
    }
    return profit;
  }

  /// حساب صافي ربح مبيعات الجملة الفعلية لصنف معين
  double getRealizedWholesaleProfitForProduct(String productId) {
    double profit = 0.0;
    for (final order in _saleOrders.where((o) => o.saleType == 'جملة')) {
      for (final item in order.items) {
        if (item.productId == productId) {
          profit += item.profit;
        }
      }
    }
    return profit;
  }

  /// حساب صافي ربح مبيعات القطاعي الفعلية لصنف معين
  double getRealizedRetailProfitForProduct(String productId) {
    double profit = 0.0;
    for (final order in _saleOrders.where((o) => o.saleType == 'قطاعي')) {
      for (final item in order.items) {
        if (item.productId == productId) {
          profit += item.profit;
        }
      }
    }
    return profit;
  }

  /// حذف فاتورة بيع مع إرجاع الكميات المباعة للمخزون تلقائياً
  void deleteSaleOrder(String orderId) {
    final oIndex = _saleOrders.indexWhere((o) => o.id == orderId);
    if (oIndex == -1) return;

    final order = _saleOrders[oIndex];

    // إرجاع الكميات المباعة إلى رصيد المخزن للصنف
    for (var item in order.items) {
      final pIndex = _products.indexWhere((p) => p.id == item.productId);
      if (pIndex != -1) {
        final current = _products[pIndex];
        _products[pIndex] = current.copyWith(
          stockKg: current.stockKg + item.quantityKg,
        );
      }
    }

    // تعديل مديونية الموزع إذا كان البيع آجل
    if (order.saleType == 'جملة' && order.customerId != null) {
      final dIndex = _distributors.indexWhere((d) => d.id == order.customerId);
      if (dIndex != -1) {
        final currentD = _distributors[dIndex];
        _distributors[dIndex] = Distributor(
          id: currentD.id,
          name: currentD.name,
          tradeName: currentD.tradeName,
          type: currentD.type,
          region: currentD.region,
          phone: currentD.phone,
          currentDebt: (currentD.currentDebt - order.remainingAmount).clamp(0.0, double.infinity),
          creditLimit: currentD.creditLimit,
          totalSalesVolumeKg: (currentD.totalSalesVolumeKg - order.totalWeightKg).clamp(0.0, double.infinity),
          notes: currentD.notes,
        );
      }
    }

    // حذف حركة الخزينة المرتبطة إذا كانت مدفوعة نقداً
    _treasuryTransactions.removeWhere((t) => t.notes?.contains(order.invoiceNumber) ?? false);

    _saleOrders.removeAt(oIndex);
    _persist();
    notifyListeners();
  }

  /// حذف مصروف من السجل وتحديث الحفظ
  void deleteExpense(String expenseId) {
    _expenses.removeWhere((e) => e.id == expenseId);
    _persist();
    notifyListeners();
  }

  /// حذف تشغيلة إنتاج مع خصم كميتها من رصيد الصنف وتحديث الحفظ
  void deleteProductionBatch(String batchId) {
    final bIndex = _batches.indexWhere((b) => b.id == batchId);
    if (bIndex == -1) return;
    final batch = _batches[bIndex];

    final pIndex = _products.indexWhere((p) => p.id == batch.productId);
    if (pIndex != -1) {
      final current = _products[pIndex];
      _products[pIndex] = current.copyWith(
        totalProducedKg: (current.totalProducedKg - batch.quantityKg).clamp(0.0, double.infinity),
        totalWasteKg: (current.totalWasteKg - batch.wasteKg).clamp(0.0, double.infinity),
        stockKg: (current.stockKg - batch.quantityKg).clamp(0.0, double.infinity),
      );
    }

    _batches.removeAt(bIndex);
    _expenses.removeWhere((e) => e.relatedProductId == batch.productId && e.title.contains(batch.productName));
    _persist();
    notifyListeners();
  }

  /// حذف سجل هالك وتعديل إجمالي هالك الصنف
  void deleteWasteRecord(String wasteId) {
    final wIndex = _wasteRecords.indexWhere((w) => w.id == wasteId);
    if (wIndex == -1) return;
    final waste = _wasteRecords[wIndex];

    final pIndex = _products.indexWhere((p) => p.id == waste.productId);
    if (pIndex != -1) {
      final current = _products[pIndex];
      _products[pIndex] = current.copyWith(
        totalWasteKg: (current.totalWasteKg - waste.wasteKg).clamp(0.0, double.infinity),
      );
    }

    _wasteRecords.removeAt(wIndex);
    _persist();
    notifyListeners();
  }

  /// حذف موزع من القائمة
  void deleteDistributor(String id) {
    _distributors.removeWhere((d) => d.id == id);
    _persist();
    notifyListeners();
  }

  // إضافة سجل جرد دوري (يومي / أسبوعي / شهري)
  void addStocktakeRecord(StocktakeRecord record, {bool updateStock = true}) {
    _stocktakeRecords.insert(0, record);

    if (updateStock) {
      // تسوية رصيد المخزن الفعلي بناءً على محضر الجرد المعتمد
      for (var entry in record.entries) {
        final pIndex = _products.indexWhere((p) => p.id == entry.productId);
        if (pIndex != -1) {
          final current = _products[pIndex];
          _products[pIndex] = current.copyWith(stockKg: entry.actualQtyKg);
        }
      }
    }

    _persist();
    notifyListeners();
  }

  // إضافة حركة وارد أو منصرف في الخزنة
  void addTreasuryTransaction({
    required String type,
    required String title,
    required String category,
    required double amount,
    required String person,
    String paymentMethod = 'نقدي كاش',
    String? notes,
    bool notify = true,
    bool recordInExpenses = true,
    bool logHistory = false,
  }) {
    final isIncome = type.contains('وارد') || type.contains('إيداع');
    final newBalance = isIncome ? (currentVaultBalance + amount) : (currentVaultBalance - amount);
    final prefix = isIncome ? 'REC' : 'PAY';
    final voucherNumber = '$prefix-2026-${(_treasuryTransactions.length + 1).toString().padLeft(3, '0')}';

    final transaction = TreasuryTransaction(
      id: 'tt-${DateTime.now().millisecondsSinceEpoch}',
      voucherNumber: voucherNumber,
      type: type,
      title: title,
      category: category,
      amount: amount,
      balanceAfter: newBalance,
      date: DateTime.now(),
      paymentMethod: paymentMethod,
      personInCharge: person,
      notes: notes,
    );

    _treasuryTransactions.insert(0, transaction);

    // إذا كانت الحركة مصروفاً نقدياً، نسجلها أيضاً في قائمة المصروفات العامة للمصنع
    // تنبيه: السلف ليست مصروفاً تشغيلياً لأنها ذمم مدينة على الموظف تسوى عند صرف الراتب
    if (recordInExpenses && !isIncome && !category.contains('سلف') && !title.contains('سلفة')) {
      _expenses.insert(
        0,
        ExpenseItem(
          id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
          title: 'صرف نقدي من الخزنة: $title',
          category: category,
          amount: amount,
          date: DateTime.now(),
          notes: notes,
        ),
      );
    }

    if (logHistory) {
      HistoryService.instance.logEvent(
        type: 'treasury_${isIncome ? "income" : "expense"}',
        title: title,
        details: 'النوع: $type | المبلغ: ${amount.toStringAsFixed(2)} ج.م | الفئة: $category | المسؤول: $person',
        entityId: transaction.id,
      );
    }

    if (notify) {
      _persist();
      notifyListeners();
    }
  }

  Future<void> resetAllToDefaults() async {
    await _db.resetDatabase();
    _loadInitialDefaultData();
    await _persist();
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _db.resetDatabase();
    _products.clear();
    _batches.clear();
    _wasteRecords.clear();
    _expenses.clear();
    _employees.clear();
    _employeeAdvances.clear();
    _salaryPayments.clear();
    _suppliers.clear();
    _distributors.clear();
    _saleOrders.clear();
    _stocktakeRecords.clear();
    _treasuryTransactions.clear();
    _rawMaterials.clear();
    _productRawMaterials.clear();
    factoryName = 'النجمة بلاست';
    plasticTonPrice = 0.0;
    todayOrdersCount = 0;
    await _persist();
    notifyListeners();
  }
}
