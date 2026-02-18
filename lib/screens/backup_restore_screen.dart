import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});
  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  late final DataService _ds;
  bool _isCreatingBackup = false;
  bool _isRestoring = false;
  Map<String, dynamic>? _lastBackupInfo;

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); }
  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _createBackup() async {
    setState(() => _isCreatingBackup = true);
    try {
      final result = await _ds.getBackup(_token);
      if (!mounted) return;
      setState(() {
        _lastBackupInfo = {
          'date': result['date'] ?? result['created_at'] ?? result['createdAt'] ?? DateTime.now().toIso8601String(),
          'size': result['size'] ?? result['fileSize'] ?? '',
          'tables': result['tables'] ?? result['tablesCount'] ?? '',
          'records': result['records'] ?? result['recordsCount'] ?? '',
        };
        _isCreatingBackup = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء النسخة الاحتياطية بنجاح'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreatingBackup = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'فشل إنشاء النسخة الاحتياطية'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _restoreBackup() async {
    setState(() => _isRestoring = true);
    try {
      final result = await _ds.restoreBackup(_token, {});
      if (!mounted) return;
      setState(() => _isRestoring = false);
      final success = result['success'] == true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تمت استعادة البيانات بنجاح' : (result['message'] ?? 'فشل استعادة البيانات')),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRestoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'فشل استعادة البيانات'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showRestoreConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 28),
            const SizedBox(width: 8),
            const Text('تأكيد الاستعادة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'سيتم حذف جميع البيانات الحالية واستبدالها بالنسخة الاحتياطية. هذا الإجراء لا يمكن التراجع عنه!',
                      style: TextStyle(fontSize: 13, color: Colors.red.shade800, fontWeight: FontWeight.w600, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'هل أنت متأكد أنك تريد المتابعة؟',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textGray, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _restoreBackup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('نعم، استعادة البيانات', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tenant = auth.tenant;
    final companyName = tenant?['companyName'] ?? 'كارواتس';
    final email = tenant?['email'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي والاستعادة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.backupRestorePage),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCompanyInfoCard(companyName, email),
          const SizedBox(height: 16),
          _buildBackupSection(),
          const SizedBox(height: 16),
          if (_lastBackupInfo != null) ...[
            _buildLastBackupInfoCard(),
            const SizedBox(height: 16),
          ],
          _buildRestoreSection(),
          const SizedBox(height: 24),
          _buildInfoNotice(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoCard(String companyName, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryButton,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.storage_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        email.isNotEmpty ? email : 'لا يوجد بريد',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'إدارة قاعدة البيانات',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'النسخ الاحتياطي',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'إنشاء نسخة احتياطية كاملة من بياناتك',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.primary.withValues(alpha: 0.7)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'يتم إنشاء نسخة احتياطية كاملة تتضمن جميع البيانات المخزنة في النظام بما في ذلك السيارات والعملاء والمبيعات والحسابات المالية.',
                          style: TextStyle(fontSize: 12, color: AppColors.textGray, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isCreatingBackup ? null : _createBackup,
                    icon: _isCreatingBackup
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.backup_outlined, size: 20),
                    label: Text(
                      _isCreatingBackup ? 'جاري إنشاء النسخة...' : 'إنشاء نسخة احتياطية',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastBackupInfoCard() {
    final date = _lastBackupInfo?['date'] ?? '';
    final size = _lastBackupInfo?['size'] ?? '';
    final tables = _lastBackupInfo?['tables'] ?? '';
    final records = _lastBackupInfo?['records'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 20, color: AppColors.success),
                const SizedBox(width: 8),
                const Text(
                  'آخر نسخة احتياطية',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (date.toString().isNotEmpty)
                  _buildInfoRow(Icons.calendar_today_outlined, 'التاريخ', date.toString().split('T').first),
                if (size.toString().isNotEmpty)
                  _buildInfoRow(Icons.data_usage_outlined, 'الحجم', size.toString()),
                if (tables.toString().isNotEmpty)
                  _buildInfoRow(Icons.table_chart_outlined, 'الجداول', tables.toString()),
                if (records.toString().isNotEmpty)
                  _buildInfoRow(Icons.format_list_numbered, 'السجلات', records.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.cloud_download_outlined, color: Colors.amber.shade800, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'استعادة البيانات',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.amber.shade900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'استعادة البيانات من نسخة احتياطية سابقة',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFFFE082)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 20, color: Colors.red.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'تحذير: عند استعادة البيانات سيتم حذف جميع البيانات الحالية بشكل نهائي واستبدالها بالبيانات الموجودة في النسخة الاحتياطية. تأكد من إنشاء نسخة احتياطية جديدة قبل المتابعة.',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade800, fontWeight: FontWeight.w600, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isRestoring ? null : _showRestoreConfirmation,
                    icon: _isRestoring
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber.shade900))
                        : const Icon(Icons.restore_outlined, size: 20),
                    label: Text(
                      _isRestoring ? 'جاري استعادة البيانات...' : 'استعادة من نسخة احتياطية',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              const Text(
                'نصائح مهمة',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipRow('قم بإنشاء نسخ احتياطية بشكل دوري للحفاظ على بياناتك.'),
          const SizedBox(height: 8),
          _buildTipRow('يُنصح بإنشاء نسخة احتياطية قبل إجراء أي تغييرات كبيرة.'),
          const SizedBox(height: 8),
          _buildTipRow('لا تقم باستعادة البيانات إلا في حالة الضرورة القصوى.'),
          const SizedBox(height: 8),
          _buildTipRow('عملية الاستعادة قد تستغرق بعض الوقت حسب حجم البيانات.'),
        ],
      ),
    );
  }

  Widget _buildTipRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.circle, size: 6, color: AppColors.textMuted),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.textGray, height: 1.4),
          ),
        ),
      ],
    );
  }
}
