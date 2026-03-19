class LoanPaymentMonth {
  final int? id;
  final int loanId;
  final int year;
  final int month;
  final bool isPaid;
  final DateTime? paidDate;
  final int? incomeSourceId;

  const LoanPaymentMonth({
    this.id,
    required this.loanId,
    required this.year,
    required this.month,
    required this.isPaid,
    this.paidDate,
    this.incomeSourceId,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'loanId': loanId,
        'year': year,
        'month': month,
        'isPaid': isPaid ? 1 : 0,
        'paidDate': paidDate?.toIso8601String(),
        'incomeSourceId': incomeSourceId,
      };

  factory LoanPaymentMonth.fromMap(Map<String, dynamic> map) =>
      LoanPaymentMonth(
        id: map['id'] as int?,
        loanId: map['loanId'] as int,
        year: map['year'] as int,
        month: map['month'] as int,
        isPaid: (map['isPaid'] as int) == 1,
        paidDate: map['paidDate'] != null
            ? DateTime.parse(map['paidDate'] as String)
            : null,
        incomeSourceId: map['incomeSourceId'] as int?,
      );
}
