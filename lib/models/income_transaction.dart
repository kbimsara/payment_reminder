class IncomeTransaction {
  final int? id;
  final int sourceId;
  final String title;
  final double amount;
  final DateTime date;
  final int month;
  final int year;
  final String? notes;

  const IncomeTransaction({
    this.id,
    required this.sourceId,
    required this.title,
    required this.amount,
    required this.date,
    required this.month,
    required this.year,
    this.notes,
  });

  IncomeTransaction copyWith({
    int? id,
    int? sourceId,
    String? title,
    double? amount,
    DateTime? date,
    int? month,
    int? year,
    String? notes,
  }) =>
      IncomeTransaction(
        id: id ?? this.id,
        sourceId: sourceId ?? this.sourceId,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        month: month ?? this.month,
        year: year ?? this.year,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'sourceId': sourceId,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'month': month,
        'year': year,
        'notes': notes,
      };

  factory IncomeTransaction.fromMap(Map<String, dynamic> map) =>
      IncomeTransaction(
        id: map['id'] as int?,
        sourceId: map['sourceId'] as int,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
        month: map['month'] as int,
        year: map['year'] as int,
        notes: map['notes'] as String?,
      );
}
