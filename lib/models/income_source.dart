import 'package:flutter/material.dart';

class IncomeSource {
  final int? id;
  final String name;
  final String iconName;
  final String colorHex;
  final bool isDefault; // default sources cannot be deleted
  final bool isActive;

  const IncomeSource({
    this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    this.isDefault = false,
    this.isActive = true,
  });

  Color get color {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blueGrey;
    }
  }

  IconData get icon => iconDataFromName(iconName);

  static IconData iconDataFromName(String name) {
    switch (name) {
      case 'salary':
        return Icons.account_balance_wallet;
      case 'business':
        return Icons.business_center;
      case 'freelance':
        return Icons.computer;
      case 'investment':
        return Icons.trending_up;
      case 'rental':
        return Icons.home_work;
      case 'gift':
        return Icons.card_giftcard;
      case 'bonus':
        return Icons.stars;
      case 'pension':
        return Icons.elderly;
      case 'part_time':
        return Icons.access_time;
      default:
        return Icons.category_outlined;
    }
  }

  // Available icon options for custom sources
  static const List<Map<String, String>> availableIcons = [
    {'name': 'salary', 'label': 'Salary'},
    {'name': 'business', 'label': 'Business'},
    {'name': 'freelance', 'label': 'Freelance'},
    {'name': 'investment', 'label': 'Investment'},
    {'name': 'rental', 'label': 'Rental'},
    {'name': 'gift', 'label': 'Gift'},
    {'name': 'bonus', 'label': 'Bonus'},
    {'name': 'pension', 'label': 'Pension'},
    {'name': 'part_time', 'label': 'Part-time'},
    {'name': 'other', 'label': 'Other'},
  ];

  // Available colour options for custom sources
  static const List<String> availableColors = [
    '#4CAF50', // green
    '#2196F3', // blue
    '#FF9800', // orange
    '#9C27B0', // purple
    '#F44336', // red
    '#00BCD4', // cyan
    '#FF5722', // deep orange
    '#607D8B', // blue grey
    '#E91E63', // pink
    '#795548', // brown
  ];

  IncomeSource copyWith({
    int? id,
    String? name,
    String? iconName,
    String? colorHex,
    bool? isDefault,
    bool? isActive,
  }) =>
      IncomeSource(
        id: id ?? this.id,
        name: name ?? this.name,
        iconName: iconName ?? this.iconName,
        colorHex: colorHex ?? this.colorHex,
        isDefault: isDefault ?? this.isDefault,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'iconName': iconName,
        'colorHex': colorHex,
        'isDefault': isDefault ? 1 : 0,
        'isActive': isActive ? 1 : 0,
      };

  factory IncomeSource.fromMap(Map<String, dynamic> map) => IncomeSource(
        id: map['id'] as int?,
        name: map['name'] as String,
        iconName: map['iconName'] as String,
        colorHex: map['colorHex'] as String,
        isDefault: (map['isDefault'] as int) == 1,
        isActive: (map['isActive'] as int) == 1,
      );
}
