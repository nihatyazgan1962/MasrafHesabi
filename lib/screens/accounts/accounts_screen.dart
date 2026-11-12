import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../providers/finance_provider.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    AccountType selectedType = AccountType.cash;
    int selectedIconCode = Icons.account_balance_wallet.codePoint;
    int selectedColor = Colors.blue.value;

    final icons = [
      Icons.account_balance_wallet,
      Icons.credit_card,
      Icons.account_balance,
      Icons.savings,
      Icons.attach_money,
      Icons.euro,
      Icons.storefront,
    ];

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.deepPurple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Yeni Hesap Ekle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Hesap Adı (Örn: Ziraat Bankası, Maaş Kartı)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Başlangıç Bakiyesi (₺)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AccountType>(
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Hesap Türü',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    items: const [
                      DropdownMenuItem(value: AccountType.cash, child: Text('Nakit Cüzdan')),
                      DropdownMenuItem(value: AccountType.bank, child: Text('Banka Hesabı')),
                      DropdownMenuItem(value: AccountType.creditCard, child: Text('Kredi Kartı')),
                      DropdownMenuItem(value: AccountType.savings, child: Text('Birikim Hesabı')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Simge Seçin', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: icons.map((icon) {
                      final isSelected = selectedIconCode == icon.codePoint;
                      return InkWell(
                        onTap: () => setModalState(() => selectedIconCode = icon.codePoint),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.indigo.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                            border: isSelected ? Border.all(color: Colors.indigo, width: 2) : null,
                          ),
                          child: Icon(icon, color: isSelected ? Colors.indigo : Colors.grey.shade700),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Renk Seçin', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: colors.map((col) {
                      final isSelected = selectedColor == col.value;
                      return InkWell(
                        onTap: () => setModalState(() => selectedColor = col.value),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: col,
                            border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                            boxShadow: isSelected ? [BoxShadow(color: col.withOpacity(0.6), blurRadius: 8)] : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      if (nameController.text.trim().isNotEmpty) {
                        final initialBal = double.tryParse(balanceController.text.replaceAll(',', '.')) ?? 0.0;
                        final newAccount = Account(
                          id: const Uuid().v4(),
                          name: nameController.text.trim(),
                          type: selectedType,
                          initialBalance: initialBal,
                          iconCode: selectedIconCode,
                          colorValue: selectedColor,
                        );
                        context.read<FinanceProvider>().addAccount(newAccount);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Hesabı Oluştur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final accounts = provider.accounts;
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesaplar ve Cüzdanlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.indigo, size: 28),
            onPressed: () => _showAddAccountDialog(context),
            tooltip: 'Hesap Ekle',
          ),
        ],
      ),
      body: accounts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Henüz eklenmiş bir hesap yok.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Hesap Ekle'),
                    onPressed: () => _showAddAccountDialog(context),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final acc = accounts[index];

                // Hesaba ait bakiye hesaplama (Başlangıç + Gelirler - Giderler)
                double currentAccBalance = acc.initialBalance;
                for (var t in provider.transactions) {
                  if (t.accountId == acc.id) {
                    if (t.type == TransactionType.income) currentAccBalance += t.amount;
                    if (t.type == TransactionType.expense || (t.type == TransactionType.payment && t.isPaid)) {
                      currentAccBalance -= t.amount;
                    }
                  }
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: acc.color.withOpacity(0.15),
                      radius: 24,
                      child: Icon(acc.icon, color: acc.color),
                    ),
                    title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(
                      acc.type == AccountType.cash
                          ? 'Nakit Cüzdan'
                          : (acc.type == AccountType.bank
                              ? 'Banka Hesabı'
                              : (acc.type == AccountType.creditCard ? 'Kredi Kartı' : 'Birikim')),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currency.format(currentAccBalance),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: currentAccBalance >= 0 ? Colors.green.shade700 : Colors.redAccent,
                          ),
                        ),
                        if (acc.initialBalance != 0)
                          Text('Açılış: ${currency.format(acc.initialBalance)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
