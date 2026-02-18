import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DataService _ds;
  int _carsCount = 0;
  int _customersCount = 0;
  int _salesCount = 0;
  int _employeesCount = 0;
  int _accountsCount = 0;
  int _containersCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _loadStats();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _ds.getCars(_token).then((v) => v.length).catchError((_) => 0),
        _ds.getCustomers(_token).then((v) => v.length).catchError((_) => 0),
        _ds.getSales(_token).then((v) => v.length).catchError((_) => 0),
        _ds.getEmployees(_token).then((v) => v.length).catchError((_) => 0),
        _ds.getAccounts(_token).then((v) => v.length).catchError((_) => 0),
        _ds.getContainers(_token).then((v) => v.length).catchError((_) => 0),
      ]);
      if (!mounted) return;
      setState(() {
        _carsCount = results[0];
        _customersCount = results[1];
        _salesCount = results[2];
        _employeesCount = results[3];
        _accountsCount = results[4];
        _containersCount = results[5];
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tenant = auth.tenant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.dashboard),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryButton,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مرحباً، ${tenant?['ownerName'] ?? ""}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(tenant?['companyName'] ?? 'كارواتس', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats cards
            const Text('إحصائيات سريعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)))
            else
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
                children: [
                  _StatCard(icon: Icons.directions_car, label: 'السيارات', value: '$_carsCount', color: const Color(0xFF059669)),
                  _StatCard(icon: Icons.people, label: 'العملاء', value: '$_customersCount', color: const Color(0xFF0891B2)),
                  _StatCard(icon: Icons.point_of_sale, label: 'المبيعات', value: '$_salesCount', color: const Color(0xFFD97706)),
                  _StatCard(icon: Icons.badge, label: 'الموظفين', value: '$_employeesCount', color: const Color(0xFF2563EB)),
                  _StatCard(icon: Icons.account_balance, label: 'الحسابات', value: '$_accountsCount', color: const Color(0xFF7C3AED)),
                  _StatCard(icon: Icons.inventory_2, label: 'الحاويات', value: '$_containersCount', color: const Color(0xFF0284C7)),
                ],
              ),
            const SizedBox(height: 24),

            // Quick actions
            const Text('الوصول السريع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: [
                _QuickAction(icon: Icons.account_balance_outlined, label: 'الحسابات', color: const Color(0xFF2563EB), onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.accounts)),
                _QuickAction(icon: Icons.receipt_long_outlined, label: 'قيود محاسبية', color: const Color(0xFF7C3AED), onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.journalEntries)),
                _QuickAction(icon: Icons.add_card_outlined, label: 'تسجيل مصروف', color: const Color(0xFFEA580C), onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.expenseRecord)),
                _QuickAction(icon: Icons.directions_car_outlined, label: 'السيارات', color: const Color(0xFF059669), onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.cars)),
                _QuickAction(icon: Icons.point_of_sale_outlined, label: 'المبيعات', color: const Color(0xFFD97706), onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.salesPage)),
                _QuickAction(icon: Icons.people_outline, label: 'العملاء', color: const Color(0xFF0891B2), onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.customersPage)),
                _QuickAction(icon: Icons.local_shipping_outlined, label: 'الموردين', color: const Color(0xFFD97706), onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.suppliersPage)),
                _QuickAction(icon: Icons.inventory_2_outlined, label: 'الحاويات', color: const Color(0xFF0284C7), onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.containersPage)),
                _QuickAction(icon: Icons.warehouse_outlined, label: 'المستودعات', color: const Color(0xFF7C3AED), onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.warehousesPage)),
                _QuickAction(icon: Icons.badge_outlined, label: 'الموظفين', color: const Color(0xFF2563EB), onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.employeesPage)),
                _QuickAction(icon: Icons.receipt_outlined, label: 'الفواتير', color: const Color(0xFFEA580C), onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.billsPage)),
                _QuickAction(icon: Icons.business_outlined, label: 'إعدادات الشركة', color: const Color(0xFF64748B), onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.companySettingsPage)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
