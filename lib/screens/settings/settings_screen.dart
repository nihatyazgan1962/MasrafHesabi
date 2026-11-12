import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/finance_provider.dart';
import '../../services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar & Bilgi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Geliştirici ve İletişim Kartı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline, color: Colors.indigo, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hakkında',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Masraf & Gelir-Gider Takip Sistemi',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Row(
                    children: [
                      Icon(Icons.person, size: 20, color: Colors.indigo),
                      SizedBox(width: 10),
                      Text('Geliştirici / İletişim:', style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(width: 6),
                      Text('Yazgan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.email, size: 20, color: Colors.indigo),
                      SizedBox(width: 10),
                      Text('E-Posta:', style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(width: 6),
                      SelectableText(
                        '1962nihat.ny@gmail.com',
                        style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.verified, size: 20, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Sürüm:', style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(width: 6),
                      Text('v1.0.0 Pro'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Yedekleme & Bulut Senkronizasyon Kartı
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.cloud_sync, color: Colors.blue),
                  ),
                  title: Text('Bulut Senkronizasyon & Yedek', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Tüm verilerinizi güvenle yedekleyin veya geri yükleyin'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download, color: Colors.green),
                  title: const Text('Yedek Dosyası Al (Dışa Aktar)'),
                  subtitle: const Text('Hesaplar, kategoriler ve tüm işlemler JSON olarak dışa aktarılır'),
                  onTap: () async {
                    try {
                      final jsonString = await storageService.exportBackupJson();
                      await Share.share(
                        jsonString,
                        subject: 'Masraf Hesabı Yedek Dosyası',
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yedek alma hatası: $e')));
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.file_upload, color: Colors.indigo),
                  title: const Text('Yedekten Geri Yükle'),
                  subtitle: const Text('Daha önce alınan JSON yedeğini yapıştırarak yükleyin'),
                  onTap: () => _showRestoreDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    final textController = TextEditingController();
    final storageService = StorageService();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yedek Geri Yükle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Yedek JSON içeriğini aşağıdaki alana yapıştırın:'),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{"version": "1.0.0", ...}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.trim().isNotEmpty) {
                final success = await storageService.importBackupJson(textController.text.trim());
                if (!ctx.mounted) return;
                if (success) {
                  await ctx.read<FinanceProvider>().refreshAll();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Yedek başarıyla yüklendi!')));
                  }
                } else {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Geçersiz yedek formatı!')));
                  }
                }
              }
            },
            child: const Text('Yükle'),
          ),
        ],
      ),
    );
  }
}
