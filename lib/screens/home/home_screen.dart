import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../providers/finance_provider.dart';
import '../accounts/accounts_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../transaction/add_transaction_modal.dart';
import '../../services/export_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFormat = DateFormat('dd MMM, HH:mm', 'tr_TR');

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. ÜST BAR: Dönem Göstergesi, Arama ve Ayarlar Butonları
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Dönem Seçici ve Değiştirici
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left, size: 22),
                                onPressed: provider.previousMonth,
                                visualDensity: VisualDensity.compact,
                              ),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: provider.selectedDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                    locale: const Locale('tr', 'TR'),
                                    helpText: 'Dönem Ayı Seçin',
                                  );
                                  if (picked != null) {
                                    provider.setPeriod(picked);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month, size: 18, color: Colors.indigo),
                                      const SizedBox(width: 6),
                                      Text(
                                        provider.currentPeriodName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, size: 22),
                                onPressed: provider.nextMonth,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),

                        // Sağ Üst Hızlı Butonlar
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.account_balance_wallet_outlined),
                              tooltip: 'Hesaplar / Cüzdanlar',
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen()));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.analytics_outlined),
                              tooltip: 'Raporlar',
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings_outlined),
                              tooltip: 'Ayarlar & Hakkında',
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'Dışa Aktar',
                              onSelected: (value) async {
                                if (value == 'pdf') {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Raporu hazırlanıyor...')));
                                  await ExportService.exportPdfReport(
                                    periodName: provider.currentPeriodName,
                                    transactions: provider.filteredTransactions,
                                    accounts: provider.accounts,
                                    categories: provider.categories,
                                    totalIncome: provider.periodIncome,
                                    totalExpense: provider.periodExpense,
                                    totalPayments: provider.periodPayments,
                                    netBalance: provider.periodNetBalance,
                                    carriedOverBalance: provider.getCarriedOverBalance(),
                                  );
                                } else if (value == 'excel') {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel Tablosu hazırlanıyor...')));
                                  await ExportService.exportExcelReport(
                                    periodName: provider.currentPeriodName,
                                    transactions: provider.filteredTransactions,
                                    accounts: provider.accounts,
                                    categories: provider.categories,
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'pdf',
                                  child: Row(
                                    children: [
                                      Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Text('PDF Olarak Aktar'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'excel',
                                  child: Row(
                                    children: [
                                      Icon(Icons.table_view, color: Colors.green, size: 20),
                                      SizedBox(width: 8),
                                      Text('Excel Olarak Aktar'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Arama Çubuğu
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Açıklama veya notlarda ara...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: provider.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => provider.setSearchQuery(''),
                              )
                            : null,
                        filled: true,
                        fillColor: theme.cardTheme.color,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: provider.setSearchQuery,
                    ),
                  ],
                ),
              ),
            ),

            // 2. GÖZE HİTAP EDEN ŞIK BAKİYE KARTI (Hero Balance Card)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade900, Colors.green.shade800, Colors.green.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade800.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.selectedAccountId == null
                                      ? 'Toplam Net Bakiye (Tüm Hesaplar)'
                                      : '${provider.accounts.firstWhere((a) => a.id == provider.selectedAccountId, orElse: () => Account(id: '', name: 'Hesap', type: AccountType.cash, iconCode: 0, colorValue: 0)).name} Bakiyesi',
                                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  alignment: Alignment.centerLeft,
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    currencyFormat.format(provider.periodNetBalance),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Aktarma / Devir Göstergesi
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Geçen Aydan Devir', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                Text(
                                  currencyFormat.format(provider.getCarriedOverBalance()),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Alt Göstergeler: Gelir, Gider, Ödeme
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCardSubStat('Gelir', '+${currencyFormat.format(provider.periodIncome)}', Icons.arrow_downward, Colors.greenAccent),
                            Container(width: 1, height: 26, color: Colors.white24),
                            _buildCardSubStat('Gider', '-${currencyFormat.format(provider.periodExpense)}', Icons.arrow_upward, Colors.redAccent),
                            Container(width: 1, height: 26, color: Colors.white24),
                            _buildCardSubStat('Ödemeler', currencyFormat.format(provider.periodPayments), Icons.alarm, Colors.amberAccent),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. HESAP FİLTRE ÇİPLERİ (Tüm Hesaplar, Nakit, Kart, vb.)
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    FilterChip(
                      selected: provider.selectedAccountId == null,
                      label: const Text('Tüm Hesaplar'),
                      avatar: const Icon(Icons.all_inbox, size: 16),
                      onSelected: (selected) => provider.selectAccount(null),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    const SizedBox(width: 8),
                    ...provider.accounts.map((acc) {
                      final isSelected = provider.selectedAccountId == acc.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(acc.name),
                          avatar: Icon(acc.icon, size: 16, color: isSelected ? Colors.white : acc.color),
                          selectedColor: acc.color.withOpacity(0.85),
                          onSelected: (selected) => provider.selectAccount(selected ? acc.id : null),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    }),
                    ActionChip(
                      label: const Text('+ Hesap Ekle'),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ],
                ),
              ),
            ),

            // 4. İŞLEM TÜRÜ FİLTRESİ (Tümü, Gelirler, Giderler, Ödemeler)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildTypeFilterChip(context, provider, null, 'Tümü'),
                    const SizedBox(width: 8),
                    _buildTypeFilterChip(context, provider, TransactionType.income, 'Gelirler'),
                    const SizedBox(width: 8),
                    _buildTypeFilterChip(context, provider, TransactionType.expense, 'Giderler'),
                    const SizedBox(width: 8),
                    _buildTypeFilterChip(context, provider, TransactionType.payment, 'Ödemeler'),
                  ],
                ),
              ),
            ),

            // 5. İŞLEM LİSTESİ BAŞLIĞI
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'İşlemler (${provider.filteredTransactions.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      provider.currentPeriodName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            // 6. İŞLEMLER LİSTESİ (Transactions)
            provider.filteredTransactions.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Bu dönem ve filtreye uygun işlem bulunamadı.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = provider.filteredTransactions[index];
                        final cat = provider.categories.firstWhere(
                          (c) => c.id == item.categoryId,
                          orElse: () => CategoryItem(id: '', name: 'Diğer', type: item.type, iconCode: Icons.category.codePoint, colorValue: Colors.grey.value),
                        );
                        final acc = provider.accounts.firstWhere(
                          (a) => a.id == item.accountId,
                          orElse: () => Account(id: '', name: 'Genel', type: AccountType.cash, iconCode: Icons.wallet.codePoint, colorValue: Colors.grey.value),
                        );

                        final isIncome = item.type == TransactionType.income;
                        final isExpense = item.type == TransactionType.expense;

                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.redAccent,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => provider.deleteTransaction(item.id),
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: cat.color.withOpacity(0.15),
                                child: Icon(cat.icon, color: cat.color, size: 20),
                              ),
                              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              subtitle: Row(
                                children: [
                                  Icon(acc.icon, size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${acc.name} • ${dateFormat.format(item.dateTime)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isIncome ? '+' : (isExpense ? '-' : '')}${currencyFormat.format(item.amount)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isIncome ? Colors.green.shade700 : (isExpense ? Colors.redAccent : Colors.orange.shade800),
                                    ),
                                  ),
                                  if (item.type == TransactionType.payment)
                                    GestureDetector(
                                      onTap: () => provider.togglePaymentStatus(item.id),
                                      child: Text(
                                        item.isPaid ? 'Ödendi ✓' : 'Bekliyor ⌛',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: item.isPaid ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: provider.filteredTransactions.length,
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),

      // ŞIK YÜZEN İŞLEM EKLEME BUTONU (FAB)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add),
        label: const Text('İşlem Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddTransactionModal(),
          );
        },
      ),
    );
  }

  Widget _buildCardSubStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildTypeFilterChip(BuildContext context, FinanceProvider provider, TransactionType? type, String label) {
    final isSelected = provider.selectedTypeFilter == type;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => provider.setTypeFilter(type),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
