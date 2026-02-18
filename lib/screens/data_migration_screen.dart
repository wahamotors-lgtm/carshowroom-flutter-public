import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class DataMigrationScreen extends StatefulWidget {
  const DataMigrationScreen({super.key});
  @override
  State<DataMigrationScreen> createState() => _DataMigrationScreenState();
}

class _DataMigrationScreenState extends State<DataMigrationScreen> {
  late final DataService _ds;
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isRestoringSQL = false;
  Map<String, dynamic>? _exportResult;
  Map<String, dynamic>? _importResult;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _exportData() async {
    setState(() { _isExporting = true; _exportResult = null; });
    try {
      final result = await _ds.getBackup(_token);
      if (!mounted) return;
      setState(() {
        _exportResult = {
          'date': result['date'] ?? result['created_at'] ?? DateTime.now().toIso8601String(),
          'size': result['size'] ?? result['fileSize'] ?? '',
          'tables': result['tables'] ?? result['tablesCount'] ?? '',
          'records': result['records'] ?? result['recordsCount'] ?? '',
          'success': true,
        };
        _isExporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تصدير البيانات بنجاح'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _isExporting = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'فشل تصدير البيانات'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      setState(() { _selectedFileName = file.name; _isImporting = true; _importResult = null; });

      if (file.bytes == null) {
        if (!mounted) return;
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل قراءة الملف'), backgroundColor: AppColors.error),
        );
        return;
      }

      // Parse JSON content
      Map<String, dynamic> jsonData;
      try {
        final content = utf8.decode(file.bytes!);
        jsonData = json.decode(content) as Map<String, dynamic>;
      } catch (_) {
        if (!mounted) return;
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الملف غير صالح. يجب أن يكون بصيغة JSON'), backgroundColor: AppColors.error),
        );
        return;
      }

      // Confirm before importing
      if (!mounted) return;
      final confirm = await _showImportConfirmation(file.name);
      if (confirm != true) {
        setState(() => _isImporting = false);
        return;
      }

      // Send to server
      final response = await _ds.restoreBackup(_token, jsonData);
      if (!mounted) return;
      setState(() {
        _importResult = {
          'success': response['success'] == true,
          'message': response['message'] ?? 'تمت العملية',
          'fileName': file.name,
        };
        _isImporting = false;
      });

      final success = response['success'] == true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم استيراد البيانات بنجاح' : (response['message'] ?? 'فشل استيراد البيانات')),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'فشل استيراد البيانات'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<bool?> _showImportConfirmation(String fileName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 28),
            const SizedBox(width: 8),
            const Text('تأكيد الاستيراد', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'سيتم استبدال جميع البيانات الحالية بالبيانات الموجودة في الملف. هذا الإجراء لا يمكن التراجع عنه!',
                      style: TextStyle(fontSize: 13, color: Colors.red.shade800, fontWeight: FontWeight.w600, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('الملف: $fileName', style: const TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w600)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('تأكيد الاستيراد', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreSQL() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['sql'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل قراءة الملف'), backgroundColor: AppColors.error));
        return;
      }

      // Confirm
      final confirm = await _showSQLRestoreConfirmation(file.name);
      if (confirm != true) return;

      setState(() => _isRestoringSQL = true);

      final content = utf8.decode(file.bytes!);
      final response = await _ds.databaseRestoreSql(_token, {'sql': content, 'fileName': file.name});

      if (!mounted) return;
      setState(() => _isRestoringSQL = false);

      final success = response['success'] == true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تمت استعادة قاعدة البيانات بنجاح' : (response['message'] ?? 'فشل استعادة قاعدة البيانات')),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRestoringSQL = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'فشل استعادة قاعدة البيانات'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<bool?> _showSQLRestoreConfirmation(String fileName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 8),
            const Text('استعادة SQL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.dangerous_outlined, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text('عملية خطيرة!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.red.shade700)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'سيتم تنفيذ أوامر SQL مباشرة على قاعدة البيانات. قد يتسبب ذلك في فقدان البيانات بشكل دائم.',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade800, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('الملف: $fileName', style: const TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w600)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('تنفيذ', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نقل البيانات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.dataMigration),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppGradients.primaryButton,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.sync_alt, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('نقل البيانات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('تصدير واستيراد بيانات النظام', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Export Section
          _buildSectionCard(
            icon: Icons.cloud_upload_outlined,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.primary.withValues(alpha: 0.1),
            title: 'تصدير البيانات',
            subtitle: 'إنشاء نسخة كاملة من جميع البيانات بصيغة JSON',
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(child: Text('يتم تصدير جميع البيانات بما فيها السيارات والعملاء والمبيعات والمصاريف والحسابات.', style: TextStyle(fontSize: 12, color: AppColors.textGray, height: 1.5))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportData,
                    icon: _isExporting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download_outlined, size: 20),
                    label: Text(_isExporting ? 'جاري التصدير...' : 'تصدير البيانات', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  ),
                ),
                // Export result
                if (_exportResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
                    child: Column(
                      children: [
                        const Row(children: [
                          Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                          SizedBox(width: 6),
                          Text('تم التصدير بنجاح', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                        ]),
                        const SizedBox(height: 8),
                        if ((_exportResult!['date'] ?? '').toString().isNotEmpty)
                          _infoRow('التاريخ', _exportResult!['date'].toString().split('T').first),
                        if ((_exportResult!['tables'] ?? '').toString().isNotEmpty)
                          _infoRow('الجداول', _exportResult!['tables'].toString()),
                        if ((_exportResult!['records'] ?? '').toString().isNotEmpty)
                          _infoRow('السجلات', _exportResult!['records'].toString()),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Import Section
          _buildSectionCard(
            icon: Icons.cloud_download_outlined,
            iconColor: Colors.amber.shade800,
            iconBgColor: Colors.amber.shade100,
            title: 'استيراد البيانات',
            subtitle: 'استيراد بيانات من ملف JSON',
            borderColor: Colors.amber.shade200,
            headerBgColor: Colors.amber.shade50,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red.shade700),
                      const SizedBox(width: 10),
                      Expanded(child: Text('تحذير: سيتم استبدال جميع البيانات الحالية بالبيانات المستوردة.', style: TextStyle(fontSize: 12, color: Colors.red.shade800, fontWeight: FontWeight.w600, height: 1.5))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isImporting ? null : _importData,
                    icon: _isImporting
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber.shade900))
                        : const Icon(Icons.upload_file_outlined, size: 20),
                    label: Text(
                      _isImporting ? 'جاري الاستيراد...' : 'اختيار ملف JSON واستيراد',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  ),
                ),
                if (_selectedFileName != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('الملف: $_selectedFileName', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ]),
                ],
                // Import result
                if (_importResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _importResult!['success'] == true ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: (_importResult!['success'] == true ? AppColors.success : AppColors.error).withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Icon(
                        _importResult!['success'] == true ? Icons.check_circle_outline : Icons.error_outline,
                        size: 16,
                        color: _importResult!['success'] == true ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(
                        _importResult!['message']?.toString() ?? '',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _importResult!['success'] == true ? AppColors.success : AppColors.error),
                      )),
                    ]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SQL Restore Section
          _buildSectionCard(
            icon: Icons.storage_outlined,
            iconColor: AppColors.error,
            iconBgColor: AppColors.error.withValues(alpha: 0.1),
            title: 'استعادة SQL',
            subtitle: 'استعادة قاعدة البيانات من ملف SQL (متقدم)',
            borderColor: AppColors.error.withValues(alpha: 0.3),
            headerBgColor: const Color(0xFFFEF2F2),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.dangerous_outlined, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text('للمستخدمين المتقدمين فقط', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.red.shade700)),
                      ]),
                      const SizedBox(height: 6),
                      Text('سيتم تنفيذ أوامر SQL مباشرة على قاعدة البيانات. استخدم هذا الخيار بحذر شديد.',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade800, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isRestoringSQL ? null : _restoreSQL,
                    icon: _isRestoringSQL
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.terminal, size: 20),
                    label: Text(_isRestoringSQL ? 'جاري التنفيذ...' : 'اختيار ملف SQL واستعادة', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  const Text('نصائح مهمة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                ]),
                const SizedBox(height: 12),
                _tipRow('قم بتصدير بياناتك بشكل دوري كنسخة احتياطية.'),
                const SizedBox(height: 6),
                _tipRow('تأكد من إنشاء نسخة احتياطية قبل أي عملية استيراد.'),
                const SizedBox(height: 6),
                _tipRow('ملفات JSON هي الطريقة الموصى بها لنقل البيانات.'),
                const SizedBox(height: 6),
                _tipRow('استخدم استعادة SQL فقط عند الضرورة القصوى.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required Widget child,
    Color? borderColor,
    Color? headerBgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(13), topRight: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: iconColor)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _tipRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.circle, size: 6, color: AppColors.textMuted)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textGray, height: 1.4))),
      ],
    );
  }
}
