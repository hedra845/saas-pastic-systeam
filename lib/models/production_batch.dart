class ProductionBatch {
  final String id;
  final String dateText; // مثال: "30 يوليو 2026 - 10:30 ص"
  final DateTime timestamp;
  final String productId;
  final String productName;
  final String rawMaterialType; // LDPE, HDPE, PP
  final double quantityKg; // الكمية الصافية المنتجة (كجم)
  final double wasteKg; // كمية الهالك في هذه التشغيلة (كجم)
  final double cost; // التكلفة الإجمالية للتشغيلة (جنيه)
  final String status; // مكتمل، قيد التشغيل، معلق
  final String? machineId; // خط الإنتاج / رقم الماكينة
  final String? operatorName; // اسم الفني / المشغل

  ProductionBatch({
    required this.id,
    required this.dateText,
    required this.timestamp,
    required this.productId,
    required this.productName,
    required this.rawMaterialType,
    required this.quantityKg,
    required this.wasteKg,
    required this.cost,
    this.status = 'مكتمل',
    this.machineId,
    this.operatorName,
  });

  double get totalRawInputKg => quantityKg + wasteKg;
  double get wastePercentage => totalRawInputKg > 0 ? (wasteKg / totalRawInputKg) * 100 : 0.0;
}
