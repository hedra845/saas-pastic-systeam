import 'package:flutter_test/flutter_test.dart';
import 'package:systeam_plastic/models/product_item.dart';
import 'package:systeam_plastic/models/raw_material.dart';
import 'package:systeam_plastic/state/factory_store.dart';

void main() {
  group('اختبارات تنبيه نقص المخزون (أقل من 10 كيلو)', () {
    test('تنبيه نقص المخزون للمنتج يظهر فقط إذا كان الرصيد أقل من 10 كيلو', () {
      ProductItem createProduct(double stockKg) {
        return ProductItem(
          id: 'test-p1',
          name: 'كيس بلاستيك 1',
          category: 'أكياس',
          materialType: 'HDPE',
          totalProducedKg: 1000,
          defaultBatchKg: 1000,
          totalWasteKg: 50,
          wholesalePricePerKg: 20,
          retailPricePerKg: 25,
          stockKg: stockKg,
        );
      }

      // إذا كان المخزون 0 أو سالب فهو نافذ
      final outProduct = createProduct(0);
      expect(outProduct.isOutOfStock, isTrue);
      expect(outProduct.isLowStock, isFalse);
      expect(outProduct.hasStockAlert, isTrue);

      // إذا كان المخزون 5 كجم (أقل من 10 كجم) -> يظهر تنبيه نقص المخزون
      final lowProduct5 = createProduct(5.0);
      expect(lowProduct5.isOutOfStock, isFalse);
      expect(lowProduct5.isLowStock, isTrue);
      expect(lowProduct5.hasStockAlert, isTrue);

      // إذا كان المخزون 9.9 كجم (أقل من 10 كجم) -> يظهر تنبيه نقص المخزون
      final lowProduct9 = createProduct(9.9);
      expect(lowProduct9.isOutOfStock, isFalse);
      expect(lowProduct9.isLowStock, isTrue);
      expect(lowProduct9.hasStockAlert, isTrue);

      // إذا كان المخزون 10 كجم -> لا يظهر تنبيه نقص المخزون (متوفر)
      final normalProduct10 = createProduct(10.0);
      expect(normalProduct10.isOutOfStock, isFalse);
      expect(normalProduct10.isLowStock, isFalse);
      expect(normalProduct10.hasStockAlert, isFalse);

      // إذا كان المخزون 50 كجم -> لا يظهر تنبيه
      final normalProduct50 = createProduct(50.0);
      expect(normalProduct50.isOutOfStock, isFalse);
      expect(normalProduct50.isLowStock, isFalse);
      expect(normalProduct50.hasStockAlert, isFalse);
    });

    test('تنبيه نقص المخزون للمادة الخام عند الرصيد الأقل من حد التنبيه الافتراضي (10 كجم)', () {
      final rmLow = RawMaterial(
        id: 'rm-1',
        name: 'HDPE Granules',
        category: 'خامات بوليمر',
        unit: 'كجم',
        currentStock: 8.0,
        unitCost: 35.0,
      );
      expect(rmLow.isLowStock, isTrue);

      final rmNormal = RawMaterial(
        id: 'rm-2',
        name: 'HDPE Granules',
        category: 'خامات بوليمر',
        unit: 'كجم',
        currentStock: 10.0,
        unitCost: 35.0,
      );
      expect(rmNormal.isLowStock, isFalse);
    });

    test('فصل الكهرباء والعمالة على جنب لوحدها في حسابات الأرباح', () {
      final product = ProductItem(
        id: 'test-p2',
        name: 'كيس تسوق هاي دي',
        category: 'أكياس',
        materialType: 'HDPE',
        totalProducedKg: 1000,
        defaultBatchKg: 1000,
        totalWasteKg: 50,
        rawMaterialExpenses: 65000, // 65 جنيه للكيلو خامات
        laborAndElectricityExpenses: 2000, // 2 جنيه للكيلو كهرباء وعمالة
        wholesalePricePerKg: 75,
        retailPricePerKg: 80,
        stockKg: 500,
      );

      // تكلفة الخامة
      expect(product.rawMaterialCostPerKg, equals(65.0));

      // الكهرباء والعمالة على جنب لوحدها
      expect(product.laborAndElectricityCostPerKg, equals(2.0));
      expect(product.laborAndElectricityExpenses, equals(2000.0));

      // التكلفة الإجمالية
      expect(product.costPerKg, equals(67.0));

      // ربح الخامة قبل خصم الكهرباء والعمالة
      expect(product.grossWholesaleProfitPerKg, equals(10.0)); // 75 - 65
      expect(product.grossRetailProfitPerKg, equals(15.0));    // 80 - 65
      expect(product.grossProfit, equals(10000.0));
      expect(product.grossRetailProfit, equals(15000.0));

      // صافي الربح النهائي بعد خصم الكهرباء والعمالة (2 ج/كجم)
      expect(product.wholesaleProfitPerKg, equals(8.0));  // 10 - 2
      expect(product.retailProfitPerKg, equals(13.0));     // 15 - 2
      expect(product.netProfit, equals(8000.0));
      expect(product.netRetailProfit, equals(13000.0));
    });

    test('تسجيل تاريخ الإضافة الأولى وسجل إضافات المخزون بتواريخها', () {
      final initialDate = DateTime(2026, 9, 10, 10, 0);
      final product = ProductItem(
        id: 'test-stock-1',
        name: 'كيس تعبئة سكر',
        category: 'أكياس',
        materialType: 'LDPE',
        totalProducedKg: 2000,
        defaultBatchKg: 2000,
        totalWasteKg: 50,
        wholesalePricePerKg: 30,
        retailPricePerKg: 35,
        stockKg: 1000,
        createdAt: initialDate,
      );

      // التحقق من تاريخ الإضافة الأولى
      expect(product.createdAt, equals(initialDate));

      // التحقق من أن الإضافة الأولى مسجلة تلقائياً في سجل الإضافات
      expect(product.stockAdditions.length, equals(1));
      expect(product.stockAdditions.first.quantityKg, equals(1000.0));
      expect(product.stockAdditions.first.previousStockKg, equals(0.0));
      expect(product.stockAdditions.first.newStockKg, equals(1000.0));
      expect(product.stockAdditions.first.date, equals(initialDate));

      // إضافة مخزون جديد بتاريخ لاحق
      final additionDate = DateTime(2026, 9, 20, 14, 30);
      final store = FactoryStore();
      store.addProduct(product);

      store.addProductStock(
        productId: 'test-stock-1',
        additionalStockKg: 500,
        date: additionDate,
        notes: 'تشغيلة إضافية ماكينة 2',
      );

      final updated = store.products.firstWhere((p) => p.id == 'test-stock-1');
      expect(updated.stockKg, equals(1500.0));
      expect(updated.createdAt, equals(initialDate)); // تاريخ الإضافة الأولى لم يتغير
      expect(updated.stockAdditions.length, equals(2));

      final secondAddition = updated.stockAdditions.last;
      expect(secondAddition.quantityKg, equals(500.0));
      expect(secondAddition.previousStockKg, equals(1000.0));
      expect(secondAddition.newStockKg, equals(1500.0));
      expect(secondAddition.date, equals(additionDate));
      expect(secondAddition.notes, equals('تشغيلة إضافية ماكينة 2'));

      // فحص الـ Json Serialization
      final json = updated.toJson();
      final fromJsonProd = ProductItem.fromJson(json);
      expect(fromJsonProd.createdAt, equals(initialDate));
      expect(fromJsonProd.stockAdditions.length, equals(2));
      expect(fromJsonProd.stockAdditions.last.quantityKg, equals(500.0));
    });
  });
}
