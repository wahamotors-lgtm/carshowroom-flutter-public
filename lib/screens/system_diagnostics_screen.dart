import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class SystemDiagnosticsScreen extends StatefulWidget {
  const SystemDiagnosticsScreen({super.key});
  @override
  State<SystemDiagnosticsScreen> createState() => _SystemDiagnosticsScreenState();
}

class _SystemDiagnosticsScreenState extends State<SystemDiagnosticsScreen> {
  late final DataService _ds;
  bool _isLoading = true;
  List<_DiagnosticResult> _results = [];

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _runDiagnostics();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _runDiagnostics() async {
    setState(() { _isLoading = true; _results = []; });

    final List<_DiagnosticResult> results = [];
    final stopwatch = Stopwatch()..start();

    // 1) API Health Check
    try {
      final health = await _ds.healthCheck();
      final status = health['status'] ?? health['message'] ?? 'ok';
      results.add(_DiagnosticResult(
        title: 'اتصال الخادم (API)',
        subtitle: 'حالة الخادم: $status',
        icon: Icons.cloud_done_outlined,
        passed: true,
        duration: '${stopwatch.elapsedMilliseconds}ms',
      ));
    } catch (e) {
      results.add(_DiagnosticResult(
        title: 'اتصال الخادم (API)',
        subtitle: e is ApiException ? e.message : 'فشل الاتصال بالخادم',
        icon: Icons.cloud_off_outlined,
        passed: false,
        duration: '${stopwatch.elapsedMilliseconds}ms',
      ));
    }

    // 2) Token validity check
    final token = _token;
    if (token.isNotEmpty) {
      results.add(_DiagnosticResult(
        title: 'صلاحية الجلسة',
        subtitle: 'الرمز المميز موجود (${token.length} حرف)',
        icon: Icons.verified_user_outlined,
        passed: true,
      ));
    } else {
      results.add(_DiagnosticResult(
        title: 'صلاحية الجلسة',
        subtitle: 'لا يوجد رمز مميز - يرجى تسجيل الدخول',
        icon: Icons.no_accounts_outlined,
        passed: false,
      ));
    }

    // 3) Cars count check
    try {
      final cars = await _ds.getCars(_token);
      results.add(_DiagnosticResult(
        title: 'بيانات السيارات',
        subtitle: 'تم تحميل ${cars.length} سيارة بنجاح',
        icon: Icons.directions_car_outlined,
        passed: true,
        count: cars.length,
      ));
    } catch (e) {
      results.add(_DiagnosticResult(
        title: 'بيانات السيارات',
        subtitle: e is ApiException ? e.message : 'فشل تحميل بيانات السيارات',
        icon: Icons.directions_car_outlined,
        passed: false,
      ));
    }

    // 4) Customers count check
    try {
      final customers = await _ds.getCustomers(_token);
      results.add(_DiagnosticResult(
        title: 'بيانات العملاء',
        subtitle: 'تم تحميل ${customers.length} عميل بنجاح',
        icon: Icons.people_outline,
        passed: true,
        count: customers.length,
      ));
    } catch (e) {
      results.add(_DiagnosticResult(
        title: 'بيانات العملاء',
        subtitle: e is ApiException ? e.message : 'فشل تحميل بيانات العملاء',
        icon: Icons.people_outline,
        passed: false,
      ));
    }

    // 5) Sales count check
    try {
      final sales = await _ds.getSales(_token);
      results.add(_DiagnosticResult(
        title: 'بيانات المبيعات',
        subtitle: 'تم تحميل ${sales.length} عملية بيع بنجاح',
        icon: Icons.point_of_sale_outlined,
        passed: true,
        count: sales.length,
      ));
    } catch (e) {
      results.add(_DiagnosticResult(
        title: 'بيانات المبيعات',
        subtitle: e is ApiException ? e.message : 'فشل تحميل بيانات المبيعات',
        icon: Icons.point_of_sale_outlined,
        passed: false,
      ));
    }

    // 6) Containers check
    try {
      final containers = await _ds.getContainers(_token);
      results.add(_DiagnosticResult(
        title: 'بيانات الحاويات',
        subtitle: 'تم تحميل ${containers.length} حاوية بنجاح',
        icon: Icons.inventory_2_outlined,
        passed: true,
        count: containers.length,
      ));
    } catch (e) {
      results.add(_DiagnosticResult(
        title: 'بيانات الحاويات',
        subtitle: e is ApiException ? e.message : 'فشل تحميل بيانات الحاويات',
        icon: Icons.inventory_2_outlined,
        passed: false,
      ));
    }

    // 7) Database backup history
    try {
      final backups = await _ds.getDatabaseBackupHistory(_token);
      results.add(_DiagnosticResult(
        title: 'سجل النسخ الاحتياطية',
        subtitle: 'تم العثور على ${backups.length} نسخة احتياطية',
        icon: Icons.backup_outlined,
        passed: true,
        count: backups.length,
      ));
    } catch (e) {
      results.add(_DiagnosticResult(
        title: 'سجل النسخ الاحتياطية',
        subtitle: e is ApiException ? e.message : 'فشل تحميل سجل النسخ الاحتياطية',
        icon: Icons.backup_outlined,
        passed: false,
      ));
    }

    // 8) Settings check
    try {
      final settings = await _ds.getSettings(_token);
      results.add(_DiagnosticResult(
        title: 'إعدادات النظام',
        subtitle: 'تم تحميل الإعدادات بنجاح (${settings.keys.length} إعداد)',
        icon: Icons.settings_outlined,
        passed: true,
      ));
    } catch (e) {
      results.add(_DiagnosticResult(
        title: 'إعدادات النظام',
        subtitle: e is ApiException ? e.message : 'فشل تحميل الإعدادات',
        icon: Icons.settings_outlined,
        passed: false,
      ));
    }

    stopwatch.stop();

    if (!mounted) return;
    setState(() { _results = results; _isLoading = false; });
  }

  int get _passedCount => _results.where((r) => r.passed).length;
  int get _failedCount => _results.where((r) => !r.passed).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فحص النظام', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.dashboard),
      body: _isLoading
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              const Text('جاري فحص النظام...', style: TextStyle(color: AppColors.textGray, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('يتم التحقق من جميع الخدمات', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            ]))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _runDiagnostics,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  // Summary card
                  _buildSummaryCard(),
                  const SizedBox(height: 14),

                  // Results
                  ..._results.map(_buildResultCard),
                  const SizedBox(height: 14),

                  // Re-run button
                  Center(child: ElevatedButton.icon(
                    onPressed: _runDiagnostics,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('إعادة الفحص', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final allPassed = _failedCount == 0;
    final color = allPassed ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final gradEnd = allPassed ? const Color(0xFF059669) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, gradEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        Icon(allPassed ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: Colors.white, size: 48),
        const SizedBox(height: 12),
        Text(
          allPassed ? 'جميع الفحوصات ناجحة' : 'يوجد مشاكل تحتاج مراجعة',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _summaryBadge('$_passedCount ناجح', Colors.white.withValues(alpha: 0.2)),
          const SizedBox(width: 12),
          if (_failedCount > 0) _summaryBadge('$_failedCount فاشل', Colors.white.withValues(alpha: 0.3)),
        ]),
      ]),
    );
  }

  Widget _summaryBadge(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildResultCard(_DiagnosticResult result) {
    final statusColor = result.passed ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(result.icon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(result.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 3),
            Text(result.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Icon(result.passed ? Icons.check_circle : Icons.cancel, color: statusColor, size: 26),
            if (result.duration != null) ...[
              const SizedBox(height: 4),
              Text(result.duration!, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ]),
        ]),
      ),
    );
  }
}

class _DiagnosticResult {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool passed;
  final String? duration;
  final int? count;

  _DiagnosticResult({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.passed,
    this.duration,
    this.count,
  });
}
