import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/transaction.dart';
import '../../providers/finance_provider.dart';
import '../../services/export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar & Analizler'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.indigo,
          labelColor: Colors.indigo,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_view_month), text: 'Aylık Rapor'),
            Tab(icon: Icon(Icons.auto_graph), text: 'Yıllık Döküm'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.share, color: Colors.indigo),
            tooltip: 'Raporu Dışa Aktar',
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
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('PDF Olarak İndir / Paylaş'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_view, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Excel (.xlsx) Aktar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonthlyReport(context, provider),
          _buildYearlyReport(context, provider),
        ],
      ),
    );
  }

  // AYLIK RAPOR SEKMESİ
  Widget _buildMonthlyReport(BuildContext context, FinanceProvider provider) {
    final carriedOver = provider.getCarriedOverBalance();
    final income = provider.periodIncome;
    final expense = provider.periodExpense;
    final payments = provider.periodPayments;
    final net = provider.periodNetBalance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dönem Başlığı
          Center(
            child: Text(
              '${provider.currentPeriodName} Finansal Durumu',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),

          // Kümülatif & Devir Kartı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryRow('Önceki Aydan Devir Bakiye', currencyFormat.format(carriedOver), Colors.blueGrey),
                  const Divider(height: 20),
                  _buildSummaryRow('Bu Ay Toplam Gelir', '+${currencyFormat.format(income)}', Colors.green),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Bu Ay Toplam Gider', '-${currencyFormat.format(expense)}', Colors.redAccent),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Bekleyen / Ödemeler', '-${currencyFormat.format(payments)}', Colors.orange),
                  const Divider(height: 20),
                  _buildSummaryRow(
                    'Dönem Sonu Toplam Net',
                    currencyFormat.format(net),
                    net >= 0 ? Colors.green.shade700 : Colors.red,
                    isBold: true,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Kategori Dağılım Pasta Grafiği
          const Text('Gider Kategorileri Dağılımı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildExpensePieChart(provider),

          const SizedBox(height: 24),
          // Hızlı Butonlar
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF Raporu'),
                  onPressed: () => ExportService.exportPdfReport(
                    periodName: provider.currentPeriodName,
                    transactions: provider.filteredTransactions,
                    accounts: provider.accounts,
                    categories: provider.categories,
                    totalIncome: income,
                    totalExpense: expense,
                    totalPayments: payments,
                    netBalance: net,
                    carriedOverBalance: carriedOver,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Excel Raporu'),
                  onPressed: () => ExportService.exportExcelReport(
                    periodName: provider.currentPeriodName,
                    transactions: provider.filteredTransactions,
                    accounts: provider.accounts,
                    categories: provider.categories,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // YILLIK RAPOR SEKMESİ (Ay Ay Karşılaştırma)
  Widget _buildYearlyReport(BuildContext context, FinanceProvider provider) {
    final year = provider.selectedDate.year;
    final summary = provider.getYearlySummary(year);

    final monthNames = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];

    double totalYearIncome = 0;
    double totalYearExpense = 0;

    summary.forEach((m, data) {
      totalYearIncome += data['income']!;
      totalYearExpense += data['expense']!;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Yıllık Toplam Gelir', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(currencyFormat.format(totalYearIncome), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Yıllık Toplam Gider', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(currencyFormat.format(totalYearExpense), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Yıl Sonu Farkı', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        currencyFormat.format(totalYearIncome - totalYearExpense),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (totalYearIncome - totalYearExpense) >= 0 ? Colors.indigo : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Ay Ay Finansal Döküm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final data = summary[month]!;
              final inc = data['income']!;
              final exp = data['expense']!;
              final net = data['net']!;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(monthNames[month], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gelir: +${currencyFormat.format(inc)}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                            Text('Gider: -${currencyFormat.format(exp)}', style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          currencyFormat.format(net),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: net >= 0 ? Colors.green.shade800 : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpensePieChart(FinanceProvider provider) {
    final expenses = provider.filteredTransactions.where((t) => t.type == TransactionType.expense).toList();

    if (expenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Bu dönem için gider kaydı bulunamadı.')),
        ),
      );
    }

    // Kategori toplamları
    final Map<String, double> catTotals = {};
    for (var e in expenses) {
      catTotals[e.categoryId] = (catTotals[e.categoryId] ?? 0) + e.amount;
    }

    final sections = catTotals.entries.map((entry) {
      final cat = provider.categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => CategoryItem(id: '', name: 'Diğer', type: TransactionType.expense, iconCode: 0, colorValue: Colors.grey.value),
      );

      return PieChartSectionData(
        value: entry.value,
        color: cat.color,
        title: '${cat.name}\n${currencyFormat.format(entry.value)}',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 36,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, Color color, {bool isBold = false, double size = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: size, color: Colors.grey.shade700, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
