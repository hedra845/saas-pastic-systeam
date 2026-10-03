class Supplier {
  final String id;
  final String name; // اسم المورد أو المسؤول
  final String companyName; // اسم الشركة أو المصنع
  final String materialSupplied; // ملخص الخامات الموردة للعرض
  final List<String> materials; // قائمة الخامات والأصناف التي يوردها المورد
  final String phone;
  final String address;
  final double currentBalance; // الرصيد المالي الحالي (دائن / مدين بالجنيه)
  final double totalPurchasesKg; // إجمالي الأوزان المشتراة بالكيلو
  final String? notes;

  Supplier({
    required this.id,
    required this.name,
    required this.companyName,
    required this.materialSupplied,
    List<String>? materials,
    required this.phone,
    required this.address,
    required this.currentBalance,
    required this.totalPurchasesKg,
    this.notes,
  }) : materials = materials ??
            (materialSupplied.isNotEmpty
                ? materialSupplied
                    .split(RegExp(r'[,،]'))
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList()
                : []);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'companyName': companyName,
    'materialSupplied': materialSupplied,
    'materials': materials,
    'phone': phone,
    'address': address,
    'currentBalance': currentBalance,
    'totalPurchasesKg': totalPurchasesKg,
    'notes': notes,
  };

  String get factoryName => companyName;

  /// قائمة الخامات والأصناف الموردة
  List<String> get suppliedMaterials {
    if (materials.isNotEmpty) return materials;
    if (materialSupplied.isNotEmpty) {
      return materialSupplied
          .split(RegExp(r'[,،]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  Supplier copyWith({
    String? id,
    String? name,
    String? companyName,
    String? materialSupplied,
    List<String>? materials,
    String? phone,
    String? address,
    double? currentBalance,
    double? totalPurchasesKg,
    String? notes,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      materialSupplied: materialSupplied ?? this.materialSupplied,
      materials: materials ?? this.materials,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      currentBalance: currentBalance ?? this.currentBalance,
      totalPurchasesKg: totalPurchasesKg ?? this.totalPurchasesKg,
      notes: notes ?? this.notes,
    );
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    final rawList = json['materials'];
    List<String> parsedMaterials = [];
    if (rawList is List) {
      parsedMaterials = rawList.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (json['materialSupplied'] != null) {
      parsedMaterials = json['materialSupplied']
          .toString()
          .split(RegExp(r'[,،]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final matStr = (json['materialSupplied'] as String?)?.trim() ?? '';
    final finalMatStr = matStr.isNotEmpty ? matStr : parsedMaterials.join('، ');

    return Supplier(
      id: (json['id'] as String?) ?? 'sup-${DateTime.now().millisecondsSinceEpoch}',
      name: (json['name'] as String?) ?? '',
      companyName: (json['companyName'] as String?) ?? '',
      materialSupplied: finalMatStr,
      materials: parsedMaterials,
      phone: (json['phone'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      currentBalance: ((json['currentBalance'] as num?) ?? 0).toDouble(),
      totalPurchasesKg: ((json['totalPurchasesKg'] as num?) ?? 0).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Supplier && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
