import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import '../models/account.dart';
import '../models/transaction.dart';

class ExportService {
  static final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  static final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  /// PDF Raporu Oluştur ve Paylaş
  static Future<void> exportPdfReport({
    required String periodName,
    required List<TransactionItem> transactions,
    required List<Account> accounts,
    required List<CategoryItem> categories,
    required double totalIncome,
    required double totalExpense,
    required double totalPayments,
    required double netBalance,
    required double carriedOverBalance,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Başlık
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MASRAF HESABI RAPORU', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                    pw.Text('Dönem: $periodName', style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(DateFormat('dd.MM.yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Özet Finansal Tablo
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryBox('Önceki Aydan Devir', currencyFormat.format(carriedOverBalance), PdfColors.blueGrey800),
                _buildSummaryBox('Toplam Gelir', currencyFormat.format(totalIncome), PdfColors.green800),
                _buildSummaryBox('Toplam Gider', currencyFormat.format(totalExpense), PdfColors.red800),
                _buildSummaryBox('Bekleyen/Ödeme', currencyFormat.format(totalPayments), PdfColors.orange800),
                _buildSummaryBox('Dönem Net Bakiye', currencyFormat.format(netBalance), PdfColors.blue800),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // İşlemler Tablosu
          pw.Text('İşlem Detayları (${transactions.length} Kayıt)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            headers: ['Tarih/Saat', 'Başlık / Not', 'Kategori', 'Hesap', 'Tür', 'Tutar'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            data: transactions.map((t) {
              final cat = categories.firstWhere((c) => c.id == t.categoryId, orElse: () => CategoryItem(id: '', name: 'Diğer', type: t.type, iconCode: 0, colorValue: 0));
              final acc = accounts.firstWhere((a) => a.id == t.accountId, orElse: () => Account(id: '', name: 'Genel', type: AccountType.cash, iconCode: 0, colorValue: 0));
              
              String typeStr = 'Gider';
              if (t.type == TransactionType.income) typeStr = 'Gelir';
              if (t.type == TransactionType.payment) typeStr = 'Ödeme';

              return [
                dateFormat.format(t.dateTime),
                t.title + (t.note != null && t.note!.isNotEmpty ? ' (${t.note})' : ''),
                cat.name,
                acc.name,
                typeStr,
                currencyFormat.format(t.amount),
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 30),
          pw.Divider(color: PdfColors.grey300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Yazgan Masraf Takip Sistemi', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              pw.Text('İletişim: 1962nihat.ny@gmail.com', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/masraf_rapor_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: '$periodName Masraf Hesabı Raporu');
  }

  static pw.Widget _buildSummaryBox(String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 3),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  /// Excel (.xlsx) Raporu Oluştur ve Paylaş
  static Future<void> exportExcelReport({
    required String periodName,
    required List<TransactionItem> transactions,
    required List<Account> accounts,
    required List<CategoryItem> categories,
  }) async {
    final excel = Excel.createExcel();
    excel.setDefaultSheet('Masraf Hesabı');
    final sheet = excel['Masraf Hesabı'];

    // Başlık Satırları
    sheet.appendRow([
      TextCellValue('Tarih'),
      TextCellValue('Saat'),
      TextCellValue('İşlem Başlığı'),
      TextCellValue('Kategori'),
      TextCellValue('Hesap'),
      TextCellValue('Tür'),
      TextCellValue('Tutar (₺)'),
      TextCellValue('Not / Açıklama'),
    ]);

    for (var t in transactions) {
      final cat = categories.firstWhere((c) => c.id == t.categoryId, orElse: () => CategoryItem(id: '', name: 'Diğer', type: t.type, iconCode: 0, colorValue: 0));
      final acc = accounts.firstWhere((a) => a.id == t.accountId, orElse: () => Account(id: '', name: 'Genel', type: AccountType.cash, iconCode: 0, colorValue: 0));

      String typeStr = 'Gider';
      if (t.type == TransactionType.income) typeStr = 'Gelir';
      if (t.type == TransactionType.payment) typeStr = 'Ödeme';

      sheet.appendRow([
        TextCellValue(DateFormat('dd.MM.yyyy').format(t.dateTime)),
        TextCellValue(DateFormat('HH:mm').format(t.dateTime)),
        TextCellValue(t.title),
        TextCellValue(cat.name),
        TextCellValue(acc.name),
        TextCellValue(typeStr),
        DoubleCellValue(t.amount),
        TextCellValue(t.note ?? ''),
      ]);
    }

    final output = await getTemporaryDirectory();
    final filePath = '${output.path}/masraf_rapor_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(filePath);
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(filePath)], text: '$periodName Masraf & Gelir-Gider Excel Raporu');
    }
  }
}
