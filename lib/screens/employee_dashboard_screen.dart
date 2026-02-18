import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});
  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  late final DataService _ds;
  bool _isLoading = true;
  String? _error;

  // Stats
  int _salesToday = 0;
  int _assignedCars = 0;
  String _employeeName = '';

  // Activity logs
  List<Map<String, dynamic>> _activityLogs = [];

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _loadAll();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _employeeName = auth.employee?['name'] ?? auth.employee?['employee_name'] ?? 'الموظف';

      final results = await Future.wait([
        _ds.getEmployeeActivityLogs(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getSales(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getCars(_token).catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (!mounted) return;

      final logs = results[0] as List<Map<String, dynamic>>;
      final sales = results[1] as List<Map<String, dynamic>>;
      final cars = results[2] as List<Map<String, dynamic>>;

      // Today's sales
      final today = DateTime.now().toIso8601String().split('T').first;
      final todaySales = sales.where((s) => (s['sale_date'] ?? s['saleDate'] ?? '').toString().split('T').first == today).toList();

      // Assigned cars (in_showroom or in_stock)
      final assigned = cars.where((c) => c['status'] == 'in_showroom' || c['status'] == 'in_stock').toList();

      setState(() {
        _activityLogs = logs.take(20).toList();
        _salesToday = todaySales.length;
        _assignedCars = assigned.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل البيانات'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الموظف', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.employeeDashboard),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.textGray)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAll,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: const Text('إعادة المحاولة'),
                  ),
                ]))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      _buildWelcomeBanner(),
                      const SizedBox(height: 14),
                      _buildStatsRow(),
                      const SizedBox(height: 14),
                      _buildActivitySection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.person_outline, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('مرحباً، $_employeeName', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('لوحة تحكم الموظف', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _buildStatsRow() {
    return Row(children: [
      Expanded(child: _statCard('مبيعات اليوم', '$_salesToday', Icons.point_of_sale, const Color(0xFF10B981))),
      const SizedBox(width: 10),
      Expanded(child: _statCard('سيارات متاحة', '$_assignedCars', Icons.directions_car, const Color(0xFF3B82F6))),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.9))),
          ),
        ])),
      ]),
    );
  }

  Widget _buildActivitySection() {
    return _cardWrapper(
      icon: Icons.history,
      iconColor: const Color(0xFF8B5CF6),
      title: 'سجل النشاط الأخير',
      child: _activityLogs.isEmpty
          ? _emptyState(Icons.history_outlined, 'لا توجد سجلات نشاط')
          : Column(children: _activityLogs.map((log) {
              final action = log['action'] ?? log['activity'] ?? '';
              final details = log['details'] ?? log['description'] ?? '';
              final date = log['created_at'] ?? log['createdAt'] ?? log['date'] ?? '';
              final module = log['module'] ?? log['entity_type'] ?? log['entityType'] ?? '';

              IconData logIcon;
              Color logColor;
              switch (action.toString().toLowerCase()) {
                case 'create': case 'add': logIcon = Icons.add_circle_outline; logColor = AppColors.success; break;
                case 'update': case 'edit': logIcon = Icons.edit_outlined; logColor = const Color(0xFF2563EB); break;
                case 'delete': case 'remove': logIcon = Icons.delete_outline; logColor = AppColors.error; break;
                case 'login': logIcon = Icons.login; logColor = AppColors.primary; break;
                case 'logout': logIcon = Icons.logout; logColor = const Color(0xFFD97706); break;
                default: logIcon = Icons.history; logColor = AppColors.textMuted;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: logColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(logIcon, color: logColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_actionLabel(action.toString()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    if (details.toString().isNotEmpty)
                      Text(details.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (date.toString().isNotEmpty)
                      Text(date.toString().split('T').first, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ])),
                  if (module.toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(4)),
                      child: Text(module.toString(), style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    ),
                ]),
              );
            }).toList()),
    );
  }

  // ── Helpers ──

  Widget _cardWrapper({required IconData icon, required Color iconColor, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark))),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _emptyState(IconData icon, String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(children: [
        Icon(icon, size: 36, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text(msg, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ]),
    );
  }

  String _actionLabel(String action) {
    switch (action.toLowerCase()) {
      case 'create': case 'add': return 'إنشاء';
      case 'update': case 'edit': return 'تعديل';
      case 'delete': case 'remove': return 'حذف';
      case 'login': return 'تسجيل دخول';
      case 'logout': return 'تسجيل خروج';
      case 'view': return 'عرض';
      case 'export': return 'تصدير';
      default: return action;
    }
  }
}
