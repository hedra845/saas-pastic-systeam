class SaleOrderItem {
  final String productId;
  final String productName;
  final double quantityKg; // الكمية بالكيلو
  final double unitPrice; // سعر بيع الكيلو (جملة أو قطاعي)
  final double unitCost; // تكلفة الكيلو على المصنع

  SaleOrderItem({
    required this.productId,
    required this.productName,
    required this.quantityKg,
    required this.unitPrice,
    required this.unitCost,
  });

  double get totalPrice => quantityKg * unitPrice;
  double get totalCost => quantityKg * unitCost;
  double get profit => totalPrice - totalCost;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantityKg': quantityKg,
    'unitPrice': unitPrice,
    'unitCost': unitCost,
  };

  factory SaleOrderItem.fromJson(Map<String, dynamic> json) => SaleOrderItem(
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    quantityKg: (json['quantityKg'] as num).toDouble(),
    unitPrice: (json['unitPrice'] as num).toDouble(),
    unitCost: (json['unitCost'] as num).toDouble(),
  );
}

class SaleOrder {
  final String id;
  final String invoiceNumber; // رقم الفاتورة مثل: INV-2026-081
  final String saleType; // 'جملة' أو 'قطاعي'
  final String? customerId; // معرف الموزع إذا كان جملة
  final String customerName; // اسم العميل أو الموزع
  final String? customerPhone;
  final DateTime date;
  final List<SaleOrderItem> items;
  final String paymentMethod; // نقدي، شيك، آجل
  final String paymentStatus; // مدفوع بالكامل، دفع جزئي، آجل
  final double paidAmount; // المبلغ المسدد / المحصل حتى الآن
  final String? notes;

  SaleOrder({
    required this.id,
    required this.invoiceNumber,
    required this.saleType,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.date,
    required this.items,
    this.paymentMethod = 'نقدي',
    this.paymentStatus = 'مدفوع بالكامل',
    double? paidAmount,
    this.notes,
  }) : paidAmount = paidAmount ??
            (paymentStatus == 'مدفوع بالكامل'
                ? items.fold(0.0, (sum, item) => sum + item.totalPrice)
                : 0.0);

  double get totalWeightKg => items.fold(0.0, (sum, item) => sum + item.quantityKg);
  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get totalCost => items.fold(0.0, (sum, item) => sum + item.totalCost);
  double get totalProfit => totalAmount - totalCost;
  double get profitMarginPercentage => totalAmount > 0 ? (totalProfit / totalAmount) * 100 : 0.0;

  /// المبلغ المتبقي غير المسدد (الآجل)
  double get remainingAmount => (totalAmount - paidAmount).clamp(0.0, double.infinity);

  /// هل الفاتورة بها مديونية أو آجل
  bool get isCredit => paymentMethod == 'آجل' || paymentStatus == 'آجل' || paymentStatus == 'دفع جزئي' || remainingAmount > 0;

  /// هل الفاتورة مسددة بالكامل
  bool get isFullyPaid => remainingAmount <= 0.01;

  SaleOrder copyWith({
    String? id,
    String? invoiceNumber,
    String? saleType,
    String? customerId,
    String? customerName,
    String? customerPhone,
    DateTime? date,
    List<SaleOrderItem>? items,
    String? paymentMethod,
    String? paymentStatus,
    double? paidAmount,
    String? notes,
  }) {
    return SaleOrder(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      saleType: saleType ?? this.saleType,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      date: date ?? this.date,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'saleType': saleType,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'date': date.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'paidAmount': paidAmount,
    'notes': notes,
  };

  factory SaleOrder.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((i) => SaleOrderItem.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [];
    final total = itemsList.fold(0.0, (sum, item) => sum + item.totalPrice);
    final status = json['paymentStatus'] as String? ?? 'مدفوع بالكامل';
    final paid = (json['paidAmount'] as num?)?.toDouble() ??
        (status == 'مدفوع بالكامل' ? total : 0.0);

    return SaleOrder(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      saleType: json['saleType'] as String,
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String?,
      date: DateTime.parse(json['date'] as String),
      items: itemsList,
      paymentMethod: json['paymentMethod'] as String? ?? 'نقدي',
      paymentStatus: status,
      paidAmount: paid,
      notes: json['notes'] as String?,
    );
  }
}
