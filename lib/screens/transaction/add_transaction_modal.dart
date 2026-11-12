import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction.dart';
import '../../providers/finance_provider.dart';

class AddTransactionModal extends StatefulWidget {
  final TransactionType? initialType;
  const AddTransactionModal({super.key, this.initialType});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _selectedType;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? TransactionType.expense;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final accounts = provider.accounts;
    final categories = provider.categories.where((c) => c.type == _selectedType).toList();

    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Üst Sürükleme Çizgisi
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tür Seçimi Segmented Button
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.expense, label: Text('Gider'), icon: Icon(Icons.arrow_upward, color: Colors.red)),
                  ButtonSegment(value: TransactionType.income, label: Text('Gelir'), icon: Icon(Icons.arrow_downward, color: Colors.green)),
                  ButtonSegment(value: TransactionType.payment, label: Text('Ödeme'), icon: Icon(Icons.alarm, color: Colors.orange)),
                ],
                selected: {_selectedType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    _selectedCategoryId = null; // Kategori reset
                  });
                },
              ),
              const SizedBox(height: 16),

              // Tutar Alanı
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₺ ',
                  labelText: 'Tutar',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Lütfen bir tutar girin';
                  if (double.tryParse(val.replaceAll(',', '.')) == null) return 'Geçersiz tutar';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Başlık Alanı
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Başlık (Örn: Market alışverişi)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  prefixIcon: const Icon(Icons.edit_note),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Başlık gerekli' : null,
              ),
              const SizedBox(height: 12),

              // Hesap ve Kategori Seçimi Yan Yana
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedAccountId,
                      decoration: InputDecoration(
                        labelText: 'Hesap',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                      ),
                      items: accounts.map((acc) {
                        return DropdownMenuItem(
                          value: acc.id,
                          child: Row(
                            children: [
                              Icon(acc.icon, size: 18, color: acc.color),
                              const SizedBox(width: 8),
                              Text(acc.name, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedAccountId = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Row(
                            children: [
                              Icon(cat.icon, size: 18, color: cat.color),
                              const SizedBox(width: 8),
                              Text(cat.name, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tarih ve Saat Seçimi Yan Yana
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(_selectedTime.format(context)),
                      onPressed: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Not Ekleme
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Not / Açıklama (İsteğe bağlı)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  prefixIcon: const Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 20),

              // Kaydet Butonu
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType == TransactionType.income
                      ? Colors.green
                      : (_selectedType == TransactionType.expense ? Colors.redAccent : Colors.orange),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                icon: const Icon(Icons.check),
                label: const Text('İşlemi Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
                    final combinedDateTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );

                    final item = TransactionItem(
                      id: const Uuid().v4(),
                      title: _titleController.text.trim(),
                      amount: amount,
                      type: _selectedType,
                      accountId: _selectedAccountId ?? accounts.first.id,
                      categoryId: _selectedCategoryId ?? (categories.isNotEmpty ? categories.first.id : ''),
                      dateTime: combinedDateTime,
                      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                    );

                    final navigator = Navigator.of(context);
                    await provider.addTransaction(item);
                    if (mounted) navigator.pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
