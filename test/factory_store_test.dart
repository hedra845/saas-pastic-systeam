import 'package:flutter_test/flutter_test.dart';
import 'package:systeam_plastic/state/factory_store.dart';
import 'package:systeam_plastic/models/product_item.dart';
import 'package:systeam_plastic/models/employee.dart';
import 'package:systeam_plastic/models/sale_order.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('اختبارات نظام مصنع أكياس البلاستيك الموسع وقاعدة البيانات المحلية', () {
    late FactoryStore store;

    setUp(() {
      store = FactoryStore();
    });

    test('التحقق من القيم الافتراضية ومطابقتها للمؤشرات الرئيسية', () {
      expect(store.totalProductionKg, greaterThan(100000));
      expect(store.totalWasteKg, greaterThan(2000));
      expect(store.totalSalesRevenue, greaterThan(1000000));
      expect(store.totalExpenses, greaterThan(900000));
      expect(store.netProfit, greaterThan(250000));
      expect(store.plasticTonPrice, equals(27500.0));
      expect(store.employees.length, equals(32));
      expect(store.suppliers.length, greaterThanOrEqualTo(4));
      expect(store.distributors.length, greaterThanOrEqualTo(4));
    });

    test('حسابات الصنف: كام كيلو، هالك قد ايه، مصروفات، سعر جملة وسعر قطاعي، ومكسب', () {
      final product = ProductItem(
        id: 'test-prod-1',
        name: 'أكياس قمامة تجريبي 70×90',
        category: 'أكياس قمامة',
        materialType: 'LDPE',
        totalProducedKg: 10000,
        totalWasteKg: 200,
        totalExpenses: 70000, // 7 جنيه للكيلو
        wholesalePricePerKg: 10.0, // جملة بـ 10 جنيه للكيلو
        retailPricePerKg: 14.0,    // قطاعي بـ 14 جنيه للكيلو
        stockKg: 3000,
        defaultBatchKg: 100.0,
      );

      expect(product.totalRawMaterialKg, equals(10200.0));
      expect(product.wastePercentage, closeTo(1.96, 0.01));
      expect(product.costPerKg, equals(7.0));

      // مبيعات وأرباح الجملة
      expect(product.totalRevenue, equals(100000.0));
      expect(product.netProfit, equals(30000.0));
      expect(product.wholesaleProfitPerKg, equals(3.0));

      // مبيعات وأرباح القطاعي
      expect(product.totalRetailRevenue, equals(140000.0));
      expect(product.netRetailProfit, equals(70000.0));
      expect(product.retailProfitPerKg, equals(7.0));
    });

    test('إدارة الموظفين والورديات', () {
      final initialCount = store.employees.length;
      store.addEmployee(Employee(
        id: 'emp-new',
        name: 'فني جديد معتمد',
        role: 'فني مقصات',
        department: 'قسم التقطيع',
        shift: 'صباحية',
        monthlySalary: 7200,
      ));

      expect(store.employees.length, equals(initialCount + 1));
      expect(store.employees.any((e) => e.id == 'emp-new'), isTrue);
    });

    test('تسجيل فواتير البيع بالجملة وخصم المخزون', () {
      final prod = store.products.first;
      final initialStock = prod.stockKg;

      store.addSaleOrder(SaleOrder(
        id: 'order-test',
        invoiceNumber: 'INV-TEST-01',
        saleType: 'جملة',
        customerName: 'وكالة تجريبية',
        date: DateTime.now(),
        items: [
          SaleOrderItem(
            productId: prod.id,
            productName: prod.name,
            quantityKg: 500,
            unitPrice: prod.wholesalePricePerKg,
            unitCost: prod.costPerKg,
          ),
        ],
      ));

      final updatedProd = store.products.firstWhere((p) => p.id == prod.id);
      expect(updatedProd.stockKg, equals(initialStock - 500));
    });

    test('حركات الخزنة وحسابات الأرباح والخسائر (P&L)', () {
      expect(store.currentVaultBalance, greaterThan(10000));
      expect(store.treasuryTransactions.isNotEmpty, isTrue);

      // P&L metrics
      expect(store.pnlTotalRevenue, equals(store.totalSalesRevenue));
      expect(store.pnlGrossProfit, greaterThan(500000));
      expect(store.pnlNetProfit, equals(store.netProfit));

      final initialBalance = store.currentVaultBalance;

      // تجربة إيداع نقدي
      store.addTreasuryTransaction(
        type: 'وارد / إيداع',
        title: 'إيداع نقدي تجريبي',
        category: 'مبيعات نقدية',
        amount: 10000,
        person: 'المحاسب',
      );

      expect(store.currentVaultBalance, equals(initialBalance + 10000));

      // تجربة صرف نقدي
      store.addTreasuryTransaction(
        type: 'منصرف / سحب',
        title: 'مصروف صيانة نقدي',
        category: 'الصيانة',
        amount: 2500,
        person: 'فني الصيانة',
      );

      expect(store.currentVaultBalance, equals(initialBalance + 10000 - 2500));
    });

    test('إضافة صنف جديد دون تضاعف البيانات وخصم المبيعات من إجمالي الإنتاج', () {
      final initialProductCount = store.products.length;
      final newProduct = ProductItem(
        id: 'prod-new-123',
        name: 'أكياس تسوق هاي دي 50×40 سم',
        category: 'شنط تسوق',
        materialType: 'HDPE',
        totalProducedKg: 10000,
        totalWasteKg: 200,
        totalExpenses: 75000,
        wholesalePricePerKg: 10.50,
        retailPricePerKg: 14.00,
        stockKg: 4000,
        defaultBatchKg: 10000,
      );

      // إضافة الصنف للنظام
      store.addProduct(newProduct);

      expect(store.products.length, equals(initialProductCount + 1));
      final added = store.products.firstWhere((p) => p.id == 'prod-new-123');
      // التأكد من عدم تضاعف الهالك (يظل 200 كجم ولا يصبح 400)
      expect(added.totalWasteKg, equals(200.0));
      expect(added.totalProducedKg, equals(10000.0));
      expect(added.stockKg, equals(4000.0));

      // التأكد من تسجيل سجل المصروفات
      expect(store.expenses.any((e) => e.relatedProductId == 'prod-new-123' && e.amount == 75000), isTrue);

      // بيع 500 كجم
      store.addSaleOrder(SaleOrder(
        id: 'order-test-prod',
        invoiceNumber: 'INV-TEST-02',
        saleType: 'جملة',
        customerName: 'محل تجريبي',
        date: DateTime.now(),
        items: [
          SaleOrderItem(
            productId: 'prod-new-123',
            productName: 'أكياس تسوق هاي دي 50×40 سم',
            quantityKg: 500,
            unitPrice: 10.50,
            unitCost: 7.50,
          ),
        ],
      ));

      // التحقق من خصم الـ 500 كجم من إجمالي الإنتاج (10000 - 500 = 9500) ومن المخزون (4000 - 500 = 3500)
      final prodAfterSale = store.products.firstWhere((p) => p.id == 'prod-new-123');
      expect(prodAfterSale.totalProducedKg, equals(9500.0));
      expect(prodAfterSale.stockKg, equals(3500.0));
      expect(store.getSoldKgForProduct('prod-new-123'), equals(500.0));
    });
  });
}
