import 'package:flutter/material.dart';

enum AccountType { cash, bank, creditCard, savings }

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final int iconCode;
  final int colorValue;

  Account({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
    required this.iconCode,
    required this.colorValue,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'initialBalance': initialBalance,
        'iconCode': iconCode,
        'colorValue': colorValue,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'],
        name: json['name'],
        type: AccountType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => AccountType.cash,
        ),
        initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
        iconCode: json['iconCode'] ?? Icons.account_balance_wallet.codePoint,
        colorValue: json['colorValue'] ?? Colors.blue.value,
      );
}