class WasteRecord {
  final String id;
  final String productId;
  final String productName;
  final double wasteKg;
  final String wasteType; // هالك مطلع فيلم، هالك تقطيع وتخريم، عيوب طباعة، لحام غير مطابق
  final DateTime date;
  final bool isRecycled; // هل تم تحويله للراجع / الكسر لإعادة التدوير
  final String? notes;

  WasteRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.wasteKg,
    required this.wasteType,
    required this.date,
    this.isRecycled = true,
    this.notes,
  });
}
