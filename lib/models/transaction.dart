import 'package:flutter/material.dart';

enum TransactionType { income, expense, payment }

class CategoryItem {
  final String id;
  final String name;
  final TransactionType type;
  final int iconCode;
  final int colorValue;

  CategoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCode,
    required this.colorValue,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'iconCode': iconCode,
        'colorValue': colorValue,
      };

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
        id: json['id'],
        name: json['name'],
        type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TransactionType.expense,
        ),
        iconCode: json['iconCode'] ?? Icons.category.codePoint,
        colorValue: json['colorValue'] ?? Colors.teal.value,
      );
}

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String accountId;
  final String categoryId;
  final DateTime dateTime;
  final String? note;
  final bool isPaid; // Ödemeler için tamamlandı/bekliyor kontrolü

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.accountId,
    required this.categoryId,
    required this.dateTime,
    this.note,
    this.isPaid = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'accountId': accountId,
        'categoryId': categoryId,
        'dateTime': dateTime.toIso8601String(),
        'note': note,
        'isPaid': isPaid,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
        id: json['id'],
        title: json['title'],
        amount: (json['amount'] as num).toDouble(),
        type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TransactionType.expense,
        ),
        accountId: json['accountId'],
        categoryId: json['categoryId'],
        dateTime: DateTime.parse(json['dateTime']),
        note: json['note'],
        isPaid: json['isPaid'] ?? true,
      );
}
