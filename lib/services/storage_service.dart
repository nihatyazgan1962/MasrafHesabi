import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import 'package:flutter/material.dart';

class StorageService {
  static const String _kAccountsKey = 'app_accounts_v1';
  static const String _kTransactionsKey = 'app_transactions_v1';
  static const String _kCategoriesKey = 'app_categories_v1';

  // Varsayılan Hesaplar
  static List<Account> getDefaultAccounts() {
    return [
      Account(
        id: 'acc_cash',
        name: 'Nakit Cüzdan',
        type: AccountType.cash,
        initialBalance: 0,
        iconCode: Icons.wallet.codePoint,
        colorValue: Colors.green.value,
      ),
      Account(
        id: 'acc_bank',
        name: 'Banka Hesabı',
        type: AccountType.bank,
        initialBalance: 0,
        iconCode: Icons.account_balance.codePoint,
        colorValue: Colors.blue.value,
      ),
      Account(
        id: 'acc_card',
        name: 'Kredi Kartı',
        type: AccountType.creditCard,
        initialBalance: 0,
        iconCode: Icons.credit_card.codePoint,
        colorValue: Colors.deepPurple.value,
      ),
    ];
  }

  // Varsayılan Kategoriler
  static List<CategoryItem> getDefaultCategories() {
    return [
      CategoryItem(
        id: 'cat_salary',
        name: 'Maaş / Gelir',
        type: TransactionType.income,
        iconCode: Icons.payments.codePoint,
        colorValue: Colors.green.value,
      ),
      CategoryItem(
        id: 'cat_market',
        name: 'Market & Gıda',
        type: TransactionType.expense,
        iconCode: Icons.shopping_cart.codePoint,
        colorValue: Colors.red.shade400.value,
      ),
      CategoryItem(
        id: 'cat_bills',
        name: 'Faturalar',
        type: TransactionType.expense,
        iconCode: Icons.receipt_long.codePoint,
        colorValue: Colors.redAccent.value,
      ),
      CategoryItem(
        id: 'cat_rent',
        name: 'Kira / Aidat',
        type: TransactionType.payment,
        iconCode: Icons.home.codePoint,
        colorValue: Colors.indigo.value,
      ),
      CategoryItem(
        id: 'cat_transport',
        name: 'Ulaşım & Yakıt',
        type: TransactionType.expense,
        iconCode: Icons.directions_car.codePoint,
        colorValue: Colors.red.shade700.value,
      ),
      CategoryItem(
        id: 'cat_other_inc',
        name: 'Ek Gelir',
        type: TransactionType.income,
        iconCode: Icons.trending_up.codePoint,
        colorValue: Colors.green.shade700.value,
      ),
    ];
  }

  Future<List<Account>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_kAccountsKey);
    if (jsonString == null || jsonString.isEmpty) {
      final defaults = getDefaultAccounts();
      await saveAccounts(defaults);
      return defaults;
    }
    final List list = jsonDecode(jsonString);
    return list.map((e) => Account.fromJson(e)).toList();
  }

  Future<void> saveAccounts(List<Account> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(accounts.map((e) => e.toJson()).toList());
    await prefs.setString(_kAccountsKey, jsonString);
  }

  Future<List<TransactionItem>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_kTransactionsKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    final List list = jsonDecode(jsonString);
    return list.map((e) => TransactionItem.fromJson(e)).toList();
  }

  Future<void> saveTransactions(List<TransactionItem> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(transactions.map((e) => e.toJson()).toList());
    await prefs.setString(_kTransactionsKey, jsonString);
  }

  Future<List<CategoryItem>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_kCategoriesKey);
    if (jsonString == null || jsonString.isEmpty) {
      final defaults = getDefaultCategories();
      await saveCategories(defaults);
      return defaults;
    }
    final List list = jsonDecode(jsonString);
    return list.map((e) => CategoryItem.fromJson(e)).toList();
  }

  Future<void> saveCategories(List<CategoryItem> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(categories.map((e) => e.toJson()).toList());
    await prefs.setString(_kCategoriesKey, jsonString);
  }

  // Tüm Verileri JSON Olarak Dışa Aktar (Yedekleme)
  Future<String> exportBackupJson() async {
    final accounts = await loadAccounts();
    final transactions = await loadTransactions();
    final categories = await loadCategories();

    final data = {
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'accounts': accounts.map((e) => e.toJson()).toList(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  // JSON Yedeğinden Geri Yükle
  Future<bool> importBackupJson(String jsonString) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      if (data.containsKey('accounts')) {
        final List accList = data['accounts'];
        final accounts = accList.map((e) => Account.fromJson(e)).toList();
        await saveAccounts(accounts);
      }
      if (data.containsKey('transactions')) {
        final List txList = data['transactions'];
        final transactions = txList.map((e) => TransactionItem.fromJson(e)).toList();
        await saveTransactions(transactions);
      }
      if (data.containsKey('categories')) {
        final List catList = data['categories'];
        final categories = catList.map((e) => CategoryItem.fromJson(e)).toList();
        await saveCategories(categories);
      }
      return true;
    } catch (e) {
      debugPrint('Backup import error: $e');
      return false;
    }
  }
}
