class Distributor {
  final String id;
  final String name; // اسم التاجر / الموزع
  final String tradeName; // الاسم التجاري (وكالة الأمانة، أسواق السلام، شركة الفهد للتوزيع...)
  final String type; // تاجر جملة، موزع معتمد، سوبرماركت، منفذ قطاعي
  final String region; // المنطقة / المحافظة (القاهرة، الجيزة، الإسكندرية، الدلتا، الصعيد)
  final String phone;
  final double currentDebt; // المديونية الحالية بالجنيه
  final double creditLimit; // الحد الائتماني المسموح به
  final double totalSalesVolumeKg; // إجمالي المسحوبات بالكيلو
  final String? notes;

  Distributor({
    required this.id,
    required this.name,
    required this.tradeName,
    required this.type,
    required this.region,
    required this.phone,
    required this.currentDebt,
    required this.creditLimit,
    required this.totalSalesVolumeKg,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tradeName': tradeName,
    'type': type,
    'region': region,
    'phone': phone,
    'currentDebt': currentDebt,
    'creditLimit': creditLimit,
    'totalSalesVolumeKg': totalSalesVolumeKg,
    'notes': notes,
  };

  factory Distributor.fromJson(Map<String, dynamic> json) => Distributor(
    id: json['id'] as String,
    name: json['name'] as String,
    tradeName: json['tradeName'] as String,
    type: json['type'] as String,
    region: json['region'] as String,
    phone: json['phone'] as String,
    currentDebt: (json['currentDebt'] as num).toDouble(),
    creditLimit: (json['creditLimit'] as num).toDouble(),
    totalSalesVolumeKg: (json['totalSalesVolumeKg'] as num).toDouble(),
    notes: json['notes'] as String?,
  );
}
