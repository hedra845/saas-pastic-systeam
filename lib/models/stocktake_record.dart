class StocktakeEntry {
  final String productId;
  final String productName;
  final double bookQtyKg; // الرصيد الدفتري المسجل بالسيستم
  final double actualQtyKg; // الرصيد الفعلي بعد الجرد بالميزان
  final double costPerKg;
  final String? reason; // سبب العجز أو الزيادة

  StocktakeEntry({
    required this.productId,
    required this.productName,
    required this.bookQtyKg,
    required this.actualQtyKg,
    required this.costPerKg,
    this.reason,
  });

  // فرق الوزن: موجب يعني زيادة، سالب يعني عجز
  double get varianceKg => actualQtyKg - bookQtyKg;
  double get variancePercentage => bookQtyKg > 0 ? (varianceKg / bookQtyKg) * 100 : 0.0;
  double get varianceCost => varianceKg * costPerKg;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'bookQtyKg': bookQtyKg,
    'actualQtyKg': actualQtyKg,
    'costPerKg': costPerKg,
    'reason': reason,
  };

  factory StocktakeEntry.fromJson(Map<String, dynamic> json) => StocktakeEntry(
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    bookQtyKg: (json['bookQtyKg'] as num).toDouble(),
    actualQtyKg: (json['actualQtyKg'] as num).toDouble(),
    costPerKg: (json['costPerKg'] as num).toDouble(),
    reason: json['reason'] as String?,
  );
}

class StocktakeRecord {
  final String id;
  final String type; // 'يومي'، 'أسبوعي'، 'شهري'
  final String title; // مثال: جرد وردية الصباح 30 يوليو 2026
  final DateTime date;
  final String auditorName; // اسم مسؤول الجرد وأمين المخزن
  final List<StocktakeEntry> entries;
  final String status; // 'معتمد ومسوى'، 'مسودة قيد المراجعة'
  final String? notes;

  StocktakeRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.auditorName,
    required this.entries,
    this.status = 'معتمد ومسوى',
    this.notes,
  });

  double get totalBookQtyKg => entries.fold(0.0, (s, e) => s + e.bookQtyKg);
  double get totalActualQtyKg => entries.fold(0.0, (s, e) => s + e.actualQtyKg);
  double get totalVarianceKg => totalActualQtyKg - totalBookQtyKg;
  double get totalVarianceCost => entries.fold(0.0, (s, e) => s + e.varianceCost);

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'date': date.toIso8601String(),
    'auditorName': auditorName,
    'entries': entries.map((e) => e.toJson()).toList(),
    'status': status,
    'notes': notes,
  };

  factory StocktakeRecord.fromJson(Map<String, dynamic> json) => StocktakeRecord(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String,
    date: DateTime.parse(json['date'] as String),
    auditorName: json['auditorName'] as String,
    entries: (json['entries'] as List<dynamic>)
        .map((e) => StocktakeEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    status: json['status'] as String? ?? 'معتمد ومسوى',
    notes: json['notes'] as String?,
  );
}
