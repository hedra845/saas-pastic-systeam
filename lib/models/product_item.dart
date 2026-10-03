import 'product_raw_material.dart';
import 'raw_material.dart';
import 'stock_addition_record.dart';

class ProductItem {
  final String id;
  final String name;
  final String category;
  final String materialType;
  final double totalProducedKg;
  final double defaultBatchKg;
  final double totalWasteKg;
  final double rawMaterialExpenses;
  final double laborAndElectricityExpenses;
  final double laborCostPerKg;
  final double totalExpenses;
  final double wholesalePricePerKg;
  final double retailPricePerKg;
  final double stockKg;
  final double minWholesaleQtyKg;
  final String? notes;
  final List<ProductRawMaterial> rawMaterials;
  final DateTime createdAt; // تاريخ الإضافة الأولى للصنف
  final List<StockAdditionRecord> stockAdditions; // سجل تواريخ إضافات المخزون

  // تكلفة العمالة والكهرباء لكل كيلو (0.0 = بدون تكلفة افتراضية، يمكن تحديدها يدوياً لكل صنف)
  static const double fixedLaborAndElectricityPerKg = 0.0;

  ProductItem({
    required this.id,
    required this.name,
    required this.category,
    required this.materialType,
    required this.totalProducedKg,
    required this.defaultBatchKg,
    required this.totalWasteKg,
    double? rawMaterialExpenses,
    double? laborAndElectricityExpenses,
    double? laborCostPerKg,
    double? totalExpenses,
    required this.wholesalePricePerKg,
    required this.retailPricePerKg,
    required this.stockKg,
    this.minWholesaleQtyKg = 100.0,
    this.notes,
    this.rawMaterials = const [],
    DateTime? createdAt,
    List<StockAdditionRecord>? stockAdditions,
  })  : createdAt = createdAt ?? DateTime.now(),
        stockAdditions = stockAdditions ??
            (stockKg > 0
                ? [
                    StockAdditionRecord(
                      id: 'sa-init-$id',
                      date: createdAt ?? DateTime.now(),
                      quantityKg: stockKg,
                      previousStockKg: 0.0,
                      newStockKg: stockKg,
                      notes: 'الرصيد الافتتاحي (الإضافة الأولى)',
                    )
                  ]
                : const []),
        laborCostPerKg = laborCostPerKg ??
            (laborAndElectricityExpenses != null && totalProducedKg > 0
                ? laborAndElectricityExpenses / totalProducedKg
                : fixedLaborAndElectricityPerKg),
        laborAndElectricityExpenses = laborAndElectricityExpenses ??
            (totalProducedKg *
                (laborCostPerKg ??
                    (laborAndElectricityExpenses != null && totalProducedKg > 0
                        ? laborAndElectricityExpenses / totalProducedKg
                        : fixedLaborAndElectricityPerKg))),
        rawMaterialExpenses = rawMaterialExpenses ??
            ((totalExpenses != null && totalExpenses > 0)
                ? (totalExpenses >=
                        (laborAndElectricityExpenses ??
                            (totalProducedKg *
                                (laborCostPerKg ?? fixedLaborAndElectricityPerKg)))
                    ? totalExpenses -
                        (laborAndElectricityExpenses ??
                            (totalProducedKg *
                                (laborCostPerKg ?? fixedLaborAndElectricityPerKg)))
                    : totalExpenses)
                : 0.0),
        totalExpenses = totalExpenses ??
            ((rawMaterialExpenses ?? 0.0) +
                (laborAndElectricityExpenses ??
                    (totalProducedKg *
                        (laborCostPerKg ?? fixedLaborAndElectricityPerKg))));

  double get sellingPricePerKg => wholesalePricePerKg;

  double get totalRawMaterialKg => totalProducedKg + totalWasteKg;

  double get wastePercentage {
    if (totalRawMaterialKg == 0) return 0.0;
    return (totalWasteKg / totalRawMaterialKg) * 100;
  }

  double get rawMaterialCostPerKg {
    if (totalProducedKg == 0) return 0.0;
    return rawMaterialExpenses / totalProducedKg;
  }

  double get laborAndElectricityCostPerKg {
    if (laborCostPerKg > 0) return laborCostPerKg;
    if (totalProducedKg == 0) return fixedLaborAndElectricityPerKg;
    return laborAndElectricityExpenses / totalProducedKg;
  }

  double get costPerKg {
    if (totalProducedKg == 0) return 0.0;
    return totalExpenses / totalProducedKg;
  }

  double get totalRevenue => totalProducedKg * wholesalePricePerKg;

  double get totalRetailRevenue => totalProducedKg * retailPricePerKg;

  /// ربح الخامة الإجمالي بالجملة (قبل خصم الكهرباء والعمالة)
  double get grossProfit => totalRevenue - rawMaterialExpenses;

  /// ربح الخامة الإجمالي بالقطاعي (قبل خصم الكهرباء والعمالة)
  double get grossRetailProfit => totalRetailRevenue - rawMaterialExpenses;

  /// ربح الكيلو جملة من الخامة (قبل خصم الكهرباء والعمالة)
  double get grossWholesaleProfitPerKg => wholesalePricePerKg - rawMaterialCostPerKg;

  /// ربح الكيلو قطاعي من الخامة (قبل خصم الكهرباء والعمالة)
  double get grossRetailProfitPerKg => retailPricePerKg - rawMaterialCostPerKg;

  double get netProfit => totalRevenue - totalExpenses;

  double get netRetailProfit => totalRetailRevenue - totalExpenses;

  double get wholesaleProfitPerKg => wholesalePricePerKg - costPerKg;

  double get retailProfitPerKg => retailPricePerKg - costPerKg;

  double get profitMarginPercentage {
    if (totalRevenue == 0) return 0.0;
    return (netProfit / totalRevenue) * 100;
  }

  double get retailProfitMarginPercentage {
    if (totalRetailRevenue == 0) return 0.0;
    return (netRetailProfit / totalRetailRevenue) * 100;
  }

  /// فحص هل نفذ رصيد الصنف تماماً من المخزن
  bool get isOutOfStock => stockKg <= 0;

  /// فحص هل الصنف قارب على النفاذ (نقص المخزون: أقل من 10 كجم)
  bool get isLowStock {
    if (stockKg <= 0) return false;
    return stockKg < 10;
  }

  /// هل الصنف به تنبيه مخزون (نفذ أو قارب على النفاذ)
  bool get hasStockAlert => isOutOfStock || isLowStock;

  /// نسبة المتبقي بالمخزن
  double get remainingStockPercentage {
    if (totalProducedKg <= 0) return 0.0;
    return (stockKg / totalProducedKg) * 100;
  }

  double getRawMaterialCost(List<RawMaterial> allRawMaterials) {
    double totalCost = 0.0;
    for (final prm in rawMaterials) {
      final rawMaterial = allRawMaterials.firstWhere(
        (r) => r.id == prm.rawMaterialId,
        orElse: () => RawMaterial(
          id: '',
          name: '',
          category: '',
          unit: '',
          currentStock: 0,
          unitCost: 0,
        ),
      );
      if (rawMaterial.id.isNotEmpty) {
        totalCost += prm.quantity * rawMaterial.unitCost;
      }
    }
    return totalCost;
  }

  ProductItem copyWith({
    String? id,
    String? name,
    String? category,
    String? materialType,
    double? totalProducedKg,
    double? defaultBatchKg,
    double? totalWasteKg,
    double? rawMaterialExpenses,
    double? laborAndElectricityExpenses,
    double? laborCostPerKg,
    double? totalExpenses,
    double? wholesalePricePerKg,
    double? retailPricePerKg,
    double? stockKg,
    double? minWholesaleQtyKg,
    String? notes,
    List<ProductRawMaterial>? rawMaterials,
    DateTime? createdAt,
    List<StockAdditionRecord>? stockAdditions,
  }) {
    final effectiveLaborCostPerKg = laborCostPerKg ?? this.laborCostPerKg;
    final newProduced = totalProducedKg ?? this.totalProducedKg;
    final newLabor = laborAndElectricityExpenses ??
        (newProduced * (effectiveLaborCostPerKg > 0 ? effectiveLaborCostPerKg : ProductItem.fixedLaborAndElectricityPerKg));
    final newRaw = rawMaterialExpenses ?? this.rawMaterialExpenses;
    final newTotal = totalExpenses ?? (newRaw + newLabor);
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      materialType: materialType ?? this.materialType,
      totalProducedKg: newProduced,
      defaultBatchKg: defaultBatchKg ?? this.defaultBatchKg,
      totalWasteKg: totalWasteKg ?? this.totalWasteKg,
      rawMaterialExpenses: newRaw,
      laborAndElectricityExpenses: newLabor,
      laborCostPerKg: effectiveLaborCostPerKg,
      totalExpenses: newTotal,
      wholesalePricePerKg: wholesalePricePerKg ?? this.wholesalePricePerKg,
      retailPricePerKg: retailPricePerKg ?? this.retailPricePerKg,
      stockKg: stockKg ?? this.stockKg,
      minWholesaleQtyKg: minWholesaleQtyKg ?? this.minWholesaleQtyKg,
      notes: notes ?? this.notes,
      rawMaterials: rawMaterials ?? this.rawMaterials,
      createdAt: createdAt ?? this.createdAt,
      stockAdditions: stockAdditions ?? this.stockAdditions,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'materialType': materialType,
    'totalProducedKg': totalProducedKg,
    'defaultBatchKg': defaultBatchKg,
    'totalWasteKg': totalWasteKg,
    'rawMaterialExpenses': rawMaterialExpenses,
    'laborAndElectricityExpenses': laborAndElectricityExpenses,
    'laborCostPerKg': laborCostPerKg,
    'totalExpenses': totalExpenses,
    'wholesalePricePerKg': wholesalePricePerKg,
    'retailPricePerKg': retailPricePerKg,
    'stockKg': stockKg,
    'minWholesaleQtyKg': minWholesaleQtyKg,
    'notes': notes,
    'rawMaterials': rawMaterials.map((rm) => rm.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'stockAdditions': stockAdditions.map((sa) => sa.toJson()).toList(),
  };

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final produced = (json['totalProducedKg'] as num).toDouble();
    final totalExp = (json['totalExpenses'] as num?)?.toDouble() ?? 0.0;
    final laborElecExpFromJson = (json['laborAndElectricityExpenses'] as num?)?.toDouble();
    final laborPerKg = (json['laborCostPerKg'] as num?)?.toDouble() ??
        (produced > 0 && laborElecExpFromJson != null
            ? laborElecExpFromJson / produced
            : ProductItem.fixedLaborAndElectricityPerKg);
    final laborElecExp = laborElecExpFromJson ?? (produced * laborPerKg);
    final rawExp = (json['rawMaterialExpenses'] as num?)?.toDouble() ??
        (totalExp >= laborElecExp ? totalExp - laborElecExp : totalExp);
    return ProductItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      materialType: json['materialType'] as String,
      totalProducedKg: (json['totalProducedKg'] as num).toDouble(),
      defaultBatchKg: (json['defaultBatchKg'] as num?)?.toDouble() ?? 1000.0,
      totalWasteKg: (json['totalWasteKg'] as num).toDouble(),
      rawMaterialExpenses: rawExp,
      laborAndElectricityExpenses: laborElecExp,
      laborCostPerKg: laborPerKg,
      totalExpenses: totalExp > 0 ? totalExp : (rawExp + laborElecExp),
      wholesalePricePerKg: (json['wholesalePricePerKg'] as num?)?.toDouble() ?? 10.0,
      retailPricePerKg: (json['retailPricePerKg'] as num?)?.toDouble() ?? 13.5,
      stockKg: (json['stockKg'] as num).toDouble(),
      minWholesaleQtyKg: (json['minWholesaleQtyKg'] as num?)?.toDouble() ?? 100.0,
      notes: json['notes'] as String?,
      rawMaterials: (json['rawMaterials'] as List?)
              ?.map((e) => ProductRawMaterial.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      stockAdditions: (json['stockAdditions'] as List?)
              ?.map((e) => StockAdditionRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}