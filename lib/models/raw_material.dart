class RawMaterial {
  final String id;
  final String name; // اسم المادة الخام (مثال: HDPE، LDPE، PP، ماستر باتش أبيض)
  final String category; // الفئة: خامات بوليمر، ماستر باتش، إضافات، مواد تعبئة
  final String unit; // وحدة القياس: كجم، طن، لتر، كيس
  final double currentStock; // الرصيد الحالي بالمخزن
  final double minStockAlert; // حد التنبيه للمخزون الأدنى
  final double unitCost; // تكلفة الوحدة (جنيه)
  final String? supplierId; // المورد المفضل (اختياري)
  final String? notes; // ملاحظات

  RawMaterial({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentStock,
    this.minStockAlert = 10.0,
    required this.unitCost,
    this.supplierId,
    this.notes,
  });

  RawMaterial copyWith({
    String? id,
    String? name,
    String? category,
    String? unit,
    double? currentStock,
    double? minStockAlert,
    double? unitCost,
    String? supplierId,
    String? notes,
  }) {
    return RawMaterial(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      unitCost: unitCost ?? this.unitCost,
      supplierId: supplierId ?? this.supplierId,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'unit': unit,
    'currentStock': currentStock,
    'minStockAlert': minStockAlert,
    'unitCost': unitCost,
    'supplierId': supplierId,
    'notes': notes,
  };

  factory RawMaterial.fromJson(Map<String, dynamic> json) => RawMaterial(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    unit: json['unit'] as String,
    currentStock: (json['currentStock'] as num).toDouble(),
    minStockAlert: (json['minStockAlert'] as num?)?.toDouble() ?? 10.0,
    unitCost: (json['unitCost'] as num).toDouble(),
    supplierId: json['supplierId'] as String?,
    notes: json['notes'] as String?,
  );

  bool get isLowStock => currentStock < minStockAlert;
  double get stockValue => currentStock * unitCost;
}