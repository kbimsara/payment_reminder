import 'package:flutter/material.dart';

enum BillCategory {
  electricity,
  water,
  internet,
  rent,
  phone,
  insurance,
  subscription,
  other,
}

extension BillCategoryExtension on BillCategory {
  String get displayName {
    switch (this) {
      case BillCategory.electricity:
        return 'Electricity';
      case BillCategory.water:
        return 'Water';
      case BillCategory.internet:
        return 'Internet';
      case BillCategory.rent:
        return 'Rent';
      case BillCategory.phone:
        return 'Phone';
      case BillCategory.insurance:
        return 'Insurance';
      case BillCategory.subscription:
        return 'Subscription';
      case BillCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case BillCategory.electricity:
        return Icons.bolt;
      case BillCategory.water:
        return Icons.water_drop;
      case BillCategory.internet:
        return Icons.wifi;
      case BillCategory.rent:
        return Icons.home;
      case BillCategory.phone:
        return Icons.phone_android;
      case BillCategory.insurance:
        return Icons.security;
      case BillCategory.subscription:
        return Icons.subscriptions;
      case BillCategory.other:
        return Icons.receipt;
    }
  }

  Color get color {
    switch (this) {
      case BillCategory.electricity:
        return const Color(0xFFFFD700);
      case BillCategory.water:
        return const Color(0xFF4FC3F7);
      case BillCategory.internet:
        return const Color(0xFF81C784);
      case BillCategory.rent:
        return const Color(0xFFFF8A65);
      case BillCategory.phone:
        return const Color(0xFFBA68C8);
      case BillCategory.insurance:
        return const Color(0xFF4DB6AC);
      case BillCategory.subscription:
        return const Color(0xFFFF7043);
      case BillCategory.other:
        return const Color(0xFF90A4AE);
    }
  }

  String get value => name;

  static BillCategory fromString(String value) {
    return BillCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BillCategory.other,
    );
  }
}

class Payment {
  final int? id;
  final String title;
  final double amount;
  final int dueDay;
  final BillCategory category;
  final bool isRecurring;
  final bool isActive;
  final String? notes;
  final String? colorHex;

  const Payment({
    this.id,
    required this.title,
    required this.amount,
    required this.dueDay,
    required this.category,
    this.isRecurring = true,
    this.isActive = true,
    this.notes,
    this.colorHex,
  });

  Color get displayColor {
    if (colorHex != null && colorHex!.isNotEmpty) {
      try {
        return Color(int.parse(colorHex!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return category.color;
  }

  Payment copyWith({
    int? id,
    String? title,
    double? amount,
    int? dueDay,
    BillCategory? category,
    bool? isRecurring,
    bool? isActive,
    String? notes,
    String? colorHex,
  }) {
    return Payment(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDay: dueDay ?? this.dueDay,
      category: category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'dueDay': dueDay,
      'category': category.value,
      'isRecurring': isRecurring ? 1 : 0,
      'isActive': isActive ? 1 : 0,
      'notes': notes,
      'colorHex': colorHex,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDay: map['dueDay'] as int,
      category: BillCategoryExtension.fromString(map['category'] as String),
      isRecurring: (map['isRecurring'] as int) == 1,
      isActive: (map['isActive'] as int) == 1,
      notes: map['notes'] as String?,
      colorHex: map['colorHex'] as String?,
    );
  }

  @override
  String toString() {
    return 'Payment{id: $id, title: $title, amount: $amount, dueDay: $dueDay, category: $category}';
  }
}

class MonthlyPaymentStatus {
  final Payment payment;
  final bool isPaid;
  final DateTime? paidDate;
  final int year;
  final int month;

  const MonthlyPaymentStatus({
    required this.payment,
    required this.isPaid,
    this.paidDate,
    required this.year,
    required this.month,
  });

  DateTime get dueDate {
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = payment.dueDay > lastDay ? lastDay : payment.dueDay;
    return DateTime(year, month, day);
  }

  bool get isOverdue {
    if (isPaid) return false;
    return dueDate.isBefore(DateTime.now());
  }

  MonthlyPaymentStatus copyWith({
    Payment? payment,
    bool? isPaid,
    DateTime? paidDate,
    int? year,
    int? month,
  }) {
    return MonthlyPaymentStatus(
      payment: payment ?? this.payment,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
}
