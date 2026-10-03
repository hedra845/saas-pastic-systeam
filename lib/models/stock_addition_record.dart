class StockAdditionRecord {
  final String id;
  final DateTime date;
  final double quantityKg; // الكمية المضافة بالكيلو
  final double previousStockKg; // الرصيد قبل الإضافة
  final double newStockKg; // الرصيد بعد الإضافة
  final String? notes; // ملاحظات الإضافة

  StockAdditionRecord({
    required this.id,
    required this.date,
    required this.quantityKg,
    required this.previousStockKg,
    required this.newStockKg,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'quantityKg': quantityKg,
    'previousStockKg': previousStockKg,
    'newStockKg': newStockKg,
    'notes': notes,
  };

  factory StockAdditionRecord.fromJson(Map<String, dynamic> json) => StockAdditionRecord(
    id: json['id'] as String? ?? 'sa-${DateTime.now().millisecondsSinceEpoch}',
    date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
    quantityKg: (json['quantityKg'] as num?)?.toDouble() ?? 0.0,
    previousStockKg: (json['previousStockKg'] as num?)?.toDouble() ?? 0.0,
    newStockKg: (json['newStockKg'] as num?)?.toDouble() ?? 0.0,
    notes: json['notes'] as String?,
  );
}
