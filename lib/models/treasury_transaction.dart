class TreasuryTransaction {
  final String id;
  final String voucherNumber; // رقم السند مثل: REC-2026-001 أو PAY-2026-001
  final String type; // 'وارد / إيداع' أو 'منصرف / سحب'
  final String title; // البيان: تحصيل فاتورة، سداد فاتورة كهرباء، شراء خامات...
  final String category; // تصنيف: مبيعات، خامات، رواتب، كهرباء، صيانة، نثريات
  final double amount; // المبلغ بالجنيه
  final double balanceAfter; // رصيد الخزنة بعد هذه الحركة
  final DateTime date;
  final String paymentMethod; // نقدي كاش، تحويل بنكي، شيك
  final String personInCharge; // أمين الخزنة / المستلم
  final String? notes;

  TreasuryTransaction({
    required this.id,
    required this.voucherNumber,
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    required this.balanceAfter,
    required this.date,
    this.paymentMethod = 'نقدي كاش',
    required this.personInCharge,
    this.notes,
  });

  bool get isIncome => type.contains('وارد') || type.contains('إيداع');

  Map<String, dynamic> toJson() => {
    'id': id,
    'voucherNumber': voucherNumber,
    'type': type,
    'title': title,
    'category': category,
    'amount': amount,
    'balanceAfter': balanceAfter,
    'date': date.toIso8601String(),
    'paymentMethod': paymentMethod,
    'personInCharge': personInCharge,
    'notes': notes,
  };

  factory TreasuryTransaction.fromJson(Map<String, dynamic> json) => TreasuryTransaction(
    id: json['id'] as String,
    voucherNumber: json['voucherNumber'] as String,
    type: json['type'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    amount: (json['amount'] as num).toDouble(),
    balanceAfter: (json['balanceAfter'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    paymentMethod: json['paymentMethod'] as String? ?? 'نقدي كاش',
    personInCharge: json['personInCharge'] as String,
    notes: json['notes'] as String?,
  );
}
