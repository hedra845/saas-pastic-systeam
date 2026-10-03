class MaterialSupplyOrder {
  final String id;
  final String invoiceNumber; // رقم إذن التوريد / الفاتورة (مثال: SUP-2026-001)
  final DateTime date;
  final String supplierId;
  final String supplierName;
  final String supplierFactory; // المصنع التابع له (سابك، بروج، إيثيدكو...)
  final String rawMaterialId;
  final String rawMaterialName;
  final double quantityKg; // الكمية الموردة بالكيلوجرام
  final double unitPrice; // سعر كيلو الخامة في هذا التوريد (ج.م)
  final double previousBasePrice; // سعر الكيلو الأساسي في المخزن قبل التوريد
  final bool updatedBasePrice; // هل تم تحديث سعر الكيلو الأساسي للخامة؟
  final double totalAmount; // الإجمالي = quantityKg * unitPrice
  final double paidAmount; // المبلغ المدفوع نقداً من الخزينة
  final double remainingAmount; // المتبقي على الحساب (آجل)
  final String paymentMethod; // نقدي كاش من الخزينة، آجل على الحساب، دفعة كاش والباقي آجل
  final String? notes; // ملاحظات

  bool get isFullyPaid => remainingAmount <= 0.01;

  MaterialSupplyOrder({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.supplierId,
    required this.supplierName,
    required this.supplierFactory,
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.quantityKg,
    required this.unitPrice,
    required this.previousBasePrice,
    required this.updatedBasePrice,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentMethod,
    this.notes,
  });

  MaterialSupplyOrder copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? date,
    String? supplierId,
    String? supplierName,
    String? supplierFactory,
    String? rawMaterialId,
    String? rawMaterialName,
    double? quantityKg,
    double? unitPrice,
    double? previousBasePrice,
    bool? updatedBasePrice,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    String? paymentMethod,
    String? notes,
  }) => MaterialSupplyOrder(
    id: id ?? this.id,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    date: date ?? this.date,
    supplierId: supplierId ?? this.supplierId,
    supplierName: supplierName ?? this.supplierName,
    supplierFactory: supplierFactory ?? this.supplierFactory,
    rawMaterialId: rawMaterialId ?? this.rawMaterialId,
    rawMaterialName: rawMaterialName ?? this.rawMaterialName,
    quantityKg: quantityKg ?? this.quantityKg,
    unitPrice: unitPrice ?? this.unitPrice,
    previousBasePrice: previousBasePrice ?? this.previousBasePrice,
    updatedBasePrice: updatedBasePrice ?? this.updatedBasePrice,
    totalAmount: totalAmount ?? this.totalAmount,
    paidAmount: paidAmount ?? this.paidAmount,
    remainingAmount: remainingAmount ?? this.remainingAmount,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'date': date.toIso8601String(),
    'supplierId': supplierId,
    'supplierName': supplierName,
    'supplierFactory': supplierFactory,
    'rawMaterialId': rawMaterialId,
    'rawMaterialName': rawMaterialName,
    'quantityKg': quantityKg,
    'unitPrice': unitPrice,
    'previousBasePrice': previousBasePrice,
    'updatedBasePrice': updatedBasePrice,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'remainingAmount': remainingAmount,
    'paymentMethod': paymentMethod,
    'notes': notes,
  };

  factory MaterialSupplyOrder.fromJson(Map<String, dynamic> json) => MaterialSupplyOrder(
    id: json['id'] as String,
    invoiceNumber: json['invoiceNumber'] as String? ?? 'SUP-000',
    date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
    supplierId: json['supplierId'] as String? ?? '',
    supplierName: json['supplierName'] as String? ?? '',
    supplierFactory: json['supplierFactory'] as String? ?? '',
    rawMaterialId: json['rawMaterialId'] as String? ?? '',
    rawMaterialName: json['rawMaterialName'] as String? ?? '',
    quantityKg: (json['quantityKg'] as num?)?.toDouble() ?? 0.0,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
    previousBasePrice: (json['previousBasePrice'] as num?)?.toDouble() ?? 0.0,
    updatedBasePrice: json['updatedBasePrice'] as bool? ?? false,
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
    remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
    paymentMethod: json['paymentMethod'] as String? ?? 'آجل على الحساب',
    notes: json['notes'] as String?,
  );
}
