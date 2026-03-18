class Loan {
  final int? id;
  final String title;
  final String lenderName;
  final double totalAmount;
  final double monthlyAmount;
  final DateTime startDate;
  final DateTime endDate;
  final int paidMonths;
  final String? notes;
  final double interestRate;

  const Loan({
    this.id,
    required this.title,
    required this.lenderName,
    required this.totalAmount,
    required this.monthlyAmount,
    required this.startDate,
    required this.endDate,
    this.paidMonths = 0,
    this.notes,
    this.interestRate = 0.0,
  });

  int get totalMonths {
    final months = (endDate.year - startDate.year) * 12 +
        (endDate.month - startDate.month);
    return months <= 0 ? 1 : months;
  }

  int get remainingMonths {
    final remaining = totalMonths - paidMonths;
    return remaining < 0 ? 0 : remaining;
  }

  double get paidAmount => monthlyAmount * paidMonths;

  double get remainingAmount {
    final remaining = totalAmount - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  double get progressPercentage {
    if (totalMonths == 0) return 1.0;
    final progress = paidMonths / totalMonths;
    return progress > 1.0 ? 1.0 : progress;
  }

  bool get isCompleted => paidMonths >= totalMonths;

  bool get isActive {
    final now = DateTime.now();
    return endDate.isAfter(now) && !isCompleted;
  }

  int get daysUntilEnd {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  bool get isExpiringSoon => daysUntilEnd <= 30 && daysUntilEnd >= 0;

  bool get isCurrentMonthDue {
    final now = DateTime.now();
    if (isCompleted) return false;
    if (startDate.isAfter(now)) return false;
    if (endDate.isBefore(DateTime(now.year, now.month, 1))) return false;
    return true;
  }

  Loan copyWith({
    int? id,
    String? title,
    String? lenderName,
    double? totalAmount,
    double? monthlyAmount,
    DateTime? startDate,
    DateTime? endDate,
    int? paidMonths,
    String? notes,
    double? interestRate,
  }) {
    return Loan(
      id: id ?? this.id,
      title: title ?? this.title,
      lenderName: lenderName ?? this.lenderName,
      totalAmount: totalAmount ?? this.totalAmount,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      paidMonths: paidMonths ?? this.paidMonths,
      notes: notes ?? this.notes,
      interestRate: interestRate ?? this.interestRate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'lenderName': lenderName,
      'totalAmount': totalAmount,
      'monthlyAmount': monthlyAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'paidMonths': paidMonths,
      'notes': notes,
      'interestRate': interestRate,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as int?,
      title: map['title'] as String,
      lenderName: map['lenderName'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      monthlyAmount: (map['monthlyAmount'] as num).toDouble(),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      paidMonths: map['paidMonths'] as int? ?? 0,
      notes: map['notes'] as String?,
      interestRate: (map['interestRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'Loan{id: $id, title: $title, lenderName: $lenderName, totalAmount: $totalAmount}';
  }
}
