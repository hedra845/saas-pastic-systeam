class ExpenseItem {
  final String id;
  final String title;
  final String category; // المواد الخام، العمالة، الكهرباء، الصيانة، تكاليف أخرى
  final double amount;
  final DateTime date;
  final String? notes;
  final String? relatedProductId;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
    this.relatedProductId,
  });
}
