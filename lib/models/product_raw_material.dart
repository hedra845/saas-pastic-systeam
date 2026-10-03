class ProductRawMaterial {
  final String id;
  final String productId;
  final String rawMaterialId;
  final double quantity; // الكمية المستخدمة في إنتاج وحدة واحدة من المنتج (حسب وحدة المادة الخام)

  ProductRawMaterial({
    required this.id,
    required this.productId,
    required this.rawMaterialId,
    required this.quantity,
  });

  ProductRawMaterial copyWith({
    String? id,
    String? productId,
    String? rawMaterialId,
    double? quantity,
  }) {
    return ProductRawMaterial(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      rawMaterialId: rawMaterialId ?? this.rawMaterialId,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'rawMaterialId': rawMaterialId,
    'quantity': quantity,
  };

  factory ProductRawMaterial.fromJson(Map<String, dynamic> json) => ProductRawMaterial(
    id: json['id'] as String,
    productId: json['productId'] as String,
    rawMaterialId: json['rawMaterialId'] as String,
    quantity: (json['quantity'] as num).toDouble(),
  );
}