import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';

class FinanceProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<Account> _accounts = [];
  List<TransactionItem> _transactions = [];
  List<CategoryItem> _categories = [];

  DateTime _selectedDate = DateTime.now(); // Aktif Dönem (Ay & Yıl)
  String? _selectedAccountId; // null ise Tüm Hesaplar
  TransactionType? _selectedTypeFilter; // null ise Tümü
  String _searchQuery = '';

  bool _isLoading = true;

  // Getters
  List<Account> get accounts => _accounts;
  List<TransactionItem> get transactions => _transactions;
  List<CategoryItem> get categories => _categories;
  DateTime get selectedDate => _selectedDate;
  String? get selectedAccountId => _selectedAccountId;
  TransactionType? get selectedTypeFilter => _selectedTypeFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  String get currentPeriodName => DateFormat('MMMM yyyy', 'tr_TR').format(_selectedDate);

  FinanceProvider() {
    _initData();
  }

  Future<void> _initData() async {
    _isLoading = true;
    notifyListeners();

    _accounts = await _storageService.loadAccounts();
    _transactions = await _storageService.loadTransactions();
    _categories = await _storageService.loadCategories();

    _isLoading = false;
    notifyListeners();
  }

  // Filtreler & Dönem Değiştirme
  void setPeriod(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, 1);
    notifyListeners();
  }

  void previousMonth() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    notifyListeners();
  }

  void nextMonth() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    notifyListeners();
  }

  void selectAccount(String? accountId) {
    _selectedAccountId = accountId;
    notifyListeners();
  }

  void setTypeFilter(TransactionType? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    notifyListeners();
  }

  // Önceki aydan devreden bakiye hesaplaması
  double getCarriedOverBalance() {
    // Seçili aydan önceki tüm işlemlerin net bakiyesi + hesapların açılış bakiyeleri
    final startOfCurrentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);

    double balance = 0;
    // Eğer tüm hesaplarsa tüm başlangıç bakiyeleri, tek hesapsa o hesap
    for (var acc in _accounts) {
      if (_selectedAccountId == null || acc.id == _selectedAccountId) {
        balance += acc.initialBalance;
      }
    }

    for (var t in _transactions) {
      if (t.dateTime.isBefore(startOfCurrentMonth)) {
        if (_selectedAccountId == null || t.accountId == _selectedAccountId) {
          if (t.type == TransactionType.income) {
            balance += t.amount;
          } else if (t.type == TransactionType.expense || (t.type == TransactionType.payment && t.isPaid)) {
            balance -= t.amount;
          }
        }
      }
    }
    return balance;
  }

  // Seçili Dönem ve Filtreye Göre İşlemler
  List<TransactionItem> get filteredTransactions {
    return _transactions.where((t) {
      // Dönem filtresi (Ay ve Yıl eşleşmeli)
      final isInPeriod = t.dateTime.year == _selectedDate.year && t.dateTime.month == _selectedDate.month;
      if (!isInPeriod) return false;

      // Hesap filtresi
      if (_selectedAccountId != null && t.accountId != _selectedAccountId) {
        return false;
      }

      // Tür filtresi
      if (_selectedTypeFilter != null && t.type != _selectedTypeFilter) {
        return false;
      }

      // Arama filtresi
      if (_searchQuery.isNotEmpty) {
        final matchesTitle = t.title.toLowerCase().contains(_searchQuery);
        final matchesNote = (t.note ?? '').toLowerCase().contains(_searchQuery);
        if (!matchesTitle && !matchesNote) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  // Dönem Gelir Toplamı
  double get periodIncome {
    double total = 0;
    for (var t in _transactions) {
      if (t.dateTime.year == _selectedDate.year && t.dateTime.month == _selectedDate.month) {
        if (_selectedAccountId == null || t.accountId == _selectedAccountId) {
          if (t.type == TransactionType.income) total += t.amount;
        }
      }
    }
    return total;
  }

  // Dönem Gider Toplamı
  double get periodExpense {
    double total = 0;
    for (var t in _transactions) {
      if (t.dateTime.year == _selectedDate.year && t.dateTime.month == _selectedDate.month) {
        if (_selectedAccountId == null || t.accountId == _selectedAccountId) {
          if (t.type == TransactionType.expense) total += t.amount;
        }
      }
    }
    return total;
  }

  // Dönem Ödemeler Toplamı (Bekleyen/Yapılan ödemeler)
  double get periodPayments {
    double total = 0;
    for (var t in _transactions) {
      if (t.dateTime.year == _selectedDate.year && t.dateTime.month == _selectedDate.month) {
        if (_selectedAccountId == null || t.accountId == _selectedAccountId) {
          if (t.type == TransactionType.payment) total += t.amount;
        }
      }
    }
    return total;
  }

  // Seçili Dönem Sonu Kümülatif Net Bakiye (Devreden Bakiye + Bu Ay Gelir - Bu Ay Gider)
  double get periodNetBalance {
    return getCarriedOverBalance() + periodIncome - periodExpense - periodPayments;
  }

  // Hesap İşlemleri
  Future<void> addAccount(Account account) async {
    _accounts.add(account);
    await _storageService.saveAccounts(_accounts);
    notifyListeners();
  }

  Future<void> deleteAccount(String accountId) async {
    _accounts.removeWhere((a) => a.id == accountId);
    if (_selectedAccountId == accountId) _selectedAccountId = null;
    await _storageService.saveAccounts(_accounts);
    notifyListeners();
  }

  // İşlem Ekleme & Silme
  Future<void> addTransaction(TransactionItem item) async {
    _transactions.add(item);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> togglePaymentStatus(String id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      final old = _transactions[index];
      _transactions[index] = TransactionItem(
        id: old.id,
        title: old.title,
        amount: old.amount,
        type: old.type,
        accountId: old.accountId,
        categoryId: old.categoryId,
        dateTime: old.dateTime,
        note: old.note,
        isPaid: !old.isPaid,
      );
      await _storageService.saveTransactions(_transactions);
      notifyListeners();
    }
  }

  // Kategori Ekleme
  Future<void> addCategory(CategoryItem category) async {
    _categories.add(category);
    await _storageService.saveCategories(_categories);
    notifyListeners();
  }

  // Yıl Sonu Ay Ay Verileri Alma
  Map<int, Map<String, double>> getYearlySummary(int year) {
    final Map<int, Map<String, double>> result = {};

    for (int month = 1; month <= 12; month++) {
      double inc = 0;
      double exp = 0;
      double pay = 0;

      for (var t in _transactions) {
        if (t.dateTime.year == year && t.dateTime.month == month) {
          if (_selectedAccountId == null || t.accountId == _selectedAccountId) {
            if (t.type == TransactionType.income) inc += t.amount;
            if (t.type == TransactionType.expense) exp += t.amount;
            if (t.type == TransactionType.payment) pay += t.amount;
          }
        }
      }

      result[month] = {
        'income': inc,
        'expense': exp,
        'payments': pay,
        'net': inc - exp - pay,
      };
    }
    return result;
  }

  // Yedek Yükleme Sonrası Yenileme
  Future<void> refreshAll() async {
    await _initData();
  }
}
