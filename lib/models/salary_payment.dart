class SalaryPayment {
  final String id;
  final String voucherNumber; // رقم السند: PAY-SAL-2026-001
  final String employeeId;
  final String employeeName;
  final String role;
  final String department;
  final String monthYear; // الشهر والسنة المستحقة، مثلاً: "سبتمبر 2026"
  final double baseSalary; // الراتب الأساسي الشهري
  final double incentives; // حوافز / إضافي / مكافآت
  final double deductions; // خصومات / جزاءات / غياب
  final double advancesDeducted; // سلف تم استقطاعها من الراتب
  final double netSalary; // صافي الراتب المستحق والمنصرف
  final DateTime paymentDate; // تاريخ الصرف الفعلي
  final String paymentMethod; // نقدي كاش، تحويل بنكي، شيك
  final bool paidFromTreasury; // هل تم الخصم من الخزنة
  final String? notes; // ملاحظات الصرف
  final List<String> deductedAdvanceIds; // معرفات السلف المستقطعة

  SalaryPayment({
    required this.id,
    required this.voucherNumber,
    required this.employeeId,
    required this.employeeName,
    required this.role,
    required this.department,
    required this.monthYear,
    required this.baseSalary,
    this.incentives = 0.0,
    this.deductions = 0.0,
    this.advancesDeducted = 0.0,
    double? netSalary,
    DateTime? paymentDate,
    this.paymentMethod = 'نقدي كاش',
    this.paidFromTreasury = true,
    this.notes,
    this.deductedAdvanceIds = const [],
  })  : netSalary = netSalary ?? (baseSalary + incentives - deductions - advancesDeducted),
        paymentDate = paymentDate ?? DateTime.now();

  SalaryPayment copyWith({
    String? id,
    String? voucherNumber,
    String? employeeId,
    String? employeeName,
    String? role,
    String? department,
    String? monthYear,
    double? baseSalary,
    double? incentives,
    double? deductions,
    double? advancesDeducted,
    double? netSalary,
    DateTime? paymentDate,
    String? paymentMethod,
    bool? paidFromTreasury,
    String? notes,
    List<String>? deductedAdvanceIds,
  }) {
    final b = baseSalary ?? this.baseSalary;
    final inc = incentives ?? this.incentives;
    final d = deductions ?? this.deductions;
    final adv = advancesDeducted ?? this.advancesDeducted;
    return SalaryPayment(
      id: id ?? this.id,
      voucherNumber: voucherNumber ?? this.voucherNumber,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      role: role ?? this.role,
      department: department ?? this.department,
      monthYear: monthYear ?? this.monthYear,
      baseSalary: b,
      incentives: inc,
      deductions: d,
      advancesDeducted: adv,
      netSalary: netSalary ?? (b + inc - d - adv),
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidFromTreasury: paidFromTreasury ?? this.paidFromTreasury,
      notes: notes ?? this.notes,
      deductedAdvanceIds: deductedAdvanceIds ?? this.deductedAdvanceIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'voucherNumber': voucherNumber,
    'employeeId': employeeId,
    'employeeName': employeeName,
    'role': role,
    'department': department,
    'monthYear': monthYear,
    'baseSalary': baseSalary,
    'incentives': incentives,
    'deductions': deductions,
    'advancesDeducted': advancesDeducted,
    'netSalary': netSalary,
    'paymentDate': paymentDate.toIso8601String(),
    'paymentMethod': paymentMethod,
    'paidFromTreasury': paidFromTreasury,
    'notes': notes,
    'deductedAdvanceIds': deductedAdvanceIds,
  };

  factory SalaryPayment.fromJson(Map<String, dynamic> json) => SalaryPayment(
    id: json['id'] as String,
    voucherNumber: json['voucherNumber'] as String? ?? 'PAY-SAL-${DateTime.now().millisecondsSinceEpoch}',
    employeeId: json['employeeId'] as String,
    employeeName: json['employeeName'] as String,
    role: json['role'] as String? ?? '',
    department: json['department'] as String? ?? '',
    monthYear: json['monthYear'] as String? ?? '',
    baseSalary: (json['baseSalary'] as num).toDouble(),
    incentives: (json['incentives'] as num?)?.toDouble() ?? 0.0,
    deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
    advancesDeducted: (json['advancesDeducted'] as num?)?.toDouble() ?? 0.0,
    netSalary: (json['netSalary'] as num?)?.toDouble(),
    paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate'] as String) : DateTime.now(),
    paymentMethod: json['paymentMethod'] as String? ?? 'نقدي كاش',
    paidFromTreasury: json['paidFromTreasury'] as bool? ?? true,
    notes: json['notes'] as String?,
    deductedAdvanceIds: (json['deductedAdvanceIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
  );
}
