class Employee {
  final String id;
  final String name;
  final String role; // مسمى وظيفي: فني ماكينة فيلم، فني مقصات، مهندس إنتاج، مشرف جودة، عامل تعبئة، سائق توزيع، محاسب
  final String department; // قسم: خطوط الفيلم، قسم التقطيع، قسم الصيانة، إدارة المصنع
  final String shift; // الوردية: صباحية (8ص - 4م)، مسائية (4م - 12ص)، ليلية (12ص - 8ص)
  final double monthlySalary; // المرتب الشهري (جنيه)
  final String? phone;
  final String? machineAssigned; // الماكينة المخصصة
  final String status; // على رأس العمل، إجازة، غياب
  final DateTime hireDate;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    required this.shift,
    required this.monthlySalary,
    this.phone,
    this.machineAssigned,
    this.status = 'على رأس العمل',
    DateTime? hireDate,
  }) : hireDate = hireDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'department': department,
    'shift': shift,
    'monthlySalary': monthlySalary,
    'phone': phone,
    'machineAssigned': machineAssigned,
    'status': status,
    'hireDate': hireDate.toIso8601String(),
  };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as String,
    name: json['name'] as String,
    role: json['role'] as String,
    department: json['department'] as String,
    shift: json['shift'] as String,
    monthlySalary: (json['monthlySalary'] as num).toDouble(),
    phone: json['phone'] as String?,
    machineAssigned: json['machineAssigned'] as String?,
    status: json['status'] as String? ?? 'على رأس العمل',
    hireDate: json['hireDate'] != null ? DateTime.parse(json['hireDate'] as String) : DateTime.now(),
  );
}
