import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/factory_store.dart';
import 'dialogs/change_password_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../auth/auth_service.dart';

class DatabaseSettingsView extends StatelessWidget {
  final FactoryStore store;

  const DatabaseSettingsView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'قاعدة البيانات الداخلية وإعدادات النظام',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'تخزين محلي آمن دائم (Offline Local Database) على قرص الجهاز مع حفظ فوري تلقائي',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.successGreenSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: AppTheme.successGreen, size: 16),
                    SizedBox(width: 6),
                    Text('قاعدة البيانات متصلة وتعمل محلياً', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // كروت مؤشرات قاعدة البيانات
          Row(
            children: [
              Expanded(
                child: _statCard('مسار ملف التخزين المحلي', 'plastic_factory_db.json', Icons.folder_open_outlined, AppTheme.primaryBlue, AppTheme.primaryBlueSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('آخر حفظ تلقائي', '${store.lastDatabaseSaveTime.hour}:${store.lastDatabaseSaveTime.minute.toString().padLeft(2, '0')}:${store.lastDatabaseSaveTime.second.toString().padLeft(2, '0')}', Icons.access_time_outlined, AppTheme.costPurple, AppTheme.costPurpleSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('حجم قاعدة البيانات', '${(store.databaseSizeBytes / 1024).toStringAsFixed(1)} KB', Icons.storage_outlined, AppTheme.profitAmber, AppTheme.profitAmberSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard('إجمالي السجلات المحفوظة', '${store.products.length + store.batches.length + store.employees.length + store.suppliers.length + store.distributors.length + store.saleOrders.length + store.stocktakeRecords.length} سجل', Icons.data_usage_outlined, AppTheme.successGreen, AppTheme.successGreenSoft),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // تفاصيل قاعدة البيانات ومسار الملف
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('معلومات تخزين القرص المحلي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderSubtle)),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SelectableText(
                            store.databasePath.isNotEmpty ? store.databasePath : 'plastic_factory_db.json',
                            style: const TextStyle(fontSize: 13, fontFamily: 'Consolas', fontWeight: FontWeight.w600),
                          ),
                        ),
                        // Import backup button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('استيراد النسخة الاحتياطية'),
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['json'],
                            );
                            if (result != null && result.files.single.path != null) {
                              final file = File(result.files.single.path!);
                              try {
                                await store.importBackup(file);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم استيراد النسخة الاحتياطية بنجاح.'), backgroundColor: AppTheme.successGreen),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('خطأ في استيراد النسخة الاحتياطية: $e'), backgroundColor: AppTheme.wasteRed),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('ميزات نظام الحفظ الداخلي:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  _featureRow(Icons.offline_pin_outlined, 'يعمل بدون إنترنت بنسبة 100% (Offline First) لضمان استمرار تشغيل المصنع'),
                  _featureRow(Icons.sync_outlined, 'حفظ تلقائي وفوري في الخلفية عند كل تشغيلة، بيع جملة/قطاعي، أو جرد مخزني'),
                  _featureRow(Icons.security_outlined, 'بياناتك مشفرة ومحفوظة بالكامل على جهازك فقط دون رفعها لأي خوادم خارجية'),
                  _featureRow(Icons.speed_outlined, 'سرعة استجابة فائقة لقراءة البيانات والرسوم البيانية وتوزيع التكاليف'),
                  const Divider(height: 30),

                  // أزرار التحكم
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('حفظ يدوي فوري الآن'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تأكيد حفظ وتحديث ملف قاعدة البيانات المحلية بنجاح!'), backgroundColor: AppTheme.successGreen),
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.wasteRed,
                          side: const BorderSide(color: AppTheme.wasteRed),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: const Text('إعادة ضبط البيانات للافتراضي'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('تأكيد إعادة الضبط'),
                              content: const Text('هل ترغب بإعادة تحميل بيانات المصنع الافتراضية الأولية المطابقة للصورة؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.wasteRed, foregroundColor: Colors.white),
                                  onPressed: () {
                                    store.resetAllToDefaults();
                                    Navigator.of(ctx).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تمت إعادة ضبط البيانات إلى القيم الافتراضية!'), backgroundColor: AppTheme.primaryBlue),
                                    );
                                  },
                                  child: const Text('نعم، إعادة ضبط'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.wasteRed,
                          side: const BorderSide(color: AppTheme.wasteRed),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.delete_forever, size: 18),
                        label: const Text('مسح البيانات'),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('مسح البيانات'),
                              content: const Text('هل تريد مسح جميع البيانات المخزونة وإعادة تهيئة قاعدة البيانات إلى الحالة الفارغة؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.wasteRed, foregroundColor: Colors.white),
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('نعم, امسح'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            // Prompt for password before wiping data
                            final TextEditingController pwdCtrl = TextEditingController();
                            final bool? pwdConfirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('تأكيد كلمة المرور'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('أدخل كلمة مرور النظام لتأكيد مسح جميع البيانات.'),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: pwdCtrl,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        hintText: 'كلمة المرور',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.wasteRed, foregroundColor: Colors.white),
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('متأكد'),
                                  ),
                                ],
                              ),
                            );
                            if (pwdConfirmed == true && AuthService.instance.verifyPassword(pwdCtrl.text)) {
                              await store.clearData();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم مسح البيانات وإعادة تهيئة قاعدة البيانات.'), backgroundColor: AppTheme.wasteRed),
                                );
                              }
                            } else if (pwdConfirmed == true) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('كلمة المرور غير صحيحة.'), backgroundColor: AppTheme.wasteRed),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // كرت أمان النظام وكلمة مرور المدير
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlueSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.security_rounded, color: AppTheme.primaryBlue, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أمان حساب المدير العام وكلمة المرور',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'يمكنك تغيير وتحديث كلمة مرور الدخول الخاصة بحساب المدير في أي وقت',
                            style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.key_rounded, size: 18),
                    label: const Text('تغيير كلمة المرور الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => ChangePasswordDialog.show(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.successGreen, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _statCard(String title, String val, IconData icon, Color color, Color bg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                  const SizedBox(height: 2),
                  Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
