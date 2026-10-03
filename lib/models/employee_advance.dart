class EmployeeAdvance {
  final String id;
  final String employeeId;
  final String employeeName;
  final double amount; // مبلغ السلفة بالجنيه
  final double settledAmount; // المبلغ المسدد أو المخصوم من الراتب حتى الآن
  final DateTime date; // تاريخ السلفة
  final String? notes; // سبب السلفة أو ملاحظات
  final String status; // 'معلقة' | 'مسددة جزئياً' | 'مسددة بالكامل'
  final bool deductedFromTreasury; // هل تم صرفها نقداً من خزنة المصنع

  EmployeeAdvance({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    this.settledAmount = 0.0,
    required this.date,
    this.notes,
    String? status,
    this.deductedFromTreasury = true,
  }) : status = status ?? _calculateStatus(amount, settledAmount);

  static String _calculateStatus(double amount, double settled) {
    if (settled >= amount - 0.001) return 'مسددة بالكامل';
    if (settled > 0.001) return 'مسددة جزئياً';
    return 'معلقة';
  }

  double get remainingAmount => (amount - settledAmount).clamp(0.0, double.infinity);
  bool get isFullySettled => remainingAmount <= 0.001;

  EmployeeAdvance copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    double? amount,
    double? settledAmount,
    DateTime? date,
    String? notes,
    String? status,
    bool? deductedFromTreasury,
  }) {
    final newAmount = amount ?? this.amount;
    final newSettled = settledAmount ?? this.settledAmount;
    return EmployeeAdvance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      amount: newAmount,
      settledAmount: newSettled,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      status: status ?? _calculateStatus(newAmount, newSettled),
      deductedFromTreasury: deductedFromTreasury ?? this.deductedFromTreasury,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'employeeName': employeeName,
    'amount': amount,
    'settledAmount': settledAmount,
    'date': date.toIso8601String(),
    'notes': notes,
    'status': status,
    'deductedFromTreasury': deductedFromTreasury,
  };

  factory EmployeeAdvance.fromJson(Map<String, dynamic> json) => EmployeeAdvance(
    id: json['id'] as String,
    employeeId: json['employeeId'] as String,
    employeeName: json['employeeName'] as String,
    amount: (json['amount'] as num).toDouble(),
    settledAmount: (json['settledAmount'] as num?)?.toDouble() ?? 0.0,
    date: DateTime.parse(json['date'] as String),
    notes: json['notes'] as String?,
    status: json['status'] as String?,
    deductedFromTreasury: json['deductedFromTreasury'] as bool? ?? true,
  );
}
